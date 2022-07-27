## 主从复制—master源码

从服务器接收到slaveof命令会主动连接主服务器请求同步数据，主要流程有：① 连接Socket; ② 发送PING请求包确认连接是否正确；③ 发起密码认证（如果需要）; ④ 通过REPLCONF命令同步信息；⑤ 发送PSYNC命令；⑥ 接收RDB文件并载入；⑦ 连接建立完成，等待主服务器同步命令请求。

主服务器针对流程中①～③的处理比较简单，这里不做介绍，本节主要介绍主服务器针对④～⑦的处理。

主服务器处理命令REPLCONF的入口函数为replconfCommand，实现如下：

```c
// replication.c/replconfCommand()
/* REPLCONF <option> <value> <option> <value> ...
 * This command is used by a slave in order to configure the replication
 * process before starting it with the SYNC command.
 *
 * Currently the only use of this command is to communicate to the master
 * what is the listening port of the Slave redis instance, so that the
 * master can accurately list slaves and their listening ports in
 * the INFO output.
 *
 * In the future the same command can be used in order to configure
 * the replication to initiate an incremental replication instead of a
 * full resync. */
void replconfCommand(client *c) {
...
    
...
}
```

函数replconfCommand主要解析客户端请求参数并存储在客户端对象client中，主要需要记录以下信息。

-   从服务器监听IP地址与端口，主服务器以此连接从服务器并同步数据。
-   客户端能力标识，eof标识主服务器可以直接将数据库中数据以RDB协议格式通过socket发送给从服务器，免去了本地磁盘文件不必要的读写操作；psync2表明从服务器支持psync2协议，即从服务器可以识别主服务器回复的“+CONTINUE <new_repl_id>”。
-   从服务器的复制偏移量以及交互时间。

接下来从服务器将向主服务器发送psync命令请求同步数据，主服务器处理psync命令的入口函数为syncCommand。主服务器首先判断是否可以执行部分重同步，如果可以则向客户端返回“+CONTINUE”，并返回复制缓冲区中的命令请求，同时更新有效从服务器数目。

```c
// replication.c/syncCommand()
/* SYNC and PSYNC command implemenation. */
void syncCommand(client *c) {
...
    /* Try a partial resynchronization if this is a PSYNC command.
     * If it fails, we continue with usual full resynchronization, however
     * when this happens masterTryPartialResynchronization() already
     * replied with:
     *
     * +FULLRESYNC <replid> <offset>
     *
     * So the slave knows the new replid and offset to try a PSYNC later
     * if the connection with the master is lost. */
    if (!strcasecmp(c->argv[0]->ptr,"psync")) {
        if (masterTryPartialResynchronization(c) == C_OK) {
            server.stat_sync_partial_ok++;
            return; /* No full resync needed, return. */
        } else {
            char *master_replid = c->argv[1]->ptr;

            /* Increment stats for failed PSYNCs, but only if the
             * replid is not "?", as this is used by slaves to force a full
             * resync on purpose when they are not albe to partially
             * resync. */
            if (master_replid[0] != '?') server.stat_sync_partial_err++;
        }
    } else {
        /* If a slave uses SYNC, we are dealing with an old implementation
         * of the replication protocol (like redis-cli --slave). Flag the client
         * so that we don't expect to receive REPLCONF ACK feedbacks. */
        c->flags |= CLIENT_PRE_PSYNC;
    } 
...
}
```
主从复制初始化流程图

![](%E4%B8%BB%E4%BB%8E%E5%A4%8D%E5%88%B6%E2%80%94master%E6%BA%90%E7%A0%81.assets/image-20200226200720559.png)


```c
// replication.c
/* This function handles the PSYNC command from the point of view of a
 * master receiving a request for partial resynchronization.
 *
 * On success return C_OK, otherwise C_ERR is returned and we proceed
 * with the usual full resync. */
int masterTryPartialResynchronization(client *c) {
    long long psync_offset, psync_len;
    char *master_replid = c->argv[1]->ptr;
    char buf[128];
    int buflen;

    /* Parse the replication offset asked by the slave. Go to full sync
     * on parse error: this should never happen but we try to handle
     * it in a robust way compared to aborting. */
    if (getLongLongFromObjectOrReply(c,c->argv[2],&psync_offset,NULL) !=
       C_OK) goto need_full_resync;

    /* Is the replication ID of this master the same advertised by the wannabe
     * slave via PSYNC? If the replication ID changed this master has a
     * different replication history, and there is no way to continue.
     *
     * Note that there are two potentially valid replication IDs: the ID1
     * and the ID2. The ID2 however is only valid up to a specific offset. */
    // 判断服务器运行ID是否匹配，复制偏移量是否合法
    if (strcasecmp(master_replid, server.replid) &&
        (strcasecmp(master_replid, server.replid2) ||
         psync_offset > server.second_replid_offset))
    {
        /* Run id "?" is used by slaves that want to force a full resync. */
        if (master_replid[0] != '?') {
            if (strcasecmp(master_replid, server.replid) &&
                strcasecmp(master_replid, server.replid2))
            {
                serverLog(LL_NOTICE,"Partial resynchronization not accepted: "
                    "Replication ID mismatch (Replica asked for '%s', my "
                    "replication IDs are '%s' and '%s')",
                    master_replid, server.replid, server.replid2);
            } else {
                serverLog(LL_NOTICE,"Partial resynchronization not accepted: "
                    "Requested offset for second ID was %lld, but I can reply "
                    "up to %lld", psync_offset, server.second_replid_offset);
            }
        } else {
            serverLog(LL_NOTICE,"Full resync requested by replica %s",
                replicationGetSlaveName(c));
        }
        goto need_full_resync;
    }

    /* We still have the data our slave is asking for? */
    // 判断复制偏移量是否包含在复制缓冲区
    if (!server.repl_backlog ||
        psync_offset < server.repl_backlog_off ||
        psync_offset > (server.repl_backlog_off + server.repl_backlog_histlen))
    {
        serverLog(LL_NOTICE,
            "Unable to partial resync with replica %s for lack of backlog (Replica request was: %lld).", replicationGetSlaveName(c), psync_offset);
        if (psync_offset > server.master_repl_offset) {
            serverLog(LL_WARNING,
                "Warning: replica %s tried to PSYNC with an offset that is greater than the master replication offset.", replicationGetSlaveName(c));
        }
        goto need_full_resync;
    }

    /* If we reached this point, we are able to perform a partial resync:
     * 1) Set client state to make it a slave.
     * 2) Inform the client we can continue with +CONTINUE
     * 3) Send the backlog data (from the offset to the end) to the slave. */
    // 部分重同步，标识从服务器
    c->flags |= CLIENT_SLAVE;
    c->replstate = SLAVE_STATE_ONLINE;
    c->repl_ack_time = server.unixtime;
    c->repl_put_online_on_ack = 0;
    // 将该客户端添加到从服务器链表slaves中
    listAddNodeTail(server.slaves,c);
    /* We can't use the connection buffers since they are used to accumulate
     * new commands at this stage. But we are sure the socket send buffer is
     * empty so this write will never fail actually. */
    // 根据从服务器能力返回+CONTINUE
    if (c->slave_capa & SLAVE_CAPA_PSYNC2) {
        buflen = snprintf(buf,sizeof(buf),"+CONTINUE %s\r\n", server.replid);
    } else {
        buflen = snprintf(buf,sizeof(buf),"+CONTINUE\r\n");
    }
    if (write(c->fd,buf,buflen) != buflen) {
        freeClientAsync(c);
        return C_OK;
    }
    // 向客户端发送复制缓冲区中的命令请求
    psync_len = addReplyReplicationBacklog(c,psync_offset);
    serverLog(LL_NOTICE,
        "Partial resynchronization request from %s accepted. Sending %lld bytes of backlog starting from offset %lld.",
            replicationGetSlaveName(c),
            psync_len, psync_offset);
    /* Note that we don't need to set the selected DB at server.slaveseldb
     * to -1 to force the master to emit SELECT, since the slave already
     * has this state from the previous connection with the master. */

    // 更新从服务器数目
    refreshGoodSlavesCount();
    return C_OK; /* The caller can return, no full resync needed. */

need_full_resync:
    /* We need a full resync for some reason... Note that we can't
     * reply to PSYNC right now if a full SYNC is needed. The reply
     * must include the master offset at the time the RDB file we transfer
     * is generated, so we need to delay the reply to that moment. */
    return C_ERR;
}
```

执行部分重同步是有条件的：① 服务器运行ID与复制偏移量必须合法；②复制偏移量必须包含在复制缓冲区中。当可以执行部分重同步时，主服务器便将该客户端添加到自己的从服务器链表slaves，并标记客户端状态为SLAVE_STATE_ONLINE，客户端类型为CLIENT_SLAVE（从服务器）。流程④中，从服务器已经通过命令请求REPLCONF向主服务器同步了自己支持的能力，主服务器根据该能力决定向从服务器返回“+CONTINUE”还是“+CONTINUE < replid >”。接下来主服务器还需要根据PSYNC请求参数中的复制偏移量，将复制缓冲区中的部分命令请求同步给从服务器。由于有新的从服务器连接成功，主服务器还需要更新有效从服务器数目，以此实现min_slaves功能。

当主服务器判断需要**执行完整重同步**时，会fork子进程执行RDB持久化，并将持久化数据发送给从服务器。RDB持久化有两种选择：① 直接通过Socket发送给从服务器；② 持久化数据到本地文件，待持久化完成后再将该文件发送给从服务器。

```c
// replication.c/int startBgsaveForReplication(int mincapa)

        if (socket_target)
            retval = rdbSaveToSlavesSockets(rsiptr);
        else
            retval = rdbSaveBackground(server.rdb_filename,rsiptr);
```

变量socket_target的赋值逻辑如下：

```c
// replication.c/int startBgsaveForReplication(int mincapa)
	int socket_target = server.repl_diskless_sync && (mincapa & SLAVE_CAPA_EOF);
```

其中变量repl_diskless_sync可通过配置参数repl-diskless-sync进行设置，默认为0；即默认情况下，主服务器都是先持久化数据到本地文件，再将该文件发送给从服务器。变量slave_capa根据步骤④从服务器的同步信息确定。

当所有流程执行完毕后，主服务器每次接收到写命令请求时，都会将该命令请求广播给所有从服务器，同时记录在复制缓冲区中。向从服务器广播命令请求的实现函数为replicationFeedSlaves，逻辑如下：

```c
// replication.c
/* Propagate write commands to slaves, and populate the replication backlog
 * as well. This function is used if the instance is a master: we use
 * the commands received by our clients in order to create the replication
 * stream. Instead if the instance is a slave and has sub-slaves attached,
 * we use replicationFeedSlavesFromMaster() */
void replicationFeedSlaves(list *slaves, int dictid, robj **argv, int argc) {
    ...
    /* Send SELECT command to every slave if needed. */
    // 如果与上次选择的数据库不相同，需要先同步select命令
    if (server.slaveseldb != dictid) {
        robj *selectcmd;

        /* For a few DBs we have pre-computed SELECT command. */
        if (dictid >= 0 && dictid < PROTO_SHARED_SELECT_CMDS) {
            selectcmd = shared.select[dictid];
        } else {
            int dictid_len;

            dictid_len = ll2string(llstr,sizeof(llstr),dictid);
            selectcmd = createObject(OBJ_STRING,
                sdscatprintf(sdsempty(),
                "*2\r\n$6\r\nSELECT\r\n$%d\r\n%s\r\n",
                dictid_len, llstr));
        }

        /* Add the SELECT command into the backlog. */
        // 将select命令添加到复制缓冲区
        if (server.repl_backlog) feedReplicationBacklogWithObject(selectcmd);

        /* Send it to slaves. */
        listRewind(slaves,&li);
        // 向所有从服务器发送select命令
        while((ln = listNext(&li))) {
            client *slave = ln->value;
            if (slave->replstate == SLAVE_STATE_WAIT_BGSAVE_START) continue;
            addReply(slave,selectcmd);
        }

        if (dictid < 0 || dictid >= PROTO_SHARED_SELECT_CMDS)
            decrRefCount(selectcmd);
    }
    server.slaveseldb = dictid;

    /* Write the command to the replication backlog if any. */
    if (server.repl_backlog) {// 将当前命令请求添加到复制缓冲区
        char aux[LONG_STR_SIZE+3];

        /* Add the multi bulk reply length. */
        aux[0] = '*';
        len = ll2string(aux+1,sizeof(aux)-1,argc);
        aux[len+1] = '\r';
        aux[len+2] = '\n';
        feedReplicationBacklog(aux,len+3);

        for (j = 0; j < argc; j++) {
            long objlen = stringObjectLen(argv[j]);

            /* We need to feed the buffer with the object as a bulk reply
             * not just as a plain string, so create the $..CRLF payload len
             * and add the final CRLF */
            aux[0] = '$';
            len = ll2string(aux+1,sizeof(aux)-1,objlen);
            aux[len+1] = '\r';
            aux[len+2] = '\n';
            feedReplicationBacklog(aux,len+3);
            feedReplicationBacklogWithObject(argv[j]);
            feedReplicationBacklog(aux+len+1,2);
        }
    }

    /* Write the command to every slave. */
    listRewind(slaves,&li);
    while((ln = listNext(&li))) {// 向所有从服务器同步命令请求
        client *slave = ln->value;

        /* Don't feed slaves that are still waiting for BGSAVE to start */
        if (slave->replstate == SLAVE_STATE_WAIT_BGSAVE_START) continue;

        /* Feed slaves that are waiting for the initial SYNC (so these commands
         * are queued in the output buffer until the initial SYNC completes),
         * or are already in sync with the master. */

        /* Add the multi bulk length. */
        addReplyMultiBulkLen(slave,argc);

        /* Finally any additional argument that was not stored inside the
         * static buffer if any (from j to argc). */
        for (j = 0; j < argc; j++)
            addReplyBulk(slave,argv[j]);
    }
}
```

当前客户端连接的数据库可能并不是上次向从服务器同步数据的数据库，因此可能需要先向从服务器同步select命令修改数据库。针对每个写命令，主服务器都需要将命令请求同步给所有从服务器，同时从上面代码可以看到，向从服务器同步的每个命令请求，都会记录到复制缓冲区中。