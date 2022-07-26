==已测试==

# PgSQL 编译安装

[TOC]

参考博客

> [PostgreSQL 9.6 SUSE 环境搭建（一）](https://blog.csdn.net/yaoqiancuo3276/article/details/80203853)

环境变量配置参考

> [PostgreSQL 10 Linux 安装](https://blog.csdn.net/yaoqiancuo3276/article/details/80212760)

## 环境配置要求

>1、GNU make version 3.80 (可通过make  --version 查看)

```shell
[hk@localhost ~]$ make --version
GNU Make 3.82
Built for x86_64-redhat-linux-gnu
Copyright (C) 2010  Free Software Foundation, Inc.
License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.
```

>2、c编译环境（要符合c89标准），GCC版本推荐最新

```shell
[hk@localhost ~]$ su
密码：
[root@localhost hk]# yum install gcc
...
已安装:
  gcc.x86_64 0:4.8.5-36.el7_6.2                                                 

作为依赖被安装:
  cpp.x86_64 0:4.8.5-36.el7_6.2                                                 
  glibc-devel.x86_64 0:2.17-260.el7_6.6                                         
  glibc-headers.x86_64 0:2.17-260.el7_6.6                                       
  kernel-headers.x86_64 0:3.10.0-957.27.2.el7                                   

作为依赖被升级:
  glibc.x86_64 0:2.17-260.el7_6.6     glibc-common.x86_64 0:2.17-260.el7_6.6   
  libgcc.x86_64 0:4.8.5-36.el7_6.2    libgomp.x86_64 0:4.8.5-36.el7_6.2        

完毕！
[root@localhost hk]# gcc --version
gcc (GCC) 4.8.5 20150623 (Red Hat 4.8.5-36)
Copyright © 2015 Free Software Foundation, Inc.
本程序是自由软件；请参看源代码的版权声明。本软件没有任何担保；
包括没有适销性和某一专用目的下的适用性担保。
```

>3、磁盘空间最少150MB，（Linux 可通过df 命令查看）

```shell
[root@localhost hk]# df
文件系统                  1K-块    已用    可用 已用% 挂载点
/dev/mapper/centos-root 8169472 4302300 3867172   53% /
devtmpfs                 914516       0  914516    0% /dev
tmpfs                    931624       0  931624    0% /dev/shm
tmpfs                    931624   10608  921016    2% /run
tmpfs                    931624       0  931624    0% /sys/fs/cgroup
/dev/sda1                201380  160364   41016   80% /boot
tmpfs                    186328       4  186324    1% /run/user/42
tmpfs                    186328      28  186300    1% /run/user/1000
```

## 源码准备

> 1、  [ PostgreSQL下载地址 ](https://www.postgresql.org/ftp/source/)
> 2、  [ readline下载地址 ] (http://ftp.gnu.org/gnu/readline/readline-7.0.tar.gz)
> 3、  [ zlib下载地址 ] http://www.zlib.net/zlib-1.2.11.tar.gz
>
> 本次下载 postgresql-9.6.8.tar.gz

下载并解压

```shell
[root@localhost ~]# pwd
~/root/
[root@localhost ~]# mkdir pgsoft
[root@localhost ~]# cd pgsoft/
[root@localhost pgsoft]# wget [包链接]
...
[root@localhost pgsoft]# ls
postgresql-9.6.8.tar.gz  readline-7.0.tar.gz  zlib-1.2.11.tar.gz
[root@localhost pgsoft]# tar -xf readline-7.0.tar.gz
[root@localhost pgsoft]# tar -xf zlib-1.2.11.tar.gz
[root@localhost pgsoft]# tar -xf postgresql-9.6.8.tar.gz
[root@localhost pgsoft]# ls
postgresql-9.6.8         readline-7.0         zlib-1.2.11
postgresql-9.6.8.tar.gz  readline-7.0.tar.gz  zlib-1.2.11.tar.gz
```



## 配置postgres用户

- 检查**postgres**用户

检查和配置**postgres**用户，用于数据库用户

查找是否该环境有当前用户

方法1

```shell
[hk@localhost ~]$ cat /etc/passwd | grep postgres
```

方法2

```shell
[hk@localhost ~]$ id postgres
id: postgres: No such user
```

- 创建 **postgres** 的 `linux` 操作系统组和账户

```shell
[hk@localhost ~]$ su
密码：
[root@localhost ~]# groupadd -g 10000 postgres
[root@localhost ~]# useradd -g 10000 -u 10000 postgres
```

- 校验用户

```shell
[root@localhost ~]# id postgres
[root@localhost ~]# uid=10000(postgres) gid=10000(postgres) 组=10000(postgres)
```

- 创建 **postgres** 用户 **home** 目录，存放 `postgres` 用户的记录(bash、profile、shell等) 

```shell
[root@localhost ~]# mkdir /home/postgres
[root@localhost ~]# chown postgres.postgres /home/postgres/
[root@localhost ~]# usermod -d /home/postgres postgres
```

## 安装Post'g'reSQL 9.6

**软件安装均在 `root`权限下进行**

### 首先安装  `readline`  依赖

```shell
[root@localhost pgsoft]# cd readline-7.0/
[root@localhost readline-7.0]#./configure
...
[root@localhost readline-7.0]# make && make install
...
```

### 其次安装 `zlib` 依赖

```shell
[root@localhost readline-7.0]# cd ../zlib-1.2.11/
[root@localhost zlib-1.2.11]#./configure
...
[root@localhost zlib-1.2.11]# make && make install
...
```

### 安装PostgreSQL 9.6.8

#### configure

readline**(记录历史sql命令查询)依赖

```shell
[root@localhost zlib-1.2.11]# mkdir -p /opt/pgsql-9.6 # 创建软件安装目录 /opt/pgsql-9.6 
[root@localhost zlib-1.2.11]# chown postgres.postgres -R /opt/ # 为创建的目录分配所属用户和组为 postgres
[root@localhost pgsoft]# cd postgresql-9.6.8/ #进入解压后的postgresql 目录
[root@localhost postgresql-9.6.8]# ./configure --prefix=/opt/pgsql-9.6
...
```

会出现错误

```
...
configure: error: readline library not found
If you have readline already installed, see config.log for details on the
failure.  It is possible the compiler isn't looking in the proper directory.
Use --without-readline to disable readline support.
```
再重新执行


```shell
[root@localhost postgresql-9.6.8]# ./configure --prefix=/opt/pgsql-9.6 --without-readline
...
g.status: linking src/include/port/linux.h to src/include/pg_config_os.h
config.status: linking src/makefiles/Makefile.linux to src/Makefile.port
[root@localhost postgresql-9.6.8]# 
```

#### 参数说明

> ./configure ：为linux源码编译安装检查命令，检查软件安装所需环境是否正常
> --prefix ：为指定软件的编译安装的目录，
> --wihtout-readline ：--without表示忽略检查,-readline 表示忽略安装的软件包，即忽略readline 依赖包的检查，该包用于 在psql命令行中记录命令，可进行上下翻滚查看历史命令，建议最好安装，不要进行忽略，即不要指定该参数 --without-readline 

#### make && make install

编译时  `world`  为安装postgresql 安装包下所有软件, 使用 `-j 8`（该参数可忽略） 指定**8核**编译；

```shell
[root@localhost postgresql-9.6.8]# make world
....
PostgreSQL, contrib, and documentation successfully made. Ready to install.
```
make 后看到“PostgreSQL, contrib, and documentation successfully made. Ready to install.”说明编译成功。

开始安装，`- world` 表示安装所有安装包自带的软件和扩展

```shell
[root@localhost postgresql-9.6.8]# make install-world
...
PostgreSQL, contrib, and documentation installation complete.
```

执行命令后看到“PostgreSQL, contrib, and documentation installation complete.”说明安装成功。

安装成功后可到指定的 /opt/pgsql-9.6 安装目录下检查是否包含以下目录

```shell
[root@localhost postgresql-9.6.8]# cd /opt/pgsql-9.6/
[root@localhost pgsql-9.6]# ls
bin  include  lib  share
```

检查安装 `postgreSQL` 版本是否为 `9.6`

```shell
[root@localhost pgsql-9.6]# /opt/pgsql-9.6/bin/postgres --version

postgres (PostgreSQL) 9.6.8
```

#### 初始化数据目录

创建数据库及相关目录

```shell
[root@localhost postgresql-9.6.8]#  mkdir -p /opt/pgsql-9.6/pgdata/9.6/{data,archive,scripts,backup}
```

目录名称可自定义

> data : 数据库存放目录， 必需
> archieve : 日志归档存放目录，非必需
> scripts : 脚本存放目录（故障转移、日志清理等）非必需
> backup : 备份存放目录 非必需

配置上面创建的目录所属用户和组(postgres.postgres中的 `.` 与 `:` 等同

```shell
[root@localhost postgresql-9.6.8]# chown -R postgres.postgres /opt/pgsql-9.6/pgdata/9.6
```

检查数据目录，**“-“** 表示会自动切换到之前创建的用户的**home**目录下

```shell
[root@localhost postgresql-9.6.8]# su - postgres 
[postgres@localhost ~]$ ls
[postgres@localhost ~]$ pwd
/home/postgres
[postgres@localhost ~]$ cd /opt/pgsql-9.6/pgdata/9.6/
[postgres@localhost 9.6]$ ll
总用量 0
drwxr-xr-x. 2 postgres postgres 6 8月   8 21:21 archive
drwxr-xr-x. 2 postgres postgres 6 8月   8 21:21 backup
drwxr-xr-x. 2 postgres postgres 6 8月   8 21:21 data
drwxr-xr-x. 2 postgres postgres 6 8月   8 21:21 scripts
```

#### 添加环境变量

```shell
[root@localhost postgresql-9.6.8]# vi /etc/profile
```

添加以下内容

```
export PGHOME=~/opt/pgsql-9.6
export PGDATA=~/opt/pgsql-9.6/pgdata/9.6/data 
export PATH=$PATH:$HOME/bin:/opt/pgsql-9.6/bin  
export PG_PATH=/opt/pgsql-9.6/bin
export PATH=$PG_PATH:$PATH
```

立即载入环境变量

```shell
[root@localhost postgresql-9.6.8]# source /etc/profile
```

#### 初始化数据目录

执行 `/opt/pgsql-9.6/bin/initdb` 进行初始化数据目录

```shell
[postgres@localhost 9.6]$ /opt/pgsql-9.6/bin/initdb -D /opt/pgsql-9.6/pgdata/9.6/data/ -E UTF-8 --locale=zh_CN.UTF-8
...

fixing permissions on existing directory /opt/pgsql-9.6/pgdata/9.6/data ... ok
creating subdirectories ... ok
selecting default max_connections ... 100
selecting default shared_buffers ... 128MB
selecting dynamic shared memory implementation ... posix
creating configuration files ... ok
running bootstrap script ... ok
performing post-bootstrap initialization ... ok
syncing data to disk ... ok

WARNING: enabling "trust" authentication for local connections
You can change this by editing pg_hba.conf or using the option -A, or
--auth-local and --auth-host, the next time you run initdb.

Success. You can now start the database server using:

    /opt/pgsql-9.6/bin/pg_ctl -D /opt/pgsql-9.6/pgdata/9.6/data/ -l logfile start
```



> -D 表示指定数据库存放目录
> -E 表示 指定字符集编码 

`data` 目录权限会自动修改为0700权限，`ll` 检查目录权限是否为`rwx` (r=4,w=2,x=1)也可手动配置,`r`为读权限 `w`为写权限 `x`为执行权限。

```shell
[postgres@localhost 9.6]$ ll
总用量 4
drwxr-xr-x.  2 postgres postgres    6 8月   8 21:21 archive
drwxr-xr-x.  2 postgres postgres    6 8月   8 21:21 backup
drwx------. 19 postgres postgres 4096 8月   8 21:25 data
drwxr-xr-x.  2 postgres postgres    6 8月   8 21:21 scripts
```

#### 启动/停止/重启服务

修改 `postgresql.conf` 配置文件，该文件在初始化时指定的数据库 `data` 目录下

```shell
[postgres@localhost 9.6]$ cd data/
[postgres@localhost data]$ vim postgresql.conf
```

编辑配置文件并修改以下参数如下：

- 必须参数

```
listen_addresses = '*'        
port = 5432  
log_destination = 'csvlog'
logging_collector = on
log_filename = 'postgresql-%Y-%m-%d_%H%M%S.log' 
```

- 可选参数 (可跳过以下参数) 配置

```
max_connections = 100    
superuser_reserved_connections = 10    
shared_buffers = 32GB    
maintenance_work_mem = 2GB      
shared_preload_libraries = 'pg_stat_statements'
wal_level = logical    
archive_mode = on    
archive_command = '/bin/true'   
max_wal_senders = 10    
max_replication_slots = 10  
hot_standby = on    
random_page_cost = 1.1        
effective_cache_size = 64GB  
```

通过 `/opt/pgsql-9.6/bin/pg_ctl` 启动 `PostgreSQL` 服务

```shell
[postgres@localhost data]$ pg_ctl -D ../data/ start
server starting
[postgres@localhost data]$ LOG:  redirecting log output to logging collector process
HINT:  Future log output will appear in directory "pg_log".

```

参数说明

> -D 表示指定初始化的数据库目录 
>
> start 启动
>
> stop 停止
>
> restart 重启

在`/opt/pgsql-9.6/pgdata/9.6/data/pg_log/***.csv`看到以下行说明启动成功：

```shell
2019-08-09 09:58:04.058 CST,,,87123,,5d4cd32c.15453,2,,2019-08-09 09:58:04 CST,,0,LOG,00000,"database system is ready to accept connections",,,,,,,,,""
2019-08-09 09:58:04.059 CST,,,87129,,5d4cd32c.15459,1,,2019-08-09 09:58:04 CST,,0,LOG,00000,"autovacuum launcher started",,,,,,,,,""
```

创建必要的数据库,`/opt/pgsql-9.6/bin/psql` 为postgresql 的命令行连接命令

```shell
[postgres@localhost data]$ psql -p 5432 -U postgres postgres
psql (9.6.8)
Type "help" for help.

postgres=# 
postgres=# CREATE DATABASE HA;   
CREATE DATABASE
```

参数说明

> -p 表示PostgreSQL数据库的端口号，默认5432 -U 表示登录用户为 postgres 
> 第二个 postgres 表示为连接的数据库名称

创建 user (非必须操作，流复制时用到)：

```shell
postgres=# \c HA
FATAL:  database "HA" does not exist
Previous connection kept
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
(4 rows)

postgres=# \c ha
You are now connected to database "ha" as user "postgres".
ha=# CREATE USER repl ENCRYPTED PASSWORD '123456' REPLICATION;
CREATE ROLE
```

参数说明

> \c 表示切换数据库，pocdb 为数据库名称

验证用户：

```shell
ha=# \du+ # \du 表示查询当前数据下所有用户和拥有的权限
                                          List of roles
 Role name |                         Attributes                         | Member
 of | Description 
-----------+------------------------------------------------------------+-------
----+-------------
 postgres  | Superuser, Create role, Create DB, Replication, Bypass RLS | {}    
    | 
 repl      | Replication                                                | {}    
    | 

ha=# \q
```

退出连接

```shell
ha=# \q
[postgres@localhost data]$
```

安装完成

### 远程访问配置

若需要从pgAdmin远程访问该数据库，则需要连接数据库为默认用户 `postgres` 修改密码，建议第一次记登陆后，执行该操作

```shell
[postgres@localhost data]$ psql
psql (9.6.8)
Type "help" for help.

postgres=# ALTER USER postgres WITH PASSWORD '自己填';
ALTER ROLE
postgres=#
```

修改 **pg_hba.conf** 配置文件，指定 IP 为**xxx.xxx.xxx.xxx** 的所有用户通过密码认证进行连接该服务器上所有数据库

```shell
[postgres@localhost data]$ vim pg_hba.conf
```

IPV4下 添加内容

```
# IPv4 local connections:
host    all             all             127.0.0.1/32            trust
host    all             all            192.168.174.1/32         md5
host    all             all             0.0.0.0/0               md5
```

参数说明

>host 表示当前主机 
>第一个all表示该主机所有的数据库，可具体指定数据库名称
>第二个 all 表示所有用户 ，可指定具体用户 
>第四个IP地址，可设置为0.0.0.0/0 表示所有ip地址
>最后一个md5 表示进行md5加密密码认证  

修改上述配置文件后需要 **重启服务** ，然后IP地址为 192.168.89.102 就可以使用pgAdmin 通过 **postgres** 用户，密码为 **xxxxxx** 进行客户端连接。

```shell
[postgres@localhost data]$ pg_ctl -D ../data/ restart
waiting for server to shut down.... done
server stopped
server starting
[postgres@localhost data]$ LOG:  redirecting log output to logging collector process
HINT:  Future log output will appear in directory "pg_log".
```



## 问题记录

1、防火墙的原因

若使用pgAdmin客户端时提示无法连接该ip的服务器时，可能是CentOS 防火墙中内置了PostgreSQL服务，配置文件位置在/usr/lib/firewalld/services/postgresql.xml，我们只需以服务方式将PostgreSQL服务开放即可

```shell
[root@localhost pgsql]# firewall-cmd --add-service=postgresql --permanent --zone=public
success
[root@localhost pgsql]# firewall-cmd --reload
success
```

重新使用pgAdmin成功

2、改变了默认端口

如果PostgreSQL正在侦听11002端口，而不是标准的5432端口，则可以执行以下操作：

```shell
 firewall-cmd --zone=public --remove-service=postgresql --permanent
 firewall-cmd --zone=public --add-port=11002/tcp --permanent
 firewall-cmd --reload
```

**注意**

- 请不要随意删除安装的数据库 `data` 目录下的任意文件，防止发生不可恢复的错误

