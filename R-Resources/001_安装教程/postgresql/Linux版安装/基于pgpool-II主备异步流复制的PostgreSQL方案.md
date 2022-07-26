# PostgreSQL的 基于 pgpool-II 主备异步流复制的方案

> 作        者：胡凯
>
> 开始时间：2019-08-9
>
> 完成时间：2019-08-16
>
> ==可参考流程，具体配置参考 [精简安装 pgSQL 和 PgPool 主从异步流复制](精简安装 pgSQL 和 PgPool 主从异步流复制.md)== 

[TOC]

参考博客

> 主要参照
>
> [搭建 基于pgpool-Ⅱ 的postgreSQL 主备异步流复制高可用方案](https://blog.csdn.net/yaoqiancuo3276/article/details/80805783)
>
> 备用
>
> [PGPool-II+PG流复制实现HA主备切换](https://www.jianshu.com/p/ef183d0a9213)
>
> [PostgreSQL+pgpool-II复制方案](https://blog.csdn.net/ygqygq2/article/details/60393006)
>
> [通过pgpool-II实现PostgreSQL数据库服务高可用](https://www.cnblogs.com/aegis1019/p/9005478.html)



## 准备

### 机器分配

> master：192.168.174.128
>
> slave：192.168.174.129
>
> VIP：
>
> pgpool-II master：192.168.174.128
>
> pgpool-II slave：192.168.174.129

### 主备异步流复制

参见 PostgreSQL 主从异步流复制配置（本地文件）

### pgpool_II简介

> PgPool-Ⅱ 是一个位于PostgreSQL 服务器和客户端的中间件，可以提供以下功能：
> 连接池、复制、负载均衡、限制超过限度的连接、并行查询等pgpool-Ⅱ 的后端数据库支持不同小版本PG数据库，不支持大版本pgpool-Ⅱ 负载均衡是基于会话级别的，不是语句级别的(即一个session开始到结束都是在同一个节点)

**在master、slave上安装pgpool-II**

## pgpool-II源码准备

#### 下载地址

下载 `pgpool-Ⅱ`，最好于PostgreSQL版本对应,此处为
[pgpool-Ⅱ下载地址:] http://www.pgpool.net/mediawiki/images/pgpool-II-3.7.3.tar.gz

#### 准备文件夹

##### 源码存放位置

```shell
[hk@localhost ~]$ su root
密码：
[root@localhost postgres]# su - postgres 
上一次登录：五 8月  9 11:26:09 CST 2019pts/1 上
[postgres@localhost ~]$ mkdir -p ha/pgpool
[postgres@localhost ~]$ ls -al
总用量 20
drwx------. 6 postgres postgres  154 8月   9 16:03 .
drwxr-xr-x. 4 root     root       32 8月   8 20:45 ..
-rw-------. 1 postgres postgres  990 8月   9 15:37 .bash_history
-rw-r--r--. 1 postgres postgres   18 10月 31 2018 .bash_logout
-rw-r--r--. 1 postgres postgres  193 10月 31 2018 .bash_profile
-rw-r--r--. 1 postgres postgres  231 10月 31 2018 .bashrc
drwxrwxr-x. 3 postgres postgres   18 8月   8 21:22 .cache
drwxrwxr-x. 3 postgres postgres   18 8月   8 21:22 .config
drwxrwxr-x. 3 postgres postgres   20 8月   9 16:03 ha
drwxr-xr-x. 4 postgres postgres   39 8月   8 18:09 .mozilla
-rw-------. 1 postgres postgres 2333 8月   9 09:54 .viminfo
```

##### 下载pgpool-II

```shell
[postgres@localhost ~]$ cd ha/pgpool/
[postgres@localhost pgpool]$ wget http://www.pgpool.net/mediawiki/images/pgpool-II-3.7.3.tar.gz
```

## master上安装pgpool-II

### 解压pgpool-II

```shell
[postgres@localhost pgpool]$ ls
pgpool-II-3.7.3.tar.gz
[postgres@localhost pgpool]$ tar xf pgpool-II-3.7.3.tar.gz 
[postgres@localhost pgpool]$ cd pgpool-II-3.7.3/
```

### configure 检查

编译检查到指定目录 `/opt/pgpool-3`

```shell
[postgres@localhost pgpool-II-3.7.3]$ ./configure --prefix=/opt/pgpool-3
checking for gcc... gcc
checking whether the C compiler works... yes
checking for C compiler default output file name... a.out
checking for suffix of executables... 
checking whether we are cross compiling... no

...
config.status: creating src/watchdog/Makefile
config.status: creating src/include/config.h
config.status: src/include/config.h is unchanged
config.status: executing libtool commands
```

看到如上信息表示编译检查完成

### make 编译

```shell
[postgres@localhost pgpool-II-3.7.3]$ make 
Making all in src
make[1]: 进入目录“/home/postgres/ha/pgpool/pgpool-II-3.7.3/src”
Making all in parser
...
make[1]: 离开目录“/home/postgres/ha/pgpool/pgpool-II-3.7.3/src”
make[1]: 进入目录“/home/postgres/ha/pgpool/pgpool-II-3.7.3”
make[1]: 对“all-am”无需做任何事。
make[1]: 离开目录“/home/postgres/ha/pgpool/pgpool-II-3.7.3”
```

### make install 安装

```shell
[postgres@localhost pgpool-II-3.7.3]$ make install
Making install in src
make[1]: 进入目录“/home/postgres/ha/pgpool/pgpool-II-3.7.3/src”
Making install in parser
...
make[2]: 对“install-data-am”无需做任何事。
make[2]: 离开目录“/home/postgres/ha/pgpool/pgpool-II-3.7.3”
make[1]: 离开目录“/home/postgres/ha/pgpool/pgpool-II-3.7.3”
```

到指定编译的目录查看

```shell
[postgres@localhost pgpool-II-3.7.3]$ cd /opt/pgpool-3/
[postgres@localhost pgpool-3]$ ls
bin  etc  include  lib  share
```

看到如上目录表示安装成功

### 配置环境变量

 配置环境变量 (方便使用命令),添加如下信息

```shell
[postgres@localhost pgpool-3]$ su
密码：
[root@localhost pgpool-3]# vim /etc/profile
```

添加

```
export PATH=/opt/pgpool-3/bin:$PATH
```

```shell
[root@localhost pgpool-3]# source /etc/profile
```

## master上安装扩展函数

**使用 `root` 权限的账户安装，否则 VIP 无法自动切换**

### `master` 上安装 `pgpool_regclass`

PG8.0之后的内部使用

```shell
[root@localhost pgpool-3]# cd /home/postgres/ha/pgpool/pgpool-II-3.7.3/src/sql/
[root@localhost sql]# ls
insert_lock.sql  Makefile  pgpool_adm  pgpool-recovery  pgpool-regclass
[root@localhost sql]# make
make -C pgpool-recovery all
make[1]: 进入目录“/home/postgres/ha/pgpool/pgpool-II-3.7.3/src/sql/pgpool-recovery”
...
make[1]: 离开目录“/home/postgres/ha/pgpool/pgpool-II-3.7.3/src/sql/pgpool_adm”
```

```shell
[root@localhost sql]# make install
make -C pgpool-recovery all
make[1]: 进入目录“/home/postgres/ha/pgpool/pgpool-II-3.7.3/src/sql/pgpool-recovery”
make[1]: 对“all”无需做任何事。
...
/usr/bin/install -c -m 644 .//pgpool_adm--1.0.sql  '/opt/pgsql-9.6/share/extension/'
make[1]: 离开目录“/home/postgres/ha/pgpool/pgpool-II-3.7.3/src/sql/pgpool_adm”
```

切换到postgres

```shell
[root@localhost sql]# su - postgres 
上一次登录：五 8月  9 16:02:50 CST 2019pts/0 上
[postgres@localhost ~]$ cd /home/postgres/ha/pgpool/pgpool-II-3.7.3/src/sql/pgpool-regclass/
[postgres@localhost pgpool-regclass]$ ls
Makefile                  pgpool_regclass.control  pgpool-regclass.sql
pgpool_regclass--1.0.sql  pgpool-regclass.o        pgpool-regclass.sql.in
pgpool-regclass.c         pgpool-regclass.so       uninstall_pgpool-regclass.sql
```

安装扩展

```shell
[postgres@localhost pgpool-regclass]$ psql -p 5432 -f pgpool-regclass.sql template1
psql: could not connect to server: 没有那个文件或目录
	Is the server running locally and accepting
	connections on Unix domain socket "/tmp/.s.PGSQL.5432"?
```

报错，pgsql服务未打开

在`postgres`用户下手动打开pgsql服务

```shell
[postgres@localhost ~]$ pg_ctl -D /opt/pgsql-9.6/pgdata/9.6/data/ start
server starting
[postgres@localhost ~]$ LOG:  redirecting log output to logging collector process
HINT:  Future log output will appear in directory "pg_log".
```

再安装

```shell
[postgres@localhost pgpool-regclass]$ psql -p 5432 -f pgpool-regclass.sql template1
CREATE FUNCTION
```

### `master` 上建立 `insert_lock` 表

```shell
[postgres@localhost pgpool-regclass]$ cd ..
[postgres@localhost sql]$ ls
insert_lock.sql  Makefile  pgpool_adm  pgpool-recovery  pgpool-regclass
[postgres@localhost sql]$ psql -p 5432 -f insert_lock.sql template1
psql:insert_lock.sql:3: ERROR:  schema "pgpool_catalog" does not exist
CREATE SCHEMA
CREATE TABLE
INSERT 0 1
GRANT
GRANT
GRANT
GRANT
[postgres@localhost sql]$
```

### `master` 上安装 C 语言函数

```shell
[postgres@localhost sql]$ cd pgpool-recovery/
[postgres@localhost pgpool-recovery]$ ls
Makefile                  pgpool_recovery.control  pgpool-recovery.sql
pgpool_recovery--1.1.sql  pgpool-recovery.o        pgpool-recovery.sql.in
pgpool-recovery.c         pgpool-recovery.so       uninstall_pgpool-recovery.sql
[postgres@localhost pgpool-recovery]$ make install
/usr/bin/mkdir -p '/opt/pgsql-9.6/share/extension'
/usr/bin/mkdir -p '/opt/pgsql-9.6/share/extension'
/usr/bin/mkdir -p '/opt/pgsql-9.6/lib'
/usr/bin/install -c -m 644 .//pgpool_recovery.control '/opt/pgsql-9.6/share/extension/'
/usr/bin/install: 无法删除"/opt/pgsql-9.6/share/extension/pgpool_recovery.control": 权限不够
make: *** [install] 错误 1
```

错误，权限不够

```shell
[postgres@localhost pgpool-recovery]$ su
密码：
[root@localhost pgpool-recovery]# make install
/usr/bin/mkdir -p '/opt/pgsql-9.6/share/extension'
/usr/bin/mkdir -p '/opt/pgsql-9.6/share/extension'
/usr/bin/mkdir -p '/opt/pgsql-9.6/lib'
/usr/bin/install -c -m 644 .//pgpool_recovery.control '/opt/pgsql-9.6/share/extension/'
/usr/bin/install -c -m 644 .//pgpool_recovery--1.1.sql pgpool-recovery.sql '/opt/pgsql-9.6/share/extension/'
/usr/bin/install -c -m 755  pgpool-recovery.so '/opt/pgsql-9.6/lib/'
```

切换到`postgres`用户安装扩展函数

```shell
[root@localhost pgpool-recovery]# exit
[postgres@localhost pgpool-recovery]$ ls
Makefile                  pgpool_recovery.control  pgpool-recovery.sql
pgpool_recovery--1.1.sql  pgpool-recovery.o        pgpool-recovery.sql.in
pgpool-recovery.c         pgpool-recovery.so       uninstall_pgpool-recovery.sql
[postgres@localhost pgpool-recovery]$ psql -p 5432 -f pgpool-recovery.s
pgpool-recovery.so      pgpool-recovery.sql     pgpool-recovery.sql.in  
[postgres@localhost pgpool-recovery]$ psql -p 5432 -f pgpool-recovery.sql template1
CREATE FUNCTION
CREATE FUNCTION
CREATE FUNCTION
CREATE FUNCTION
[postgres@localhost pgpool-recovery]$ 
```

### `master` PostgreSQL 中创建扩展

```shell
[postgres@localhost pgpool-recovery]$ psql
psql (9.6.8)
Type "help" for help.

postgres=# create extension pgpool_regclass;
CREATE EXTENSION
postgres=# create extension pgpool_recovery;
CREATE EXTENSION
postgres=# \df
                                                              List of functions
 Schema |        Name         | Result data type |                               Argument data types    
                            |  Type  
--------+---------------------+------------------+------------------------------------------------------
----------------------------+--------
 public | pgpool_pgctl        | boolean          | action text, stop_mode text                          
                            | normal
 public | pgpool_recovery     | boolean          | script_name text, remote_host text, remote_data_direc
tory text                   | normal
 public | pgpool_recovery     | boolean          | script_name text, remote_host text, remote_data_direc
tory text, remote_port text | normal
 public | pgpool_remote_start | boolean          | remote_host text, remote_data_directory text         
                            | normal
 public | pgpool_switch_xlog  | text             | arcive_dir text                                      
                            | normal
(5 rows)
```

注：上述扩展函数和插件在主库执行，因为PG数据库配置的为 `主备流复制` ，所以备库也会自动安装该扩展和函数

## master上修改pgpool-II 配置文件

详情参见 pgpool-II的参数配置说明.md

### master的pgpool.conf文件

- `复制`默认 `pgpool 配置模板` 文件

```shell
[root@localhost hk]# cd /opt/pgpool-3/etc/
[root@localhost etc]# ls
pcp.conf.sample                  pgpool.conf.sample-replication
pgpool.conf.sample               pgpool.conf.sample-stream
pgpool.conf.sample-logical       pool_hba.conf.sample
pgpool.conf.sample-master-slave
[root@localhost etc]# su - postgres
[postgres@localhost etc]# cp pgpool.conf.sample pgpool.conf
[postgres@localhost etc]# cp pcp.conf.sample pcp.conf
```

- 配置 `pgpool.conf` 文件,该文件为pgpool-Ⅱ 的主要配置文件，用于配置具体参数

```shell
[root@localhost etc]# vim pgpool.conf
```

```
##########################################################
#                    customer added                      #
##########################################################
listen_addresses = '*'  # rtm  用于pgpool监听地址，控制哪些地址可以通过pgpool 连接,`*`表示接受所有连接
port = 9999    # rtm   pgpool 监听的端口
pcp_listen_addresses = '*' # rtm
pcp_port = 9898         # rtm

# host0,master
backend_hostname0 = '192.168.174.128' # rtm  配置后端postgreSQL 数据库地址，此处为 master 
backend_port0 = 5432              # rtm 后端postgreSQL 数据库端口
backend_weight0 = 1               # rtm 权重，用于负载均衡
backend_data_directory0 = '/opt/pgsql-9.6/pgdata/9.6/data' # rtm 后端postgreSQL 数据库实例目录
backend_flag0 = 'ALLOW_TO_FAILOVER'   # rtm  允许故障自动切换

# host1,slave
backend_hostname1 = '192.168.174.129'      # rtm 此处为 PostgreSQL slave数据库地址 
backend_port1 = 5432                    # rtm 
backend_weight1 = 1                     # rtm
backend_data_directory1 = '/opt/pgsql-9.6/pgdata/9.6/data'        # rtm
backend_flag1 = 'ALLOW_TO_FAILOVER'     # rtm

enable_pool_hba = on            # rtm  开启pgpool认证，需要通过 `pool_passwd` 文件对连接到数据库的用户进行md5认证
pool_passwd = 'pool_passwd'     # rtm 认证文件

# log set
log_destination = 'stderr'  # rtm  日志级别，标注错误输出和系统日志级别
log_line_prefix = '%t: pid %p: '    # rtm  日志输出格式
log_connections = on               # rtm  开启日志
log_hostname = on                  # rtm  打印主机名称
log_statement = all             # rtm    取消注释则打印sql 语句
log_per_node_statement = on     # rtm    取消注释则开启打印sql负载均衡日志，记录sql负载到每个节点的执行情况
client_min_messages = log  # rtm          日志
log_min_messages = info   # rtm            # 日志级别
pid_file_name = '/opt/pgpool-3/run/pgpool/pgpool.pid'   # rtm pgpool的运行目录，若不存在则先创建
logdir = '/opt/pgpool-3/log/pgpool'  # rtm  指定日志输出的目录
replication_mode = off           # rtm   关闭pgpool的复制模式
load_balance_mode = on             # rtm  开启负载均衡
master_slave_mode = on           # rtm   开启主从模式
master_slave_sub_mode = 'stream'         # rtm  设置主从为流复制模式

# src check
sr_check_period = 10             # rtm    流复制的延迟检测的时间间隔
sr_check_user = 'postgres'        # rtm    流复制的检查用户，该用户需要在pg数据库中存在，且拥有查询权限
sr_check_password = 'pg1235'       # rtm   
sr_check_database = 'postgres'           # rtm  流复制检查的数据库名称
delay_threshold = 10000000             # rtm  设置允许主备流复制最大延迟字节数,单位为kb

# health check
health_check_period = 10          # rtm  pg数据库检查检查间隔时间
health_check_timeout = 20        # rtm 
health_check_user = 'postgres'           # rtm   健康检查用户，需pg数据库中存在
health_check_password = 'pg1235'        # rtm   
health_check_database = 'postgres'      # rtm   健康检查的数据库名称
health_check_max_retries = 3            # rtm   健康检查最大重试次数
health_check_retry_delay = 3            # rtm  重试次数间隔

failover_command = '/opt/pgpool-3/script/failover.sh %H'           # rtm  故障切换脚本
fail_over_on_backend_error = off  # rtm    如果设置了health_check_max_retries次数，则关闭该参数

# watch dog
use_watchdog = on                   # rtm  开启看门狗，用于监控pgpool 集群健康状态
wd_hostname = '192.168.174.128'             # rtm  本地看门狗地址
wd_port = 9000                          # rtm 
wd_priority = 1                         # rtm  看门狗优先级，用于pgpool 集群中master选举
delegate_IP = '192.168.174.159'             # rtm   VIP 地址
if_up_cmd = 'ip addr add $_IP_$/24 dev ens33'  # rtm 配置虚拟IP到本地网卡
if_down_cmd = 'ip addr del $_IP_$/24 dev ens33'          # rtm  
# wd_lifecheck_method = 'heartbeat'       # rtm  看门狗健康检测方法
wd_heartbeat_port = 9694                # rtm    看门狗心跳端口，用于pgpool 集群健康状态通信
wd_heartbeat_keepalive = 2              # rtm    看门狗心跳检测间隔
wd_heartbeat_deadtime = 30              # rtm
heartbeat_destination0 = '192.168.174.129'  # rtm    配置需要监测健康心跳的IP地址，非本地地址，即互相监控，配置对端的IP地址
heartbeat_destination_port0 = 9694      # rtm 监听的端口
heartbeat_device0 = 'ens33'              # rtm 监听的网卡名称
wd_life_point = 3               # rtm   生命检测失败后重试次数
wd_lifecheck_query = 'SELECT 1' # rtm  用于检查 pgpool-II 的查询语句。默认为“SELECT 1”。#wd_lifecheck_dbname = 'postgres'        # rtm 检查健康状态的数据库名称
wd_lifecheck_user = 'postgres'           # rtm 检查数据库的用户，该用户需要在Postgres数据库存在，且有查询权限
wd_lifecheck_password = 'pg1235'        # rtm  看门狗健康检查用户密码
other_pgpool_hostname0 = '192.168.174.129'  # rtm 指定被监控的 pgpool-II 服务器的主机名
other_pgpool_port0 = 9999       # rtm 指定被监控的 pgpool-II 服务器的端口号
other_wd_port0 = 9000           # rtm 指定 pgpool-II 服务器上的需要被监控的看门狗的端口号
```

- 创建pgpool 的 `pid` 目录,为pgpool的启动进程文件目录

```shell
[postgres@localhost etc]# mkdir -p /opt/pgpool-3/run/pgpool/
```

### master的pcp.conf文件

- 配置 `pcp.conf`文件，通过 `pg_md5` 工具可生成对应的 md5密码

```shell
[postgres@localhost etc]# pg_md5 pg1235
39ec09490128f32fdc1a9b8091c99a57
[postgres@localhost etc]# vim pcp.conf

# 添加内容
postgres:39ec09490128f32fdc1a9b8091c99a57

# 查看内容
[postgres@localhost etc]# tail -2 pcp.conf
# USERID:MD5PASSWD
postgres:39ec09490128f32fdc1a9b8091c99a57
```

### master的pool_passwd文件

- 配置 `pool_passwd` 文件，用户：`postgres` 密码：`pg1235`

```shell
[postgres@localhost etc]# pg_md5 -m -p -u postgres pool_passwd
password: 
[postgres@localhost etc]# cat pool_passwd 
postgres:md5a3556571e93b0d20722ba62be61e8c2d
```

此文件默认不存在，可通过 `pg_md5` 自动生成该文件,该文件存放用户名和MD5密码，该文件用户控制认证哪些用户可以通过密码验证访问pgpool-Ⅱ。 

注意：上述 `pcp.conf` 和 `pool_passwd` 文件中用户名和密码直接不能包含空格，默认会把空格当成字符。

以上方式使用明文密码，不安全，也可通过以下方式来获取MD5密码

```shell
postgres=#  SELECT rolpassword FROM pg_authid WHERE rolname='postgres';
             rolpassword
-------------------------------------
 md5a3556571e93b0d20722ba62be61e8c2d
(1 row)

postgres=#
```

之后将 `psotgres` 用户名，和密码：`md5a3556571e93b0d20722ba62be61e8c2d` 写入 `pool_passwd` 文件，并且用 `冒号` 相隔，且中间 `不能包含空格`

### master的failover.sh文件

- 创建failover.sh

```shell
[postgres@localhost pgpool-3]# mkdir script
[postgres@localhost pgpool-3]# cd script
[postgres@localhost script]# vim failover.sh # 添加下文
```

- failover.sh内容

```shell
!#/usr/bash

export PGPORT=5432
export PGUSER=postgres
export PGDBNAME=postgres
export PGPATH=/opt/pgsql-9.6/bin
export PATH=$PATH:$PGPATH
# export NEW_MASTER=$1
export PGDATA=/opt/pgsql-9.6/pgdata/9.6/data
# log=/opt/pgpool-3/script/log/failover.log
set PGPASSWORD=pg1235
# 主备数据库同步时延，单位为秒

SQL1='select pg_is_in_recovery  from pg_is_in_recovery();'

db_role=`echo $SQL1 | psql -At -p $PGPORT -U $PGUSER -d $PGDBNAME`


SWITCH_COMMAND='pg_ctl promote -D /opt/pgsql-9.6/pgdata/9.6/data'

# "t" means standby
# "f" means primary
# 如果为主库，则不切换
if [ $db_role == t ]; then
        echo -e `date +"%F %T"` "Attention:The current database is statndby,ready to switch master database!" >> $log
        # su - $PG_OS_USER -c "$SWITCH_COMMAND"
        $SWITCH_COMMAND
        echo -e `date +"%F %T"` "success:The current standby database successed to switched the primary PG database !" >> $log
        exit 0
fi
```

- 并分配755权限

```shell
[postgres@localhost script]# chmod 755 failover.sh # 如果没有权限，则切换至root
```

- 需要创建failover.log文件的保存目录

```shell
[postgres@localhost etc] # mkdir -p /opt/pgpool-3/script/log
```



## slave上修改pgpool-II配置文件

上述扩展函数和插件在主库执行，因为PG数据库配置的为 `主备流复制` ，所以备库也会自动安装该扩展和函数

### slave的pgpool.conf文件

- `复制`默认 `pgpool 配置模板` 文件

```shell
[root@localhost hk]# cd /opt/pgpool-3/etc/
[root@localhost etc]# ls
pcp.conf.sample                  pgpool.conf.sample-replication
pgpool.conf.sample               pgpool.conf.sample-stream
pgpool.conf.sample-logical       pool_hba.conf.sample
pgpool.conf.sample-master-slave
[root@localhost etc]# su - postgres
[postgres@localhost etc]# cp pgpool.conf.sample pgpool.conf
[postgres@localhost etc]# cp pcp.conf.sample pcp.conf
```

- 配置 `pgpool.conf` 文件,该文件为pgpool-Ⅱ 的主要配置文件，用于配置具体参数

```shell
[root@localhost etc]# vim pgpool.conf
```

```
##########################################################
#                    customer modified                   #
##########################################################

listen_addresses = '*'  # rtm  用于pgpool监听地址，控制哪些地址可以通过pgpool 连接,`*`表示接受所有连接
port = 9999    # rtm   pgpool 监听的端口
pcp_listen_addresses = '*' # rtm
pcp_port = 9898         # rtm

# host0,master
backend_hostname0 = '192.168.174.128' # rtm  配置后端postgreSQL 数据库地址，此处为 master 
backend_port0 = 5432              # rtm 后端postgreSQL 数据库端口
backend_weight0 = 1               # rtm 权重，用于负载均衡
backend_data_directory0 = '/opt/pgsql-9.6/pgdata/9.6/data' # rtm 后端postgreSQL 数据库实例目录
backend_flag0 = 'ALLOW_TO_FAILOVER'   # rtm  允许故障自动切换

# host1,slave
backend_hostname1 = '192.168.174.129'      # rtm 此处为 PostgreSQL slave数据库地址 
backend_port1 = 5432                    # rtm 
backend_weight1 = 1                     # rtm
backend_data_directory1 = '/opt/pgsql-9.6/pgdata/9.6/data'        # rtm
backend_flag1 = 'ALLOW_TO_FAILOVER'     # rtm

enable_pool_hba = on            # rtm  开启pgpool认证，需要通过 `pool_passwd` 文件对连接到数据库的用户进行md5认证
pool_passwd = 'pool_passwd'     # rtm 认证文件

# log set
log_destination = 'stderr,syslog'  # rtm  日志级别，标注错误输出和系统日志级别
log_line_prefix = '%t: pid %p: '    # rtm  日志输出格式
log_connections = on               # rtm  开启日志
log_hostname = on                  # rtm  打印主机名称
log_statement = all             # rtm    取消注释则打印sql 语句
log_per_node_statement = on     # rtm    取消注释则开启打印sql负载均衡日志，记录sql负载到每个节点的执行情况
client_min_messages = log  # rtm          日志
log_min_messages = info   # rtm            # 日志级别
pid_file_name = '/opt/pgpool-3/run/pgpool/pgpool.pid'   # rtm pgpool的运行目录，若不存在则先创建
logdir = '/opt/pgpool-3/log/pgpool'  # rtm  指定日志输出的目录
replication_mode = off           # rtm   关闭pgpool的复制模式
load_balance_mode = on             # rtm  开启负载均衡
master_slave_mode = on           # rtm   开启主从模式
master_slave_sub_mode = 'stream'         # rtm  设置主从为流复制模式

# src check
sr_check_period = 10             # rtm    流复制的延迟检测的时间间隔
sr_check_user = 'postgres'        # rtm    流复制的检查用户，该用户需要在pg数据库中存在，且拥有查询权限
sr_check_password = 'pg1235'       # rtm   
sr_check_database = 'postgres'           # rtm  流复制检查的数据库名称
delay_threshold = 10000000             # rtm  设置允许主备流复制最大延迟字节数,单位为kb

# health check
health_check_period = 10          # rtm  pg数据库检查检查间隔时间
health_check_timeout = 20        # rtm 
health_check_user = 'postgres'           # rtm   健康检查用户，需pg数据库中存在
health_check_password = 'pg1235'        # rtm   
health_check_database = 'postgres'      # rtm   健康检查的数据库名称
health_check_max_retries = 3            # rtm   健康检查最大重试次数
health_check_retry_delay = 3            # rtm  重试次数间隔

failover_command = '/opt/pgpool-3/script/failover.sh %H'           # rtm  故障切换脚本
fail_over_on_backend_error = off  # rtm    如果设置了health_check_max_retries次数，则关闭该参数

# watch dog
use_watchdog = on                   # rtm  开启看门狗，用于监控pgpool 集群健康状态
wd_hostname = '192.168.174.129'             # rtm  本地看门狗地址
wd_port = 9000                          # rtm 
wd_priority = 1                         # rtm  看门狗优先级，用于pgpool 集群中master选举
delegate_IP = '192.168.174.159'             # rtm   VIP 地址

if_up_cmd = 'ip addr add $_IP_$/24 dev ens33'  # rtm 配置虚拟IP到本地网卡
if_down_cmd = 'ip addr del $_IP_$/24 dev ens33'          # rtm  
#wd_lifecheck_method = 'heartbeat'       # rtm  看门狗健康检测方法
wd_heartbeat_port = 9694                # rtm    看门狗心跳端口，用于pgpool 集群健康状态通信
wd_heartbeat_keepalive = 2              # rtm    看门狗心跳检测间隔
wd_heartbeat_deadtime = 30              # rtm
heartbeat_destination0 = '192.168.174.128'  # rtm    配置需要监测健康心跳的IP地址，非本地地址，即互相监控，配置对端的IP地址
heartbeat_destination_port0 = 9694      # rtm 监听的端口
heartbeat_device0 = 'ens33'              # rtm 监听的网卡名称
wd_life_point = 3               # rtm   生命检测失败后重试次数
wd_lifecheck_query = 'SELECT 1' # rtm  用于检查 pgpool-II 的查询语句。默认为“SELECT 1”。
wd_lifecheck_dbname = 'postgres'        # rtm 检查健康状态的数据库名称
wd_lifecheck_user = 'postgres'           # rtm 检查数据库的用户，该用户需要在Postgres数据库存在，且有查询权限
wd_lifecheck_password = 'pg1235'        # rtm  看门狗健康检查用户密码
other_pgpool_hostname0 = '192.168.174.128'  # rtm 指定被监控的 pgpool-II 服务器的主机名
other_pgpool_port0 = 9999       # rtm 指定被监控的 pgpool-II 服务器的端口号
other_wd_port0 = 9000           # rtm 指定 pgpool-II 服务器上的需要被监控的看门狗的端口号
```

- 创建pgpool 的 `pid` 目录,为pgpool的启动进程文件目录

```shell
[postgres@localhost etc]# mkdir -p /opt/pgpool-3/run/pgpool/
```

### slave的pcp.conf文件

- 配置 `pcp.conf`文件，通过 `pg_md5` 工具可生成对应的 md5密码

```shell
[postgres@localhost etc]# pg_md5 pg1235
39ec09490128f32fdc1a9b8091c99a57
[postgres@localhost etc]# vim pcp.conf

# 添加内容
postgres:39ec09490128f32fdc1a9b8091c99a57

# 查看内容
[postgres@localhost etc]# tail -2 pcp.conf
# USERID:MD5PASSWD
postgres:39ec09490128f32fdc1a9b8091c99a57
```

### slave的pool_passwd文件

- 配置 `pool_passwd` 文件，用户：`postgres` 密码：`pg1235`

```shell
[postgres@localhost etc]# pg_md5 -m -p -u postgres pool_passwd
password: 
[postgres@localhost etc]# cat pool_passwd 
postgres:md5a3556571e93b0d20722ba62be61e8c2d
```

此文件默认不存在，可通过 `pg_md5` 自动生成该文件,该文件存放用户名和MD5密码，该文件用户控制认证哪些用户可以通过密码验证访问pgpool-Ⅱ。 

注意：上述 `pcp.conf` 和 `pool_passwd` 文件中用户名和密码直接不能包含空格，默认会把空格当成字符。

### slave的failover.sh文件

- 创建failover.sh

```shell
[postgres@localhost pgpool-3]# mkdir script
[postgres@localhost pgpool-3]# cd script
[postgres@localhost script]# vim failover.sh # 添加下文
```

- failover.sh内容

```shell
!#/usr/bash

export PGPORT=5432
export PGUSER=postgres
export PGDBNAME=postgres
export PGPATH=/opt/pgsql-9.6/bin
export PATH=$PATH:$PGPATH
# export NEW_MASTER=$1
export PGDATA=/opt/pgsql-9.6/pgdata/9.6/data
log=/opt/pgpool-3/script/log/failover.log
# set PGPASSWORD=pg1235
# 主备数据库同步时延，单位为秒

SQL1='select pg_is_in_recovery  from pg_is_in_recovery();'

db_role=`echo $SQL1 | psql -At -p $PGPORT -U $PGUSER -d $PGDBNAME`


SWITCH_COMMAND='pg_ctl promote -D /opt/pgsql-9.6/pgdata/9.6/data'

# "t" means standby
# "f" means primary
# 如果为主库，则不切换
if [ $db_role == t ]; then
        echo -e `date +"%F %T"` "Attention:The current database is statndby,ready to switch master database!" >> $log
        # su - $PG_OS_USER -c "$SWITCH_COMMAND"
        $SWITCH_COMMAND
        echo -e `date +"%F %T"` "success:The current standby database successed to switched the primary PG database !" >> $log
        exit 0
fi
```

- 并分配755权限

```shell
[postgres@localhost script]# chmod 755 failover.sh # 如果没有权限，则切换至root
```

- 需要创建failover.log文件的保存目录

```shell
[postgres@localhost etc] # mkdir -p /opt/pgpool-3/script/log
```



## 管理pgpool服务

### 启动

启动 `pgpool`,默认为守护进程启动，不会打印日志，若需显示打印信息，则如下启动

```shell
[postgres@localhost etc]$ pgpool -n -d -D > pgpool.log 2>&1 &
[1] 13987
```

参数说明

> -d 模式Debug下log 
> -n 是不使用后台模式
> -D 会重新加载pg nodes的状态如down或up

在 `后台启动pgpool`，并将标准错误输出和标准输出 到指定 `pgpool.log` 日志文件，可指定绝对路径

### 停止

```shell
[postgres@localhost etc]$ pgpool -m fast stop
2019-08-10 17:12:38: pid 13989: LOG:  stop request sent to pgpool. waiting for termination...
done.
[1]+  中断                  pgpool -n -d > pgpool.log 2>&1
```

### 重载

```shell
[postgres@localhost etc]$ pgpool reload
```

## pgpool状态查询

启动psql服务和pgpool服务后

### 连接 pgpool

- -h 为 pgpool 服务器安装的地址，或者为配置的VIP

```shell
[postgres@localhost ~]$ psql -h 127.0.0.1 -p 9999 postgres postgres
Password for user postgres: 
psql (9.6.8)
Type "help" for help.

postgres=# 
```

### 查询节点 `show pool_nodes`

- 查询节后端数据库节点状态,若没有该函数，则说明没有在postgresql 数据库安装pgpool的扩展函数和插件

```shell
postgres=# show pool_nodes;
LOG:  statement: show pool_nodes;
 node_id |    hostname     | port | status | lb_weight |  role   | select_cnt | load_balance_node | replication_delay 
---------+-----------------+------+--------+-----------+---------+------------+-------------------+-------------------
 0       | 192.168.174.128 | 5432 | up     | 0.500000  | primary | 0          | true              | 0
 1       | 192.168.174.129 | 5432 | down   | 0.500000  | standby | 0          | false             | 0
(2 rows)

postgres=# 
```

参数说明

 `status` 中 `up` 表示后端Postgres数据库正在运行 

 `role` 为数据库对应的角色

 `lb_weight` 为权重 

`load_balance_node` 是否开启负载均衡

`replication_delay` 复制延迟

### 线程池进程 `show pool_processes`

- 显示 `pgpool` 的线程池的进程信息

```shell
postgres=# show pool_processes;
LOG:  statement: show pool_processes;
 pool_pid |     start_time      | database | username |     create_time     | pool_counter 
----------+---------------------+----------+----------+---------------------+--------------
 27135    | 2019-08-14 20:34:31 |          |          |                     | 
 27136    | 2019-08-14 20:34:31 |          |          |                     | 
 27137    | 2019-08-14 20:34:31 |          |          |                     | 
 27138    | 2019-08-14 20:34:31 |          |          |                     | 
 27139    | 2019-08-14 20:34:31 |          |          |                     | 
 27140    | 2019-08-14 20:34:31 |          |          |                     | 
 27141    | 2019-08-14 20:34:31 |          |          |                     | 
 27142    | 2019-08-14 20:34:31 |          |          |                     | 
 27143    | 2019-08-14 20:34:31 |          |          |                     | 
 27144    | 2019-08-14 20:34:31 |          |          |                     | 
 27145    | 2019-08-14 20:34:31 |          |          |                     | 
 27146    | 2019-08-14 20:34:31 |          |          |                     | 
 27147    | 2019-08-14 20:34:31 |          |          |                     | 
 27148    | 2019-08-14 20:34:31 |          |          |                     | 
 27149    | 2019-08-14 20:34:31 |          |          |                     | 
 27150    | 2019-08-14 20:34:31 |          |          |                     | 
 27151    | 2019-08-14 20:34:31 |          |          |                     | 
 27152    | 2019-08-14 20:34:31 |          |          |                     | 
 27153    | 2019-08-14 20:34:31 |          |          |                     | 
 27154    | 2019-08-14 20:34:31 |          |          |                     | 
 27155    | 2019-08-14 20:34:31 |          |          |                     | 
 27156    | 2019-08-14 20:34:31 |          |          |                     | 
 27157    | 2019-08-14 20:34:31 |          |          |                     | 
 27158    | 2019-08-14 20:34:31 |          |          |                     | 
 27159    | 2019-08-14 20:34:31 |          |          |                     | 
 27160    | 2019-08-14 20:34:31 |          |          |                     | 
 27161    | 2019-08-14 20:34:31 |          |          |                     | 
 27162    | 2019-08-14 20:34:31 |          |          |                     | 
 27163    | 2019-08-14 20:34:31 |          |          |                     | 
 27953    | 2019-08-14 20:53:18 | postgres | postgres | 2019-08-14 20:58:04 | 1
 27164    | 2019-08-14 20:34:31 |          |          |                     | 
 27165    | 2019-08-14 20:34:31 |          |          |                     | 
(32 rows)

```

### 查看配置信息 `show pool_status`

- 查看 `pgpool` 配置信息

```shell
postgres=# show pool_status;
LOG:  statement: show pool_status;
                 item                 |                                          value                                 
         |                                   description                                   
--------------------------------------+--------------------------------------------------------------------------------
---------+---------------------------------------------------------------------------------
 listen_addresses                     | *                                                                              
         | host name(s) or IP address(es) to listen on
 port                                 | 9999                                                                           
         | pgpool accepting port number
 socket_dir                           | /tmp                                                                           
         | pgpool socket directory
 pcp_listen_addresses                 | *                                                                              
         | host name(s) or IP address(es) for pcp process to listen on
 pcp_port                             | 9898                                                                           
         | PCP port # to bind
 pcp_socket_dir                       | /tmp                                                                           
         | PCP socket directory
 enable_pool_hba                      | 1                                                                              
         | if true, use pool_hba.conf for client authentication
 pool_passwd                          | pool_passwd                                                                    
         | file name of pool_passwd for md5 authentication
 authentication_timeout               | 60                                                                             
         | maximum time in seconds to complete client authentication
...
...
 backend_hostname0                    | 192.168.174.128                                                                
         | backend #0 hostname
 backend_port0                        | 5432                                                                           
         | backend #0 port number
 backend_weight0                      | 0.500000                                                                       
         | weight of backend #0
 backend_data_directory0              | /opt/pgsql-9.6/pgdata/9.6/data                                                 
         | data directory for backend #0
 backend_status0                      | up                                                                             
         | status of backend #0
 standby_delay0                       | 0                                                                              
         | standby delay of backend #0
 backend_flag0                        | ALLOW_TO_FAILOVER                                                              
         | backend #0 flag
 backend_hostname1                    | 192.168.174.129                                                                
         | backend #1 hostname
 backend_port1                        | 5432                                                                           
         | backend #1 port number
 backend_weight1                      | 0.500000                                                                       
         | weight of backend #1
 backend_data_directory1              | /opt/pgsql-9.6/pgdata/9.6/data                                                 
         | data directory for backend #1
 backend_status1                      | down                                                                           
         | status of backend #1
 standby_delay1                       | 0                                                                              
         | standby delay of backend #1
 backend_flag1                        | ALLOW_TO_FAILOVER                                                              
         | backend #1 flag
 other_pgpool_hostname0               | 192.168.174.129                                                                
         | pgpool #0 hostname
 other_pgpool_port0                   | 9999                                                                           
         | pgpool #0 port number
 other_pgpool_wd_port0                | 9000                                                                           
         | pgpool #0 watchdog port number
 heartbeat_device0                    | ens33                                                                          
         | name of NIC device #0 for sending hearbeat
 heartbeat_destination0               | 192.168.174.129                                                                
         | destination host for sending heartbeat using NIC device 0
 heartbeat_destination_port0          | 9694                                                                           
         | destination port for sending heartbeat using NIC device 0
(141 rows)
```

### 查看连接池的连接情况 `show pool_pools`

- 查看 `pgpool` 连接池中的各个连接信息

```
postgres=# show pool_pools;
LOG:  statement: show pool_pools;
 pool_pid |     start_time      | pool_id | backend_id | database | username |     create_time     | majorversion | min
orversion | pool_counter | pool_backendpid | pool_connected 
----------+---------------------+---------+------------+----------+----------+---------------------+--------------+----
----------+--------------+-----------------+----------------
 27135    | 2019-08-14 20:34:31 | 0       | 0          |          |          |                     | 0            | 0  
          | 0            | 0               | 0
...
 27953    | 2019-08-14 20:53:18 | 0       | 0          | postgres | postgres | 2019-08-14 20:58:04 | 3            | 0            | 1            | 28145           | 1
...
 27165    | 2019-08-14 20:34:31 | 3       | 1          |          |          |                     | 0            | 0            | 0            | 0               | 0
(256 rows)
```

## PCP介绍

### 背景

> pcp 是用来管理 pgpool 的linux命令 ，所有参数 在pgpool-Ⅱ 3.5之后都发生了，通过pcp.conf 来管理认证连接，管理哪些用户可以通过pcp 连接管理pgpool-Ⅱ

### pcp命令参数说明

> -h 为pgpool服务器安装地址，或者VIP 地址
> -d 表示为debug 模式
> -U 为pcp 用户，该用户为 `pcp.conf` 配置文件配置的用户，与数据库用户无关，推荐全部使用统一用户，便于管理
> -v 表示输出详细信息

### 通过 `pcp` 查看 `pgpool的配置信息`

```shell
[postgres@localhost ~]$ pcp_pool_status -h 127.0.0.1 -p 9898 -U postgres -v -d
Password: 
DEBUG: recv: tos="m", len=8
DEBUG: recv: tos="r", len=21
DEBUG pcp_pool_status: send: tos="B", len=4
DEBUG: recv: tos="b", len=18
...
DEBUG: recv: tos="b", len=20
Name [  0]:	listen_addresses
Value:      	*
Description:	host name(s) or IP address(es) to listen on

Name [  1]:	port
Value:      	9999
Description:	pgpool accepting port number

Name [  2]:	socket_dir
Value:      	/tmp
Description:	pgpool socket directory

Name [  3]:	pcp_listen_addresses
Value:      	*
Description:	host name(s) or IP address(es) for pcp process to listen on

Name [  4]:	pcp_port
Value:      	9898
Description:	PCP port # to bind

...

Name [ 65]:	failover_command
Value:      	/opt/pgpool-3/script/failover.sh 1 5432 192.168.174.129 /opt/pgsql-9.6//pgdata/9.6/data
Description:	failover command

Name [ 66]:	failback_command
Value:      	
Description:	failback command

Name [ 67]:	fail_over_on_backend_error
Value:      	0
Description:	fail over on backend error

Name [ 68]:	recovery_user
Value:      	nobody
Description:	online recovery user

...

Name [140]:	heartbeat_destination_port0
Value:      	9694
Description:	destination port for sending heartbeat using NIC device 0

DEBUG: send: tos="X", len=4
```

### 查看 `pgpool` 集群状态

```shell
[postgres@localhost ~]$ pcp_watchdog_info -h 127.0.0.1 -p 9898 -v -U postgres
Password: 
Watchdog Cluster Information 
Total Nodes          : 2
Remote Nodes         : 1
Quorum state         : QUORUM IS ON THE EDGE
Alive Remote Nodes   : 0
VIP up on local node : YES
Master Node Name     : 192.168.174.128:9999 Linux localhost.localdomain
Master Host Name     : 192.168.174.128

Watchdog Node Information 
Node Name      : 192.168.174.128:9999 Linux localhost.localdomain
Host Name      : 192.168.174.128
Delegate IP    : 192.168.174.159
Pgpool port    : 9999
Watchdog port  : 9000
Node priority  : 1
Status         : 4
Status Name    : MASTER

Node Name      : Not_Set
Host Name      : 192.168.174.129
Delegate IP    : Not_Set
Pgpool port    : 9999
Watchdog port  : 9000
Node priority  : 0
Status         : 0
Status Name    : DEAD
```

参数说明

> Total Nodes : 节点数量
> Quorum state：集群选举状态，当pgpool 服务器数量大于3时，通过优先级来进行选举
> VIP up on local node ： VIP 是否在当前节点
> Status ：当前节点状态
> Status Name ： 当前节点名称

### 查看 `pgpool-Ⅱ` 节点数量

```shell
[postgres@localhost ~]$ pcp_node_count -h 127.0.0.1 -p 9898 -U postgres -dv
Password: 
DEBUG: recv: tos="m", len=8
DEBUG: recv: tos="r", len=21
DEBUG: send: tos="L", len=4
DEBUG: recv: tos="l", len=22
Node Count
____________
 2
DEBUG: send: tos="X", len=4
```

### 添加/删除节点

```
# 添加节点
pcp_attach_node
# 删除节点
pcp_detach_node
```

使用帮助

```shell
[postgres@localhost ~]$ pcp_attach_node --help
pcp_attach_node - attach a node from pgpool-II
Usage:
pcp_attach_node [OPTION...] [node-id]
Options:
  -U, --username=NAME    username for PCP authentication
  -h, --host=HOSTNAME    pgpool-II host
  -p, --port=PORT        PCP port number
  -w, --no-password      never prompt for password
  -W, --password         force password prompt (should happen automatically)
  -n, --node-id=NODEID   ID of a backend node
  -d, --debug            enable debug message (optional)
  -v, --verbose          output verbose messages
  -?, --help             print this help
```

- 添加 pgpool 节点,其中参数 `-n 1` 表示需要添加的 `pgpool 机器对应的节点id为1`
- 删除一个 pgpool 节点 ,参数`-n 1 表示该pgpool节点id 为 1`

### 查看 `pgpool` 节点状态

```shell
[postgres@localhost ~]$ pcp_node_info -h 127.0.0.1 -p 9898 -U postgres -dv -n 1
Password: 
DEBUG: recv: tos="m", len=8
DEBUG: recv: tos="r", len=21
DEBUG: send: tos="I", len=6
DEBUG: recv: tos="i", len=63
Hostname   : 192.168.174.129
Port       : 5432
Status     : 3
Weight     : 0.500000
Status Name: down
Role       : standby
DEBUG: send: tos="X", len=4
[postgres@localhost ~]$ pcp_node_info -h 127.0.0.1 -p 9898 -U postgres -dv -n 0
Password: 
DEBUG: recv: tos="m", len=8
DEBUG: recv: tos="r", len=21
DEBUG: send: tos="I", len=6
DEBUG: recv: tos="i", len=63
Hostname   : 192.168.174.128
Port       : 5432
Status     : 2
Weight     : 0.500000
Status Name: up
Role       : primary
DEBUG: send: tos="X", len=4
```

参数说明

> status : 为pgpool的状态 ，共有0、1、2、3
> 0 表示初始化，pcp永远不会显示该状态
> 1 表示 up 在运行状态，但是还没有用户连接
> 2 表示 up 在运行状态，用户连接使用中
> 3 表示 down 该节点停止服务
>
> Weight 表示权重
> Status Name： 参数状态
>      up 表示启用用户连接 与 1 对应
>      waiting 表示启用等待用户连接 与 2 对应
>      down 表示停止服务器状态 与 3 对应

### 其他命令

在pgpool-3/bin目录可查

```shell
[postgres@localhost ~]$ cd /opt/pgpool-3/bin/
[postgres@localhost bin]$ ls -al
总用量 5668
drwxrwxr-x.  2 postgres postgres    4096 8月   9 16:06 .
drwxrwxr-x. 10 postgres postgres     121 8月  14 18:24 ..
-rwxr-xr-x.  1 postgres postgres   89144 8月   9 16:06 pcp_attach_node
-rwxr-xr-x.  1 postgres postgres   89144 8月   9 16:06 pcp_detach_node
-rwxr-xr-x.  1 postgres postgres   89144 8月   9 16:06 pcp_node_count
-rwxr-xr-x.  1 postgres postgres   89144 8月   9 16:06 pcp_node_info
-rwxr-xr-x.  1 postgres postgres   89144 8月   9 16:06 pcp_pool_status
-rwxr-xr-x.  1 postgres postgres   89144 8月   9 16:06 pcp_proc_count
-rwxr-xr-x.  1 postgres postgres   89144 8月   9 16:06 pcp_proc_info
-rwxr-xr-x.  1 postgres postgres   89144 8月   9 16:06 pcp_promote_node
-rwxr-xr-x.  1 postgres postgres   89144 8月   9 16:06 pcp_recovery_node
-rwxr-xr-x.  1 postgres postgres   89144 8月   9 16:06 pcp_stop_pgpool
-rwxr-xr-x.  1 postgres postgres   89144 8月   9 16:06 pcp_watchdog_info
-rwxr-xr-x.  1 postgres postgres  271704 8月   9 16:06 pg_md5
-rwxr-xr-x.  1 postgres postgres 4489488 8月   9 16:06 pgpool
-rwxr-xr-x.  1 postgres postgres   27991 8月   9 16:06 pgpool_setup
-rwxr-xr-x.  1 postgres postgres    9116 8月   9 16:06 watchdog_setup
```

### 查看 `sql语句` 负载均衡

```shell
[postgres@localhost ~]$ psql -h 127.0.0.1 -p 9999 -U postgres
Password for user postgres: 
psql (9.6.8)
Type "help" for help.

postgres=# \c test
You are now connected to database "test" as user "postgres".
test=# select * from apple;
LOG:  statement: select * from apple;
LOG:  DB node id: 0 backend pid: 33136 statement: SELECT count(*) from (SELECT has_function_privilege('postgres', 'pg_catalog.to_regclass(cstring)', 'execute') WHERE EXISTS(SELECT * FROM pg_catalog.pg_proc AS p WHERE p.proname = 'to_regclass')) AS s
LOG:  DB node id: 0 backend pid: 33136 statement: SELECT count(*) FROM pg_catalog.pg_class AS c WHERE c.relname = 'pg_namespace'
LOG:  DB node id: 0 backend pid: 33136 statement: SELECT count(*) FROM pg_class AS c, pg_namespace AS n WHERE c.oid = pg_catalog.to_regclass('"apple"') AND c.relnamespace = n.oid AND n.nspname = 'pg_catalog'
LOG:  DB node id: 0 backend pid: 33136 statement: SELECT count(*) FROM pg_catalog.pg_class AS c, pg_attribute AS a WHERE c.relname = 'pg_class' AND a.attrelid = c.oid AND a.attname = 'relistemp'
LOG:  DB node id: 0 backend pid: 33136 statement: SELECT count(*) FROM pg_class AS c, pg_namespace AS n WHERE c.relname = 'apple' AND c.relnamespace = n.oid AND n.nspname ~ '^pg_temp_'
LOG:  DB node id: 0 backend pid: 33136 statement: SELECT count(*) FROM pg_catalog.pg_class AS c, pg_catalog.pg_attribute AS a WHERE c.relname = 'pg_class' AND a.attrelid = c.oid AND a.attname = 'relpersistence'
LOG:  DB node id: 0 backend pid: 33136 statement: SELECT count(*) FROM pg_catalog.pg_class AS c WHERE c.oid = pg_catalog.to_regclass('"apple"') AND c.relpersistence = 'u'
LOG:  DB node id: 0 backend pid: 33136 statement: select * from apple;
 id |             name              
----+-------------------------------
  1 | 2019-08-14 21:39:06.822326+08
(1 row)
```

上述可知 该查询语句分配在 `DB node 0` ，即主库，负载是基于会话(session)级别的,即第一次分配在哪个库，再结束该会话前会一直再该库

## 模拟主库pgpool宕机，备库的pgpool接管服务

参考链接

> [PGPool-II+PG流复制实现HA主备切换](https://www.jianshu.com/p/ef183d0a9213)
>
> [PostgreSQL流复制热备](https://www.jianshu.com/p/12bc931ebba3)

### 在主库上停止pgpool服务

```shell
[postgres@localhost ~]$ pgpool -m fast stop
2019-08-16 17:07:22: pid 36665: LOG:  stop request sent to pgpool. waiting for termination...
.done.
[1]+  完成                  pgpool -n -d -D > /opt/pgpool-3/pgpool.log 2>&1
```

### 在备库上查询pgpool集群状态

```shell
[postgres@localhost ~]$ psql -h 127.0.0.1 -p 9999
Password: 
psql (9.6.8)
Type "help" for help.

postgres=# show pool_nodes;
LOG:  statement: show pool_nodes;
 node_id |    hostname     | port | status | lb_weight |  role   | select_cnt | load_balance_node | replication_delay 
---------+-----------------+------+--------+-----------+---------+------------+-------------------+-------------------
 0       | 192.168.174.128 | 5432 | up     | 0.500000  | primary | 0          | true              | 0
 1       | 192.168.174.129 | 5432 | up     | 0.500000  | standby | 0          | false             | 0
(2 rows)
```

访问成功，在master节点上的pgpool宕机后，由slave节点的pgpool接管vip和集群服务，并未中断应用访问。

## 测试主库宕机，备库自动切换（正向）

### 查看正常运行时，数据库状态

```shell
[postgres@localhost etc]$ psql -h 192.168.174.159 -p 9999 postgres postgres
Password for user postgres: 
psql (9.6.8)
Type "help" for help.

postgres=# show pool_nodes;
LOG:  statement: show pool_nodes;
 node_id |    hostname     | port | status | lb_weight |  role   | select_cnt | load_balance_node | replication_delay 
---------+-----------------+------+--------+-----------+---------+------------+-------------------+-------------------
 0       | 192.168.174.128 | 5432 | up     | 0.500000  | primary | 0          | true              | 0
 1       | 192.168.174.129 | 5432 | up     | 0.500000  | standby | 0          | false             | 0
(2 rows)
```

参数说明

> node_id : 对应 pgpool-Ⅱ 服务器节点的 id 
> hostname ： postsgreSQL数据库 服务器的 IP 地址
> port ： postgresql 数据库端口
> lb_weight ： 权重，用于控制sql语句的负载 ，此处配置的为1：1 及 平均分配
> role ：postgresSQL 数据库的角色
> load_balance_node：是否开启负载均衡

上述可知 128 为 `primary` ,129 为 `standby` ,PostgreSQL 数据库服务 `status` 都为 `up` 即都正常运行

### `停止128服务器` 主数据库的服务,模拟数据库宕机

```shell
[postgres@localhost ~]$ pg_ctl -D $PGDATA stop
waiting for server to shut down.... done
server stopped
[postgres@localhost etc]$ 
```

在128服务器上查看此时数据库 `节点状态`

```shell
[postgres@localhost ~]$ psql -h 192.168.174.159 -p 9999
Password: 
psql (9.6.8)
Type "help" for help.

postgres=# show pool_nodes;
LOG:  statement: show pool_nodes;
 node_id |    hostname     | port | status | lb_weight |  role   | select_cnt | load_balance_node | replication_delay 
---------+-----------------+------+--------+-----------+---------+------------+-------------------+-------------------
 0       | 192.168.174.128 | 5432 | down   | 0.500000  | standby | 0          | false             | 0
 1       | 192.168.174.129 | 5432 | up     | 0.500000  | primary | 0          | true              | 0
(2 rows)

postgres=# 
```

发现此时 `128服务器`数据库已经 `down`即 服务停止了，且 `129服务器` 数据库由 `standby` 切换为 `primary`

### 在129服务器上测试变更数据

- 查看已有的数据

```
[postgres@localhost ~]$ psql
psql (9.6.8)
Type "help" for help.

postgres=# \c test
You are now connected to database "test" as user "postgres".
test=# select * from apple;
 id |             name              
----+-------------------------------
  1 | 2019-08-15 09:50:58.633367+08
(1 row)
```

- 添加新数据


```shell
test=# insert into appl(name) values(now());
ERROR:  relation "appl" does not exist
LINE 1: insert into appl(name) values(now());
                    ^
test=# insert into apple(name) values(now());
INSERT 0 1
test=# select * from apple;
 id |             name              
----+-------------------------------
  1 | 2019-08-15 09:50:58.633367+08
  2 | 2019-08-16 10:55:47.760169+08
(2 rows)

test=#
```

发现129上数据库可以正常提供服务，即 `pgpool正向自动切换` 成功！

## 测试主库宕机，备库自动切换（反向）

接上述内容，此时主库为129服务器，备库为128服务器，备库待修复

正常状态下时，主库的recovery为recovery.done；宕机后，主库已发生转移，因修复宕机的主库将其作为新主库的备库。修复为备库时，将原有的recovery.done修改为recovery.conf，并将该节点添加至pgpool中。

### 修复备库（128）

master节点down机后，slave节点已经被切换成了primary，修复好master后应重新加入节点，作为primary的standby。假设修复工作是将128服务器作为备库从129服务器那里通过异步流复制恢复数据。

- 修复master端并启动操作：

```shell
[postgres@localhost data]$ rm recovery.done # 在数据库实例data目录下将recovery.done 改为 recovery.conf
[postgres@localhost data]$ pg_ctl -D $PGDATA start
```

- 在pgpool集群中加入节点状态:

注意master（128）的node_id是0，所以-n 0

```shell
[postgres@localhost ~]$ pcp_attach_node -d -U postgres -h 192.168.174.159 -p 9898 -n 0
Password: 
DEBUG: recv: tos="m", len=8
DEBUG: recv: tos="r", len=21
DEBUG: send: tos="C", len=6
DEBUG: recv: tos="N", len=97
BACKEND LOG:  received failback request for node_id: 0 from pid [42615]
DEBUG: recv: tos="c", len=20
pcp_attach_node -- Command Successful
DEBUG: send: tos="X", len=4
```

- 重启pgpool服务

```shell
[postgres@localhost ~]$ pgpool -n -d -D > /opt/pgpool-3/pgpool.log 2>&1 &
[2] 42698
```

- 查看节点状态

```shell
[postgres@localhost ~]$ psql -h 127.0.0.1 -p 9999
Password: 
psql (9.6.8)
Type "help" for help.

postgres=# show pool_nodes;
LOG:  statement: show pool_nodes;
 node_id |    hostname     | port | status | lb_weight |  role   | select_cnt | load_balance_node | replication_delay 
---------+-----------------+------+--------+-----------+---------+------------+-------------------+-------------------
 0       | 192.168.174.128 | 5432 | up     | 0.500000  | standby | 0          | false             | 0
 1       | 192.168.174.129 | 5432 | up     | 0.500000  | primary | 0          | true              | 0
(2 rows)
```

发现加入后，两节点正常运行，且128节点成为standby，129节点是primary

- 数据同步

在129节点中增、删、改、查等操作，在128节点可查询相应的状态

### 主库（此时是129节点）宕机

当前slave节点（129）是primay，我们直接将slave（129）服务器直接关机后，发现实现了主备切换，slave（129）已经down了，而master（128）已经被切换成了primary。

在128节点上查看节点状态：

```shell
[postgres@localhost ~]$ psql -h 127.0.0.1 -p 9999
Password: 
psql (9.6.8)
Type "help" for help.

postgres=# show pool_nodes;
LOG:  statement: show pool_nodes;
 node_id |    hostname     | port | status | lb_weight |  role   | select_cnt | load_balance_node | replication_delay 
---------+-----------------+------+--------+-----------+---------+------------+-------------------+-------------------
 0       | 192.168.174.128 | 5432 | up     | 0.500000  | primary | 0          | true              | 0
 1       | 192.168.174.129 | 5432 | down   | 0.500000  | standby | 0          | false             | 0
(2 rows)
```

- 修复slave（129节点）

```shell
[postgres@localhost data]$ mv recovery.done recovery.conf # 在数据库实例data目录下将recovery.done 改为 recovery.conf
[postgres@localhost data]$ pg_ctl -D $PGDATA start
```

此时我们查看

```shell
# 128节点上
[postgres@localhost ~]$ pg_controldata 
pg_control version number:            960
Catalog version number:               201608131
Database system identifier:           6722786531198359146
Database cluster state:               in production
pg_control last modified:             2019年08月16日 星期五 18时29分35秒
...
```

`state`为  `in production`

```
# 129节点上
[postgres@localhost ~]$ pg_controldata 
pg_control version number:            960
Catalog version number:               201608131
Database system identifier:           6722786531198359146
Database cluster state:               in archive recovery
pg_control last modified:             2019年08月16日 星期五 18时32分10秒
...
```

`state`  为`in archive recovery`

- 数据同步

在128节点中增、删、改、查等操作，在129节点可查询相应的状态

## 数据线同步问题

在主备切换时，修复节点并重启后，由于primary数据发生变化，或修复的节点数据发生变化再按照流复制模式加入集群，很可能报时间线不同步错误：

采用异步方式流复制，当原主机有大量的事务操作压力比较大时，比如update,delete等操作，在原备机提升为主机后，原主机很多时候并不能正常切为备机，这是因为对于原主机，原备机会有一定的延时，也就是说原主机是超前，切换后有一部分内容主备间是不一致的，这个时候原主机降为备机就会报错。这种情况很容易模拟，在不关闭原主机的时候，把备机提升为主机，然后原主机插入新数据，再切为备机即可。

暂时未遇到该情况。

留下链接做后续参考

> https://www.jianshu.com/p/ef183d0a9213



## 问题记录

### 问题1，pgpool pid error

```
could not open pid file as /opt/pgpool-3/run/pgpool/pgpool.pid. reason: No such file or directory
```

分析：该目录用于存放pgpool启动进程的 PID 文件

解决：

```
mkdir -p /opt/pgpool-3/run/pgpool/
```

### 问题2，pgpool.conf配置中的log_destination问题

`log_destination`

参数解释链接：http://www.pgpool.net/docs/pgpool-II-3.2.1/pgpool-zh_cn.html

> pgpool-II 支持多种记录服务器消息的方式，包括 stderr 和 syslog。默认为记录到 stderr。       
>
> 注：要使用syslog 作为 log_destination 的选项，你将需要更改你系统的 syslog 守护进程的配置。pgpool-II 可以记录到 syslog 设备 LOCAL0 到 LOCAL7 （参考 syslog_facility），       	但是大部分平台的默认的 syslog 配置将忽略这些消息。你需要添加如下一些内容 	
>
> ```
> local0.*    /var/log/pgpool.log	
> ```
>
> 到 syslog 守护进程的配置文件以使它生效。 	

### 问题3，pgpool.log中发现

```
WARNING:  checking setuid bit of if_up_cmd
DETAIL:  ifup[/sbin/ip] doesn't have setuid bit
WARNING:  checking setuid bit of if_down_cmd
DETAIL:  ifdown[/sbin/ip] doesn't have setuid bit
WARNING:  checking setuid bit of arping command
DETAIL:  arping[/usr/sbin/arping] doesn't have setuid bit
```

网上查找原因：该命令缺少沾滞位的关系

解决：

```shell
cd /sbin/
chmod +s ifup
chmod +s ip
chmod +s arping
```

### 问题4，pgpool connections error for pool_hba.conf

```shell
[postgres@localhost ~]$ psql -h 192.168.174.159(VIP) -p 9999 postgres postgres -w
psql: ERROR:  pgpool is not accepting any new connections
DETAIL:  all backend nodes are down, pgpool requires at least one valid node
HINT:  repair the backend nodes and restart pgpool
```

参说说明：

```
-h 指定pgpoo-Ⅱ 服务器地址或者VIP      
-p 指定pgpool-Ⅱ 端口
第一个`postgres` 为数据库名称          
第二个 `postgres` 为用户名称
-w 表示不输入密码，该方式需要在postgres的home目录下配置 .pgpass 文件,且权限为600
```

以下不使用`-w`参数

修改了**pg_hba.conf**并重启pgsql服务，pg_hba.conf配置如下：

```
# 修改项

# user add
host    all             all             0.0.0.0/0               md5
host    replication     repl            192.168.174.129/32      md5
```

修改了pool_hba.conf，pool_hba.conf配置如下：

```
# 修改项
host    all         all         0.0.0.0/0             md5 
```

并重载pgpool服务

```shell
pgpool reload
# 或者
pgpool -m fast stop
pgpool -n -d > /path/to/pgpool.log 2>&1 &
```

仍不起作用

网上搜索方法：http://www.pgpool.net/mantisbt/view.php?id=259

> It seems Pgpool-II works as expected. Points are:
> - Once a PostgreSQL node goes down and Pgpool-II recognizes it,
>   the PostgreSQL node will not come back online without manually
>   attached by pcp_attach_node (or restart Pgpool-II with -D
>   option). Reloading Pgpool-II does not help.

因此执行

```shell
pgpool -n -d -D > /path/to/pgpool.log 2>&1 &
```

出现以下问题：

```shell
[postgres@localhost ~]$ psql -h 192.168.174.159 -p 9999
psql: ERROR:  MD5 authentication is unsupported in replication and master-slave modes.
HINT:  check pg_hba.conf
```

原因：该错误为 pgpool-Ⅱ 本地默认认证方式为trust,只需要把 `pool_hba.conf` 对应的 `trust` 改为 md5

解决：

```shell
[postgres@localhost ~]$ vim /opt/pgpool-3/etc/pool_hba.conf
```

pool_hba.conf配置，修改项：

```
host    all         all         127.0.0.1/32          md5 
```

再次执行，输入密码进入

```shell
[postgres@localhost ~]$ psql -h 192.168.174.159 -p 9999
Password: 
psql (9.6.8)
Type "help" for help.

postgres=#
```

### 问题5，pgpool connection error for role

```shell
[postgres@localhost ~]$ psql -h 192.168.174.159 -p 9999 pgpool repl
psql: FATAL:  md5 authentication failed
DETAIL:  pool_passwd file does not contain an entry for "repl"
```

出现该问题是因为在 `pool_passwd`文件中没有配置该用户 `repl`



### 问题6，pgpool connection error for db

```shell
ERROR:  failed to make persistent db connection
```

该问题是pgpool.conf配置文件中，查询数据库的问题，要确保该数据库已存在

### 问题7，SSL debug

该日志信息不理解，还未弄懂哪里出错的。

即使之后能够完成主机宕机后，备机切换为主机的任务，该日志信息仍然存在。

```shell
DEBUG:  SSL is requested but SSL support is not available
```

### 问题8， pgpool 启动失败

现象：查看 pgpool.pid， 存在一段时间后消失

查看 pgpool.log ，问题如下

```
2019-10-11 20:23:59: pid 7557: FATAL:  failed to bind a socket: "/tmp/.s.PGSQL.9898"
2019-10-11 20:23:59: pid 7557: DETAIL:  bind socket failed with error: "Address already in use"
```

```
2019-10-11 20:23:59: pid 7557: FATAL:  failed to bind a socket: "/tmp/.s.PGSQL.9999"
2019-10-11 20:23:59: pid 7557: DETAIL:  bind socket failed with error: "Address already in use"
```

原因：由于 pgpool 服务异常关闭

处理办法：

```
rm -f /tmp/.s.PGSQL.9999 
rm -f /tmp/.s.PGSQL.9898
```

重新启动 pgpool



## 其他记录

### 1、配置多台服务器互信—SSH方式

假设有主机

|           主机            |   用户   | 用户 |
| :-----------------------: | :------: | :--: |
| （master）192.168.174.128 | postgres | root |
| （slave）192.168.174.129  | postgres | root |

需求：`postgres@master`与`postgres@slave`相互访问，`root@master`与`root@slave`相互访问。在对应用户下执行一下操作，以前者为例。

- 在`master`服务器和`slave`服务器上各自生成密钥和公钥，执行 `ssh-keygen -t rsa`，一路回车即可

```shell
[locallhost hk]# su - postgres
上一次登录：五 8月 16 09:54:32 CST 2019pts/0 上
[postgres@localhost ~]$ ssh-keygen -t rsa
Generating public/private rsa key pair.
Enter file in which to save the key (/root/.ssh/id_rsa):
Enter passphrase (empty for no passphrase):
Enter same passphrase again:
Your identification has been saved in /root/.ssh/id_rsa.
Your public key has been saved in /root/.ssh/id_rsa.pub.
The key fingerprint is:
...
...
[postgres@localhost .ssh]$ ll
-rw-------. 1 postgres postgres 1679 8月  15 18:12 id_rsa
-rw-r--r--. 1 postgres postgres  412 8月  15 18:12 id_rsa.pub
```

`id_rsa.pub` 为公钥，用于加密，`id_rsa` 为私钥用于解密

- 将`master`的`id_rsa.pub`复制到`slave`的`authorized_keys`，让`master`信任`slave`

- 同样将`slave`的`id_rsa.pub`复制到`master`的`authorized_keys`，让`slave`信任`master`

- 测试是否 `master`服务器 信任 `slave`服务器 ，通过在`master`服务器 `ssh` 命令连接，若无需输入密码则表示成功

```shell
[postgres@localhost .ssh]$ ssh 192.168.174.129
Last login: Fri Aug 16 10:13:30 2019
[postgres@localhost ~]$ 登出
Connection to 192.168.174.129 closed.
[postgres@localhost .ssh]$ 
```

`ctrl+D`登出

### 2、连接异常问题自查表

| pg_hba.conf | pool_hba.conf | pool_passwd | result                                                       |
| :------: | :---------: | :-------: | :------------------------------------------------------------: |
|     md5     | md5           | yes         | md5 auth                                                     |
|     md5     | md5           | no          | "MD5" authentication with pgpool failed for user "XX"        |
|     md5     | trust         | yes/no      | MD5 authentication is unsupported in replication, master-slave and parallel mode |
|    trust    | md5           | yes         | no auth                                                      |
|    trust    | md5           | no          | "MD5" authentication with pgpool failed for user "XX"        |
|    trust    | trust         | yes/no      | no auth                                                      |

### 3、负载均衡的条件

需要对一个查询使用负载均衡，需要满足以下的所有条件： 

- PostgreSQL 7.4 或更高版本

- 即可以在复制模式中，也可以在主备模式中

- 在复制模式中，查询必须不是在一个显式的事务中（例如，不在 BEGIN ~ END 块中）         

  - 不过，如果碰到以下情况，即使是在显式事务中，也能够进行负载均衡：               
    - 事务的隔离级别不为 SERIALIZABLE
    - 事务一直没执行一个写类查询（直到执行了一个写类型的查询，负载均衡都能生效。在这里“写类型查询”指非 SELECT DML 或者 DDL。调用了在黑名单或者白名单里面的函数的 SELECT 语句不会被认为是写类型的查询。不过这在以后可能会改变。）
    - 如果函数黑白名单为空，则调用了函数的 SELECT 语句会被认为是只读的。

- 不能是 SELECT INTO

- 不能是 SELECT FOR UPDATE 或者 FOR SHARE

- 以 "SELECT" 开始或者为 COPY TO STDOUT, EXPLAIN, EXPLAIN ANALYZE SELECT... 其中一个，ignore_leading_white_space = true 将忽略开头的空格。（除非是在 [black_list](http://www.pgpool.net/docs/pgpool-II-3.5.4/doc/pgpool-zh_cn.html#BLACK_FUNCTION_LIST) 或者 [white_list](http://www.pgpool.net/docs/pgpool-II-3.5.4/doc/pgpool-zh_cn.html#WHITE_FUNCTION_LIST) 指明的有写动作的函数）     

- V3.0 - 在主备模式中，除了以上条件，还包含以下条件：         

  - 不能使用临时表

  - 不能使用不写日志的表

  - 不能使用系统表

  - 不过，如果碰到以下条件，即使是显式事务，依然有可能进行负载均衡

  - - 事务隔离级别不是SERIALIZABLE
    - 事务一直没有进行写查询（直到发生写入查询前，都可能进行负载均衡）

 注意你可以通过在 SELECT 语句之前插入任意的注释来禁止负载均衡： 

```
/*REPLICATION*/ SELECT ...
```

请参考[replicate_select](http://www.pgpool.net/docs/pgpool-II-3.5.4/doc/pgpool-zh_cn.html#replicate_select)。也可以参考[flow chart](http://www.pgpool.net/docs/pgpool-II-3.5.4/doc/where_to_send_queries.pdf)。 

注：JDBC 驱动有自动提交的选项。如果自动提交为 false， 则 JDBC 驱动将自己发送 "BEGIN" 和 "COMMIT"。在这种情况下[与进行负载均衡相同的约束](http://www.pgpool.net/docs/pgpool-II-3.5.4/doc/pgpool-zh_cn.html#condition_for_load_balance)也会发生。  

