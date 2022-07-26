> 基于PGPool的1主2从PostgreSQL流复制HA的搭建
>
> 原文：https://yq.aliyun.com/articles/463935

==Note：未测试==

# 基于PGPool的1主2从PostgreSQL流复制HA的搭建-云栖社区-阿里云

PostgreSQL的流复制为HA提供了很好的支持，但是部署HA集群还需要专门的HA组件， 比如通用的Pacemaker+Corosync。pgpool作为PostgreSQL的中间件，也提供HA功能。

pgpool可以监视后端PostgreSQL的健康并实施failover，由于应用的所有流量都经过pgpool，可以很容易对故障节点进行隔离， 但，同时必须为pgpool配置备机，防止pgpool本身成为单点。pgpool自身带watchdog组件通过quorum机制防止脑裂， 因此建议pgpool节点至少是3个，并且是奇数。在失去quorum后watchdog会自动摘除VIP，并阻塞客户端连接。

下面利用pgpool搭建3节点PostgreSQL流复制的HA集群。 集群的目标为强数据一致HA，实现思路如下:

*   基于PostgreSQL的1主2从同步复制
*   Slave的复制连接字符串使用固定的pgsql\_primary作为Master的主机名，在/etc/hosts中将Master的ip映射到pgsql\_primary上，通过/etc/hosts的修改实现Slave对复制源(Master)的切换。 之所以采取这种方式是为了避免直接修改recovery.conf后重启postgres进程时会被pgpool检测到并设置postgres后端为down状态。
*   pgpool分别部署在3个节点上，pgpool的Master和PostgreSQL的Primary最好不在同一个节点上，这样在PostgreSQL的Primary down时可以干净的隔离故障机器。

环境
--

### 软件

*   CentOS 7.0
*   PGPool 3.5
*   PostgreSQL9.5

### 节点

*   node1 192.168.0.211
*   node2 192.168.0.212
*   node3 192.168.0.213
*   vip 192.168.0.220

### 配置

*   PostgreSQL Port:5433
*   复制账号:replication/replication
*   管理账号:admin/admin

### 前提

*   3个节点建立ssh互信。

*   3个节点配置好主机名解析（/etc/hosts）  
    
*   将pgsql\_primary解析为主节点的IP
    
    ```
    [postgres@node3 ~]$ cat /etc/hosts
    127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
    ::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
    192.168.0.211 node1
    192.168.0.212 node2
    192.168.0.213 node3
    192.168.0.211 pgsql_primary 
    ```
    
    
    
*   3个节点事先装好PostgreSQL，并配置1主2从同步流复制，node1是主节点。  
    在2个Slave节点node2和node3上设置recovery.conf中的复制源的主机名为pgsql\_primary
    
    ```
    [postgres@node3 ~]$ cat /data/postgresql/data/recovery.conf 
    standby_mode = 'on'
    primary_conninfo = 'host=pgsql_primary port=5433 application_name=node3 user=replication password=replication keepalives_idle=60 keepalives_interval=5 keepalives_count=5'
    restore_command = ''
    recovery_target_timeline = 'latest' 
    ```
    
    
    

安装pgpool
--------

### 在node1,node2和node3节点上安装pgpool-II

```
yum install http://www.pgpool.net/yum/rpms/3.5/redhat/rhel-7-x86_64/pgpool-II-release-3.5-1.noarch.rpm

yum install pgpool-II-pg95 pgpool-II-pg95-extensions 
```



### 在Master上安装pgpool\_recovery扩展(可选）

```
[postgres@node1 ~]$ psql template1 -p5433 
psql (9.5.2)
Type "help" for help.

template1=# CREATE EXTENSION pgpool_recovery; 
```

pgpool\_recovery扩展定义了4个函数用于远程控制PG，这样可以避免了对ssh的依赖，不过下面的步骤没有用到这些函数。

```
template1=> \dx+ pgpool_recovery
    Objects in extension "pgpool_recovery"
              Object Description               
-----------------------------------------------
 function pgpool_pgctl(text,text)
 function pgpool_recovery(text,text,text)
 function pgpool_recovery(text,text,text,text)
 function pgpool_remote_start(text,text)
 function pgpool_switch_xlog(text)
(5 rows) 
```



配置pgpool.conf
-------------

以下是node3上的配置，node1和node2节点上参照设置

```
$ cp /etc/pgpool-II/pgpool.conf.sample-stream /etc/pgpool-II/pgpool.conf
$ vi /etc/pgpool-II/pgpool.conf
listen_addresses = '*'
port = 9999
pcp_listen_addresses = '*'
pcp_port = 9898

backend_hostname0 = 'node1'
backend_port0 = 5433
backend_weight0 = 1
backend_data_directory0 = '/data/postgresql/data'
backend_flag0 = 'ALLOW_TO_FAILOVER'

backend_hostname1 = 'node2'
backend_port1 = 5433
backend_weight1 = 1
backend_data_directory1 = '/data/postgresql/data'
backend_flag1 = 'ALLOW_TO_FAILOVER'

backend_hostname2 = 'node3'
backend_port2 = 5433
backend_weight2 = 1
backend_data_directory2 = '/data/postgresql/data'
backend_flag2 = 'ALLOW_TO_FAILOVER'

enable_pool_hba = off
pool_passwd = 'pool_passwd'

pid_file_name = '/var/run/pgpool/pgpool.pid'
logdir = '/var/log/pgpool'

connection_cache = on
replication_mode = off
load_balance_mode = on

master_slave_mode = on
master_slave_sub_mode = 'stream'

sr_check_period = 10
sr_check_user = 'admin'
sr_check_password = 'admin'
sr_check_database = 'postgres'
delay_threshold = 10000000
follow_master_command = ''

health_check_period = 3
health_check_timeout = 20
health_check_user = 'admin'
health_check_password = 'admin'
health_check_database = 'postgres'
health_check_max_retries = 0
health_check_retry_delay = 1
connect_timeout = 10000

failover_command = '/home/postgres/failover.sh %h %H %d %P'
failback_command = ''
fail_over_on_backend_error = on
search_primary_node_timeout = 10


use_watchdog = on
wd_hostname = 'node3'     ##设置本节点的节点名
wd_port = 9000
wd_priority = 1
wd_authkey = ''
wd_ipc_socket_dir = '/tmp'

delegate_IP = '192.168.0.220'
if_cmd_path = '/usr/sbin'
if_up_cmd = 'ip addr add $_IP_$/24 dev eno16777736 label eno16777736:0'
if_down_cmd = 'ip addr del $_IP_$/24 dev eno16777736'
arping_path = '/usr/sbin'
arping_cmd = 'arping -U $_IP_$ -w 1 -I eno16777736'

wd_monitoring_interfaces_list = ''
wd_lifecheck_method = 'heartbeat'
wd_interval = 10

wd_heartbeat_port = 9694
wd_heartbeat_keepalive = 2
wd_heartbeat_deadtime = 30
heartbeat_destination0 = 'node1'    ##设置其它PostgreSQL节点的节点名
heartbeat_destination_port0 = 9694
heartbeat_device0 = 'eno16777736'
heartbeat_destination1 = 'node2'    ##设置其它PostgreSQL节点的节点名
heartbeat_destination_port1 = 9694
heartbeat_device1 = 'eno16777736'

other_pgpool_hostname0 = 'node1'    ##设置其它pgpool节点的节点名
other_pgpool_port0 = 9999
other_wd_port0 = 9000
other_pgpool_hostname0 = 'node2'    ##设置其它pgpool节点的节点名
other_pgpool_port0 = 9999
other_wd_port0 = 9000 
```



配置PCP命令接口
---------

pgpool-II 有一个用于管理功能的接口，用于通过网络获取数据库节点信息、关闭 pgpool-II 等。要使用 PCP 命令，必须进行用户认证。这需要在 pcp.conf 文件中定义一个用户和密码。

```
$ pg_md5 pgpool
ba777e4c2f15c11ea8ac3be7e0440aa0

$ vi /etc/pgpool-II/pcp.conf
root:ba777e4c2f15c11ea8ac3be7e0440aa0 
```

为了免去每次执行pcp命令都输入密码的麻烦，可以配置免密码文件。

```
$ vi ~/.pcppass
localhost:9898:root:pgpool

$ chmod 0600 ~/.pcppass 
```



配置pool\_hba.conf（可选）
--------------------

pgpool可以按照和PostgreSQL的hba.conf类似的方式配置自己的主机认证，所有连接到pgpool上的客户端连接将接受认证，这解决了后端PostgreSQL无法直接对前端主机进行IP地址限制的问题。

开启pgpool的hba认证

```
$ vi /etc/pgpool-II/pgpool.conf
enable_pool_hba = on 
```

编辑pool\_hba.conf，注意客户端的认证请求最终还是要被pgpool转发到后端的PostgreSQL上去，所以pool\_hba.conf上的配置应和后端的hba.conf一致，比如pgpool对客户端的连接采用md5认证，那么PostgreSQL对这个pgpool转发的连接也要采用md5认证，并且密码相同。

```
$ vi /etc/pgpool-II/pool_hba.conf 
```

如果pgpool使用了md5认证，需要在pgpool上设置密码文件。

密码文件名通过pgpool.conf中的pool\_passwd参数设置，默认为/etc/pgpool-II/pool\_passwd

设置pool\_passwd的方法如下。

```
$ pg_md5 -m -u admin admin 
```



启动pgpool
--------

分别在3个节点上启动pgpool。

```
[root@node3 ~]# service pgpool start
Redirecting to /bin/systemctl start  pgpool.service 
```

检查pgpool日志输出，确认启动成功。

```
[root@node3 ~]# tail /var/log/messages

Nov  8 12:53:47 node3 pgpool: 2016-11-08 12:53:47: pid 31078: LOG:  pgpool-II successfully started. version 3.5.4 (ekieboshi) 
```

通过pcp\_watchdog\_info命令确认集群状况

```
[root@node3 ~]# pcp_watchdog_info  -w -v
Watchdog Cluster Information 
Total Nodes          : 3
Remote Nodes         : 2
Quorum state         : QUORUM EXIST
Alive Remote Nodes   : 2
VIP up on local node : NO
Master Node Name     : Linux_node2_9999
Master Host Name     : node2

Watchdog Node Information 
Node Name      : Linux_node3_9999
Host Name      : node3
Delegate IP    : 192.168.0.220
Pgpool port    : 9999
Watchdog port  : 9000
Node priority  : 1
Status         : 7
Status Name    : STANDBY

Node Name      : Linux_node1_9999
Host Name      : node1
Delegate IP    : 192.168.0.220
Pgpool port    : 9999
Watchdog port  : 9000
Node priority  : 1
Status         : 7
Status Name    : STANDBY

Node Name      : Linux_node2_9999
Host Name      : node2
Delegate IP    : 192.168.0.220
Pgpool port    : 9999
Watchdog port  : 9000
Node priority  : 1
Status         : 4
Status Name    : MASTER 
```

通过psql命令确认集群状况

```
[root@node3 ~]# psql -hnode3 -p9999 -U admin postgres
...
postgres=> show pool_nodes;
 node_id | hostname | port | status | lb_weight |  role   | select_cnt 
---------+----------+------+--------+-----------+---------+------------
 0       | node1    | 5433 | 2      | 0.333333  | standby | 0
 1       | node2    | 5433 | 2      | 0.333333  | standby | 0
 2       | node3    | 5433 | 2      | 0.333333  | primary | 0
(3 rows) 
```



准备failover脚本
------------

准备failover脚本,并部署在3个节点上

### /home/postgres/failover.sh

```
#!/bin/bash

pgsql_nodes="node1 node2 node3"
logfile=/var/log/pgpool/failover.log

down_node=$1
new_master=$2
down_node_id=$3
old_master_id=$4
old_master=$down_node

export PGDATA="/data/postgresql/data"
export PGPORT=5433
export PGDATABASE=postgres
export PGUSER=admin
export PGPASSWORD=admin

trigger_command="pg_ctl -D $PGDATA promote -m fast"
stop_command="pg_ctl -D $PGDATA stop -m fast"
start_command="pg_ctl -D $PGDATA start"
restart_command="pg_ctl -D $PGDATA restart -m fast"

CHECK_XLOG_LOC_SQL="select pg_last_xlog_replay_location(),pg_last_xlog_receive_location()"

log()
{
  echo "$*" >&2
  echo "`date +'%Y-%m-%d %H:%M:%S'` $*" >> $logfile
}

# Execulte SQL and return the result.
exec_sql() {
    local host="$1"
    local sql="$2"
    local output
    local rc

    output=`psql -h $host -Atc "$sql"`
    rc=$?

    echo $output
    return $rc
}

get_xlog_location() {
    local rc
    local output
    local replay_loc
    local receive_loc
    local output1
    local output2
    local log1
    local log2
    local newer_location
    local target_host=$1

    output=`exec_sql "$target_host" "$CHECK_XLOG_LOC_SQL"`
    rc=$?

    if [ $rc -ne 0 ]; then
        log "Can't get xlog location from $target_host.(rc=$rc)"
        exit 1
    fi
    replay_loc=`echo $output | cut -d "|" -f 1`
    receive_loc=`echo $output | cut -d "|" -f 2`

    output1=`echo "$replay_loc" | cut -d "/" -f 1`
    output2=`echo "$replay_loc" | cut -d "/" -f 2`
    log1=`printf "%08s\n" $output1 | sed "s/ /0/g"`
    log2=`printf "%08s\n" $output2 | sed "s/ /0/g"`
    replay_loc="${log1}${log2}"

    output1=`echo "$receive_loc" | cut -d "/" -f 1`
    output2=`echo "$receive_loc" | cut -d "/" -f 2`
    log1=`printf "%08s\n" $output1 | sed "s/ /0/g"`
    log2=`printf "%08s\n" $output2 | sed "s/ /0/g"`
    receive_loc="${log1}${log2}"

    newer_location=`printf "$replay_loc\n$receive_loc" | sort -r | head -1`
    echo "$newer_location"
    return 0
}

get_newer_location()
{
    local newer_location

    newer_location=`printf "$1\n$2" | sort -r | head -1`
    echo "$newer_location"
}

log "##########failover start:$0 $*"

# if standby down do nothing
if [ "X$down_node_id" != "X$old_master_id" ]; then
   log "standby node '$down_node' down,skip"
   exit
fi

# check the old_master dead
log "check the old_master '$old_master' dead ..."
exec_sql $old_master "select 1" >/dev/null 2>&1
if [ $? -eq 0 ]; then
  log "the old master $old_master is alive, cancel faiover"
  exit 1
fi

# check all nodes other than the old master alive and is standby
log "check all nodes '$pgsql_nodes' other than the old master alive and is standby ..."
for host in $pgsql_nodes ; do
    if [ $host != $old_master ]; then
        is_in_recovery=`exec_sql $host "select pg_is_in_recovery()"`
        if [ $? -ne 0 ]; then
          log "failed to check $host"
          exit 1
        fi

        if [ "$is_in_recovery" != 't' ];then
            log "$host is not a valid standby(is_in_recovery=$is_in_recovery)"
            exit
        fi
    fi
done

# find the node with the newer xlog
log "find the node with the newer xlog ..."
# TODO wait for all xlog replayed
newer_location=$(get_xlog_location $new_master)
log "$new_master : $newer_location"
new_primary=$new_master

for host in $pgsql_nodes ; do
  if [ $host != $new_primary -a $host != $old_master ]; then
    location=$(get_xlog_location $host)
    log "$host : $location"
    if [ "$newer_location" != "$(get_newer_location $location $newer_location)" ]; then
      newer_location=$location
      new_primary=$host
      log "change new primary to $new_primary"
    fi
  fi
done


# change replication source to the new primary in all standbys
for host in $pgsql_nodes ; do
  if [ $host != $new_primary -a $host != $old_master ]; then
    log "change replication source to $new_primary in $host ..."
    output=`ssh -T $host "/home/postgres/change_replication_source.sh $new_primary" 2>&1`
    rc=$?
    log "$output"
    if [ $rc -ne 0 ]; then
      log "failed to change replication source to $new_primary in $host"
      exit 1
    fi
  fi
done

# trigger failover
log "trigger failover to '$new_primary' ..."
ssh -T $new_primary su - postgres -c "'$trigger_command'"
rc=$?

log "fire promote '$new_primary' to be the new primary (rc=$rc)"

exit $rc 
```

/home/postgres/change_replication_source.sh

```
#!/bin/bash

new_primary=$1

cat /etc/hosts | grep -v ' pgsql_primary$' >/tmp/hosts.tmp
echo "`resolveip -s $new_primary` pgsql_primary" >>/tmp/hosts.tmp
cp -f /tmp/hosts.tmp /etc/hosts
rm -f /tmp/hosts.tmp 
```



添加2个脚本的执行权限

```
[postgres@node1 ~]# chmod +x /home/postgres/failover.sh /home/postgres/change_replication_source.sh 
```

注:以上脚本并不十分严谨，仅供参考。

failover测试
----------

故障发生前的集群状态

```
[root@node3 ~]# psql -h192.168.0.220 -p9999 -U admin postgres
Password for user admin: 
psql (9.5.2)
Type "help" for help.

postgres=> show pool_nodes;
 node_id | hostname | port | status | lb_weight |  role   | select_cnt 
---------+----------+------+--------+-----------+---------+------------
 0       | node1    | 5433 | 2      | 0.333333  | primary | 3
 1       | node2    | 5433 | 2      | 0.333333  | standby | 0
 2       | node3    | 5433 | 2      | 0.333333  | standby | 0
(3 rows)

postgres=> select inet_server_addr();
 inet_server_addr 
------------------
 192.168.0.211
(1 row 
```

杀死主节点的postgres进程

```
[root@node1 ~]# killall -9 postgres 
```

检查集群状态，已经切换到node2

```
postgres=> show pool_nodes;
FATAL:  unable to read data from DB node 0
DETAIL:  EOF encountered with backend
server closed the connection unexpectedly
    This probably means the server terminated abnormally
    before or while processing the request.
The connection to the server was lost. Attempting reset: Succeeded.
postgres=> show pool_nodes;
 node_id | hostname | port | status | lb_weight |  role   | select_cnt 
---------+----------+------+--------+-----------+---------+------------
 0       | node1    | 5433 | 3      | 0.333333  | standby | 27
 1       | node2    | 5433 | 2      | 0.333333  | primary | 11
 2       | node3    | 5433 | 2      | 0.333333  | standby | 0
(3 rows)

postgres=> select inet_server_addr();
 inet_server_addr 
------------------
 192.168.0.212
(1 row) 
```



恢复
--

恢复node1为新主的Slave

修改pgsql\_primary的名称解析为新主的ip

```
vi /etc/hosts
...
192.168.0.212 pgsql_primary 
```

从新主上拉备份恢复

```
su - postgres
cp /data/postgresql/data/recovery.done  /tmp/
rm -rf /data/postgresql/data
pg_basebackup -hpgsql_primary -p5433 -Ureplication -D /data/postgresql/data -X stream -P
cp /tmp/recovery.done /data/postgresql/data/recovery.conf
pg_ctl -D /data/postgresql/data start
exit 
```

将node1加入集群

```
pcp_attach_node -w 0 
```

确认集群状态

```
postgres=> show pool_nodes;
 node_id | hostname | port | status | lb_weight |  role   | select_cnt 
---------+----------+------+--------+-----------+---------+------------
 0       | node1    | 5433 | 1      | 0.333333  | standby | 27
 1       | node2    | 5433 | 2      | 0.333333  | primary | 24
 2       | node3    | 5433 | 2      | 0.333333  | standby | 0
(3 rows) 
```



错误处理
----

1.  地址被占用pgpool启动失败
    
    ```
    Nov 15 02:33:56 node3 pgpool: 2016-11-15 02:33:56: pid 3868: FATAL:  failed to bind a socket: "/tmp/.s.PGSQL.9999"
    Nov 15 02:33:56 node3 pgpool: 2016-11-15 02:33:56: pid 3868: DETAIL:  bind socket failed with error: "Address already in use" 
    ```
    
    由于上次没有正常关闭导致，处理方法：
    
    ```
    rm -f /tmp/.s.PGSQL.9999 
    ```
    
2.  pgpool的master断网后，连接阻塞
    

切换pgpool的master节点(node1)的网络后，通过pgpool的连接阻塞，剩余节点的pgpool重新协商出新的Master，但阻塞继续，包括新建连接，也没有发生切换。

pgpool的日志里不断输出下面的消息

```
Nov 15 23:12:37 node3 pgpool: 2016-11-15 23:12:37: pid 4088: ERROR:  Failed to check replication time lag
Nov 15 23:12:37 node3 pgpool: 2016-11-15 23:12:37: pid 4088: DETAIL:  No persistent db connection for the node 0
Nov 15 23:12:37 node3 pgpool: 2016-11-15 23:12:37: pid 4088: HINT:  check sr_check_user and sr_check_password
Nov 15 23:12:37 node3 pgpool: 2016-11-15 23:12:37: pid 4088: CONTEXT:  while checking replication time lag
Nov 15 23:12:39 node3 pgpool: 2016-11-15 23:12:39: pid 4088: LOG:  failed to connect to PostgreSQL server on "node1:5433", getsockopt() detected error "No route to host"
Nov 15 23:12:39 node3 pgpool: 2016-11-15 23:12:39: pid 4088: ERROR:  failed to make persistent db connection
Nov 15 23:12:39 node3 pgpool: 2016-11-15 23:12:39: pid 4088: DETAIL:  connection to host:"node1:5433" failed 
```

node2和node3已经协商出新主，但连接阻塞状态一直继续，除非解禁旧master的网卡。

```
[root@node3 ~]# pcp_watchdog_info -w -v
Watchdog Cluster Information 
Total Nodes          : 3
Remote Nodes         : 2
Quorum state         : QUORUM EXIST
Alive Remote Nodes   : 2
VIP up on local node : YES
Master Node Name     : Linux_node3_9999
Master Host Name     : node3

Watchdog Node Information 
Node Name      : Linux_node3_9999
Host Name      : node3
Delegate IP    : 192.168.0.220
Pgpool port    : 9999
Watchdog port  : 9000
Node priority  : 1
Status         : 4
Status Name    : MASTER

Node Name      : Linux_node1_9999
Host Name      : node1
Delegate IP    : 192.168.0.220
Pgpool port    : 9999
Watchdog port  : 9000
Node priority  : 1
Status         : 8
Status Name    : LOST

Node Name      : Linux_node2_9999
Host Name      : node2
Delegate IP    : 192.168.0.220
Pgpool port    : 9999
Watchdog port  : 9000
Node priority  : 1
Status         : 7
Status Name    : STANDBY 
```

根据下面的堆栈，是pgpool通过watchdog将某个后端降级时，阻塞了。这应该是一个bug。

```
[root@node3 ~]# ps -ef|grep pgpool.conf
root      4048     1  0 Nov15 ?        00:00:00 /usr/bin/pgpool -f /etc/pgpool-II/pgpool.conf -n
root      5301  4832  0 00:10 pts/3    00:00:00 grep --color=auto pgpool.conf
[root@node3 ~]# pstack 4048
#0  0x00007f73647e98d3 in __select_nocancel () from /lib64/libc.so.6
#1  0x0000000000493d2e in issue_command_to_watchdog ()
#2  0x0000000000494ac3 in wd_degenerate_backend_set ()
#3  0x000000000040bcf3 in degenerate_backend_set_ex ()
#4  0x000000000040e1c4 in PgpoolMain ()
#5  0x0000000000406ec2 in main () 
```



总结
--

本次1主2从的架构中，用pgpool实施PostgreSQL的HA,效果并不理想。与pgpool和pgsql部署在一起有关，靠谱的做法是把pgpool部署在单独的节点或和应用服务器部署在一起。

1.  1主2从或1主多从架构中，primary节点切换后，其它Slave要follow新的primary，需要自己实现，这一步要做的严谨可靠并不容易。
2.  pgpool的primary出现断网错误会导致整个集群挂掉，应该是一个bug，实际部署时应尽量避免pgpool和pgsql部署在相同的节点。

参考
--

*   https://www.sraoss.co.jp/event_seminar/2016/edb_summit\_2016.pdf#search='pgpool+2016'
*   http://francs3.blog.163.com/blog/static/4057672720149285445881/
*   http://blog.163.com/digoal@126/blog/static/1638770402014413104753331/
*   https://my.oschina.net/Suregogo/blog/552765
*   https://www.itenlight.com/blog/2016/05/18/PostgreSQL+HA+with+pgpool-II+-+Part+1