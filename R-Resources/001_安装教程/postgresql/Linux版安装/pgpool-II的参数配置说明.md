# pgpool-II的参数配置说明

> 作        者：胡凯
>
> 开始时间：2019-08-05
>
> 完成时间：

[TOC]

# 1、编译安装时的参数

```
./configure [-options]
```

[-options]：

> --prefix=path，pgpool-II 的二进制程序和文档将被安装到这个目录。默认值为 `/usr/local`
>
> --with-pgsql=path，PostgreSQL 的客户端库安装的顶层目录。默认值由 `pg_config` 提供
>
> --with-openssl，pgpool-II 程序将提供 OpenSSL 支持。默认是禁用 OpenSSL 支持的
>
> --enable-sequence-lock，在 pgpool-II 3.0 系列中使用 insert_lock 兼容。pgpool-II 针对序列表中的一行进行加锁。PostgreSQL 8.2 或2011年六月以后发布的版本无法使用这种加锁方法。
>
> --enable-table-lock，在 pgpool-II 2.2 和 2.3 系列中使用 insert_lock 兼容。pgpool-II 针对被插入的表进行加锁。这种锁因为和 VACUUM 冲突，已被废弃。
>
> --with-memcached=path，gpool-II 的二进制程序将使用 [memcached](http://www.pgpool.net/docs/pgpool-II-3.5.4/doc/pgpool-zh_cn.html#memcached_params) 作为 [基于内存的查询缓存](http://www.pgpool.net/docs/pgpool-II-3.5.4/doc/pgpool-zh_cn.html#memqcache)。你必须先安装 [libmemcached](http://libmemcached.org/libMemcached.html)。
>
> --with-pam，Pgpool-II二进制文件将使用PAM身份验证支持构建。 dafault禁用了PAM身份验证支持。



# 2、配置文件

## 2.1、pgpool-II运行模式

默认路径为`/path/to/pgpool/etc/`

| Operation mode             | Configuration file name           |
| -------------------------- | --------------------------------- |
| Streaming replication mode | `pgpool.conf.sample-stream`       |
| Replication mode           | `pgpool.conf.sample-replication`  |
| Master slave mode          | `pgpool.conf.sample-master-slave` |
| Raw mode                   | `pgpool.conf.sample`              |
| Logical replication mode   | `pgpool.conf.sample-logical`      |

- Streaming replication mode

流复制模式可以与运行流复制的PostgreSQL服务器一起使用。在这种模式下，PostgreSQL负责同步数据库。这种模式被广泛使用，也是推荐使用Pgpool-II的最佳方式。在该模式下可以进行负载平衡。示例配置文件是`$prefix / etc / pgpool.conf.sample-stream`。

- Logical replication mode

逻辑复制模式可以与运行逻辑复制的PostgreSQL服务器一起使用。在这种模式下，PostgreSQL负责同步表。在该模式下可以进行负载平衡。由于逻辑复制不会复制所有表，因此用户有责任复制可以进行负载平衡的表。Pgpool-II负载平衡所有表。这意味着如果没有复制表，Pgpool-II可能会在订阅者端查找过时的表。示例配置文件是`$ prefix / 
etc / pgpool.conf.sample-logical`。

- Master slave mode(slony mode)

主从模式模式（slony模式）可以与运行Slony的PostgreSQL服务器一起使用。在此模式下，Slony/PostgreSQL负责同步数据库。由于Slony-I被流式复制淘汰，我们不建议使用此模式，除非您有特定的理由使用Slony。在该模式下可以进行负载平衡。示例配置文件是`$
prefix / etc / pgpool.conf.sample-master-slave`。

- Native replication mode

在本机复制模式下，Pgpool-II负责同步数据库。该模式的优点是同步以同步方式完成：在所有PostgreSQL服务器完成写入操作之前，不会返回写入数据库。但是，使用PostgreSQL
9.6或更高版本可以获得类似的效果，并在流复制中设置`synchronous_commit = 
remote_apply`。如果您可以使用该设置，我们强烈建议您使用它而不是本机复制模式，因为您可以避免在本机复制模式下的某些限制。由于PostgreSQL不提供跨节点快照控制，因此会话X可以在会话Y提交节点B上的数据之前查看会话Y提交的节点A上的数据。如果会话X尝试根据所看到的数据更新节点B上的数据在节点A上，节点A和B之间的数据一致性可能会丢失。为避免此问题，用户需要对数据发出显式锁定。这是我们建议使用`synchronous_commit
= remote_apply`的流复制模式的另一个原因。

在该模式下可以进行负载平衡。示例配置文件`$ prefix / etc / pgpool.conf.sample-replication`。

- Raw mode

在原始模式下，Pgpool-II不关心数据库同步。用户有责任使整个系统做有意义的事情。在模式下无法进行负载平衡。

## 2.2、配置pcp.conf

Pgpool-II为管理员提供了一个执行管理操作的界面，例如获取Pgpool-II状态或远程终止Pgpool-II进程。 pcp.conf是用于此接口进行身份验证的用户/密码文件。所有操作模式都需要设置pcp.conf文件。在安装Pgpool-II期间会创建`$prefix path/
etc/pcp.conf.sample`文件。将文件复制为`$ prefix path/etc/pcp.conf`并将其用户名和密码添加到其中。

在文件末追加内容

```
username:[md5 encrypted password]
```

`[md5 encrypted password]`由以下方式得到

```
$ pg_md5 your_password
1060b7b46a3bd36b3a0d66e0127d0517
```

如果不想将密码以参数形式（明文）传递，可以加`-p`约束

```
pg_md5 -p
password:your_password
```

`pcp.conf` 文件对于运行 pgpool-II 的用户必须可读。

## 2.3、配置pgpool.conf

### 2.3.1、连接设置

#### listen_addresses

指定 pgpool-II 将接受 TCP/IP 连接的主机名或者IP地址。 `'*'` 将接受所有的连接。`''` 将禁用 TCP/IP 连接。默认为 `'localhost'`。总是支持接受通过 UNIX 域套接字发起的连接。 需要重启 pgpool-II 以使改动生效。     

#### `port`

pgpool-II 监听 TCP/IP 连接的端口号。默认为 9999。需要重启 pgpool-II 以使改动生效。     

#### `socket_dir`

pgpool-II 建立用于建立接受 UNIX 域套接字连接的目录。默认为 `'/tmp'`。注意，这个套接字可能被 cron 任务删除。我们建议设置这个值为 `'/var/run'` 或类似目录。需要重启 pgpool-II 以使改动生效。     

#### `pcp_listen_addresses`

指定 pcp 进程接收 TCP/IP 连接的主机名或IP地址。 `'*'` 接收所有的连接。`''` 禁用 TCP/IP 连接。默认为 `'*'`。总是允许使用 UNIX 域套接字进行连接。本参数必须在服务启动前设置。     

#### `pcp_port`

PCP 进程接受连接的端口号。默认为 9898。本参数必须在服务启动前设置。     

#### `pcp_socket_dir`

PCP 进程用于建立接受 UNIX 域套接字连接的目录。默认为 `'/tmp'`。注意，这个套接字可能被 cron 任务删除。我们建议设置这个值为 `'/var/run'` 或类似目录。需要重启 pgpool-II 以使改动生效。

### 2.3.2、池

#### `num_init_children`

预生成的 pgpool-II 服务进程数。默认为 32。num_init_children 也是 pgpool-II 支持的从客户端发起的最大并发连接数。如果超过 num_init_children 数的客户端尝试连接到 pgpool-II，它们将被阻塞（而不是拒绝连接），直到到任何一个 pgpool-II 进程的连接被关闭为止。最多有 [listen_backlog_multiplier](http://www.pgpool.net/docs/37/en/html/runtime-config-connection-pooling.html#GUC-LISTEN-BACKLOG-MULTIPLIER)*num_init_children 可以被放入等待队列。         

这个队列存在于操作系统内核中，名为 "监听队列(listen queue)"。监听队列的长度被称为 "积压(backlog)"。 一些系统中有对积压的上限限制，如果`num_init_children*listen_backlog_multiplier`达到这个数值，你需要将积压值设置得更高点。否则，在高负载的系统中可能发生以下问题：1) 连接到 pgpool-II 失败 2) 连接到  pgpool-II 的时间变长，因为内核中存在一些限制。你可以使用命令 "netstat -s" 检查监听队列是不是发生过溢出。如果你发现类似于以下的： 		

```
535 times the listen queue of a socket overflowed
```

那么很明显监听队列溢出了。这种情况下你需要增加积压(backlog)值（需要管理员权限）。         

```
# sysctl net.core.somaxconn
net.core.somaxconn = 128
# sysctl -w net.core.somaxconn = 256		
```

 你也可以添加以下语句到 /etc/sysctl.conf 中。 		

```
net.core.somaxconn = 256		
```

每个 PostgreSQL 的连接数大约为 max_pool*num_init_children

对于以上内容的一些提示：

（1）取消一个执行中的查询将导致建立另一个到后端的连接；因此，如果所有的连接都在使用，则查询无法被取消。如果你想确保查询可以被取消，设置本值为预期最大连接数的两倍。

（2）PostgreSQL 允许最多 `max_connections-superuser_reserved_connections`             个非超级用户的并发连接。

归纳起来，`max_pool`，`num_init_children`，`max_connections`和`superuser_reserved_connections`必须符合以下规则：     

```
max_pool*num_init_children <= (max_connections - superuser_reserved_connections) (不需要取消查询)
max_pool*num_init_children*2 <= (max_connections - superuser_reserved_connections) (需要取消查询)
```

本参数必须在服务器启动前设置。

#### `listen_backlog_multiplier`

控制前端到 pgpool-II 的连接队列的长度。默认值为 2。队列长度（实际上是系统调用 listen 的 "backlog" 参数）由`listen_backlog_multiplier * num_init_children`定义。         如果这个队列不够长，你应该增加这个参数。有一些系统会限制 listen 系统调用的 backlog 参数的上限。参考 [num_init_children](http://www.pgpool.net/docs/pgpool-II-3.5.4/doc/pgpool-zh_cn.html#NUM_INIT_CHILDREN) 获取详细信息。         

本参数必须在服务启动前设置。

#### `serialize_accept`

是否针对客户端的连接串行化`accept()`的调用过程。默认为 off，即不进行串行化（和 pgpool-II 3.4 以及以前版本的行为相同）。如果为 off，则内核唤醒所有的 pgpool-II 子进程来执行`accept()`且其中一个会真正获取到进入的连接。这里的问题是，由于有太大量的子进程被唤醒，会发生大量的上下文切换，应能可能会受影响。这种现象就是经典的“惊群问题（the thundering herd problem）”。在启用`serialize_accept`后，只有一个 pgpool-II 子进程被唤醒并执行`accept()`且以上问题得以避免。

那什么时候需要开启`serialize_accept`呢？在`num_init_children`的值非常大的时候，推荐开启`serialize_accept`。对于`num_init_children`被设置得很小的情况，不会提升性能，反而由于串行的成本而可能降低性能。这个值有多大则依赖于实际环境。建议在做决定前做一次性能测试。以下为一个使用 pgbench 进行性能测试的例子： 			  

```shell
pgbench -n -S -p 9999 -c 32 -C -S -T 300 test
```

这里，`-C`告诉 pgbench 在每个事物被执行的时候都发起一个新连接。`-c 32`表示连接到 pgpool-II 的并行会话数。可以根据你系统的需求改变这个值。当 pgbench 执行完后，你需要查看“including connections establishing”中得出的数字。 		

注意如果 [child_life_time](http://www.pgpool.net/docs/pgpool-II-3.5.4/doc/pgpool-zh_cn.html#CHILD_LIFE_TIME) 被启用，则`serialize_accept`无效。也就是要注意如果你希望启用`serialize_accept`，则需要将`child_life_time`设置为 0。如果你担心 pgpool-II 进程的内存泄露或其他潜在的问题，你应该使用 [child_max_connections](http://www.pgpool.net/docs/pgpool-II-3.5.4/doc/pgpool-zh_cn.html#CHILD_MAX_CONNECTIONS) 来替代它。这是一种为了限制而限制的实现方式，可能以后会被移除。 		

本参数必须在服务启动前设置。

#### `child_life_time`

pgpool-II 子进程的生命周期，单位为秒。     如果子进程空闲了这么多秒，它将被终止，一个新的子进程将被创建。     这个参数是用于应对内存泄露和其他不可预料错误的一个措施。默认值为 300 （5分钟）。     0 将禁用本功能。注意它不影响尚未接受任何连接的进程。     

注：如果本参数非零，则 [serialize_accept](http://www.pgpool.net/docs/pgpool-II-3.5.4/doc/pgpool-zh_cn.html#SERIALIZE_ACCEPT) 无效。     

如果改变了这个值，你需要重新加载 pgpool.conf 以使变动生效。     

#### `child_max_connections`

当 pgpool-II 子进程处理这么多个客户端连接后，它将被终止。这个参数在繁忙到 [child_life_time](http://www.pgpool.net/docs/pgpool-II-3.5.4/doc/pgpool-zh_cn.html#CHILD_LIFE_TIME") 和 [connection_life_time](http://www.pgpool.net/docs/pgpool-II-3.5.4/doc/pgpool-zh_cn.html#CONNECTION_LIFE_TIME) 永远不会触发的服务器上有效。     

如果你改变了这个值，需要重新加载 pgpool.conf 以使变动生效。     

#### `client_idle_limit`

当一个客户端在执行最后一条查询后如果空闲到了`client_idle_limit`秒数，到这个客户端的连接将被断开。这在避免 pgpool 子进程被懒客户端占用或者探测断开的客户端和 pgpool 之间的 TCP/IP 连接非常有用。     

如果你改变了这个值，需要重新加载 pgpool.conf 以使变动生效。     

#### `enable_pool_hba`

如果为 true，则使用 pgpool_hba.conf 来进行客户端认证。参考[设置用于客户端认证的 pool_hba.conf](http://www.pgpool.net/docs/pgpool-II-3.5.4/doc/pgpool-zh_cn.html#hba)。     

如果你改变了这个值，需要重新加载 pgpool.conf 以使变动生效。     

#### `pool_passwd`

指定用于 md5 认证的文件名。默认值为"pool_passwd"。"" 表示禁用。参考 [认证 / 访问控制](http://www.pgpool.net/docs/pgpool-II-3.5.4/doc/pgpool-zh_cn.html#md5) 获得更多信息。     

如果你改变了这个值，需要重启 pgpool-II 以生效。     

#### `authentication_timeout`

指定 pgpool 认证超时的时长。0 指禁用超时，默认值为 60 。     

如果你改变了这个值，需要重新加载 pgpool.conf 以使变动生效。     

### 2.3.3、日志

#### `log_destination`

pgpool-II 支持多种记录服务器消息的方式，包括`stderr`和`syslog`。默认为记录到 `stderr`。     

注：要使用`syslog`作为`log_destination`的选项，你将需要更改你系统的`syslog`守护进程的配置。pgpool-II 可以记录到`syslog `设备`LOCAL0`到`LOCAL7`（参考 `syslog_facility`），但是大部分平台的默认的`syslog`配置将忽略这些消息。你需要添加如下一些内容     

```shell
local0.*  /var/log/pgpool.log
```

到`syslog`守护进程的配置文件以使它生效。

#### `print_timestamp-V3.4 (REMOVED)`

如果本值被设置为 true ，则将在日志中添加时间戳。默认值为 true。     

如果你改变了这个值，需要重新加载 pgpool.conf 以使变动生效。     

#### `print_user - V3.4 (REMOVED)`

如果本值被设置为 true，则将在日志中添加会话的用户名。默认为 false。     

如果你改变了这个值，需要重新加载 pgpool.conf 以使变动生效。     

#### `log_line_prefix`

这是输出到每行日志开头的打印样式字符串。% 字符开始的 "转义序列" 将被下表的内容替换。所有不支持的转义将被忽略。其他的字符串将直接拷贝到日志行中。默认值为 '%t: pid %p: '，即打印时间戳和进程好，这将与 3.4 之前的版本保持兼容。 	

| 转义字符 |        效果        |
| :------: | :----------------: |
|    %a    |  客户端应用程序名  |
|    %p    |    进程号 (PID)    |
|    %P    |       进程名       |
|    %t    |       时间戳       |
|    %d    |      数据库名      |
|    %u    |       用户名       |
|    %l    | 为每个进程记录行号 |
|    %%    |      '%' 字符      |

如果你改变了这个值，需要重新加载 pgpool.conf 以使变动生效。 	

#### `log_error_verbosity`

控制记录的日支消息的详细程度。有效的取值包括`TERSE`、`DEFAULT`和`VERBOSE`，每个都会增加显示的消息内容。`TERSE`不包括记录`DETAIL`、`HINT`以及`CONTEXT`错误信息。     

如果你改变了这个值，需要重新加载 pgpool.conf 以使变动生效。     

#### `log_connections`

如果为 true，进入的连接将被打印到日志中。     

如果你改变了这个值，需要重新加载 pgpool.conf 以使变动生效。     

#### `client_min_messages`

控制哪个最小级别的消息被发送到客户端。可用的值为`DEBUG5`、`DEBUG4`、`DEBUG3`、`DEBUG2`、`DEBUG1`、`LOG`、`NOTICE`、`WARNING`以及`ERROR`。每个级别包含它后面的级别。默认值为`NOTICE`。     

如果你改变了这个值，需要重新加载 pgpool.conf 以使变动生效。     

#### `log_min_messages`

控制哪个最小级别的消息被发送到日志中。可用的值为`DEBUG5`、`DEBUG4`、`DEBUG3`、`DEBUG2`、`DEBUG1`、`LOG`、`NOTICE`、`WARNING`、`ERROR`、`FATAL` 以及`PANIC`。每个级别包含它后面的级别。默认值为`NOTICE`。     

如果你改变了这个值，需要重新加载 pgpool.conf 以使变动生效。     

#### `log_hostname`

如果为 true，ps 命令将显示客户端的主机名而不是 IP 地址。而且，如果 [log_connections](http://www.pgpool.net/docs/pgpool-II-3.5.4/doc/pgpool-zh_cn.html#LOG_CONNECTIONS) 被开启，也会将主机名写入日志。     

如果你改变了这个值，需要重新加载 pgpool.conf 以使变动生效。     

#### `log_statement`

当设置为 true 时生成 SQL 日志消息。这类似于 PostgreSQL 中的 log_statement 参数。     即使调试选项没有在启动的时候传递到 pgpool-II，它也会产生日志。     

如果你改变了这个值，需要重新加载 pgpool.conf 以使变动生效。     

#### `log_per_node_statement`

类似于 [log_statement](http://www.pgpool.net/docs/pgpool-II-3.5.4/doc/pgpool-zh_cn.html#LOG_PER_NODE_STATEMENT)，除了它是针对每个 DB 节点产生日志外。例如它对于确定复制是否正常运行非常有用。     

如果你改变了这个值，需要重新加载 pgpool.conf 以使变动生效。     

#### `syslog_facility`

当记录日志到`syslog`被启用，本参数确定被使用的`syslog` “设备”。你可以使用`LOCAL0`, `LOCAL1`, `LOCAL2`, `LOCAL3`, `LOCAL4`, `LOCAL5`, `LOCAL6`,` LOCAL7`；默认为`LOCAL0`。还请参考你系统的`syslog`守护进程的文档。     

#### `syslog_ident`

当记录日志到`syslog`被启用，本参数确定用于标记`syslog`中 pgpool-II 消息的程序名。默认为“pgpool”。

### 2.3.4、文件位置

#### `pid_file_name`

到包含 pgpool-II 进程 ID 的文件的完整路径名。默认为 `'/var/run/pgpool/pgpool.pid'`。     

需要重启 pgpool-II 以使改动生效。     

#### `logdir`

保存日志文件的目录。 pgpool_status 将被写入这个目录。

### 2.3.5、连接池

#### `connection_cache`

如果本值被设置为 true，则缓存到 PostgreSQL 的连接。默认为 true。     

需要重启 pgpool-II 以使改动生效。     

### 2.3.6、健康检查

#### health_check_timeout

pgpool-II 定期尝试连接到后台以检测服务器是否在服务器或网络上有问题。这种错误检测过程被称为“健康检查”。如果检测到错误，则 pgpool-II 会尝试进行故障恢复或者退化操作。     

本参数用于避免健康检查在例如网线断开等情况下等待很长时间。超时值的单位为秒。默认值为 20 。0 禁用超时（一直等待到 TCP/IP 超时）。     

健康检查需要额外的到后端程序的连接，所以 `postgresql.conf`中的 `max_connections` 需要加一。     

如果你改变了这个值，需要重新加载 pgpool.conf 以使变动生效。     

#### health_check_period

本参数指出健康检查的间隔，单位为秒。默认值为 0 ，代表禁用健康检查。     

如果你改变了这个值，需要重新加载 pgpool.conf 以使变动生效。     

#### health_check_user

用于执行健康检查的用户。用户必须存在于 PostgreSQL 后台中。     

如果你改变了这个值，需要重新加载 pgpool.conf 以使变动生效。     

#### health_check_password

用于执行健康检查的用户的密码。     

如果你改变了这个值，需要重新加载 pgpool.conf 以使变动生效。     

#### health_check_database

执行健康检查的数据库名。默认为 ''，即首先尝试使用“postgres”数据库，之后尝试“template1”数据库，直到成功。这和 3.4 或者以前版本的行为相同。     

如果你改变了这个值，需要重新加载 pgpool.conf 以使变动生效。     

#### health_check_max_retries

在执行失效故障切换前尝试的最大失效健康检查次数。这个参数对于网络不稳定的时，健康检查失败但主节点依旧正常的情况下非常有效。默认值为 0，也就是不重试。如果你想启用 health_check_max_retries，建议你禁用 [fail_over_on_backend_error](http://www.pgpool.net/docs/pgpool-II-3.5.4/doc/pgpool-zh_cn.html#FAIL_OVER_ON_BACKEND_ERROR)。     

如果你改变了 health_check_max_retries，需要重新加载 pgpool.conf。     

#### health_check_retry_delay

失效健康检查重试的间隔时间（单位为秒）（ health_check_max_retries > 0 时有效 ）。     如果为 0 则立即重试（不延迟）。     

如果你改变了 health_check_retry_delay，需要重新加载 pgpool.conf。     

#### connect_timeout

使用 connect() 系统调用时候放弃连接到后端的超时毫秒值。默认为 10000 毫秒（10秒）。网络不稳地的用户可能需要增加这个值。0 表示不允许超时。注意本参数不仅仅用于健康检查，也用于普通连接池的连接。     

如果你改变了 connect_timeout，需要重新加载 pgpool.conf。     

#### search_primary_node_timeout

本参数指定在发生故障切换的时候查找一个主节点的最长时间，单位为秒。默认值为 10。pgpool-II 将在发生故障切换的时候在设置的时间内尝试搜索主节点，如果到达这么长时间未搜索到则放弃搜索。0 表示一直尝试。本参数在流复制模式之外的情况下被忽略。     

如果你改变了`search_primary_node_timeout`，需要重新加载 pgpool.conf。     

### 2.3.7、故障切换和恢复

#### failover_command

本参数指定当一个节点断开连接时执行的命令。pgpool-II 使用后台对应的信息代替以下的特别字符。     

| 特殊字符 |                 描述                 |
| :------: | :----------------------------------: |
|    %d    |      断开连接的节点的后台 ID。       |
|    %h    |       断开连接的节点的主机名。       |
|    %p    |       断开连接的节点的端口号。       |
|    %D    | 断开连接的节点的数据库实例所在目录。 |
|    %M    |           旧的主节点 ID。            |
|    %m    |           新的主节点 ID。            |
|    %H    |          新的主节点主机名。          |
|    %P    |          旧的第一节点 ID。           |
|    %r    |         新的主节点的端口号。         |
|    %R    |   新的主节点的数据库实例所在目录。   |
|    %%    |               '%' 字符               |

如果你改变了这个值，需要重新加载 pgpool.conf 以使变动生效。     

当进行故障切换时，pgpool 杀掉它的所有子进程，这将顺序终止所有的到 pgpool 的会话。     然后，pgpool 调用 failover_command 并等待它完成。然后，pgpool 启动新的子进程并再次开始从客户端接受连接。     

#### failback_command

本参数指定当一个节点连接时执行的命令。pgpool-II 使用后台对应的信息代替以下的特别字符。     

| 特殊字符 |                 描述                 |
| :------: | :----------------------------------: |
|    %d    |      新连接上的节点的后台 ID。       |
|    %h    |       新连接上的节点的主机名。       |
|    %p    |       新连接上的节点的端口号。       |
|    %D    | 新连接上的节点的数据库实例所在目录。 |
|    %M    |           旧的主节点 ID。            |
|    %m    |           新的主节点 ID。            |
|    %H    |          新的主节点主机名。          |
|    %P    |          旧的第一节点 ID。           |
|    %r    |         新的主节点的端口号。         |
|    %R    |   新的主节点的数据库实例所在目录。   |
|    %%    |               '%' 字符               |

如果你改变了这个值，需要重新加载 pgpool.conf 以使变动生效。     

#### follow_master_command

本参数指定一个在主备流复制模式中发生主节点故障恢复后执行的命令。pgpool-II 使用后台对应的信息代替以下的特别字符。

| 特殊字符 |                 描述                 |
| :------: | :----------------------------------: |
|    %d    |      断开连接的节点的后台 ID。       |
|    %h    |       断开连接的节点的主机名。       |
|    %p    |       断开连接的节点的端口号。       |
|    %D    | 断开连接的节点的数据库实例所在目录。 |
|    %M    |           旧的主节点 ID。            |
|    %m    |           新的主节点 ID。            |
|    %H    |          新的主节点主机名。          |
|    %P    |          旧的第一节点 ID。           |
|    %r    |         新的主节点的端口号。         |
|    %R    |   新的主节点的数据库实例所在目录。   |
|    %%    |               '%' 字符               |

如果你改变了这个值，需要重新加载 pgpool.conf 以使变动生效。     

如果`follow_master_commnd`不为空，当一个主备流复制中的主节点的故障切换完成，     pgpool 退化所有的除新的主节点外的所有节点并启动一个新的子进程，再次准备好接受客户端的连接。在这之后，pgpool 针对每个退化的节点运行 ‘follow_master_command’ 指定的命令。通常，这个命令应该用于调用例如 [pcp_recovery_node](http://www.pgpool.net/docs/pgpool-II-3.5.4/doc/pgpool-zh_cn.html#pcp_recovery_node) 命令来从新的主节点恢复备节点。     

#### fail_over_on_backend_error

如果为 true，当往后台进程的通信中写入数据时发生错误，pgpool-II 将触发故障处理过程。     这和 pgpool-II 2.2.x 甚至以前版本的行为一样。如果设置为 false，则 pgpool 将报告错误并断开该连接。请注意如果设置为 true，当连接到一个后台进程失败或者 pgpool 探测到 postmaster 由于管理原因关闭，pgpool 也会执行故障恢复过程。     

如果你改变了这个值，需要重新加载 pgpool.conf 以使变动生效。     

### 2.3.8、负载均衡模式

#### ignore_leading_white_space

在负载均衡模式中 pgpool-II 忽略 SQL 查询语句前面的空白字符。如果使用类似于 DBI/DBD:Pg 一类的在用户的查询前增加空白的 API 中非常有用。     

如果你改变了这个值，需要重新加载 pgpool.conf 以使变动生效。     

#### allow_sql_comments

如果设置为 on，在判断是否负载均衡或查询缓存的时候忽略 SQL 注释。如果设置为 off，SQL 注释会有效地阻止以上的判断（3.4以前版本的行为）。     

如果你改变了这个值，需要重新加载 pgpool.conf 以使变动生效。     

###  2.3.9、后端（postgreSQL服务）

#### backend_hostname

指出连接到 PostgreSQL 后台程序的地址。它用于 pgpool-II 与服务器通信。如果你改变了这个值，需要重新加载 pgpool.conf 以使变动生效。     

对于 TCP/IP 通信，本参数可以是一个主机名或者IP地址。如果它是从斜线开始的，它指出是通过 UNIX 域套接字通信，而不是 TCP/IP 协议；它的值为存储套接字文件所在的目录。如果 backend_host 为空，则它的默认行为是通过 `/tmp` 中的 UNIX 域套接字连接。     

可以通过在本参数名的末尾添加一个数字来指定多个后台程序（例如`backend_hostname0`）。这个数字对应为“数据库节点  ID”，是从 0 开始的正整数。被设置数据库节点ID为 0  的后台程序后台程序将被叫做“主数据库”。当定义了多个后台程序时，即使主数据库当机后依然能继续（某些模式下不行）。在这种情况下，存活的最小的数据库节点编号的数据库将被变成新的主数据库。     

请注意有编号为 0 的节点在流复制中没有其他意义。但是，你需要注意数据库节点是不是“主节点”。请参考 [流复制](http://www.pgpool.net/docs/pgpool-II-3.5.4/doc/pgpool-zh_cn.html#stream) 获得更多细节。

如果你只计划使用一台 PostgreSQL 服务器，可以通过 `backend_hostname0` 指定。

可以通过配置本参数后重新加载配置文件添加新的节点。但是，对已有的值无法更新，所以这种情况下你必须重启 pgpool-II。     

#### backend_port

指定后台程序的端口号。可以通过在本参数名的末尾添加一个数字来指定多个后台程序（例如`backend_port0`）。如果你只计划使用一台 PostgreSQL 服务器，可以通过 `backend_port0` 指定。     

可以通过配置本参数后重新加载配置文件添加新的后台端口。但是，对已有的值无法更新，所以这种情况下你必须重启 pgpool-II。     

#### backend_weight

指定后台程序的负载均衡权重。可以通过在本参数名的末尾添加一个数字来指定多个后台程序（例如`backend_weight0`）。如果你只计划使用一台 PostgreSQL 服务器，可以通过 `backend_weight0` 指定。在原始模式中，请将本值设置为 1。

可以通过配置本参数后重新加载配置文件添加新的负载均衡权重。     

在 pgpool-II 2.2.6/2.3 或者更新的版本中，你可以通过重新加载配置文件来改变本值。但这只对新连接的客户会话生效。这在主备模式中可以避免任何执行一些管理工作的查询被发送到备用节点上。     

#### backend_data_directory

指定后台的数据库实例的目录。可以通过在本参数名的末尾添加一个数字来指定多个后台程序（例如`backend_data_directory0`）。如果你不打算使用在线恢复，你可以不设置本参数。     

可以通过配置本参数后重新加载配置文件添加新的后台的数据库实例目录。但是，对已有的值无法更新，所以这种情况下你必须重启 pgpool-II。     

#### backend_flag

控制大量的后台程序的行为。可以通过在本参数名的末尾添加一个数字来指定多个后台程序（例如`backend_flag0`）     

当前支持以下的内容。多个标志可以通过“|”来分隔。     

|  ALLOW_TO_FAILOVER   | 允许故障切换或者从后台程序断开。本值为默认值。指定本值后，不能同时指定 DISALLOW_TO_FAILOVER 。 |
| :------------------: | :----------------------------------------------------------- |
| DISALLOW_TO_FAILOVER | 不允许故障切换或者从后台程序断开。本值在你使用 HA(高可用性)软件例如 Heartbeat 或者 Packmaker 来保护后台程序时非常有用。本值为默认值。指定本值后，不能同时指定 DISALLOW_TO_FAILOVER 。 |

### 2.3.10、SSL设置

- #### ssl

如果设置为 ture，则启用了到前端程序和后端程序的连接的 ssl 支持。注意为了能与前端程序进行 SSL 连接，必须设置 `ssl_key` 和 `ssl_cert`。SSL 默认被关闭。就像在 [pgpool-II 的安装](http://www.pgpool.net/docs/pgpool-II-3.5.4/doc/pgpool-zh_cn.html#install) 小节所说的， 注意必须在编译时配置 OpenSSL 支持才能打开 SSL 支持。如果修改了 SSL 相关的设置， pgpool-II 守护进程必须重启。          

- #### ssl_key

对于进入的连接使用的私钥文件所在路径。 本选项没有默认值，如果本值不设置，则对于进入的连接将禁用 SSL。          

- #### ssl_cert

对于进入的连接使用的公共 x509 证书文件所在的路径。本选项没有默认值，如果本值不设置，则对于进入的连接将禁用 SSL。          

- #### ssl_ca_cert

到一个 PEM 格式的证书文件路径，包含一个或多个 CA 根证书，用于校验后端的服务器证书。类似于 OpenSSL 的 `verify(1)` 命令的 `-CAfile` 选项。本选项的默认值是不设置，因此不会发生校验。但是在 `ssl_ca_cert_dir` 被设置的时候，还是会发生校验。          

- #### ssl_ca_cert_dir

到一个包含 PEM 格式的 CA 证书的目录的路径，用于校验后端的服务器证书。类似于OpenSSL 的 `verify(1)` 命令的 `-CApath` 选项。本选项的默认值是不设置，因此不会发生校验。但是在 `ssl_ca_cert` 被设置的时候，还是会发生校验。          

### 2.3.11、其他

#### relcache_expire

关系缓存的生命周期。0（默认值）表示没有缓冲区过期。关系缓存用于缓存用来获取包含表结构信息或一个表是不是一个临时表等大量信息的相关的PostgreSQL 系统 catalog 的查询结果。缓存位于 pgpool 子进程的本地，并被保存到它的生命结束。如果某些人使用了 ALTER TABLE 修改了表结构或其他类似内容，关系缓存不再一致。为了这个目的，relcache_expire 控制缓存的生命周期。     

#### relcache_size

relcache 的条目数。默认为 256。如果你频繁看到以下信息，请增加此数量。     

```
"pool_search_relcache: cache replacement happened"
```

#### check_temp_table

如果为 on，在 SELECT 语句中启用临时表检查。这会在启动查询前查询主节点上的系统对象，因此增加了主节点上的负载。如果你确定你的系统不会使用临时表，并且你想降低对主节点的访问，弄可以将它设置为 off。默认为 on。     

#### check_unlogged_table

如果设置为 on，启用在 SELECT 语句中对无日志表的检查。这回在主节点上查询系统表，因此会增加主节点的负载。如果你确认你的系统没有使用无日志的表（例如，你在使用 PostgreSQL 9.0 或者之前的版本），并且你想减少对主节点的访问，

### 2.3.12、在原始模式中的故障切换

如果定义了多个服务器，可以在原始模式中进行故障切换。pgpool-II 在普通操作中通常访问 `backend_hostname0` 指定的后台程序。如果 backend_hostname0 因为某些原因不能正常工作，pgpool-II 尝试访问 backend_hostname1 指定的后台程序。如果它也不能正常工作，pgpool-II 尝试访问 backend_hostname2，3 等等

## 2.4、连接池模式

在连接池模式中，所有在原始模式中的功能以及连接池功能都可以使用。要启用本模式，你需要设置 "[connection_cache](http://www.pgpool.net/docs/pgpool-II-3.5.4/doc/pgpool-zh_cn.html#CONNECTION_CACHE)" 为 on。

### 2.4.1、连接池相关参数

以下参数会对连接池产生影响。

#### max_pool

在 pgpool-II 子进程中缓存的最大连接数。当有新的连接使用相同的用户名连接到相同的数据库，pgpool-II  将重用缓存的连接。如果不是，则 pgpool-II 建立一个新的连接到PostgreSQL。如果缓存的连接数达到了  max_pool，则最老的连接将被抛弃，并使用这个槽位来保存新的连接。默认值为 4。请小心通过 pgpool-II 进程到后台的连接数可能达到         `num_init_children` * max_pool` 个。需要重启 pgpool-II 以使改动生效。        

#### connection_life_time

缓存的连接的过期时长，单位为秒。过期的缓存连接将被关闭。默认值为 0，表示缓存的连接将不被关闭。   

#### reset_query_list

指定在推出一个会话时发送到后台程序的SQL命令。多个命令可以通过“;”隔开。默认为以下的设置但你可以根据你的需求改变。  `reset_query_list = 'ABORT; DISCARD ALL' `         不同版本的 PostgreSQL 需要使用不同的命令。以下为推荐的设置。

| PostgreSQL 版本  |                reset_query_list 的值                |
| :--------------: | :-------------------------------------------------: |
| 7.1 或更老的版本 |                        ABORT                        |
|    7.2 到 8.2    | ABORT; RESET ALL; SET SESSION AUTHORIZATION DEFAULT |
| 8.3 或更新的版本 |                 ABORT; DISCARD ALL                  |

在 7.4 或更新的版本中，当不是在一个事务块中的时候，“ABORT”将不会被发出。                修改本参数后需要重新加载 pgpool.conf 以使改变生效。          

### 2.4.2、连接池模式中的故障切换

连接池模式中的故障切换和原始模式的相同。

## 2.5、复制模式

本模式在后台程序间启用了数据复制。以下配置参数必须在设置以上参数之外另外设置。

### 2.5.1、复制模式相关参数

#### replication_mode

设置为 true 以启用复制模式。默认值为 false。   

#### load_balance_mode

当设置为 true 时，SELECT 查询将被分发到每个后台程序上用于负载均衡。默认值为 false。本参数必须在服务器启动前设置。   

#### replication_stop_on_mismatch

当设置为 true 时，当不同的后台程序返回不同的包类型时，则和其他后台程序差别最大的后台程序将被退化。一个典型的用例为一个事务中的 SELECT 语句，在 [replicate_select](http://www.pgpool.net/docs/pgpool-II-3.5.4/doc/pgpool-zh_cn.html#REPLICATE_SELECT) 设置为 true 的情况下，一个 SELECT 语句从不同的后台程序中返回不同的行数。非 SELECT 语句也可能触发这种情况。例如，一个后台程序执行 UPDATE 成功但其他的失败。注意 pgpool 不会检查 SELECT 返回的记录的内容。如果设置为 false，则会话被终止但后台程序不被退化。默认值为 false。   

#### failover_if_affected_tuples_mismatch

当设置为 true 时，如果后端在执行 INSERT/UPDATE/DELETE 时返回影响的行数不相同，     那么拥有与其他后端匹配度最低的结果的后端将被退化掉（踢出集群）。如果匹配度相同，则包含主数据库节点（拥有最小节点 ID 的数据库节点）的一组将被保留 而其他的将被退化掉。如果设置为 false，则会话被终止但后端不被退化。默认值为 false。     

#### white_function_list

指定一系列用逗号隔开的**不会**更新数据库的函数名。在复制模式中，不在本列表中指定的函数将即不会被负载均衡，也不会被复制。在主备模式中，这些 SELECT 语句只被发送到主节点。你可以使用正则表达式来匹配函数名，例如你通过前缀“get_”或“select_”来作为你只读函数的开头：

```
white_function_list = 'get_.*,select_.*'
```

#### black_function_list V3.0 -

指定一系列用逗号隔开的会更新数据库的函数名。在复制模式中，在本列表中指定的函数将即不会被负载均衡，也不会被复制。在主备模式中，这些 SELECT 语句只被发送到主节点。 你可以使用正则表达式来匹配函数名，例如你通过前缀“set_”、“update_”、“delete_”或“insert_”来作为你只读函数的开头：

```
black_function_list = 'nextval,setval,set_.*,update_.*,delete_.*,insert_.*' 
```

以上两项不能同时配置。在 pgpool-II 3.0 之前，nextval() 和 setval() 是已知的会写入数据库的函数。你可以通使用`white_function_list`和`balck_function_list`来做到：  

```
white_function_list = '' black_function_list = 'nextval,setval,lastval,currval' 
```

注意我们在 nextval 和 setval 后面追加了 lastval 和 currval。虽然 lastval() 和 currval() 不是会写入的函数，但添加 lastval() 和 currval() 可以避免这些函数被无意地被负载均衡到其他的数据库节点而导致错误。添加到 black_function_list 将避免它们被负载均衡。          

#### replicate_select

当设置为 true，pgpool-II 在复制模式中将复制 SELECT 语句。如果为 false，则 pgpool-II 只发送它们到主数据库。默认为 false。如果 SELECT 查询是在一个显式的事务块中，[replicate_select](http://www.pgpool.net/docs/pgpool-II-3.5.4/doc/pgpool-zh_cn.html#REPLICATE_SELECT) 和 [load_balance_mode](http://www.pgpool.net/docs/pgpool-II-3.5.4/doc/pgpool-zh_cn.html#LOAD_BALANCE_MODE) 将影响复制的工作模式。以下为具体的细节。 

| replicate_select 为 true                             | Y    | N    | N    | N    | N    |
| ---------------------------------------------------- | ---- | ---- | ---- | ---- | ---- |
| load_balance_mode 为 true                            | any  | Y    | Y    | N    | Y    |
| SELECT 在一个事务块中                                | any  | Y    | Y    | 任意 | N    |
| 事务隔离级别为 SERIALIZABLE 且事务执行了写类型的查询 | any  | Y    | N    | 任意 | 任意 |
| 结果（R：复制，M：发送到主节点，L：负载均衡）        | R    | M    | L    | M    | L    |

#### insert_lock

如果在包含 SERIAL 类型的表中做复制， SERIAL 列的值在不同后台间可能不同。这个问题可以通过显式的锁表解决（当然，事务的并发性将被严重退化）。为了达到这个目的，必须做以下的改变：

```
INSERT INTO ...
```

​     改变为     

```
BEGIN;
LOCK TABLE ...
INSERT INTO ...
COMMIT;
```

当 `insert_lock` 为 true 时，pgpool-II 自动在每次执行 INSERT 时添加以上的查询（如果已经在事务中，它只是简单地添加 LOCK TABLE ... ）。     

pgpool-II 2.2 或更高的版本中，可以自动探测是否表拥有 SERIAL 类型的列，所以如果没有 SERIAL 类型的列，则将不会锁表。     

pgpool-II 3.0 系列直到3.0.4为止针对串行的关系使用一个行锁，而不是表锁。这使在VACUUM(包括  autovacuum)时的锁冲突最小。但这会导致另一个问题。如果发生了嵌套事务，对串行的关系使用行所会导致 PostgreSQL  的内部错误（确切地说，保存事务状态的 pg_clog 会发生访问错误）。为了避免这个问题，PostgreSQL  核心开发者决定禁止对串行的关系加锁，当然这也会让 pgpool-II 无法工作（"修复"后的 PostgreSQL 版本为 9.0.5,  8.4.9, 8.3.16 和 8.2.22）。

由于新版的 PostgreSQL不允许对串行的关系加锁，pgpool-II 3.0.5 或更新的版本针对pgpool_catalog.insert_lock 使用行锁。所以需要预先在通过 pgpool-II 访问的数据库中建立  insert_lock 表。详细内容请参考[建立 insert_lock 表](http://www.pgpool.net/docs/pgpool-II-3.5.4/doc/pgpool-zh_cn.html#install)。如果不存在 insert_lock 表，pgpool-II 将锁定插入的目标表。这种行为和pgpool-II 2.2 和 2.3 系列相同。如果你希望使用与旧版本兼容的 insert_lock，你可以在配置脚本中指定锁定模式。详细内容请参考 [configure](http://www.pgpool.net/docs/pgpool-II-3.5.4/doc/pgpool-zh_cn.html#install) 。        

你也许需要更好（针对每个事务）的控制手段：       

1. 设置 `insert_lock` 为 true，并添加 `/*NO INSERT LOCK*/` 代码到你不想要表锁的 INSERT 语句的开始位置。
2. 设置 `insert_lock` 为 false，并添加 `/*INSERT LOCK*/` 到你需要表锁的 INSERT 语句的开始位置。

默认值为 false。如果 `insert_lock` 被启用，则（通过 pgpool-II 运行的） PostgreSQL 8.0 的事务、权限、规则和 alter_table 的回归测试会失败。原因是 pgpool-II 会尝试 LOCK 这些规则测试的 VIEW ，并产生以下的错误消息：       

```
! ERROR: current transaction is aborted, commands ignored until
end of transaction block
```

例如，事务测试尝试 INSERT 到一个不存在的表，而 pgpool-II 导致 PostgreSQL 在这之前请求锁。事务将被终止，而之后的 INSERT 语句会产生以上的错误消息。       

#### recovery_user

本参数指定一个用于在线恢复的 PostgreSQL 用户名。改变本参数不需要重启。 

#### recovery_password

本参数指定一个用于在线恢复的 PostgreSQL 密码。改变本参数不需要重启。 

#### recovery_1st_stage_command

本参数指定一个在在线恢复第一阶段在主（Primary）PostgreSQL  服务器上运行的命令。处于安全原因，本命令必须被放置在数据库实例目录中。例如，如果 recovery_1st_stage_command =  'sync-command'，那么 pgpool-II 将执行 $PGDATA/sync-command。 

recovery_1st_stage_command 将接受以下 3 个参数： 

​	1、到主（Primary）数据库实例的路径

​	2、需要恢复的 PostgreSQL 主机名

​	3、需要恢复的数据库实例路径

注意 pgpool-II 在执行 recovery_1st_stage_command 时**接收**连接和查询。在本阶段中，你可以查询和更新数据。 

改变本参数不需要重启。 

#### recovery_2nd_stage_command

本参数指定一个在在线恢复第二阶段在主（Primary）PostgreSQL  服务器上运行的命令。处于安全原因，本命令必须被放置在数据库实例目录中。例如，如果 recovery_2st_stage_command =  'sync-command'，那么 pgpool-II 将执行 $PGDATA/sync-command。     

recovery_2nd_stage_command 将接受以下 4 个参数：     

​	1、到主（Primary）数据库实例的路径

​	2、需要恢复的 PostgreSQL 主机名

​	3、需要恢复的数据库实例路径

​	4、需要恢复的数据库实例的端口号

注意：

​	1、pgpool-II 在运行 recovery_2nd_stage_command 时不接收连接和查询。因此如果一个客户端长时间持有一个连接，则恢复命令不会被执行。pgpool-II 等待所有的客户端关闭它们的连接。这个命令只在没有任何客户端连接到 pgpool-II 时才执行。     

​	2、recovery_2nd_stage_command 对于 PostgreSQL 来说就是运行一个SQL命令。如果你启用了 PostgreSQL 的 statement_time_out 且它的值比 recovery_2nd_stage_command  执行的时间要短，PostgreSQL 会（在时间到达后）取消这个命令的执行。这种情况的典型现象是，例如命令中的 rsync 收到信号 2。     

改变本参数不需要重启。     

#### recovery_timeout

pgpool 在第二阶段不接受新的连接。如果一个客户端在恢复过程中连接到 pgpool，它必须等待到恢复结束。     

本参数指定恢复超时的时间，单位为秒。如果到达了本超时值，则 pgpool 取消在线恢复并接受连接。0 表示不等待。     

改变本参数不需要重启。     

#### client_idle_limit_in_recovery

类似于 client_idle_limit 但是只在恢复的第二阶段生效。从执行最后一个查询后空闲到client_idle_limit_in_recovery 秒的客户端将被断开连接。这对避免 pgpool 的恢复被懒客户端扰乱或者客户机和 pgpool 之间的 TCP/IP 连接被意外断开（例如网线断开）非常有用。如果设置为 -1 ，则立即断开客户端连接。     client_idle_limit_in_recovery 的默认值为 0，表示本功能不启用。     

如果你的客户端非常繁忙，则无论你将 client_idle_limit_in_recovery 设置为多少 pgpool-II 都无法进入恢复的第二阶段。在这种情况下，你可以设置 client_idle_limit_in_recovery 为 -1 因而 pgpool-II 在进入第二阶段前立即断开这些繁忙的客户端的连接。     

如果你改变了 client_idle_limit_in_recovery 你需要重新加载 pgpool.conf 。

#### lobj_lock_table

本参数指定一个表名用于大对象的复制控制。如果它被指定，pgpool 将锁定由 lobj_lock_table 指定的表并通过查找  pg_largeobject 系统 catalog 生产一个大对象 id，并调用 lo_create 来建立这个大对象。这个过程保证pgpool 在复制模式中在所有的数据库节点中获得相同的大对象 id。注意 PostgreSQL 8.0 或者更老的版本没有lo_create，因此本功能将无法工作。     

对 libpq 的 lo_creat() 函数的调用将触发本功能。通过 Java API（JDBC 驱动），PHP  API（pg_lo_create，或者 PHP 库中类似的 API 例如 PDO）进行的大对象创建，以及其他各种编程语言中相同的 API  使用相同的协议，因此也应该能够运行。 

以下的大对象建立操作将无法运行： 

libpq 中的 lo_create 

​	1、任何语言中使用 lo_create 的任何 API 

​	2、后台程序的 lo_import 函数 

​	3、SELECT lo_creat 

lobj_lock_table 存储在哪个 schema 并不重要，但是这个表必须对任何用户都可以写入。以下为如何建立这样一个表的示例： 

```
CREATE TABLE public.my_lock_table ();
GRANT ALL ON public.my_lock_table TO PUBLIC;
```

lobj_lock_table 指定的表必须被预先建立。如果你在 template1 中建立这个表，之后建立的任何数据库都将有这个表。 

如果 lobj_lock_table 为空字符串('')，这个功能被禁用（大对象的复制将无法工作）。lobj_lock_table is 的默认值为''。 

### 2.5.2、复制模式中的故障切换

pgpool-II 退化一个死掉的后台并继续提供服务。只要最少还有一个后台还或者，服务就可以继续。

### 2.5.3、复制模式中的特有错误

在复制模式中，如果 pgpool 发现 INSERT，UPDATE 和 DELETE 生效的行数不同，如果  failover_if_affected_tuples_mismatch 被设置为 false，则 pgpool 将发送错误的 SQL  语句到所有的数据库节点来取消当前当前事务（如果为 false 则发生退化）。 在这种情况下，你将在客户端终端中看到以下错误信息： 


```
=# UPDATE t SET a = a + 1;
ERROR: pgpool detected difference of the number of update tuples Possible last query was: "update t1 set i = 1;"
HINT: check data consistency between master and other db node
```

你将在 PostgreSQL 的日志中看到更新的行数（在本例中，数据库节点 0 更新了 0 行而数据库节点 1 更新了 1 行）。 

```
2010-07-22 13:23:25 LOG:   pid 5490: SimpleForwardToFrontend: Number of affected tuples are: 0 1
2010-07-22 13:23:25 LOG:   pid 5490: ReadyForQuery: Degenerate backends: 1
2010-07-22 13:23:25 LOG:   pid 5490: ReadyForQuery: Number of affected tuples are: 0 1
```

## 2.6、主/备模式

本模式用于使用其他负责完成实际的数据复制的主/备复制软件（类似于 Slong-I 和 基于流复制）来连接 pgpool-II。 必须设置数据库节点的信息（如果你需要在线恢复功能，[backend_hostname](http://www.pgpool.net/docs/pgpool-II-3.5.4/doc/pgpool-zh_cn.html#BACKEND_HOSTNAME)、[backend_port](http://www.pgpool.net/docs/pgpool-II-3.5.4/doc/pgpool-zh_cn.html#BACKEND_PORT)、 [backend_weight](http://www.pgpool.net/docs/pgpool-II-3.5.4/doc/pgpool-zh_cn.html#BACKEND_WEIGHT)、[backend_flag](http://www.pgpool.net/docs/pgpool-II-3.5.4/doc/pgpool-zh_cn.html#BACKEND_FLAG) 和 [backend_data_directory](http://www.pgpool.net/docs/pgpool-II-3.5.4/doc/pgpool-zh_cn.html#BACKEND_DATA_DIRECTORY)），这和复制模式中的方法相同。另外，还需要设置 `master_slave_mode` 和 `load_balance_mode` 为 true。 

pgpool-II 将发送需要复制的查询到主数据库，并在必要时将其他的查询将被负载均衡。不能被负载均衡而发送到主数据库的查询当然也是受负载均衡逻辑控制的。 

在主/备模式中，对于临时表的 DDL 和 DML 操作只能在主节点上被执行。SELECT 也可以被强制在主节点上执行，但这需要你在 SELECT 语句前添加一个`/*NO LOAD BALANCE*/`注释。 

在主/备模式中， `replication_mode` 必须被设置为 false ，并且 `master_slave_mode` 为 true。

主/备模式有一个“master_slave_sub mode”。默认值为 'slony'，用于 Slony-I。你也可以设置它为  'stream'，它在你想使用 PostgreSQL 内置的复制系统（基于流复制）时被设置。用于 Slony-I 子模式的示例配置文件为  pgpool.conf.sample-master-slave，用于基于流复制的子模式的示例文件为 sub-module is  pgpool.conf.sample-stream。 

修改以上任何参数都需要重新启动 pgpool-II。 

在主/备模式中，你可以通过设置 [white_function_list](http://www.pgpool.net/docs/pgpool-II-3.5.4/doc/pgpool-zh_cn.html#WHITE_FUNCTION_LIST) 和 [black_function_list](http://www.pgpool.net/docs/pgpool-II-3.5.4/doc/pgpool-zh_cn.html#BLACK_FUNCTION_LIST) 来控制负载均衡。参考 [white_function_list](http://www.pgpool.net/docs/pgpool-II-3.5.4/doc/pgpool-zh_cn.html#WHITE_FUNCTION_LIST) 获得详细信息。 

## 2.7、流复制

### 2.7.1、流复制相关设置

就像以上规定的，pgpool-II 可以与 PostgreSQL 9.0 带来的基于流复制协同工作。要使用它，启用“[master_slave_mode](http://www.pgpool.net/docs/pgpool-II-3.5.4/doc/pgpool-zh_cn.html#MASTER_SLAVE_MODE)”并设置“[master_slave_sub_mode](http://www.pgpool.net/docs/pgpool-II-3.5.4/doc/pgpool-zh_cn.html#MASTER_SLAVE_SUB_MODE)”为“stream”。 pgpool-II 认为基于流复制启用了热备，也就是说备库是以只读方式打开的。以下参数可以用于本模式： 

#### delay_threshold

指定能够容忍的备机上相对于主服务器上的 WAL 的复制延迟，单位为字节。如果延迟到达了 delay_threshold，pgpool-II 不再发送 SELECT 查询到备机。所有的东西都被发送到主服务器，即使启用了负载均衡模式，直到备机追赶上来。如果 delay_threshold 为 0 或者流复制检查被禁用，则延迟检查不被执行。这个检查在每“[sr_check_period](http://www.pgpool.net/docs/pgpool-II-3.5.4/doc/pgpool-zh_cn.html#SR_CHECK_PERIOD")”周期执行一次。delay_threshold 的默认值为 0。要使对本参数的改动生效，你需要重新加载 pgpool.conf。          

#### sr_check_period

本参数指出基于流复制的延迟检查的间隔，单位为秒。     默认为 0，表示禁用这个检查。               如果你修改了 sr_check_period，需要重新加载 pgpool.conf 以使变动生效。          

#### sr_check_user

执行基于流复制检查的用户名。用户必须存在于所有的 PostgreSQL 后端上，否则，检查将出错。注意即使 sr_check_period 为 0， sr_check_user 和 sr_check_password 也会被使用。要识别主服务器，pgpool-II 发送函数调用请求到每个后端。sr_check_user 和 sr_check_password 用于这个会话。如果你修改了 sr_check_user，需要重新加载 pgpool.conf 以使变动生效。          

#### sr_check_password

执行流复制检测的用户的密码。如果不需要密码，则指定空串（''）。如果你改变了 sr_check_password，你需要重新加载 pgpool.conf。          

#### sr_check_database

执行流复制延迟检测的数据库。默认为“postgres”（这是 3.4 或者以前版本使用的内置数据库名）。如果你改变了 sr_check_database，你需要重新加载 pgpool.conf。          

#### log_standby_delay

指出如何记录复制延迟。如果指定 'none'，则不写入日志。如果为 'always'，在每次执行复制延迟检查时记录延迟。如果 'if_over_threshold' 被指定，只有当延迟到达 [delay_threshold](http://www.pgpool.net/docs/pgpool-II-3.5.4/doc/pgpool-zh_cn.html#DELAY_THRESHOLD) 时记录日志。log_standby_delay 的默认值为 'none'。如果你改变了 log_standby_delay，你需要重新加载 pgpool.conf。你也可以使用“[show pool_status](http://www.pgpool.net/docs/pgpool-II-3.5.4/doc/pgpool-zh_cn.html#pool_status)”命令监控复制延迟。列名为“standby_delay#”（其中 '#' 需要用数据库节点编号代

### 2.7.2、流复制下的故障切换

在使用流复制的主/备模式中，如果主节点或者备节点失效，pgpool-II 可以被设置为触发一个故障切换。节点可以被自动断开而不需要进行更多设置。 当进行流复制的时候，备节点检查一个“触发文件”的存在，一旦发现它，则备节点停止持续的恢复并进入读写模式。通过使用这种功能，我们可以使备数据库在主节点失效的时候进行替换。 

**警告：如果你计划使用多个备节点，我们建议设置一个 delay_threshold 值来避免任何查询由于查询被发送到其他备节点而导致获取旧数据。** 

**如果第二个备节点在第一个备节点已经发生替换的时候替换主节点，你会从第二备节点获取错误的数据。我们不推荐计划使用这种配置。**  

 以下例举了如何设置一个故障切换的配置。 

1、将一个故障切换脚本放置到某个地方（例如 /usr/local/pgsql/bin ）并给它执行权限。 

```
$ cd /usr/loca/pgsql/bin
$ cat failover_stream.sh
#! /bin/sh
# Failover command for streaming replication.
# This script assumes that DB node 0 is primary, and 1 is standby.
#
# If standby goes down, do nothing. If primary goes down, create a
# trigger file so that standby takes over primary node.
#
# Arguments: $1: failed node id. $2: new master hostname. $3: path to
# trigger file.

failed_node=$1
new_master=$2
trigger_file=$3

# Do nothing if standby goes down.
if [ $failed_node = 1 ]; then
    exit 0;
fi

# Create the trigger file.
/usr/bin/ssh -T $new_master /bin/touch $trigger_file

exit 0;

chmod 755 failover_stream.sh
```

2、在 pgpool.conf 中设置 [failover_commmand](http://www.pgpool.net/docs/pgpool-II-3.5.4/doc/pgpool-zh_cn.html#FAILOVER_COMMAND)

```
failover_command = '/usr/local/src/pgsql/9.0-beta/bin/failover_stream.sh %d %H /tmp/trigger_file0'
```

3、在备节点中设置 recovery.conf。一个 [recovery.conf 示例](http://www.pgpool.net/docs/pgpool-II-3.5.4/doc/recovery.conf.sample) 可以在 PostgreSQL 安装目录中找到。它的名字为 "share/recovery.conf.sample"。拷贝 recovery.conf.sample 为 recovery.conf 到数据库节点目录并编辑它。 

```
standby_mode = 'on'
primary_conninfo = 'host=name of primary_host user=postgres'
trigger_file = '/tmp/trigger_file0'
```

4、设置主节点上的 postgresql.conf 。以下仅仅是一个示例。你需要根据你自己的环境做调整。 

```
wal_level = hot_standby
max_wal_senders = 1
```

5、设置主节点上的 pg_hba.conf 。以下仅仅是一个示例。你需要根据你自己的环境做调整。 

```
host    replication    postgres        192.168.0.10/32        trust
```

启动首要 PostgreSQL 节点和第二 PostgreSQL 节点来初始化基于流复制。如果主节点失效，备节点将自动启动为普通 PostgreSQL 并准备好接受写查询。 

### 2.7.3、流复制中的查询

当使用流复制和热备的时候，确定哪个查询可以被发送到主节点或备节点或者不能被发送到备节点非常重要。pgpool-II 的流复制模式可以很好的处理这种情况。在本章，我们将解释 pgpool-II 如何做到这一点的。 

我们通过检查查询来辨别哪个查询应该被发送到哪个节点。 

- 这些查询只允许被发送到主节点     
  - INSERT, UPDATE, DELETE, COPY FROM, TRUNCATE, CREATE, DROP, ALTER, COMMENT
  - SELECT ... FOR SHARE | UPDATE
  - 在事务隔离级别为 SERIALIZABLE 的 SELECT
  - 比 ROW EXCLUSIVE MODE 更严厉的 LOCK 命令
  - DECLARE, FETCH, CLOSE
  - SHOW
  - 一些事务相关命令：            
    - BEGIN READ WRITE, START TRANSACTION READ WRITE
    - SET TRANSACTION READ WRITE, SET SESSION CHARACTERISTICS AS TRANSACTION READ WRITE
    - SET transaction_read_only = off             
  - 两步提交命令：PREPARE TRANSACTION, COMMIT PREPARED, ROLLBACK PREPARED
  - LISTEN, UNLISTEN, NOTIFY
  - VACUUM
  - 一些序列生成器操作函数（nextval 和 setval）
  - 大对象建立命令
- 这些查询可以被发送到主节点和备节点。如果启用了负载均衡，这些查询可以被发送到备节点。但是，如果设置了`delay_threshold` 且复制延迟大于这个值，则查询被发送到主节点。     
  - SELECT not listed above
  - COPY TO
- 以下查询被同时发送到主节点和备节点    
  - SET
  - DISCARD
  - DEALLOCATE ALL

 在一个显式的事务中： 

- 启动事务的命令例如 BEGIN 只被发送到主节点。
- 接下来的 SELECT 和一些可以被发送到主节点或备节点的其他查询会在事务中执行或者在备节点中执行。
- 无法在备节点中执行的命令例如 INSERT 被发送到主节点。在这些命令之后的命令，即使是 SELECT 也被发送到主节点。这是因为这些 SELECT 语句可能需要立即查看 INSERT 的结果。这种行为一直持续到事务关闭或者终止。 

在扩展协议中，在负载均衡模式中在分析查询时，有可能探测是否查询可以被发送到备节点。规则和非扩展协议下相同。例如，INSERT 被发送到主节点。接下来的 bind，describe 和 execute 也将被发送到主节点。 

 [注：如果对 SELECT 语句的分析由于负载均衡被发送到备节点，然后一个 DML 语句，例如一个 INSERT ，被发送到 pgpool-II，那么，被分析的 SELECT 必须在主节点上执行。因此，我们会在主节点上重新分析这个 SELECT 语句。] 

 最后，pgpool-II 的分析认为有错误的查询将被发送到主节点。 

 在指定负载均衡的时候，你可以使用数据库名和应用程序名而达到更小的粒度。 

####  database_redirect_preference_list

你可以成对设置 "database name:node id" 来指定在连接到数据库时候使用的节点编号。       例如，指定 "test:1"，则 pgpool-II 在连接到 "test" 数据库的时候总是将 SELECT 语句重定向到节点 1。你可以指定多个用逗号(,)分隔的 "database name:node id" 参数对。数据库名允许使用正则表达式。关键字 "primary" 表示主节点，关键字 "standby" 表示备节点。示例如下：

```
database_redirect_preference_list = 'postgres:primary,mydb[01]:1,mydb2:standby' 
```

连接到 postgres 数据库时 SELECT 语句将被重定向到主节点。连接到 mydb0 或者  mydb1 将重定向 SELECT 语句到节点 1。连接到 mydb2 将重定向 SELECT 语句重定向到一个备节点。

要使对本参数的改动生效，你需要重新加载 pgpool.conf。          

#### app_name_redirect_preference_list

你可以成对设置 "application name:node id" 来指定应用程序使用的节点编号。       "Application name" 是客户端连接到数据库时指定的一个名称。你可以在 PostgreSQL 9.0 或以后的版本中使用。

注意： 	

即使为 JDBC 驱动指定了“ApplicationName”选项以及“assumeMinServerVersion=9.0”选项， postgresql-9.3 以及以前版本的 JDBC 驱动在启动包中不会发送应用程序名，因此也无法使用这个功能。 如果你希望使用这个功能，请使用 postgresql-9.4 或者之后版本的驱动。                        

例如，psql 命令的名称是 "psql"。pgpool-II 只能识别客户端在初始数据包中包含的应用程序名。客户端可以在之后发送应用程序名但 pgpool-II 无法识别它。                 app_name_redirect_preference_list 的概念和 app_name_redirect_preference_list 相同。       因此你也可以使用正则表达式来匹配应用程序名。                

以下为一个示例：    

```
app_name_redirect_preference_list = 'psql:primary,myapp1:1,myapp2:standby'  
```

本例中， psql 的 SELECT 语句被发送到主节点，myapp1 的发送到节点 1，myapp2 的发送到备节点。app_name_redirect_preference_list 的优先级高于database_redirect_preference_list。

例如：

```
database_redirect_preference_list = 'bigdb:primary'    app_name_redirect_preference_list = 'myapp:2' 
```

应用程序连接到数据库 bigdb 并发送 SELECT 语句到主节点。但是 myapp 发送 SELECT 语句到节点 2，即使它连接到的是 bigdb 数据库。这在脚本中非常有用：myapp2 发送大量繁重的 SELECT 语句以执行分析任务。你想单独使用节点 2 来进行分析工作。

要使对本参数的改动生效，你需要重新加载 pgpool.conf。          

### 2.7.4、流复制中的在线恢复

在流复制的主/备模式中，可以执行在线恢复。在在线恢复过程中，首要务器扮演了主服务器的角色并恢复到指定的备服务器。因此恢复过程需要首要服务器启动并运行。 如果第一服务器失效且没有备用服务器被提升，你需要停止 pgpool-II 和所有的 PostgreSQL 服务器并手动恢复它们。 

1、设置 [recovery_user](http://www.pgpool.net/docs/pgpool-II-3.5.4/doc/pgpool-zh_cn.html#RECOVERY_USER)。通常为 "postgres"。 

```
recovery_user = 'postgres'
```

2、设置登录到数据库的 [recovery_user](http://www.pgpool.net/docs/pgpool-II-3.5.4/doc/pgpool-zh_cn.html#RECOVERY_USER) 的 [recovery_password](http://www.pgpool.net/docs/pgpool-II-3.5.4/doc/pgpool-zh_cn.html#RECOVERY_PASSWORD)。 

```
recovery_password = 't-ishii'
```

3、设置 recovery_1st_stage_command。

这个阶段的这个脚本用来执行一个首要数据库的备份并还原它到备用节点。将此脚本放置在首要数据库示例的目录中并给它可执行权限。这里有一个用于配置了一个主节点和一个备节点的示例脚本 ([basebackup.sh](http://www.pgpool.net/docs/pgpool-II-3.5.4/doc/basebackup.sh)) 。

```shell
#! /bin/sh
# Recovery script for streaming replication.
# This script assumes that DB node 0 is primary, and 1 is standby.
# basebackup.sh
# 
datadir=$1
desthost=$2
destdir=$3

psql -c "SELECT pg_start_backup('Streaming Replication', true)" postgres

rsync -C -a --delete -e ssh --exclude postgresql.conf --exclude postmaster.pid \
--exclude postmaster.opts --exclude pg_log --exclude pg_xlog \
--exclude recovery.conf $datadir/ $desthost:$destdir/

ssh -T $desthost mv $destdir/recovery.done $destdir/recovery.conf

psql -c "SELECT pg_stop_backup()" postgres
```

你需要设置 ssh 让 recovery_user 可以从首要节点登录到备用节点而不需要提供密码。  

```
recovery_1st_stage_command = 'basebackup.sh'
```

4、让 [recovery_2nd_stage_command](http://www.pgpool.net/docs/pgpool-II-3.5.4/doc/pgpool-zh_cn.html#RECOVERY_2ND_STAGE_COMMAND)  保留为空。 

```
recovery_2nd_stage_command = ''
```

5、在每个数据库节点中安装必须的执行在线恢复的 C 和 SQL 函数。 

```
# cd pgpool-II-x.x.x/sql/pgpool-recovery
# make
# make install
# psql -f pgpool-recovery.sql template1
```

6、在完成在线恢复后，pgpool-II 将在备节点启动 PostgreSQL。在每个数据库节点中安装用于本用途的脚本。[示例脚本](http://www.pgpool.net/docs/pgpool-II-3.5.4/doc/pgpool_remote_start) 包含在源码的“sample”目录中。这个脚本使用了 ssh。你需要允许 recover_user 从首要节点登录到备用节点而不需要输入密码。     

以上未全部内容。现在你可以使用 pcp_recovery_node （作为备用节点的步骤）或者点击 pgpoolAdmin 的“恢复”按钮来执行在线恢复了。 如果出现问题，请检查 pgpool-II 的日子，首要服务器的日志和备用服务器的日志。 

作为参考，以下为恢复过程的步骤。 

（1）、Pgpool-II 使用 user = [recovery_user](http://www.pgpool.net/docs/pgpool-II-3.5.4/doc/pgpool-zh_cn.html#RECOVERY_USER), password = [recovery_password](http://www.pgpool.net/docs/pgpool-II-3.5.4/doc/pgpool-zh_cn.html#RECOVERY_PASSWORD)连接到首要服务器的 template1 数据库。     

（2）、首要服务器执行 pgpool_recovery 函数。     

（3）、pgpool_recovery 函数执行 recovery_1st_stage_command。注意 PostgreSQL 在数据库实例的当前目录中执行函数。因此，recovery_1st_stage_command 在数据库实例的目录中执行。     

（4）、首要服务器执行 pgpool_remote_start 函数。本函数执行一个在数据库实例路径中名为“pgpool_remote_start”的脚本，它通过 ssh 在备用服务器上执行 pg_ctl 命令来进行恢复。pg_ctl 将在后台启动 postmaster。所以我们需要确保备用节点上的 postmaster 真正启动了。     

（5）、pgpool-II 尝试使用 user = recovery_user 和 password = recovery_password         连接到备用 PostgreSQL。如果可能，连接到的数据库为“postgres”。否则，使用“template1”。pgpool-II 尝试 [recovery_timeout](http://www.pgpool.net/docs/pgpool-II-3.5.4/doc/pgpool-zh_cn.html#RECOVERY_TIMEOUT) 秒。如果成功，进行下一步。     

（6）、如果 [failback_command](http://www.pgpool.net/docs/pgpool-II-3.5.4/doc/pgpool-zh_cn.html#FAILBACK_COMMAND) 不为空，pgpool-II 父进程执行这个脚本。     

（7）、在 failback_command 完成后，pgpool-II 重新启动所有的子进程。     

## 2.8、配置pool_hba.conf

和PostgreSQL中使用的pg_hba.conf文件类似，pgpool-II使用一个称之为"pool_hba.conf" 的配置文件来支持类似的客户端认证功能。 

当安装 pgpool 的时候，pool_hba.conf.sample  文件将被安装在"/usr/local/etc"目录下，该位置也是配置文件的默认目录。拷贝 pool_hba.conf.sample 为  pool_hba.conf，如果必要的话并修改它。默认的情况下，[enable_pool_hba](http://www.pgpool.net/docs/pgpool-II-3.5.4/doc/pgpool-zh_cn.html#ENABLE_POOL_HBA) 认证被开启。 

pool_hba.conf 文件的格式和 PostgreSQL 的 pg_hba.conf 的格式遵循的非常相近。 

```
local      DATABASE  USER  METHOD  [OPTION]
host       DATABASE  USER  CIDR-ADDRESS  METHOD  [OPTION]
```

 查看 "pool_hba.conf.sample" 文件获取每个字段详细的解释。 

 下面是 pool_hba 的一些限制。 

- DATABASE 字段使用的"samegroup" 不被支持

- 尽管 pgpool 并不知道后端服务器的用户的任何信息，但是将通过 pool_hba.conf 中的 DATABASE 字段项对数据库名进行简单的检查。     

- USER 字段使用的 group 名字后面跟个"+"不被支持 

  这与上面介绍的 "samegroup" 原因相同，将通过 pool_hba.conf 中 USER 字段项对用户名进行简单的检查。     

- 为 IP address/mask 使用的 IPv6 不被支持

- pgpool 当前不支持 IPv6.     

- METHOD 字段仅仅支持 "trust", "reject", "md5" 和 "pam" 

- 再次，这与上面介绍的 "samegroup" 原因相同, pgpool 不能够访问 user/password 信息。要使用md5认证，你需要在 "pool_passwd" 中注册你的名字和密码。详见[认证/访问控制](http://www.pgpool.net/docs/pgpool-II-3.5.4/doc/pgpool-zh_cn.html#md5)。 

注意本节描述的所有认证发生在客户端和pgpool-II之间；客户端仍然需要继续通过PostgreSQL的认证过程。pool_hba 并不关心客户端提供的用户名/数据库名（例如 psql -U testuser testdb）是否真实存在于后端服务器中。pool_hba 仅仅关心是否在 pool_hba.conf 中存在匹配。 

PAM 认证使用 pgpool 运行的主机上的用户信息来获得支持。若让 pgpool 支持PAM，需要在 configure 时指定"--with-pam"选项。 

```
configure --with-pam
```

若启用 PAM 认证，你需要为 pgpool 在系统的 PAM 配置目录(通常是在"/etc/pam.d")中创建一个 service-configuration 文件。一个 service-configuration 的示例文件被安装为安装目录下的"share/pgpool.pam"。 