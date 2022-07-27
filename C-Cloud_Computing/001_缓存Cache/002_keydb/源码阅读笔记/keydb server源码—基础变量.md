replication中涉及到的基础变量

`redisServerThreadVars`

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



`redisMaster`

```c
struct redisMaster {
    char *masteruser;               /* AUTH with this user and masterauth with master */
    char *masterauth;               /* AUTH with this password with master */
    char *masterhost;               /* Hostname of master */
    int masterport;                 /* Port of master */
    client *cached_master;          /* Cached master to be reused for PSYNC. */
    client *master;
    /* The following two fields is where we store master PSYNC replid/offset
     * while the PSYNC is in progress. At the end we'll copy the fields into
     * the server->master client structure. */
    char master_replid[CONFIG_RUN_ID_SIZE+1];  /* Master PSYNC runid. */
    long long master_initial_offset;           /* Master PSYNC offset. */

    int repl_state;          /* Replication status if the instance is a replica */
    off_t repl_transfer_size; /* Size of RDB to read from master during sync. */
    off_t repl_transfer_read; /* Amount of RDB read from master during sync. */
    off_t repl_transfer_last_fsync_off; /* Offset when we fsync-ed last time. */
    int repl_transfer_s;     /* Slave -> Master SYNC socket */
    int repl_transfer_fd;    /* Slave -> Master SYNC temp file descriptor */
    char *repl_transfer_tmpfile; /* Slave-> master SYNC temp file name */
    time_t repl_transfer_lastio; /* Unix time of the latest read, for timeout */
    time_t repl_down_since; /* Unix time at which link with master went down */

    unsigned char master_uuid[UUID_BINARY_LEN];  /* Used during sync with master, this is our master's UUID */
                                                /* After we've connected with our master use the UUID in g_pserver->master */
    uint64_t mvccLastSync;
    /* During a handshake the server may have stale keys, we track these here to share once a reciprocal connection is made */
    std::map<int, std::vector<robj_sharedptr>> *staleKeyMap;
};
```



`redisServerConst`

```c
// Const vars are not changed after worker threads are launched
struct redisServerConst {
    pid_t pid;                  /* Main process pid. */
    time_t stat_starttime;          /* Server start time */
    char *configfile;           /* Absolute config file path, or NULL */
    char *executable;           /* Absolute executable file path. */
    char **exec_argv;           /* Executable argv vector (copy). */

    int cthreads;               /* Number of main worker threads */
    int fThreadAffinity;        /* Should we pin threads to cores? */
    char *pidfile;              /* PID file path */

    /* Fast pointers to often looked up command */
    struct redisCommand *delCommand, *multiCommand, *lpushCommand,
                        *lpopCommand, *rpopCommand, *zpopminCommand,
                        *zpopmaxCommand, *sremCommand, *execCommand,
                        *expireCommand, *pexpireCommand, *xclaimCommand,
                        *xgroupCommand, *rreplayCommand;

    /* Configuration */
    char *default_masteruser;               /* AUTH with this user and masterauth with master */
    char *default_masterauth;               /* AUTH with this password with master */
    int verbosity;                  /* Loglevel in keydb.conf */
    int maxidletime;                /* Client timeout in seconds */
    int tcpkeepalive;               /* Set SO_KEEPALIVE if non-zero. */
    int active_defrag_enabled;
    size_t active_defrag_ignore_bytes; /* minimum amount of fragmentation waste to start active defrag */
    int active_defrag_threshold_lower; /* minimum percentage of fragmentation to start active defrag */
    int active_defrag_threshold_upper; /* maximum percentage of fragmentation at which we use maximum effort */
    int active_defrag_cycle_min;       /* minimal effort for defrag in CPU percentage */
    int active_defrag_cycle_max;       /* maximal effort for defrag in CPU percentage */
    unsigned long active_defrag_max_scan_fields; /* maximum number of fields of set/hash/zset/list to process from within the main dict scan */
    size_t client_max_querybuf_len; /* Limit for client query buffer length */
    int dbnum;                      /* Total number of configured DBs */
    int supervised;                 /* 1 if supervised, 0 otherwise. */
    int supervised_mode;            /* See SUPERVISED_* */
    int daemonize;                  /* True if running as a daemon */
    clientBufferLimitsConfig client_obuf_limits[CLIENT_TYPE_OBUF_COUNT];

    /* System hardware info */
    size_t system_memory_size;  /* Total memory in system as reported by OS */

    unsigned char uuid[UUID_BINARY_LEN];         /* This server's UUID - populated on boot */
    bool fUsePro = false;
};
```



`redisServer`

```c
struct redisServer{
...
/* Replication (master) */
    char replid[CONFIG_RUN_ID_SIZE+1];  /* My current replication ID. */
    char replid2[CONFIG_RUN_ID_SIZE+1]; /* replid inherited from master*/
    long long master_repl_offset;   /* My current replication offset */
    long long second_replid_offset; /* Accept offsets up to this for replid2. */
    int replicaseldb;                 /* Last SELECTed DB in replication output */
    int repl_ping_slave_period;     /* Master pings the replica every N seconds */
    char *repl_backlog;             /* Replication backlog for partial syncs */
    long long repl_backlog_size;    /* Backlog circular buffer size */
    long long repl_backlog_histlen; /* Backlog actual data length */
    long long repl_backlog_idx;     /* Backlog circular buffer current offset,
                                       that is the next byte will'll write to.*/
    long long repl_backlog_off;     /* Replication "master offset" of first
                                       byte in the replication backlog buffer.*/
    time_t repl_backlog_time_limit; /* Time without slaves after the backlog
                                       gets released. */
    time_t repl_no_slaves_since;    /* We have no slaves since that time.
                                       Only valid if g_pserver->slaves len is 0. */
    int repl_min_slaves_to_write;   /* Min number of slaves to write. */
    int repl_min_slaves_max_lag;    /* Max lag of <count> slaves to write. */
    int repl_good_slaves_count;     /* Number of slaves with lag <= max_lag. */
    int repl_diskless_sync;         /* Send RDB to slaves sockets directly. */
    int repl_diskless_sync_delay;   /* Delay to start a diskless repl BGSAVE. */
    /* Replication (replica) */
    list *masters;
    int enable_multimaster; 
    int repl_timeout;               /* Timeout after N seconds of master idle */
    int repl_syncio_timeout; /* Timeout for synchronous I/O calls */
    int repl_disable_tcp_nodelay;   /* Disable TCP_NODELAY after SYNC? */
    int repl_serve_stale_data; /* Serve stale data when link is down? */
    int repl_slave_ro;          /* Slave is read only? */
    int repl_slave_ignore_maxmemory;    /* If true slaves do not evict. */
    int slave_priority;             /* Reported in INFO and used by Sentinel. */
    int slave_announce_port;        /* Give the master this listening port. */
    char *slave_announce_ip;        /* Give the master this ip address. */
    int repl_slave_lazy_flush;          /* Lazy FLUSHALL before loading DB? */
    /* Replication script cache. */
    dict *repl_scriptcache_dict;        /* SHA1 all slaves are aware of. */
    list *repl_scriptcache_fifo;        /* First in, first out LRU eviction. */
    unsigned int repl_scriptcache_size; /* Max number of elements. */
    /* Synchronous replication. */
    list *clients_waiting_acks;         /* Clients waiting in WAIT command. */
    int get_ack_from_slaves;            /* If true we send REPLCONF GETACK. */
...
}
```



`client`

```c
/* With multiplexing we need to take per-client state.
 * Clients are taken in a linked list. */
typedef struct client {
    uint64_t id;            /* Client incremental unique ID. */
    int fd;                 /* Client socket. */
    int resp;               /* RESP protocol version. Can be 2 or 3. */
    redisDb *db;            /* Pointer to currently SELECTed DB. */
    robj *name;             /* As set by CLIENT SETNAME. */
    sds querybuf;           /* Buffer we use to accumulate client queries. */
    size_t qb_pos;          /* The position we have read in querybuf. */
    sds pending_querybuf;   /* If this client is flagged as master, this buffer
                               represents the yet not applied portion of the
                               replication stream that we are receiving from
                               the master. */
    size_t querybuf_peak;   /* Recent (100ms or more) peak of querybuf size. */
    int argc;               /* Num of arguments of current command. */
    robj **argv;            /* Arguments of current command. */
    struct redisCommand *cmd, *lastcmd;  /* Last command executed. */
    user *puser;             /* User associated with this connection. If the
                               user is set to NULL the connection can do
                               anything (admin). */
    int reqtype;            /* Request protocol type: PROTO_REQ_* */
    int multibulklen;       /* Number of multi bulk arguments left to read. */
    long bulklen;           /* Length of bulk argument in multi bulk request. */
    list *reply;            /* List of reply objects to send to the client. */
    unsigned long long reply_bytes; /* Tot bytes of objects in reply list. */
    size_t sentlen;         /* Amount of bytes already sent in the current
                               buffer or object being sent. */
    size_t sentlenAsync;    /* same as sentlen buf for async buffers (which are a different stream) */
    time_t ctime;           /* Client creation time. */
    time_t lastinteraction; /* Time of the last interaction, used for timeout */
    time_t obuf_soft_limit_reached_time;
    std::atomic<uint64_t> flags;              /* Client flags: CLIENT_* macros. */
    int casyncOpsPending;
    int fPendingAsyncWrite; /* NOTE: Not a flag because it is written to outside of the client lock (locked by the global lock instead) */
    int authenticated;      /* Needed when the default user requires auth. */
    int replstate;          /* Replication state if this is a replica. */
    int repl_put_online_on_ack; /* Install replica write handler on ACK. */
    int repldbfd;           /* Replication DB file descriptor. */
    off_t repldboff;        /* Replication DB file offset. */
    off_t repldbsize;       /* Replication DB file size. */
    sds replpreamble;       /* Replication DB preamble. */
    long long read_reploff; /* Read replication offset if this is a master. */
    long long reploff;      /* Applied replication offset if this is a master. */
    long long reploff_skipped;  /* Repl backlog we did not send to this client */
    long long repl_ack_off; /* Replication ack offset, if this is a replica. */
    long long repl_ack_time;/* Replication ack time, if this is a replica. */
    long long psync_initial_offset; /* FULLRESYNC reply offset other slaves
                                       copying this replica output buffer
                                       should use. */
    char replid[CONFIG_RUN_ID_SIZE+1]; /* Master replication ID (if master). */
    int slave_listening_port; /* As configured with: SLAVECONF listening-port */
    char slave_ip[NET_IP_STR_LEN]; /* Optionally given by REPLCONF ip-address */
    int slave_capa;         /* Slave capabilities: SLAVE_CAPA_* bitwise OR. */
    multiState mstate;      /* MULTI/EXEC state */
    int btype;              /* Type of blocking op if CLIENT_BLOCKED. */
    blockingState bpop;     /* blocking state */
    long long woff;         /* Last write global replication offset. */
    list *watched_keys;     /* Keys WATCHED for MULTI/EXEC CAS */
    dict *pubsub_channels;  /* channels a client is interested in (SUBSCRIBE) */
    list *pubsub_patterns;  /* patterns a client is interested in (SUBSCRIBE) */
    sds peerid;             /* Cached peer ID. */
    listNode *client_list_node; /* list node in client list */

    /* UUID announced by the client (default nil) - used to detect multiple connections to/from the same peer */
    /* compliant servers will announce their UUIDs when a replica connection is started, and return when asked */
    /* UUIDs are transient and lost when the server is shut down */
    unsigned char uuid[UUID_BINARY_LEN];

    /* If this client is in tracking mode and this field is non zero,
     * invalidation messages for keys fetched by this client will be send to
     * the specified client ID. */
    uint64_t client_tracking_redirection;

    /* Response buffer */
    int bufpos;
    char buf[PROTO_REPLY_CHUNK_BYTES];

    /* Async Response Buffer - other threads write here */
    int bufposAsync;
    int buflenAsync;
    char *bufAsync;

    int iel; /* the event loop index we're registered with */
    struct fastlock lock;
} client;

struct saveparam {
    time_t seconds;
    int changes;
};
```

