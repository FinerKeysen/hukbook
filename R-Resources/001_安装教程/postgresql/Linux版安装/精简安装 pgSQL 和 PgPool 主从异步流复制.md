==已测试==

# 安装 PGSQL 和 PGPOOL 主从异步流复制

# 一、安装 PGSQL 主库

注意：可在==某用户下安装== ，安装完后 postgresql 的==默认超级管理员就是该用户==，==数据库名为 postgres==

安装 `readline` 和`zlib` 需要 root 权限因此安装时不要这两个库

## 1.1、条件

**要求一：**

要求有GNU make，版本要大于等于 3.76.1，检查gmake的方法如下：gmake --version

**要求二：**

编译器要求是兼容ISO/ANSI C 的编译器，遵从C89标准。

如果使用gcc，这两个条件都能支持。

**要求三：**

由于源代码包是.tar.gz或.tar.bz2的格式，所以要求平台下有能解压缩源代码包的tar和gzip工具。

**要求四(非强制）：**

PostgreSQL默认是使用GNU Readline库支持在psql的命令行中可以使用光标键（↑↓）翻出历史命令。当然如果没有GNU Readline库的话，需要增加without-readline 选项到./configure命令后，当然这样做后就失去了使用光标键（↑↓）翻出历史命令的功能。也可以使用libedit库（BSD-licensed）提供类似的功能，这时需要在.configure后增加--with-libedit-preferred 选项。常用的Linux发行版本默认安装了时都安装了GNU  Readline库。下面的命令检查是否安装了Readline库：

```
[root@osdba /usr/src/postgresql-8.4.3]#rpm -qa |grep readline
```

**要求五(非强制）：**
PostgreSQL默认使用zlib压缩库，主要是pg_dump和pg_restore这两个导入导出工具使用zlib压缩库，指定配置选项--without-zlib可以不使用zlib库，当然这样pg_dump和pg_restore就没有了压缩



> 源码
>
> [pgsql10.10](https://ftp.postgresql.org/pub/source/v10.10/postgresql-10.10.tar.gz)
>
> 





## 1.2、安装

### 1.2.1、在解压目录下

```
./configure --prefix=/home/ctgcache/ctg-pgsql/opt/pgsql-10.10 --without-readline --without-zlib --with-libedit-preferred
```



### 1.2.2、make && make install

```
make world
```



```
make instal-world
```



### 1.2.3、添加环境变量

在用户目录下， 在 .bashrc 文件中添加

```
export PGPORT=5432
export PGHOME=/home/ctgcache/ctg-pgsql/opt/pgsql-10.10
export PGPATH=$PGHOME/bin
export PGDATA=/home/ctgcache/ctg-pgsql/usr/pgsql/pgdata/10.10/data
PGARCHIVE=/home/ctgcache/ctg-pgsql/usr/pgsql/pgdata/10.10/archive

export PGPOOLHOME=/home/ctgcache/ctg-pgsql/opt/pgpool-II-4
export PGPOOLPATH=$PGPOOLHOME/bin

export PATH=$PATH:$HOME/bin:$PGHOME:$PGPATH:$PGPOOLHOME:$PGPOOLPATH
```



### 1.2.4、初始化 pgsql 数据库

```
initdb -D $PGDATA -E UTF-8
```



### 1.2.5、修改 postgresql.conf

进入 $PGDATA 目录

```
vim postgresql.conf
```

末尾追加内容

```
listen_addresses = '*'
port = 5432
log_destination = 'csvlog'
logging_collector = on
log_filename = 'postgresql-%Y-%m-%d_%H%M%S.log'

# the following are optional parameters 

max_connections = 1000
superuser_reserved_connections = 10
maintenance_work_mem = 2GB
shared_preload_libraries = 'pg_stat_statements'
wal_level = replica
wal_keep_segments = 256
wal_sender_timeout = 60s
archive_mode = on
archive_command = 'cp %p $PGARCHIVE/%f'
max_wal_senders = 10
max_replication_slots = 10  
hot_standby = on    
random_page_cost = 1.1        
effective_cache_size = 64GB
```



### 1.2.6、修改 pg_hba.conf

进入 $PGDATA 目录

```
vim pg_hba.conf
```

末尾追加内容

```
# USER ADD

host    all             all             191.268.174.1/32        md5
host    all             all             0.0.0.0/0               md5
host    replication     repl            备库ip/32       md5

```



启动/停止/重启

```
pg_ctl -D $PGDATA/ start/stop/restart
```



### 1.2.7、重置 postgres 数据库的密码

```
# 先进数据库
psql -U 用户名 -d postgres

# 改密码
postgres=# ALTER USER 用户名 WITH PASSWORD '自己填';
```



### 1.2.8、创建流复制用户

```
postgres=# CREATE USER repl ENCRYPTED PASSWORD '123456' REPLICATION;
```





### 1.2.9、安装备库

#### 1.2.9.1 从主库复制数据

时先进行步骤1~1.2.3 ，特别注意备库不进行初始化

执行到1.2.3后

```
pg_basebackup -h 主库ip -U repl -W -Fp -Pv -Xs -R -D $PGDATA
```

#### 1.2.9.2 修改recovery.conf

追加内容

```
recovery_target_timeline = 'latest'
```

1.2.9.3 修改备库 data目录的权限

```
chmod 0700 $PGDATA
```

**然后进行步骤 2.5~2.7**



# 二、PGPOOL-II安装

解压包进包目录 比如 /home/ctgcache/ctg-pgsql/softwares/pgpool-II-4.0.6

## 2.1、主库上安装

### 2.1.1、make && make install

```
./configure --prefix=$PGPOOLHOME

make -j4 # 选择小于等于 cpu的核数


make install
```

### 2.1.2、添加环境变量

参考 [1.2.3](#1.2.3、添加环境变量) 小节

### 2.1.3、安装扩展

```
cd 包目录/src/sql
make -j4
make install
psql -p 5433 -f pgpool-regclass/pgpool-regclass.sql template1
```

### 2.1.4、建立 insert_lock 表

```
psql -p 5433 -f insert_lock.sql template1
```

### 2.1.5、安装 C 语言函数

```
cd pgpool-recovery
make install
psql -p 5433 -f pgpool-recovery.sql template1
```

### 2.1.6、PGPOOL 配置

#### pgpool.conf

```
listen_addresses = '*'
port = 9999
pcp_listen_addresses = '*' # rtm
pcp_port = 9898         # rtm

backend_hostname0 = '192.168.174.11'
backend_port0 = 5432
backend_weight0 = 1
backend_data_directory0 = '/home/ctgcache/usr/pgsql/pgdata/10.10/data/' # $PGDATA
backend_flag0 = 'ALLOW_TO_FAILOVER'

backend_hostname1 = '192.168.174.10'
backend_port1 = 5432
backend_weight1 = 1
backend_data_directory1 = '/home/ctgcache/usr/pgsql/pgdata/10.10/data/' # $PGDATA
backend_flag1 = 'ALLOW_TO_FAILOVER'

enable_pool_hba = on
pool_passwd = 'pool_passwd'

log_destination = 'stderr'
log_line_prefix = '%t: pid %p: '
log_connections = on
log_hostname = on
log_statement = all
log_per_node_statement = on
client_min_messages = log
log_min_messages = info
pid_file_name = '/home/ctgcache/opt/pgpool-II-4/run/pgpool/pgpool.pid' # $PGPOOLHOME'/run/pgpool/pgpool.pid'
logdir = '/home/ctgcache/opt/pgpool-II-4/log/pgpool' # $PGPOOLHOME'/log/pgpool'

master_slave_mode = on
master_slave_sub_mode = 'stream'

sr_check_period = 10
sr_check_user = 'repl'
sr_check_password = '123456'

failover_command = '/home/ctgcache/opt/pgpool-II-4/scripts/failover.sh %H' # $PGPOOLHOME'/scripts/failover.sh'
```

#### failover.sh

需要有可执行权限

```
chmod 775 failover.sh
```

脚本内容

```
#!/bin/bash

export PGUSER=$USER
export PGDBNAME=postgres
log=$PGPOOLHOME'/scripts/failover.log'

SQL1='select pg_is_in_recovery from pg_is_in_recovery();'

db_role=`echo $SQL1 | psql -At -U $PGUSER -d $PGDBNAME`

# "t" means standby
# "f" means primary
# 为备库时切换为主库
if [ $db_role == t ]; then
        echo -e `date +"%F %T"` "Attention:The current database is statndby,ready to switch master database!" >> $log
        pg_ctl promote -D $PGDATA
        echo -e `date +"%F %T"` "success:The current standby database successed to switched the primary PG database !" >> $log
        psql -U $PGUSER -d PGDBNAME -p 9999
        exit 0
fi

```



#### pool_hba.conf

```
host all all 0.0.0.0/0 md5
```

#### pcp.conf

添加 pgsql 的用户和密码

```
pg_md5 密码
xxxxxxxxxxxx # 此处是根据密码为生成的随机码，将随机码按以下方式加入到 pcp.conf 中
```

文件内容

```
ctgcache:xxxxxxxxxxx
```

#### pool_passwd

可通过 

```
pg_md5 -m -u 用户名 密码

# 或者

pg_md5 -m -p -u 用户名
输入密码：
```

生成 poolpasswd 文件

### 2.2、备库上安装 PGPOOL

```
./configure --prefix=$PGPOOLHOME

make -j4 # 选择小于等于 cpu的核数

make install
```

同上

### 2.3 pgpool 的启动/停止/重载命令

pgpool 的启动

```
pgpool -n -d -D > $PGPOOLHOME/log/pgpool/pgpool.log 2>&1 &
```

pgpool 的停止

```
pgpool -m fast stop
```

pgpool 的重载

```
pgpool -m fast reload
```

