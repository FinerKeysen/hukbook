# PgSQL 日志

> 参考：
>
> [Postgresql日志收集](https://www.cnblogs.com/alianbog/p/5596921.html)

PG安装后默认不会记录日志，需要在 postgresql.conf 中配置。

## 日志配置

```
logging_collector = on/off  ----  是否将日志重定向至文件中，默认是off（该配置修改后，需要重启DB服务）
```



```
log_directory = 'pg_log' ---- 日志文件目录，默认是PGDATA的相对路径，即{PGDATA}/pg_log，也可以改为绝对路径
```

默认为 `${PGDATA}/pg_log` ，即集群目录下，但是日志文件可能会非常多，建议将日志重定向到其他目录或分区。

将此配置修改为 `/var/log/pg_log` 下，必须先创建此目录，并修改权限，如

```
[root@localhost ~]# mkdir -p /var/log/pg_log
[root@localhost ~]# chown postgres:postgres /var/log/pg_log/
[root@localhost ~]# chmod 700 /var/log/pg_log/
```

重启DB服务后，日志将重定向至/var/log/pg_log下.



```
log_filename = 'postgresql-%Y-%m-%d_%H%M%S.log' ---- 日志文件命名形式，使用默认即可
log_rotation_age = 1d ----  单个日志文件的生存期，默认1天，在日志文件大小没有达到log_rotation_size时，一天只生成一个日志文件
log_rotation_size = 10MB  ---- 单个日志文件的大小，如果时间没有超过log_rotation_age，一个日志文件最大只能到10M，否则将新生成一个日志文件
log_truncate_on_rotation = off ---- 当日志文件已存在时，该配置如果为off，新生成的日志将在文件尾部追加，如果为on，则会覆盖原来的日志
log_lock_waits = off ---- 控制当一个会话等待时间超过deadlock_timeout而被锁时是否产生一个日志信息。在判断一个锁等待是否会影响性能时是有用的，缺省是off
log_statement = 'none' # none, ddl, mod, all ---- 控制记录哪些SQL语句。none不记录，ddl记录所有数据定义命令，比如CREATE,ALTER,和DROP语句。mod记录所有ddl语句,加上数据修改语句INSERT,UPDATE等,all记录所有执行的语句，将此配置设置为all可跟踪整个数据库执行的SQL语句
log_duration = off ---- 记录每条SQL语句执行完成消耗的时间，将此配置设置为on,用于统计哪些SQL语句耗时较长
log_min_duration_statement = -1 # -1表示不可用，0将记录所有SQL语句和它们的耗时，>0只记录那些耗时超过（或等于）这个值（ms）的SQL语句。个人更喜欢使用该配置来跟踪那些耗时较长，可能存在性能问题的SQL语句。虽然使用log_statement和log_duration也能够统计SQL语句及耗时，但是SQL语句和耗时统计结果可能相差很多行，或在不同的文件中，但是log_min_duration_statement会将SQL语句和耗时在同一行记录，更方便阅读
log_connections = off ----是否记录连接日志
log_disconnections = off ---- 是否记录连接断开日志
log_line_prefix = '%m %p %u %d %r ' ---- 日志输出格式（%m,%p实际意义配置文件中有解释）,可根据自己需要设置（能够记录时间，用户名称，数据库名称，客户端IP和端口，方便定位问题）
log_timezone = 'Asia/Shanghai' ---- 日志时区，最好和服务器设置同一个时区，方便问题定位服务器时区设置

```