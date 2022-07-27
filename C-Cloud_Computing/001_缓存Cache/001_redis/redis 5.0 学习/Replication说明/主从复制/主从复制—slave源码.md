## 主从复制—slave源码

用户可以通过执行slaveof命令开启主从复制功能。当Redis服务器接收到slaveof命令时，需要主动连接主服务器请求同步数据。slaveof命令的处理函数为replicaofCommand，这是我们分析slaver源码的入口，主要实现如下：

```c
// replication.c
void replicaofCommand(client *c) {
...
    /* The special host/port combination "NO" "ONE" turns the instance
     * into a master. Otherwise the new master address is set. */
    if (!strcasecmp(c->argv[1]->ptr,"no") &&
        !strcasecmp(c->argv[2]->ptr,"one")) {
        ...
    } else {
    	...
    	/* There was no previous master or the user specified a different one,
         * we can continue. */
        replicationSetMaster(c->argv[1]->ptr, port);
        ...
    }
    addReplay(c, shared.ok);
}

/* Set replication to the specified master address and port. */
void replicationSetMaster(char *ip, int port) {
    ...
    server.masterhost = sdsnew(ip);
    server.masterport = port;
	...
    server.repl_state = REPL_STATE_CONNECT;
}
```

可以看到用户可以通过命令“slaveof no one”取消主从复制功能，此时主从服务器之间会断开连接，从服务器成为普通的Redis实例。看到这里可能存在两个疑问：1）replica-ofCommand函数只是记录主服务器IP地址与端口，什么时候连接主服务器呢？2）变量repl_state有什么作用？

第一个问题。replicaofCommand函数实现并没有向主服务器发起连接请求，说明该操作应该是一个异步操作，那么很有可能是在时间事件中执行，搜索时间事件处理函数serverCron会发现，以一秒为周期执行主从复制相关操作：

```c
// ae.c/serverCron()
int serverCron(struct aeEventLoop *eventLoop, long long id, void *clientData) {
...
    /* Replication cron function -- used to reconnect to master,
     * detect transfer failures, start background RDB transfers and so forth. */
    run_with_period(1000) replicationCron();
...
}
```

显然可以看到在函数replicationCron中，从服务器向主服务器发起了连接请求：

```c
/* Replication cron function, called 1 time per second. */
void replicationCron(void) {
...
    /* Check if we should connect to a MASTER */
    if (server.repl_state == REPL_STATE_CONNECT) {
        serverLog(LL_NOTICE,"Connecting to MASTER %s:%d",
            server.masterhost, server.masterport);
        if (connectWithMaster() == C_OK) {
            serverLog(LL_NOTICE,"MASTER <-> REPLICA sync started");
        }
    }
...
}
```

待从服务器成功连接到主服务器时，还会创建对应的文件事件：

```c
// replication.c
int connectWithMaster(void) {
...
	aeCreateFileEvent(server.el,fd,AE_READABLE|AE_WRITABLE,syncWithMaster,NULL)
...
}
```

另外，replicationCron函数还用于检测主从连接是否超时，定时向主服务器发送心跳包，定时报告自己的复制偏移量等。

```c
// replication.c
/* Replication cron function, called 1 time per second. */
void replicationCron(void) {
...

    /* Non blocking connection timeout? */
    if (server.masterhost &&
        (server.repl_state == REPL_STATE_CONNECTING ||
         slaveIsInHandshakeState()) &&
         (time(NULL)-server.repl_transfer_lastio) > server.repl_timeout)
    {
        serverLog(LL_WARNING,"Timeout connecting to the MASTER...");
        cancelReplicationHandshake();
    }
...
}
```

变量repl_transfer_lastio存储的是主从服务器上次交互时间，repl_timeout表示主从服务器超时时间，用户可通过参数repl-timeout配置，默认为60，单位秒，超过此时间则认为主从服务器之间的连接出现故障，从服务器会主动断开连接。

```c
// replication.c
/* Send a REPLCONF ACK command to the master to inform it about the current
 * processed offset. If we are not connected with a master, the command has
 * no effects. */
void replicationSendAck(void) {
    client *c = server.master;

    if (c != NULL) {
        c->flags |= CLIENT_MASTER_FORCE_REPLY;
        addReplyMultiBulkLen(c,3);
        addReplyBulkCString(c,"REPLCONF");
        addReplyBulkCString(c,"ACK");
        addReplyBulkLongLong(c,c->reploff);
        c->flags &= ~CLIENT_MASTER_FORCE_REPLY;
    }
}
```

从服务器通过命令“REPLCONF ACK < reploff >”定时向主服务器汇报自己的复制偏移量，主服务器使用变量repl_ack_time存储接收到该命令的时间，以此作为检测从服务器是否有效的标准。

第二个问题。当从服务器接收到slaveof命令时，会主动连接主服务器请求同步数据，这并不是一蹴而就的，需要若干个步骤交互：

1）连接Socket；
2）发送PING请求包确认连接是否正确；
3）发起密码认证（如果需要）；
4）信息同步；
5）发送PSYNC命令；
6）接收RDB文件并载入；
7）连接建立完成，等待主服务器同步命令请求。

变量repl_state表示的就是主从复制流程的进展（从服务器状态）, Redis定义了以下状态：

```c
// server.h
/* Slave replication state. Used in server.repl_state for slaves to remember
 * what to do next. */
// 未开启主从复制功能，当前服务器是普通的Redis实例
#define REPL_STATE_NONE 0 /* No active replication */
// 待发起Socket连接主服务器；
#define REPL_STATE_CONNECT 1 /* Must connect to master */
// Socket连接成功；
#define REPL_STATE_CONNECTING 2 /* Connecting to master */

/* --- Handshake states, must be ordered --- */
// 已经发送了PING请求包，并等待接收主服务器PONG回复；
#define REPL_STATE_RECEIVE_PONG 3 /* Wait for PING reply */
// 待发起密码认证；
#define REPL_STATE_SEND_AUTH 4 /* Send AUTH to master */
// 已经发起了密码认证请求“AUTH<password>”，等待接收主服务器回复；
#define REPL_STATE_RECEIVE_AUTH 5 /* Wait for AUTH reply */
// 待发送端口号
#define REPL_STATE_SEND_PORT 6 /* Send REPLCONF listening-port */
// 已发送端口号“REPLCONFlistening-port <port>”，等待接收主服务器回复；
#define REPL_STATE_RECEIVE_PORT 7 /* Wait for REPLCONF reply */
// 待发送IP地址；
#define REPL_STATE_SEND_IP 8 /* Send REPLCONF ip-address */
// 已发送IP地址“REPLCONF ip-address <ip>”，等待接收主服务器回复；该IP地址与端口号用于主服务器主动建立Socket连接，并向从服务器同步数据；
#define REPL_STATE_RECEIVE_IP 9 /* Wait for REPLCONF reply */
// 主从复制功能进行过优化升级，不同版本Redis服务器支持的能力可能不同，因此从服务器需要告诉主服务器自己支持的主从复制能力，通过命令“REPLCONF capa<capability>”实现；
#define REPL_STATE_SEND_CAPA 10 /* Send REPLCONF capa */
// 等待接收主服务器回复；
#define REPL_STATE_RECEIVE_CAPA 11 /* Wait for REPLCONF reply */
// 待发送PSYNC命令；
#define REPL_STATE_SEND_PSYNC 12 /* Send PSYNC */
// 等待接收主服务器PSYNC命令的回复结果；
#define REPL_STATE_RECEIVE_PSYNC 13 /* Wait for PSYNC reply */

/* --- End of handshake states --- */
// 正在接收RDB文件；
#define REPL_STATE_TRANSFER 14 /* Receiving .rdb from master */
// RDB文件接收并载入完毕，主从复制连接建立成功。此时从服务器只需要等待接收主服务器同步数据即可。
#define REPL_STATE_CONNECTED 15 /* Connected to master */
```

上面说过，待从服务器成功连接到主服务器时，还会创建对应的文件事件，处理函数为syncWithMaster（当Socket可读或者可写时调用执行），主要实现从服务器与主服务器的交互流程，即完成从服务器的状态转换。下面分析从服务器状态转换源码实现，其中符号“→”表示状态转换。

1）REPL_STATE_CONNECTING→REPL_STATE_RECEIVE_PONG：

```c
// replication.c/void syncWithMaster()

    /* Send a PING to check the master is able to reply without errors. */
    if (server.repl_state == REPL_STATE_CONNECTING) {
        serverLog(LL_NOTICE,"Non blocking connect for SYNC fired the event.");
        /* Delete the writable event so that the readable event remains
         * registered and we can wait for the PONG reply. */
        aeDeleteFileEvent(server.el,fd,AE_WRITABLE);
        server.repl_state = REPL_STATE_RECEIVE_PONG;
        /* Send the PING, don't check for errors at all, we have the timeout
         * that will take care about this. */
        err = sendSynchronousCommand(SYNC_CMD_WRITE,fd,"PING",NULL);
        if (err) goto write_error;
        return;
    }
```

可以看到，当检测到当前状态为REPL_STATE_CONNECTING，从服务器发送PING命令请求，并修改状态为REPL_STATE_RECEIVE_PONG，函数直接返回。

2）REPL_STATE_RECEIVE_PONG→REPL_STATE_SEND_AUTH→REPL_STATE_RECEIVE_AUTH（或REPL_STATE_SEND_PORT）：

```c
// replication.c/void syncWithMaster()

    /* Receive the PONG command. */
    if (server.repl_state == REPL_STATE_RECEIVE_PONG) {
        err = sendSynchronousCommand(SYNC_CMD_READ,fd,NULL);

        /* We accept only two replies as valid, a positive +PONG reply
         * (we just check for "+") or an authentication error.
         * Note that older versions of Redis replied with "operation not
         * permitted" instead of using a proper error code, so we test
         * both. */
        if (err[0] != '+' &&
            strncmp(err,"-NOAUTH",7) != 0 &&
            strncmp(err,"-ERR operation not permitted",28) != 0)
        {
            serverLog(LL_WARNING,"Error reply to PING from master: '%s'",err);
            sdsfree(err);
            goto error;
        } else {
            serverLog(LL_NOTICE,
                "Master replied to PING, replication can continue...");
        }
        sdsfree(err);
        server.repl_state = REPL_STATE_SEND_AUTH;
    }

    /* AUTH with the master if required. */
    if (server.repl_state == REPL_STATE_SEND_AUTH) {
        if (server.masterauth) {
            err = sendSynchronousCommand(SYNC_CMD_WRITE,fd,"AUTH",server.masterauth,NULL);
            if (err) goto write_error;
            server.repl_state = REPL_STATE_RECEIVE_AUTH;
            return;
        } else {
            server.repl_state = REPL_STATE_SEND_PORT;
        }
    }
```

当检测到当前状态为REPL_STATE_RECEIVE_PONG，会从socket中读取主服务器PONG回复，并修改状态为REPL_STATE_SEND_AUT；可以看到这里函数没有返回，也就是说下面的if语句依然会执行。如果用户配置了参数“masterauth <master-password>”，从服务器会向主服务器发送密码认证请求，同时修改状态为REPL_STATE_RECEIVE_AUTH。否则，修改状态为REPL_STATE_SEND_PORT，同样，这里函数也没有返回，会继续执行4）中状态转换逻辑。

3）REPL_STATE_RECEIVE_AUTH→REPL_STATE_SEND_PORT：

```c
// replication.c/void syncWithMaster()

    /* Receive AUTH reply. */
    if (server.repl_state == REPL_STATE_RECEIVE_AUTH) {
        err = sendSynchronousCommand(SYNC_CMD_READ,fd,NULL);
        if (err[0] == '-') {
            serverLog(LL_WARNING,"Unable to AUTH to MASTER: %s",err);
            sdsfree(err);
            goto error;
        }
        sdsfree(err);
        server.repl_state = REPL_STATE_SEND_PORT;
    }
```

当检测到当前状态REPL_STATE_RECEIVE_AUTH，会从Socket中读取主服务器回复结果，并修改状态为REPL_STATE_SEND_PORT，同样的这里函数也没有返回，会继续执行4）中状态转换逻辑。

4）REPL_STATE_SEND_PORT→REPL_STATE_RECEIVE_PORT：

```c
// replication.c/void syncWithMaster()

    /* Set the slave port, so that Master's INFO command can list the
     * slave listening port correctly. */
    if (server.repl_state == REPL_STATE_SEND_PORT) {
        sds port = sdsfromlonglong(server.slave_announce_port ?
            server.slave_announce_port : server.port);
        err = sendSynchronousCommand(SYNC_CMD_WRITE,fd,"REPLCONF",
                "listening-port",port, NULL);
        sdsfree(port);
        if (err) goto write_error;
        sdsfree(err);
        server.repl_state = REPL_STATE_RECEIVE_PORT;
        return;
    }
```

当检测到当前状态为REPL_STATE_SEND_PORT，从服务器向主服务器发送端口号，并修改状态为REPL_STATE_RECEIVE_PORT，函数直接返回。

5）REPL_STATE_RECEIVE_PORT→EPL_STATE_SEND_IP→REPL_STATE_RECEIVE_IP：

```c
// replication.c/void syncWithMaster()

    /* Receive REPLCONF listening-port reply. */
    if (server.repl_state == REPL_STATE_RECEIVE_PORT) {
        err = sendSynchronousCommand(SYNC_CMD_READ,fd,NULL);
        /* Ignore the error if any, not all the Redis versions support
         * REPLCONF listening-port. */
        if (err[0] == '-') {
            serverLog(LL_NOTICE,"(Non critical) Master does not understand "
                                "REPLCONF listening-port: %s", err);
        }
        sdsfree(err);
        server.repl_state = REPL_STATE_SEND_IP;
    }

    /* Skip REPLCONF ip-address if there is no slave-announce-ip option set. */
    if (server.repl_state == REPL_STATE_SEND_IP &&
        server.slave_announce_ip == NULL)
    {
            server.repl_state = REPL_STATE_SEND_CAPA;
    }

    /* Set the slave ip, so that Master's INFO command can list the
     * slave IP address port correctly in case of port forwarding or NAT. */
    if (server.repl_state == REPL_STATE_SEND_IP) {
        err = sendSynchronousCommand(SYNC_CMD_WRITE,fd,"REPLCONF",
                "ip-address",server.slave_announce_ip, NULL);
        if (err) goto write_error;
        sdsfree(err);
        server.repl_state = REPL_STATE_RECEIVE_IP;
        return;
    }
```

当检测到当前状态为REPL_STATE_RECEIVE_PORT，会从Socket中读取主服务器回复结果，并修改状态为REPL_STATE_SEND_IP。函数没有返回，会继续执行下面的if语句；向主服务器发送IP地址，并修改状态为REPL_STATE_RECEIVE_IP，函数返回。

6）REPL_STATE_RECEIVE_IP→REPL_STATE_SEND_CAPA→REPL_STATE_RECEIVE_CAPA：

```c
// replication.c/void syncWithMaster()

    /* Receive REPLCONF ip-address reply. */
    if (server.repl_state == REPL_STATE_RECEIVE_IP) {
        err = sendSynchronousCommand(SYNC_CMD_READ,fd,NULL);
        /* Ignore the error if any, not all the Redis versions support
         * REPLCONF listening-port. */
        if (err[0] == '-') {
            serverLog(LL_NOTICE,"(Non critical) Master does not understand "
                                "REPLCONF ip-address: %s", err);
        }
        sdsfree(err);
        server.repl_state = REPL_STATE_SEND_CAPA;
    }

    /* Inform the master of our (slave) capabilities.
     *
     * EOF: supports EOF-style RDB transfer for diskless replication.
     * PSYNC2: supports PSYNC v2, so understands +CONTINUE <new repl ID>.
     *
     * The master will ignore capabilities it does not understand. */
    if (server.repl_state == REPL_STATE_SEND_CAPA) {
        err = sendSynchronousCommand(SYNC_CMD_WRITE,fd,"REPLCONF",
                "capa","eof","capa","psync2",NULL);
        if (err) goto write_error;
        sdsfree(err);
        server.repl_state = REPL_STATE_RECEIVE_CAPA;
        return;
    }
```

当检测到当前状态为REPL_STATE_RECEIVE_IP时，会从Socket中读取主服务器回复结果，并修改状态为REPL_STATE_SEND_CAPA。函数没有返回，会继续执行下面的if语句；可以看到这里向主服务器发送“REPLCONF capa eof capa psync2”, capa为单词capability的简写，意为能力，表示的是从服务器支持的主从复制功能。Redis主从复制经历过优化升级，高版本的Redis服务器可能支持更多的功能，因此这里从服务器需要向主服务器同步自身具备的功能。

主从复制功能实现中，主服务器在接收到psync命令时，如果必须执行完整重同步，会持久化数据库到RDB文件，完成后将RDB文件发送给从服务器。而当从服务器支持“eof”功能时，主服务器便可以直接将数据库中的数据以RDB协议格式通过Socket发送给从服务器，免去了本地磁盘文件不必要的读写操作。

Redis 4.0针对主从复制提出了psync2协议，使得主服务器故障导致主从切换后，依然有可能执行部分重同步。而这时候当主服务器接收到psync命令时，向客户端回复的是“+CONTINUE <new_repl_id>”。参数“psync2”表明从服务器支持psync2协议。

最后从服务器修改状态为REPL_STATE_RECEIVE_CAPA，函数返回。

1）REPL_STATE_RECEIVE_CAPA→REPL_STATE_SEND_PSYNC→REPL_STATE_RECEIVE_PSYNC：

```c
// replication.c/void syncWithMaster()

    /* Receive CAPA reply. */
    if (server.repl_state == REPL_STATE_RECEIVE_CAPA) {
        err = sendSynchronousCommand(SYNC_CMD_READ,fd,NULL);
        /* Ignore the error if any, not all the Redis versions support
         * REPLCONF capa. */
        if (err[0] == '-') {
            serverLog(LL_NOTICE,"(Non critical) Master does not understand "
                                  "REPLCONF capa: %s", err);
        }
        sdsfree(err);
        server.repl_state = REPL_STATE_SEND_PSYNC;
    }

    /* Try a partial resynchonization. If we don't have a cached master
     * slaveTryPartialResynchronization() will at least try to use PSYNC
     * to start a full resynchronization so that we get the master run id
     * and the global offset, to try a partial resync at the next
     * reconnection attempt. */
    if (server.repl_state == REPL_STATE_SEND_PSYNC) {
        if (slaveTryPartialResynchronization(fd,0) == PSYNC_WRITE_ERROR) {
            err = sdsnew("Write error sending the PSYNC command.");
            goto write_error;
        }
        server.repl_state = REPL_STATE_RECEIVE_PSYNC;
        return;
    }
```

当检测到当前状态为REPL_STATE_RECEIVE_CAPA，会从Socket中读取主服务器回复结果，并修改状态为REPL_STATE_SEND_PSYNC。函数没有返回，会继续执行下面的if语句。可以看到这里调用函数slaveTryPartialResynchronization尝试执行部分重同步，并修改状态为REPL_STATE_RECEIVE_PSYNC。

函数slaveTryPartialResynchronization主要执行两个操作：1）尝试获取主服务器运行ID以及复制偏移量，并向主服务器发送psync命令请求；2）读取并解析psync命令回复，判断执行完整重同步还是部分重同步。函数slaveTryPartialResynchronization第二个参数表明执行操作1还是操作2。

2）REPL_STATE_RECEIVE_PSYNC→REPL_STATE_TRANSFER：

```c
// replication.c/void syncWithMaster()
...
    psync_result = slaveTryPartialResynchronization(fd,1);
    if (psync_result == PSYNC_WAIT_REPLY) return; /* Try again later... */

    /* If the master is in an transient error, we should try to PSYNC
     * from scratch later, so go to the error path. This happens when
     * the server is loading the dataset or is not connected with its
     * master and so forth. */
    if (psync_result == PSYNC_TRY_LATER) goto error;

    /* Note: if PSYNC does not return WAIT_REPLY, it will take care of
     * uninstalling the read handler from the file descriptor. */

    if (psync_result == PSYNC_CONTINUE) {
        serverLog(LL_NOTICE, "MASTER <-> REPLICA sync: Master accepted a Partial Resynchronization.");
        return;
    }
...
    /* Setup the non blocking download of the bulk file. */
    if (aeCreateFileEvent(server.el,fd, AE_READABLE,readSyncBulkPayload,NULL)
            == AE_ERR)
    {
        serverLog(LL_WARNING,
            "Can't create readable event for SYNC: %s (fd=%d)",
            strerror(errno),fd);
        goto error;
    }

    server.repl_state = REPL_STATE_TRANSFER;
...
```

调用函数slaveTryPartialResynchronization读取并解析psync命令回复时，如果返回的是PSYNC_CONTINUE，表明可以执行部分重同步（函数slaveTryPartialResynchronization内部会修改状态为REPL_STATE_CONNECTED）。否则说明需要执行完整重同步，从服务器需要准备接收主服务器发送的RDB文件，可以看到这里创建了文件事件，处理函数为readSyncBulkPayload，并修改状态为REPL_STATE_TRANSFER。

函数readSyncBulkPayload实现了RDB文件的接收与加载，加载完成后同时会修改状态为REPL_STATE_CONNECTED。当从服务器状态成为REPL_STATE_CONNECTED时，表明从服务器已经成功与主服务器建立连接，从服务器只需要接收并执行主服务器同步过来的命令请求即可，与执行普通客户端命令请求差别不大。

