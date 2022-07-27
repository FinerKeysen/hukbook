replication.c

**1、主向从写复制缓冲区的操作**

redis中

```c
void replicationFeedSlaves(list *slaves, int dictid, robj **argv, int argc);
```



keydb中拆分为两部分

```c
void replicationFeedSlave(client *replica, int dictid, robj **argv, int argc, bool fSendRaw);

void replicationFeedSlaves(list *slaves, int dictid, robj **argv, int argc);

// replicationFeedSlave在replicationFeedSlaves中被调用
```

keydb中都引用了下面的锁机制

```c
std::unique_lock<decltype(replica->lock)> lock(replica->lock);
```

博文[C++11中std::unique_lock的使用](https://blog.csdn.net/fengbingchun/article/details/78638138) 中说明：**std::unique_lock对象以独占所有权的方式(unique owership)管理mutex对象的上锁和解锁操作，即在unique_lock对象的声明周期内，它所管理的锁对象会一直保持上锁状态；而unique_lock的生命周期结束之后，它所管理的锁对象会被解锁**。

此外，相较redis的master-slave而言，keydb/replicationFeedSlaves中fActiveReplica非零时的操作，写入了更多的参数到复制缓冲区

```c
        {
            feedReplicationBacklog(proto, cchProto);
            feedReplicationBacklog(fake->buf, fake->bufpos);
            listRewind(fake->reply, &liReply);
            while ((lnReply = listNext(&liReply)))
            {
                clientReplyBlock* reply = (clientReplyBlock*)listNodeValue(lnReply);
                feedReplicationBacklog(reply->buf(), reply->used);
            }
            const char *crlf = "\r\n";
            feedReplicationBacklog(crlf, 2);
            feedReplicationBacklog(szDbNum, cchDbNum);
            feedReplicationBacklog(szMvcc, cchMvcc);
        }
```

向每个replica写命令时的不同：

```c
while(每个replica节点) { // 写协议和数据到缓冲区，发送给client buffer，client output buffer
    ...
    std::unique_lock<decltype(replica->lock)> lock(replica->lock, std::defer_lock);
    ...
    if (!fSendRaw)
                addReplyProtoAsync(replica, proto, cchProto);
    ...
    if (!fSendRaw)
            {
                addReplyAsync(replica,shared.crlf);
                addReplyProtoAsync(replica, szDbNum, cchDbNum);
                addReplyProtoAsync(replica, szMvcc, cchMvcc);
        	}
    ...
}
```



在void replconfCommand(client *c)中对传入的参数进行处理，其中uuid的处理如下

```c
        } else if (!strcasecmp((const char*)ptrFromObj(c->argv[j]),"uuid")) {
            /* REPLCONF uuid is used to set and send the UUID of each host */
            processReplconfUuid(c, c->argv[j+1]);
```

具体processReplconfUuid()函数如下

uuid格式与字符串格式的转换和保存

```c
void processReplconfUuid(client *c, robj *arg)
{
    const char *remoteUUID = nullptr;c
...
    remoteUUID = (const char*)ptrFromObj(arg);
    if (strlen(remoteUUID) != 36)
        goto LError;

    if (uuid_parse(remoteUUID, c->uuid) != 0)
        goto LError;

    char szServerUUID[36 + 2]; // 1 for the '+', another for '\0'
    szServerUUID[0] = '+';
    uuid_unparse(cserver.uuid, szServerUUID+1);
    addReplyProto(c, szServerUUID, 37);
    addReplyProto(c, "\r\n", 2);
    return;
...
}
```



replicaReplayCommand()

```c
    ...
	unsigned char uuid[UUID_BINARY_LEN];
    if (c->argv[1]->type != OBJ_STRING || sdslen((sds)ptrFromObj(c->argv[1])) != 36
        || uuid_parse((sds)ptrFromObj(c->argv[1]), uuid) != 0)
	...
    if (FSameUuidNoNil(uuid, cserver.uuid))
    ...
	// OK We've recieved a command lets execute
    client *current_clientSave = serverTL->current_client;
    client *cFake = createClient(-1, c->iel);
    cFake->lock.lock();
    cFake->authenticated = c->authenticated;
    cFake->puser = c->puser;
    cFake->querybuf = sdscatsds(cFake->querybuf,(sds)ptrFromObj(c->argv[2]));
    selectDb(cFake, c->db->id);
    auto ccmdPrev = serverTL->commandsExecuted;
    processInputBuffer(cFake, (CMD_CALL_FULL & (~CMD_CALL_PROPAGATE)));
    bool fExec = ccmdPrev != serverTL->commandsExecuted;
    cFake->lock.unlock();
```





Uncomment the option below to enable Active Active support. Note that replicas will still sync in the normal way and incorrect ordering when bringing up replicas can result in data loss (the first master will win).

取消注释以下选项以启用Active Active支持。 请注意，副本仍将以正常方式同步，并且在启动副本时错误的顺序会导致数据丢失（第一个主副本将获胜）。





```c
/* SYNC can't be issued when the server has pending data to send to
 * the client about already issued commands. We need a fresh reply
 * buffer registering the differences between the BGSAVE and the current
 * dataset, so that we can copy to other slaves if needed. */
 // 当服务器有待发送的有关已发出命令的数据发送给客户端时，将无法发出SYNC。
 // 我们需要一个新的答复缓冲区来注册BGSAVE和当前数据集之间的差异，
 // 以便在需要时可以将其复制到其他从站。
if (clientHasPendingReplies(c)) {
    addReplyError(c,"SYNC and PSYNC are invalid with pending output");
    return;
}
```


```
/* ----------------------- SYNCHRONOUS REPLICATION --------------------------
 * Redis synchronous replication design can be summarized in points:
 *
 * - Redis masters have a global replication offset, used by PSYNC.
 * - Master increment the offset every time new commands are sent to slaves.
 * - Slaves ping back masters with the offset processed so far.
 *
 * So synchronous replication adds a new WAIT command in the form:
 *
 *   WAIT <num_replicas> <milliseconds_timeout>
 *
 * That returns the number of replicas that processed the query when
 * we finally have at least num_replicas, or when the timeout was
 * reached.
 *
 * The command is implemented in this way:
 *
 * - Every time a client processes a command, we remember the replication
 *   offset after sending that command to the slaves.
 * - When WAIT is called, we ask slaves to send an acknowledgement ASAP.
 *   The client is blocked at the same time (see blocked.c).
 * - Once we receive enough ACKs for a given offset or when the timeout
 *   is reached, the WAIT command is unblocked and the reply sent to the
 *   client.
```

