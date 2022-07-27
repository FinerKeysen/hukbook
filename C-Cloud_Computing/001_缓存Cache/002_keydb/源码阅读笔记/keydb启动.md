[TOC]



# keydb的启动

## 相较于redis启动的不同

KeyDB将redis原来的主线程拆分成了主线程和worker线程。每个worker线程都是io线程，负责监听端口，accept请求，读取数据和解析协议。

### 线程初始化

在initServerConfig()之后有管理线程循环(抽象出多线程变量结构体)的初始化，实际是keydb的主线程，即rghreadvar[0]

```c
// server.cpp/main()
for (int iel = 0; iel < MAX_EVENT_LOOPS; ++iel)
    {
        initServerThread(g_pserver->rgthreadvar+iel, iel == IDX_EVENT_LOOP_MAIN);
    }
    serverTL = &g_pserver->rgthreadvar[IDX_EVENT_LOOP_MAIN];
    aeAcquireLock();    // We own the lock on boot
```

### 账户权限管理系统初始化

```c
// server.cpp/main()
	ACLInit(); /* The ACL subsystem must be initialized ASAP because the
                  basic networking code and client creation depends on it. */
```

### 基本的有效性校验

```c
// server.cpp/main()
// 可设置的线程数量；
// 启动多主时是否开启activeReplcation，即 multimaster标志和fActiveReplica标志
validateConfiguration();
```

keydb采用线程对象数组来代替redis中的事件循环

```c
// server.cpp/main()/initServer()
    /* Create the timer callback, this is our way to process many background
     * operations incrementally, like clients timeout, eviction of unaccessed
     * expired keys and so forth. */
    if (aeCreateTimeEvent(g_pserver->rgthreadvar[IDX_EVENT_LOOP_MAIN].el, 1, serverCron, NULL, NULL) == AE_ERR) {
        serverPanic("Can't create event loop timers.");
        exit(1);
    }
```

看线程对象定义：实际上keydb将redis中管理客户端、事件循环、文件描述符等相关的对象进行再次封装，redis是单线程而keydb是多线程

```c
// Per-thread variabels that may be accessed without a lock
struct redisServerThreadVars {
    aeEventLoop *el;
    int ipfd[CONFIG_BINDADDR_MAX]; /* TCP socket file descriptors */
    int ipfd_count;             /* Used slots in ipfd[] */
    int clients_paused;         /* True if clients are currently paused */
    std::vector<client*> clients_pending_write; /* There is to write or install handler. */
    list *unblocked_clients;     /* list of clients to unblock before next loop NOT THREADSAFE */
    list *clients_pending_asyncwrite;
    int cclients;
    client *current_client; /* Current client */
    int module_blocked_pipe[2]; /* Pipe used to awake the event loop if a
                                client blocked on a module command needs
                                to be processed. */
    client *lua_client = nullptr;   /* The "fake client" to query Redis from Lua */
    struct fastlock lockPendingWrite { "thread pending write" };
    char neterr[ANET_ERR_LEN];   /* Error buffer for anet.c */
    long unsigned commandsExecuted = 0;
};
```

### 创建uuid

```c
// server.cpp/main()/initServer()
	/* Generate UUID */
    static_assert(sizeof(uuid_t) == sizeof(cserver.uuid), "UUIDs are standardized at 16-bytes");
    uuid_generate((unsigned char*)cserver.uuid);
// 调用内核uuid/uuid.h/uuid_generate()函数
```

uuid可参考：https://www.cnblogs.com/oloroso/p/4633744.html

### 初始化后台系统，生成线程。

```c
// 调用在 server.cpp/main()/initServer()/bioInit()

// 实现在 bio.cpp
void bioInit(void){}
```

### 在initNetworking()中启动监听

```c
// server.c/main()
initNetworking(cserver.cthreads > 1 /* fReusePort */);

// 实现
// server.c/initnetworking()
{
    ...;
    // TCP socket
        for (int iel = 0; iel < celListen; ++iel)
        initNetworkingThread(iel, fReusePort);
    ...;
    // Unix socket
        if (g_pserver->sofd > 0 && aeCreateFileEvent(g_pserver->rgthreadvar[IDX_EVENT_LOOP_MAIN].el,g_pserver->sofd,AE_READABLE|AE_READ_THREADSAFE,
        acceptUnixHandler,NULL) == AE_ERR) serverPanic("Unrecoverable error creating g_pserver->sofd file event.");
}
```

其中`initNetworkingThread`函数启动监听

```c
// 在server.cpp/initNetworkingThread()中调用
// 实现
// server.cpp
static void initNetworkingThread(int iel, int fReusePort)
{
    /* Open the TCP listening socket for the user commands. */
    if (fReusePort || (iel == IDX_EVENT_LOOP_MAIN))
    {
        if (g_pserver->port != 0 &&
            listenToPort(g_pserver->port,g_pserver->rgthreadvar[iel].ipfd,&g_pserver->rgthreadvar[iel].ipfd_count, fReusePort, (iel == IDX_EVENT_LOOP_MAIN)) == C_ERR)
            exit(1);
    }
    else
    {
        // We use the main threads file descriptors
        memcpy(g_pserver->rgthreadvar[iel].ipfd, g_pserver->rgthreadvar[IDX_EVENT_LOOP_MAIN].ipfd, sizeof(int)*CONFIG_BINDADDR_MAX);
        g_pserver->rgthreadvar[iel].ipfd_count = g_pserver->rgthreadvar[IDX_EVENT_LOOP_MAIN].ipfd_count;
    }

    /* Create an event handler for accepting new connections in TCP */
    for (int j = 0; j < g_pserver->rgthreadvar[iel].ipfd_count; j++) {
        if (aeCreateFileEvent(g_pserver->rgthreadvar[iel].el, g_pserver->rgthreadvar[iel].ipfd[j], AE_READABLE|AE_READ_THREADSAFE,
            acceptTcpHandler,NULL) == AE_ERR)
            {
                serverPanic(
                    "Unrecoverable error creating g_pserver->ipfd file event.");
            }
    }
}
```



```c
// server.cpp/main()
	pthread_t rgthread[MAX_EVENT_LOOPS];
    for (int iel = 0; iel < cserver.cthreads; ++iel)
    {
        pthread_create(rgthread + iel, NULL, workerThreadMain, (void*)((int64_t)iel));
        if (cserver.fThreadAffinity)
        {
#ifdef __linux__
            cpu_set_t cpuset;
            CPU_ZERO(&cpuset);
            CPU_SET(iel, &cpuset);
            if (pthread_setaffinity_np(rgthread[iel], sizeof(cpu_set_t), &cpuset) == 0)
            {
                serverLog(LOG_INFO, "Binding thread %d to cpu %d", iel, iel);
            }
#else
			serverLog(LL_WARNING, "CPU pinning not available on this platform");
#endif
        }
    }
```

### 类似redis开始事件循环，keydb中加入work thread

```c
// server.cpp/main()
/* The main thread sleeps until all the workers are done.
        this is so that all worker threads are orthogonal in their startup/shutdown */
pthread_join(rgthread[IDX_EVENT_LOOP_MAIN], &pvRet);
```

# fastlock 锁机制

KeyDB实现了一套类似spinlock的锁机制，称之为fastlock。
 fastlock的主要数据结构有：

```cpp
struct ticket
{
    uint16_t m_active;  //解锁+1
    uint16_t m_avail;  //加锁+1
};
struct fastlock
{
    volatile struct ticket m_ticket;

    volatile int m_pidOwner; //当前解锁的线程id
    volatile int m_depth; //当前线程重复加锁的次数
};
```

使用原子操作`__atomic_load_2，__atomic_fetch_add，__atomic_compare_exchange`来通过比较m_active=m_avail判断是否可以获取锁。
 fastlock提供了两种获取锁的方式：

-   try_lock：一次获取失败，直接返回
-   lock：忙等，每1024 * 1024次忙等后使用sched_yield 主动交出cpu，挪到cpu的任务末尾等待执行。

在KeyDB中将try_lock和事件结合起来，来避免忙等的情况发生。每个客户端有一个专属的lock，在读取客户端数据之前会先尝试加锁，如果失败，则退出，因为数据还未读取，所以在下个epoll_wait处理事件循环中可以再次处理。

![img](keydb%E5%90%AF%E5%8A%A8.assets/2509688-28ce403e7ccae0b4.webp)

# 命令处理

## 客户端发起连接请求，服务端接收

```c
// server.cpp/initNetWorkingThread()
	/* Create an event handler for accepting new connections in TCP */
    for (int j = 0; j < g_pserver->rgthreadvar[iel].ipfd_count; j++) {
        if (aeCreateFileEvent(g_pserver->rgthreadvar[iel].el, g_pserver->rgthreadvar[iel].ipfd[j], AE_READABLE|AE_READ_THREADSAFE,
            acceptTcpHandler,NULL) == AE_ERR)
            {
                serverPanic(
                    "Unrecoverable error creating g_pserver->ipfd file event.");
            }
    }
```

## 连接处理函数 acceptTcpHandler

acceptTcpHandler为TCP连接请求的处理函数，并由其中的acceptCommonHandler处理发送过来的客户端命令。

```c
// networking.cpp/acceptTcpHandler()
            // We always accept on the same thread
        LLocalThread:
            aeAcquireLock();// 获取全局锁
            acceptCommonHandler(cfd,0,cip, ielCur);
            aeReleaseLock();// 释放全局锁
        }

// networking.cpp/acceptCommonHandler()
#define MAX_ACCEPTS_PER_CALL 1000
static void acceptCommonHandler(int fd, int flags, char *ip, int iel) {
    client *c;
    if ((c = createClient(fd, iel)) == NULL) {
        serverLog(LL_WARNING,
            "Error registering fd event for the new client: %s (fd=%d)",
            strerror(errno),fd);
        return;
    }
...
    g_pserver->stat_numconnections++;
    c->flags |= flags;
}
```

## 接收连接请求后，服务端创建文件事件等待命令请求

```c
// networking.cpp/createClient()
client *createClient(int fd, int iel) {
    client *c = (client*)zmalloc(sizeof(client), MALLOC_LOCAL);

    c->iel = iel;
    /* passing -1 as fd it is possible to create a non connected client.
     * This is useful since all the commands needs to be executed
     * in the context of a client. When commands are executed in other
     * contexts (for instance a Lua script) we need a non connected client. */
    if (fd != -1) {
        serverAssert(iel == (serverTL - g_pserver->rgthreadvar));
        anetNonBlock(NULL,fd);
        anetEnableTcpNoDelay(NULL,fd);
        if (cserver.tcpkeepalive)
            anetKeepAlive(NULL,fd,cserver.tcpkeepalive);
        if (aeCreateFileEvent(g_pserver->rgthreadvar[iel].el,fd,AE_READABLE|AE_READ_THREADSAFE,
            readQueryFromClient, c) == AE_ERR)
        {
            close(fd);
            zfree(c);
            return NULL;
        }
    }
    ...
    return 0;
}
```

接收到客户端连接请求之后，服务器需要创建文件事件等待客户端的命令请求，可以看到文件事件的处理函数为readQueryFromClient，当服务器接收到客户端的命令请求时，会执行此函数。

## 命令请求的文件事件处理函数 readQueryFromClient

```c
// networking.cpp/readQueryFromClient()
void readQueryFromClient(aeEventLoop *el, int fd, void *privdata, int mask) {
    client *c = (client*) privdata;
    ...
    
    AeLocker aelock;
    AssertCorrectThread(c);
    std::unique_lock<decltype(c->lock)> lock(c->lock, std::defer_lock);
    if (!lock.try_lock())
        return; // Process something else while we wait
    ...
    /* Time to process the buffer. If the client is a master we need to
     * compute the difference between the applied offset before and after
     * processing the buffer, to understand how much of the replication stream
     * was actually applied to the master state: this quantity, and its
     * corresponding part of the replication stream, will be propagated to
     * the sub-slaves and to the replication backlog. */
    processInputBufferAndReplicate(c);
    if (listLength(serverTL->clients_pending_asyncwrite))
    {
        aelock.arm(c);
        ProcessPendingAsyncWrites();
    }
}
```

### 步骤①：解析命令请求

在Redis服务器中接收到的命令请求首先存储在客户端对象的querybuf输入缓冲区，然后解析命令请求各个参数，并存储在客户端对象的argv（参数对象数组）和argc（参数数目）字段。解析客户端命令请求的入口函数为readQueryFromClient，会读取socket数据存储到客户端对象的输入缓冲区，并调用函数processInputBuffer解析命令请求。同样在keydb中有类似的过程，在函数`processInputBufferAndReplicate`中调用processInputBuffer以解析命令请求。

```c
// networking.cpp
void processInputBufferAndReplicate(client *c){
    ...;
    /* If the client is a master we need to compute the difference
         * between the applied offset before and after processing the buffer,
         * to understand how much of the replication stream was actually
         * applied to the master state: this quantity, and its corresponding
         * part of the replication stream, will be propagated to the
         * sub-replicas and to the replication backlog. */
        size_t prev_offset = c->reploff;
        processInputBuffer(c, CMD_CALL_FULL);
        size_t applied = c->reploff - prev_offset;
        if (applied) {
            if (!g_pserver->fActiveReplica)
            {
                AeLocker ae;
                ae.arm(c);
                replicationFeedSlavesFromMasterStream(g_pserver->slaves,
                        c->pending_querybuf, applied);
            }
            sdsrange(c->pending_querybuf,applied,-1);
        }
    ...;
}
```

Redis采用自定义协议格式实现不同命令请求的区分，例如当用户在redis-cli客户端键入下面的命令：

```
SET redis-key value1
```

客户端会将该命令请求转换为以下协议格式，然后发送给服务器：

```
*3\r\n$3\r\nSET\r\n$9\r\nredis-key\r\n$6\r\nvalue1\r\n
```

换行符\r\n用于区分命令请求的若干参数，“*3”表示该命令请求有3个参数，“$3”“$9”和“$6”等表示该参数字符串长度。

Redis还支持在telnet会话输入命令的方式，此时没有了请求协议中的“*”来声明参数的数量，必须使用空格来分隔各个参数，服务器在接收到数据之后，会将空格作为参数分隔符解析命令请求。这种方式的命令请求称为内联命令。

processInputBuffer函数主要逻辑如下图所示：

![image-20200304231328155](keydb%E5%90%AF%E5%8A%A8.assets/image-20200304231328155.png)

processInputBuffer函数定义：

```c
// networking.cpp
void processInputBuffer(client *c, int callFlags) {
    ...;
    while(c->qb_pos < sdsllen(c->querybuf)){
        ...;
                if (c->reqtype == PROTO_REQ_INLINE) {
            if (processInlineBuffer(c) != C_OK) break;
        } else if (c->reqtype == PROTO_REQ_MULTIBULK) {
            if (processMultibulkBuffer(c) != C_OK) break;
        } else {
            serverPanic("Unknown request type");
        }
        ...;
    }
}
```

解析命令请求可以分为2个步骤：
a、解析命令请求参数数目；
b、循环解析每个请求参数。

#### 步骤a、解析命令请求参数数目

querybuf指向命令请求首地址，命令请求参数数目的协议格式为`*3\r\n`，即首字符必须是“*”，并且可以使用字符“\r”定位到行尾位置。解析后的参数数目暂存在客户端对象的multibulklen字段，表示等待解析的参数数目，变量pos记录已解析命令请求的长度。

#### 步骤b、循环解析每个请求参数

命令请求各参数的协议格式为`$3\r\nSET\r\n`，即首字符必须是“$”。解析当前参数之前需要解析出参数的字符串长度，可以使用字符“\r”定位到行尾位置；注意，解析参数长度时，字符串开始位置为querybuf+pos+1；字符串参数长度暂存在客户端对象的bulklen字段，同时更新已解析字符串长度pos。

按redis协议格式的处理函数

```c
// networking.c/readQueryFromClient()/processInputBufferAndReplicate()/processInputBuffer()中调用
int processMultibulkBuffer(client *c) {
    char *newline = NULL;// 指向分隔符"\r"
    int ok;
    long long ll;// 参数数目或参数的长度

    if (c->multibulklen == 0) {
        /* The client should have been reset */
        serverAssertWithInfo(c,NULL,c->argc == 0);

        /* Multi bulk length cannot be read without a \r\n */
        newline = strchr(c->querybuf+c->qb_pos,'\r');
        ...

        /* Buffer should also contain \n */
        if (newline-(c->querybuf+c->qb_pos) > (ssize_t)(sdslen(c->querybuf)-c->qb_pos-2))
            return C_ERR;

        /* We know for sure there is a whole line since newline != NULL,
         * so go ahead and find out the multi bulk length. */
        serverAssertWithInfo(c,NULL,c->querybuf[c->qb_pos] == '*');
        ok = string2ll(c->querybuf+1+c->qb_pos,newline-(c->querybuf+1+c->qb_pos),&ll);
        ...

        c->qb_pos = (newline-c->querybuf)+2;// 到每个结束符（首地址querybuf到\r\n的偏移）的偏移量

        if (ll <= 0) return C_OK;

        c->multibulklen = ll;// 第一次取的就是参数的总个数

        /* Setup argv array on client structure */
        if (c->argv) zfree(c->argv);
        c->argv = zmalloc(sizeof(robj*)*c->multibulklen);
    }

    serverAssertWithInfo(c,NULL,c->multibulklen > 0);
    while(c->multibulklen) {// 循环取完所有参数
        /* Read bulk length if unknown */
        if (c->bulklen == -1) {
            newline = strchr(c->querybuf+c->qb_pos,'\r');
            ...

            /* Buffer should also contain \n */
            if (newline-(c->querybuf+c->qb_pos) > (ssize_t)(sdslen(c->querybuf)-c->qb_pos-2))
                break;

            if (c->querybuf[c->qb_pos] != '$') {// 每个参数区段的开头是符号$
                ...
            }

            ok = string2ll(c->querybuf+c->qb_pos+1,newline-(c->querybuf+c->qb_pos+1),&ll);// 此时 ll 记录了当前参数字符串的长度
            ...

            c->qb_pos = newline-c->querybuf+2;// 记录到下一个结束符"\r\n"的偏移
            ...
            c->bulklen = ll;
        }

        /* Read bulk argument */
        // 读取参数字符串内容
        if (sdslen(c->querybuf)-c->qb_pos < (size_t)(c->bulklen+2)) {
            /* Not enough data (+2 == trailing \r\n) */
            break;
        } else {
            /* Optimization: if the buffer contains JUST our bulk element
             * instead of creating a new object by *copying* the sds we
             * just use the current sds string. */
            if (c->qb_pos == 0 &&
                c->bulklen >= PROTO_MBULK_BIG_ARG &&
                sdslen(c->querybuf) == (size_t)(c->bulklen+2))
            {
                ...
            } else {// 解析的参数记录在argv数组(相对于一个二维数组)中，argc记录参数个数
                c->argv[c->argc++] =
                    createStringObject(c->querybuf+c->qb_pos,c->bulklen);
                c->qb_pos += c->bulklen+2;
            }
            c->bulklen = -1;
            c->multibulklen--;
        }
    }

    /* We're done when c->multibulk == 0 */
    if (c->multibulklen == 0) return C_OK;

    /* Still not ready to process the command */
    return C_ERR;
}
```

当`multibulklen`值更新为0时，说明参数解析完成，结束循环。

### 步骤②：命令调用

解析完命令请求之后，会调用processCommandAndResetClient()/processCommand函数处理该命令请求，而处理命令请求之前还有很多校验逻辑，比如客户端是否已经完成认证，命令请求参数是否合法等。

```c
// networking.cpp/processInputBuffer()
void processInputBuffer(client *c, int callFlags){
    ...;
            /* Multibulk processing could see a <= 0 length. */
        if (c->argc == 0) {
            resetClient(c);
        } else {
            /* We are finally ready to execute the command. */
            if (processCommandAndResetClient(c, callFlags) == C_ERR) {
                /* If the client is no longer valid, we avoid exiting this
                 * loop and trimming the client buffer later. So we return
                 * ASAP in that case. */
                return;
            }
        }
    ...;
}
```

实际上，processCommandAndResetClient封装了redis中的processCommand函数和resetClient的条件处理，其实现为：

```c
// networking.cpp
int processCommandAndResetClient(client *c, int flags){
    ...;
        if (processCommand(c, flags) == C_OK) {
        if (c->flags & CLIENT_MASTER && !(c->flags & CLIENT_MULTI)) {
            /* Update the applied replication offset of our master. */
            c->reploff = c->read_reploff - sdslen(c->querybuf) + c->qb_pos;
        }

        /* Don't reset the client structure for clients blocked in a
         * module blocking command, so that the reply callback will
         * still be able to access the client argv and argc field.
         * The client will be reset in unblockClientFromModule(). */
        if (!(c->flags & CLIENT_BLOCKED) ||
            c->btype != BLOCKED_MODULE)
        {
            resetClient(c);
        }
    }
    ...;
}
```

processCommand()函数定义：

```c
// server.c
int processCommand(client *client){
    // 按规则校验参数
    
    // 执行命令
}
```

下面简要列出若干校验规则：

校验1：如果是quit命令直接返回并关闭客户端。

```c
// server.c/processCommand()
    if (!strcasecmp((const char*)ptrFromObj(c->argv[0]),"quit")) {
        addReply(c,shared.ok);
        c->flags |= CLIENT_CLOSE_AFTER_REPLY;
        return C_ERR;
    }
```

校验2：执行函数lookupCommand查找命令后，如果命令不存在返回错误。

```c
// server.c/processCommand()
	/* Now lookup the command and check ASAP about trivial error conditions
     * such as wrong arity, bad command name and so forth. */
    c->cmd = c->lastcmd = lookupCommand((sds)ptrFromObj(c->argv[0]));
    if (!c->cmd) {
        flagTransaction(c);
        sds args = sdsempty();
        int i;
        for (i=1; i < c->argc && sdslen(args) < 128; i++)
            args = sdscatprintf(args, "`%.*s`, ", 128-(int)sdslen(args), (char*)ptrFromObj(c->argv[i]));
        addReplyErrorFormat(c,"unknown command `%s`, with args beginning with: %s",
            (char*)ptrFromObj(c->argv[0]), args);
        sdsfree(args);
        return C_OK;
    }
```

校验3：如果命令参数数目不合法，返回错误

```c
// server.c/processCommand()
	if ((c->cmd->arity > 0 && c->cmd->arity != c->argc) ||
               (c->argc < -c->cmd->arity)) {
        flagTransaction(c);
        addReplyErrorFormat(c,"wrong number of arguments for '%s' command",
            c->cmd->name);
        return C_OK;
    }
```

命令结构体的arity用于校验参数数目是否合法，当arity小于0时，表示命令参数数目大于等于arity的绝对值；当arity大于0时，表示命令参数数目必须为arity。注意命令请求中命令的名称本身也是一个参数。

校验4：如果配置文件中使用指令“requirepass password”设置了密码，且客户端没未认证通过，只能执行auth命令，auth命令格式为“AUTH password”。

```c
// server.c/processCommand()
	/* Check if the user is authenticated */
    int auth_required = !(DefaultUser->flags & USER_FLAG_NOPASS) &&
                        !c->authenticated;
    if (auth_required || DefaultUser->flags & USER_FLAG_DISABLED) {
        /* AUTH and HELLO are valid even in non authenticated state. */
        if (c->cmd->proc != authCommand || c->cmd->proc == helloCommand) {
            flagTransaction(c);
            addReply(c,shared.noautherr);
            return C_OK;
        }
    }
```

除了上面的5种校验，还有很多校验规则，比如mvcc校验、集群相关校验、持久化相关校验、主从复制相关校验、发布订阅相关校验及事务操作等。相比redis的系列校验，keydb针对其MVCC特性增加了mvcc的有关校验，其定义如下：

```c
// server.cpp/processCommand()
incrementMvccTstamp();

// server.cpp
void incrementMvccTstamp()
{
    uint64_t msPrev;
    __atomic_load(&g_pserver->mvcc_tstamp, &msPrev, __ATOMIC_ACQUIRE);
    msPrev >>= MVCC_MS_SHIFT;  // convert to milliseconds

    long long mst;
    __atomic_load(&g_pserver->mstime, &mst, __ATOMIC_RELAXED);
    if (msPrev >= (uint64_t)mst)  // we can be greater if the count overflows
    {
        atomicIncr(g_pserver->mvcc_tstamp, 1);
    }
    else
    {
        atomicSet(g_pserver->mvcc_tstamp, ((uint64_t)g_pserver->mstime) << MVCC_MS_SHIFT);
    }
}
```

当所有校验规则都通过后，才会调用命令处理函数执行命令，代码如下：

```c
// server.c/processCommand()/call函数中执行命令
/* Exec the command */
call(c,CMD_CALL_FULL);

// server.c/call()
void call(client *c, int flags){
    ...
    start = server.ustime;
    c->cmd->proc(c);
    duration = ustime()-start;
    ...;
    
    /* Log the command into the Slow log if needed, and populate the
     * per-command statistics that we show in INFO commandstats. */
    if (flags & CMD_CALL_SLOWLOG && c->cmd->proc != execCommand) {
        char *latency_event = (c->cmd->flags & CMD_FAST) ?
                              "fast-command" : "command";
        latencyAddSampleIfNeeded(latency_event,duration/1000);
        // 记录慢查询日志
        slowlogPushEntryIfNeeded(c,c->argv,c->argc,duration);
    }
    // 更新统计信息：当前命令执行时间和调用次数
    if (flags & CMD_CALL_STATS) {
        /* use the real command that was executed (cmd and lastamc) may be
         * different, in case of MULTI-EXEC or re-written commands such as
         * EXPIRE, GEOADD, etc. */
        real_cmd->microseconds += duration;
        real_cmd->calls++;
    }
}
```

执行命令完成后，如果有必要，还需要更新统计信息，记录慢查询日志，AOF持久化该命令请求，传播命令请求给所有的从服务器等。

### 步骤③：返回结果

Keydb服务器返回结果类型不同，协议格式不同，而客户端根据返回结果的第一个字符判断返回类型。

Keydb的返回结果可以分为5类：

1）状态回复，第一个字符是“+”；例如，SET命令执行完毕会向客户端返回“+OK\r\n”。

```c
addReply(c, ok_reply ? ok_reply : shared.ok);
```

变量ok_reply通常为NULL，则返回的是共享变量shared.ok，在服务器启动时就完成了共享变量的初始化：

```c
// server.c/createSharedObjects()
shared.ok = createObject(OBJ_STRING, sdsnew("+OK\r\n"));
```

2）错误回复，第一个字符是“-”。例如，当客户端请求命令不存在时，会向客户端返回“-ERR unknowncommand 'testcmd'”。

```c
addReplyErrorFormate(c, "unkown command '%s'", (char*)c-argv[0]->ptr);
```

函数addReplyErrorFormat内部调用addReplyErrorLength实现会拼装错误回复字符串：

```c
    if (!len || s[0] != '-') addReplyString(c,"-ERR ",5);
    addReplyString(c,s,len);
    addReplyString(c,"\r\n",2);
```

3）整数回复，第一个字符是“:”。例如，INCR命令执行完毕向客户端返回“:100\r\n”。

```c
addReply(c, shared.colon);
addReply(c, new);
addReply(c, shared.crlf);
```

共享变量shared.colon与shared.crlf同样都是在服务器启动时就完成了初始化：

```c
// server.c/createSharedObjects()
shared.crlf = createObject(OBJ_STRING,sdsnew("\r\n"));
shared.colon = createObject(OBJ_STRING,sdsnew(":"));
```

4）批量回复，第一个字符是“`$`”。例如，GET命令查找键向客户端返回结果`$5\r\nhello\r\n`，其中`$5`表示返回字符串长度。

```c
// 计算返回对象obj长度，并拼接为字符串"$5\r\n"
addReplyBulkLen(c, obj);
addReply(c, obj);
addReply(c, shared.crlf);
```

5）多条批量回复，第一个字符是`*`。例如，LRANGE命令可能会返回多个值，格式为`*3\r\n$6\r\nvalue1\r\n$6\r\nvalue2\r\n$6\r\nvalue3\r\n`，与命令请求协议格式相同，`*3`表示返回值数目，`$6`表示当前返回值字符串长度：

```c
// 拼接返回值数目 "*3\r\n"
addReplyMultiBulkLen(c, rangelen);
// 循环输出所有返回值
while(rangelen--){
    // 拼接当前返回值长度 "$6\r\n"
    addReplyLongWithPrefix(c, len, '$');
    addReplyString(c, p, len);
    addReply(c, shared.crlf);
}
```

以上5种类型的返回结果都调用类似addReply函数返回，但是并不是这些方法将结果返回给客户端的。函数addReply会直接或间接调用以下函数将返回结果暂时缓存在客户端client的reply或buf字段，两个关键字段reply和buf，分别表示输出链表与输出缓冲区。

```c
// networking.c
// 如
void addReplyString(client *c, const char *s, size_t len) {
    if (prepareClientToWrite(c) != C_OK) return;
    if (_addReplyToBuffer(c,s,len) != C_OK)
        _addReplyStringToList(c,s,len);
}
// 同样也有
int __addReplyToBuffer(client *c, const char *s, size_t len);
void __addReplyObjectToList(client *c, robj *o);
void __addReplySdsToList(client *c, sds s);
void __addReplyStringToList(client *c, const char *s, size_t len);
```

调用函数_addReplyToBuffer缓存数据到输出缓冲区时，如果检测到reply字段有待返回给客户端的数据，则函数返回错误。而通常缓存数据时都会先尝试缓存到buf输出缓冲区，如果失败会再次尝试缓存到reply输出链表：

```c
// networking.c
int _addReplyToBuffer(client *c, const char *s, size_t len) {
    size_t available = sizeof(c->buf)-c->bufpos;

    if (c->flags & CLIENT_CLOSE_AFTER_REPLY) return C_OK;

    /* If there already are entries in the reply list, we cannot
     * add anything more to the static buffer. */
    if (listLength(c->reply) > 0) return C_ERR;

    /* Check that the buffer has enough space available for this string. */
    if (len > available) return C_ERR;

    memcpy(c->buf+c->bufpos,s,len);
    c->bufpos+=len;
    return C_OK;
}
```

函数addReply在将待返回给客户端的数据暂时缓存在输出缓冲区或者输出链表的同时，会将当前客户端添加到服务端结构体的clients_pending_write链表，以便后续能快速查找出哪些客户端有数据需要发送。

```c
listAddNodeHead(server.clients_pending_write, c);
```

函数addReply只是将待返回给客户端的数据暂时缓存在输出缓冲区或者输出链表，**那么什么时候将这些数据发送给客户端呢？**

在服务器启动过程的“步骤⑦开启事件循环”时，提到函数beforesleep在每次事件循环阻塞等待文件事件之前执行，主要执行一些不是很费时的操作，比如过期键删除操作，向客户端返回命令回复等。函数beforesleep会遍历clients_pending_write链表中每一个客户端节点，并发送输出缓冲区或者输出链表中的数据。

```c
/* This function is called just before entering the event loop, in the hope
 * we can just write the replies to the client output buffer without any
 * need to use a syscall in order to install the writable event handler,
 * get it called, and so forth. */
int handleClientsWithPendingWrites(void) {
    listIter li;
    listNode *ln;
    int processed = listLength(server.clients_pending_write);

    listRewind(server.clients_pending_write,&li);
    while((ln = listNext(&li))) {
        client *c = listNodeValue(ln);
        c->flags &= ~CLIENT_PENDING_WRITE;
        listDelNode(server.clients_pending_write,ln);

        /* If a client is protected, don't do anything,
         * that may trigger write error or recreate handler. */
        if (c->flags & CLIENT_PROTECTED) continue;

        /* Try to write buffers to the client socket. */
        if (writeToClient(c->fd,c,0) == C_ERR) continue;

        /* If after the synchronous writes above we still have data to
         * output to the client, we need to install the writable handler. */
        if (clientHasPendingReplies(c)) {
            int ae_flags = AE_WRITABLE;
            /* For the fsync=always policy, we want that a given FD is never
             * served for reading and writing in the same event loop iteration,
             * so that in the middle of receiving the query, and serving it
             * to the client, we'll call beforeSleep() that will do the
             * actual fsync of AOF to disk. AE_BARRIER ensures that. */
            if (server.aof_state == AOF_ON &&
                server.aof_fsync == AOF_FSYNC_ALWAYS)
            {
                ae_flags |= AE_BARRIER;
            }
            if (aeCreateFileEvent(server.el, c->fd, ae_flags,
                sendReplyToClient, c) == AE_ERR)
            {
                    freeClientAsync(c);
            }
        }
    }
    return processed;
}
```

此时也不一定能认为返回结果已经发送给客户端，命令请求也已经处理完成。当返回结果数据量非常大时，是无法一次性将所有数据都发送给客户端的，即函数writeToClient执行之后，客户端输出缓冲区或者输出链表中可能还有部分数据未发送给客户端。

那么redis中如何处理的？

redis通过添加文件事件，监听当前客户端socket文件描述符的可写事件

```c
// 仍然在handleClientsWithPendingWrites()中
            if (aeCreateFileEvent(server.el, c->fd, ae_flags,
                sendReplyToClient, c) == AE_ERR)
            {
                    freeClientAsync(c);
            }
```

看到该文件事件的事件处理函数为sendReplyToClient，即当客户端可写时，函数sendReplyToClient会发送剩余部分的数据给客户端。至此，命令请求才算真正处理完。

# 主从复制

replicaReplayCommand()

```c
// the replay command contains two arguments:
    //  1: The UUID of the source
    //  2: The raw command buffer to be replayed
    //  3: (OPTIONAL) the database ID the command should apply to

...;
	// uuid的校验
	unsigned char uuid[UUID_BINARY_LEN];
    if (c->argv[1]->type != OBJ_STRING || sdslen((sds)ptrFromObj(c->argv[1])) != 36
        || uuid_parse((sds)ptrFromObj(c->argv[1]), uuid) != 0)
	...
    if (FSameUuidNoNil(uuid, cserver.uuid))
    ...
	// OK We've recieved a command lets execute
    // raw command的执行
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

从代码上看，rreplayCommand函数中对于raw command的处理同keydb通用的形式一致。源码跟踪中没有发现对于数据同步冲突的处理，但是从官方文档描述解决数据同步这个问题时采用的是时间戳版本，由最新的时间戳获胜。

