# PostgreSQL 主从异步流复制配置

[TOC]

参考博客

> [PostgreSQL 主从异步流复制配置（二）](https://blog.csdn.net/yaoqiancuo3276/article/details/80205574)

pgsql安装参见 PostgreSQL 9.6编译安装

服务器地址如下：

> master :192.168.174.128 
> slave  :192.168.174.129
>

## 安装master

在 **master** 上搭建PostgeSQL 环境 基于PostgreSQL 9.6编译安装

### 修改master的pg_hba.conf

安装成功后,在**master**的客户端认证文件**pg_hba.conf** 后新增如下：

```powershell
[postgres@localhost data]$ vim pg_hba.conf
```

```
# TYPE   DATABASE   USER         ADDRESS               METHOD
host    replication repl        192.168.174.129/32          md5

```

上述表示：允许地址为129的用户repl 通过MD5密码验证从主机进行复制。

修改配置文件后，若PostgeSQL 服务在运行 则**reload**，没有运行则 **start** 使之生效：

```powershell
[postgres@localhost data]$ pg_ctl -D ../data/ reload
server signaled
```

### 修改master的postgresql.conf

在master的postgresql.conf中添加

```
wal_level = replica
max_connections = 100 #一般查多于写的应用从库的最大连接数要比较大
archive_mode = on
archive_command = 'cp %p /opt/pgsql-9.6/pgdata/9.6/archive/%f'
max_wal_senders = 10
wal_keep_segments = 256
wal_sender_timeout = 60s   

# optional parameters
hot_standby = on  #在备份的同时允许查询
superuser_reserved_connections = 10    
#shared_buffers = 32GB    
maintenance_work_mem = 2GB      
shared_preload_libraries = 'pg_stat_statements'    
#archive_command = '/bin/true'      
max_replication_slots = 10  
random_page_cost = 1.1        
effective_cache_size = 64GB 
```

## 安装slave

master配置成功后，slave 安装基本环境同 master ,**区别在于 slave 从库不需要进行 initdb 初始化数据库**

### slave复制数据

```powershell
[postgres@localhost 9.6]$ pg_basebackup -h 192.168.174.128 -U repl -W -Fp -Pv -Xs -R -D data/
Password: 
pg_basebackup: initiating base backup, waiting for checkpoint to complete
pg_basebackup: checkpoint completed
transaction log start point: 0/2000028 on timeline 1
pg_basebackup: starting background WAL receiver
30419/30419 kB (100%), 1/1 tablespace                                         
transaction log end point: 0/2000130
pg_basebackup: waiting for background process to finish streaming ...
pg_basebackup: base backup completed
```

参数说明

>-h 表示主机地址
>-W 表示需要密码
>-Fp 表示普通文件格式输出
>-Xs 表示通过流复制抓取备份日志
>-R 表示在输出目录默认创建一个recovery.conf文件
>-u 表示用户
>-D 指定数据库存放的目录

上述表示把数据从主库master同步到slave 上

### slave的recovery配置文件

#### 查看recovery

```powershell
[postgres@localhost 9.6]$ cd data/
[postgres@localhost data]$ cat recovery.conf 
standby_mode = 'on'
primary_conninfo = 'user=repl password=123456 host=192.168.174.128 port=5432 sslmode=disable sslcompression=1'
```

#### 修改recovery

```powershell
[postgres@localhost data]$ vim recovery.conf
```

修改后内容

```powershell
standby_mode = on    #说明该节点是从服务器
primary_conninfo = 'user=repl password=123456 host=192.168.174.128 port=5432 sslmode=disable sslcompression=1' #主节点的信息以及连接的用户
recovery_target_timeline = 'latest'
```

### 启动slave

```powershell
[postgres@localhost data]$ pg_ctl -D ../data/ start
server starting
[postgres@localhost data]$ FATAL:  data directory "/opt/pgsql-9.6/pgdata/9.6/data/../data" has group or world access
DETAIL:  Permissions should be u=rwx (0700).
```

解决方法：

```powershell
[postgres@localhost data]$ chmod 0700 ../data
```

再启动pgserver

```powershell
[postgres@localhost data]$ pg_ctl -D ../data/ start
server starting
[postgres@localhost data]$ LOG:  redirecting log output to logging collector process
HINT:  Future log output will appear in directory "pg_log".
```

看到日志输出以下内容说明启动成功

```
2019-08-09 14:20:39.571 CST,,,84972,,5d4d10b7.14bec,2,,2019-08-09 14:20:39 CST,,0,LOG,00000,"database system is ready to accept read only connections",,,,,,,,,""
2019-08-09 14:20:39.577 CST,,,84978,,5d4d10b7.14bf2,1,,2019-08-09 14:20:39 CST,,0,LOG,00000,"started streaming WAL from primary at 0/3000000 on timeline 1",,,,,,,,,""
```

### 配置slave的postgresql.conf 文件

```powershell
[postgres@localhost data]$ vim postgresql.conf
```

注释以下内容

```
# 注释掉以下内容
		wal_level，
		max_wal_senders 
		wal_keep_segments等参数
```

添加或保留

```
wal_level = replica
hot_standby = on #在备份的同时允许查询
max_connections = 1000 #一般查多于写的应用从库的最大连接数要比较大
max_standby_streaming_delay = 30s #数据流备份的最大延迟时间
wal_receiver_status_interval = 10s #多久向主报告一次从的状态，当然从每次数据复制都会向主报告状态，这里只是设置最长的间隔时间
```

配置完启动服务

```powershell
[postgres@localhost data]$ pg_ctl -D ../data/ restart
waiting for server to shut down.... done
server stopped
server starting
[postgres@localhost data]$ LOG:  redirecting log output to logging collector process
HINT:  Future log output will appear in directory "pg_log".
```

### 为slave添加白名单

#### 修改slave的pg_hba.conf

允许某ip上的服务通过远程访问

```shell
[postgres@localhost data]$ vim pg_hba.conf 
```

```powershell
添加下面内容
host	replication		在数据库里创建的同步用的用户名		主库IP地址或域名/32		trust或md5
# 在从库中维护的主库IP地址是为了以后切换使用
```

配置完启动服务

```powershell
[postgres@localhost data]$ pg_ctl -D ../data/ restart
```

## 查看主从是否已连接

### 方法一，数据字典表`pg_stat_replication`

在master上执行

```powershell
[postgres@localhost data]$ psql
psql (9.6.8)
Type "help" for help.

postgres=# select client_addr,sync_state from pg_stat_replication;
   client_addr   | sync_state 
-----------------+------------
 192.168.174.129 | async
(1 row)

```

说明129服务器是从节点，在接收流，而且是异步流复制

### 方法二，查看进程

在master上执行

```powershell
ps -ef | grep postgres
```

在master节点中可看到有wal sender进程

```
postgres=# \q
[postgres@localhost data]$ ps -ef | grep postgres
root      93436  93389  0 11:28 pts/1    00:00:00 su - postgres
postgres  93438  93436  0 11:28 pts/1    00:00:00 -bash
postgres 100743      1  0 13:20 pts/1    00:00:00 /opt/pgsql-9.6/bin/postgres -D ../data
postgres 100744 100743  0 13:20 ?        00:00:00 postgres: logger process   
postgres 100746 100743  0 13:20 ?        00:00:00 postgres: checkpointer process   
postgres 100747 100743  0 13:20 ?        00:00:00 postgres: writer process   
postgres 100748 100743  0 13:20 ?        00:00:00 postgres: wal writer process   
postgres 100749 100743  0 13:20 ?        00:00:00 postgres: autovacuum launcher process  
postgres 100750 100743  0 13:20 ?        00:00:00 postgres: archiver process   last was 000000010000000000000002.00000028.backup
postgres 100751 100743  0 13:20 ?        00:00:00 postgres: stats collector process   
postgres 105998 100743  0 14:38 ?        00:00:00 postgres: wal sender process repl 192.168.174.129(41466) streaming 0/3000F40
postgres 106587  93438  0 14:47 pts/1    00:00:00 ps -ef
postgres 106588  93438  0 14:47 pts/1    00:00:00 grep --color=auto postgres
```

在slave上执行

```powershell
ps -ef | grep postgres
```

在slave节点中可看到有wal receiver进程

```powershell
[postgres@localhost data]$ ps -ef | grep postgres
root      33155  20057  0 13:07 pts/0    00:00:00 su - postgres
postgres  33156  33155  0 13:07 pts/0    00:00:00 -bash
postgres  85367      1  0 14:38 pts/0    00:00:00 /opt/pgsql-9.6/bin/postgres -D ../data
postgres  85368  85367  0 14:38 ?        00:00:00 postgres: logger process   
postgres  85369  85367  0 14:38 ?        00:00:00 postgres: startup process   recovering 000000010000000000000003
postgres  85370  85367  0 14:38 ?        00:00:00 postgres: checkpointer process   
postgres  85371  85367  0 14:38 ?        00:00:00 postgres: writer process   
postgres  85372  85367  0 14:38 ?        00:00:00 postgres: stats collector process   
postgres  85373  85367  0 14:38 ?        00:00:00 postgres: wal receiver process   streaming 0/3000F40
postgres  85554  33156  0 14:49 pts/0    00:00:00 ps -ef
postgres  85555  33156  0 14:49 pts/0    00:00:00 grep --color=auto postgres
```

### 方法三，数据同步

在master上执行

```powershell
[postgres@localhost data]$ psql -p 5432 -U postgres ha
psql (9.6.8)
Type "help" for help.

ha=# \x
Expanded display is on. 
ha=# select * from pg_stat_replication;
-[ RECORD 1 ]----+------------------------------
pid              | 105998
usesysid         | 16385
usename          | repl
application_name | walreceiver
client_addr      | 192.168.174.129
client_hostname  | 
client_port      | 41466
backend_start    | 2019-08-09 14:38:57.301488+08
backend_xmin     | 
state            | streaming
sent_location    | 0/3001020
write_location   | 0/3001020
flush_location   | 0/3001020
replay_location  | 0/3001020
sync_priority    | 0
sync_state       | async
```

主服务器上插入数据或删除数据，在从服务器上能看到相应的变化。从服务器上只能查询，不能插入或删除。

在master上创建一个数据库和临时表

```shell
[postgres@localhost data]$ psql
psql (9.6.8)
Type "help" for help.

postgres=# create database test;
CREATE DATABASE
postgres=# \c test
You are now connected to database "test" as user "postgres".
test=# create table apple(id serial not null, name text);                             
CREATE TABLE
test=# insert into apple(name) values('fushihong');
INSERT 0 1
```

在slave从机上查询刚才创建的表和数据，判定是否有数据同步

```shell
[postgres@localhost data]$ psql
psql (9.6.8)
Type "help" for help.

postgres=# \l
                                  List of databases
   Name    |  Owner   | Encoding |   Collate   |    Ctype    |   Access privileg
es   
-----------+----------+----------+-------------+-------------+------------------
-----
 ha        | postgres | UTF8     | zh_CN.UTF-8 | zh_CN.UTF-8 | 
 postgres  | postgres | UTF8     | zh_CN.UTF-8 | zh_CN.UTF-8 | 
 template0 | postgres | UTF8     | zh_CN.UTF-8 | zh_CN.UTF-8 | =c/postgres      
    +
           |          |          |             |             | postgres=CTc/post
gres
 template1 | postgres | UTF8     | zh_CN.UTF-8 | zh_CN.UTF-8 | =c/postgres      
    +
           |          |          |             |             | postgres=CTc/post
gres
 test      | postgres | UTF8     | zh_CN.UTF-8 | zh_CN.UTF-8 | 
(5 rows)

postgres=# \c test	
You are now connected to database "test" as user "postgres".
test=# select * from apple;
 id |   name    
----+-----------
  1 | fushihong
(1 row
```

### 方法四，自带函数 `pg_is_in_recovery()`

```shell
# 主机显示 f(false)
postgres=# select pg_is_in_recovery();
 pg_is_in_recovery 
-------------------
 f
(1 row)

# 备机显示 t(true)
postgres=# select pg_is_in_recovery();
 pg_is_in_recovery 
-------------------
 t
(1 row)
```

### 方法五，通过`pg_controldata`

```shell
# 主机
[postgres@localhost ~]$ pg_controldata
...
Database cluster state:               in production
...


# 备机
[postgres@localhost pg_log]$ pg_controldata
...
Database cluster state:               in archive recovery
...
```

## 模拟主机宕机，备机切换到主机

### 基础版—通过配置`recovery.conf`文件实现

recovey.conf文件中再添加一行

```
trigger_file = '/database/pgdata/trigger_files'   # --新的触发文件，名称任取
```

该方式不是很好，以文件的形式实现HA时会遇到不能来回切换的问题。

#### 1、主机宕机

```shell
[postgres@localhost ]$pg_stop
```

主机停机前备机的进程 

```shell
[postgres@localhost pg_log]$ ps -ef|grep postgres
root      2215  2197  0 00:35 pts/0    00:00:00 su - postgres
postgres  2217  2215  0 00:35 pts/0    00:00:00 -bash
postgres  5224     1  0 05:22 pts/0    00:00:02 /home/postgres/bin/postgres -D /database/pgdata
postgres  5226  5224  0 05:22 ?        00:00:00 postgres: logger process                      
postgres  5227  5224  0 05:22 ?        00:00:00 postgres: startup process   recovering 00000001000000000000003B
postgres  5228  5224  0 05:22 ?        00:00:06 postgres: wal receiver process   streaming 0/ED610000
postgres  5231  5224  0 05:22 ?        00:00:01 postgres: writer process                      
postgres  5232  5224  0 05:22 ?        00:00:00 postgres: stats collector process             
postgres  5902  2217  0 19:05 pts/0    00:00:00 ps -ef
postgres  5903  2217  0 19:05 pts/0    00:00:00 grep postgres
```

主机停机后备机的进程 

```shell
[postgres@localhost pg_log]$ ps -ef|grep postgres
root      2215  2197  0 00:35 pts/0    00:00:00 su - postgres
postgres  2217  2215  0 00:35 pts/0    00:00:00 -bash
postgres  5224     1  0 05:22 pts/0    00:00:02 /home/postgres/bin/postgres -D /database/pgdata
postgres  5226  5224  0 05:22 ?        00:00:00 postgres: logger process                      
postgres  5227  5224  0 05:22 ?        00:00:00 postgres: startup process   waiting for 00000001000000000000003C
postgres  5231  5224  0 05:22 ?        00:00:01 postgres: writer process                      
postgres  5232  5224  0 05:22 ?        00:00:00 postgres: stats collector process             
postgres  5904  2217  0 19:05 pts/0    00:00:00 ps -ef
postgres  5905  2217  0 19:05 pts/0    00:00:00 grep postgres
```

可以发现原先的streaming进程(pid=5228)没了。 同时，备机中的日志，出现大量的错误信息 

```shell
2019-08-03 19:09:07.064 PST,,,5948,,50d918d3.173c,1,,2019-08-03 19:09:07 PST,,0,FATAL,XX000,"could not connect to the primary server: could not connect to server: Connection refused
        Is the server running on host ""192.168.174.128"" and accepting
        TCP/IP connections on port 5432?
",,,,,,,,,""
2019-08-03 19:09:12.069 PST,,,5949,,50d918d8.173d,1,,2019-08-03 19:09:12 PST,,0,FATAL,XX000,"could not connect to the primary server: could not connect to server: Connection refused
        Is the server running on host ""192.168.74.128"" and accepting
        TCP/IP connections on port 5432?
",,,,,,,,,""
```

显示的错误信息很明显，primary 服务器连不上了。 此时查看备机的pg_controldata状态信息，仍是备机状态

```shell
[postgres@localhost ]$ pg_controldata
...
Database cluster state:               in archive recovery
...
```

#### 2.备机切换成主机 

需要在之前备机上的recovery.conf中配置 trigger_file = '/database/pgdata/trigger_files' 要切换备机成主机，只要创建一个触发文件trigger_files即可，这个名字可以随便写。 此时查看备机上的日志,可以看到成功切换到主机了。

```shell
[postgres@localhost ]$ touch /database/pgdata/trigger_files
```

此时查看备机上的日志,可以看到成功切换到主机了

```shell
[postgres@localhost ]$tail -f postgresql-2012-08-03_190930.csv 
2019-08-03 19:09:37.100 PST,,,5954,,50d918f1.1742,1,,2012-08-03 19:09:37 PST,,0,FATAL,XX000,"could not connect to the primary server: could not connect to server: Connection refused
        Is the server running on host ""192.168.174.128"" and accepting
        TCP/IP connections on port 5432?
",,,,,,,,,""
2019-08-03 19:09:42.093 PST,,,5227,,50d85726.146b,6,,2019-08-03 05:22:46 PST,1/0,0,LOG,00000,"trigger file found: /database/pgdata/trigger.kenyon",,,,,,,,,""
2012-08-03 19:09:42.097 PST,,,5227,,50d85726.146b,7,,2019-08-03 05:22:46 PST,1/0,0,LOG,00000,"redo done at 0/F0000020",,,,,,,,,""
2019-08-03 19:09:42.104 PST,,,5227,,50d85726.146b,8,,2019-08-03 05:22:46 PST,1/0,0,LOG,00000,"last completed transaction was at log time 2012-08-03 05:29:38.526602-08",,,,,,,,,""
2019-08-03 19:09:42.112 PST,,,5227,,50d85726.146b,9,,2019-08-03 05:22:46 PST,1/0,0,LOG,00000,"selected new timeline ID: 2",,,,,,,,,""
2019-08-03 19:10:04.403 PST,,,5227,,50d85726.146b,10,,2019-08-03 05:22:46 PST,1/0,0,LOG,00000,"archive recovery complete",,,,,,,,,""
2019-08-03 19:10:04.705 PST,,,5224,,50d8571c.1468,2,,2019-08-03 05:22:36 PST,,0,LOG,00000,"database system is ready to accept connections",,,,,,,,,""
2019-08-03 19:10:04.710 PST,,,5964,,50d9190c.174c,1,,2019-08-03 19:10:04 PST,,0,LOG,00000,"autovacuum launcher started",,,,,,,,,""
```

日志里可以体现出来原来的备机已经切换为主机了。 
再去看现在这台机子的pg_controldata的信息，再次确认一下：

```shell
[postgres@localhost pg_log]$ pg_controldata
...
Database cluster state:               in production
...
```

已经变成production了，对，备机切主机就这么简单。 
还有一处明显的变化是现在的主机(137)上的recovery.conf文件名字变成了recovery.done。备机切换为主机后，就可以正常连接使用了。此时就有时间去处理原master端问题了。

#### 3.宕机的主机切换成备机

- 先在现在的主机(129)上做一些数据的增删改 

- 在现在的备机(128)上准备恢复文件，拷贝recovery.conf文件，并修改 

```shell
[postgres@localhost ~]$ cp $PGHOME/share/recovery.conf.sample $PGDATA/recovery.conf
[postgres@localhost ~]$ vi $PGDATA/recovery.conf

recovery_target_timeline = 'latest'
primary_conninfo = 'host=192.168.174.129 port=5432 user=repuser password=repuser'--指定129为新的主机
trigger_file = '/database/pgdata/trigger.kenyon'   --新的触发文件
standby_mode = on                                  --标记为备机

同时修改postgresql.conf文件
[postgres@localhost ~]$ vi $PGDATA/postgresql.conf
hot_standby = on
```

配置好了后，我们启动128这台模拟宕掉的原主机，并使之与129连接，并做他的备机。

若出现连接的问题可在129服务器的pg_hba.conf文件中添加可信ip，md5验证

- 有可能出现时间线不一致问题

参考https://my.oschina.net/Kenyon/blog/98217其中的相关内容。

### 基于keepalived的postgreSQL HA切换

参见独立文档 

### 基于pgpool-II的postgresSQL HA切换

参见独立文档