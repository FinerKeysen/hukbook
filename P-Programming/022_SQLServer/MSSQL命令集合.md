## 查某数据库的文件空间使用率

```mssql
-------------------------------
-- 可查某数据库的文件空间使用率
-------------------------------

use tempdb;
SELECT a.name [文件名称]
  ,cast(a.[size]*1.0/128 as decimal(12,2)) AS [文件设置大小(MB)]
  ,CAST( fileproperty(s.name,'SpaceUsed')/(8*16.0) AS DECIMAL(12,2)) AS [文件所占空间(MB)]
  ,CAST( (fileproperty(s.name,'SpaceUsed')/(8*16.0))/(s.size/(8*16.0))*100.0 AS DECIMAL(12,2)) AS [所占空间率%]
  ,CASE WHEN A.growth =0 THEN '文件大小固定，不会增长' ELSE '文件将自动增长' end [增长模式]
  ,CASE WHEN A.growth > 0 AND is_percent_growth = 0 THEN '增量为固定大小'
    WHEN A.growth > 0 AND is_percent_growth = 1 THEN '增量将用整数百分比表示'
    ELSE '文件大小固定，不会增长' END AS [增量模式]
  ,CASE WHEN A.growth > 0 AND is_percent_growth = 0 THEN cast(cast(a.growth*1.0/128as decimal(12,0)) AS VARCHAR)+'MB'
    WHEN A.growth > 0 AND is_percent_growth = 1 THEN cast(cast(a.growth AS decimal(12,0)) AS VARCHAR)+'%'
    ELSE '文件大小固定，不会增长' end AS [增长值(%或MB)]
  ,a.physical_name AS [文件所在目录]
  ,a.type_desc AS [文件类型]
FROM sys.database_files a
INNER JOIN sys.sysfiles AS s ON a.[file_id]=s.fileid
LEFT JOIN sys.dm_db_file_space_usage b ON a.[file_id]=b.[file_id]
ORDER BY a.[type]
```



## 查一些指标

```mssql
--------------------------------------
-- 查一些指标
--------------------------------------

SELECT TOP 10
    [session_id],
    [request_id],
    [start_time] AS '开始时间',
    [status] AS '状态',
    [command] AS '命令',
    dest.[text] AS 'sql语句', 
    DB_NAME([database_id]) AS '数据库名',
    [blocking_session_id] AS '正在阻塞其他会话的会话ID',
    [wait_type] AS '等待资源类型',
    [wait_time] AS '等待时间',
    [wait_resource] AS '等待的资源',
    [reads] AS '物理读次数',
    [writes] AS '写次数',
    [logical_reads] AS '逻辑读次数',
    [row_count] AS '返回结果行数'
FROM sys.[dm_exec_requests] AS der 
CROSS APPLY 
	sys.[dm_exec_sql_text](der.[sql_handle]) AS dest 
WHERE [session_id]>50 AND DB_NAME(der.[database_id])='gposdb' 
ORDER BY [cpu_time] DESC
```



## 查看是哪些SQL语句占用较大

```mssql
---------------------------------
-- 查看是哪些SQL语句占用较大 
---------------------------------

SELECT TOP 10 
	dest.[text] AS 'sql语句'
FROM sys.[dm_exec_requests] AS der 
CROSS APPLY 
	sys.[dm_exec_sql_text](der.[sql_handle]) AS dest 
WHERE [session_id]>50 
ORDER BY [cpu_time] DESC
```



## 显示出会话中worker等待数

```mssql
-------------------------------------------
-- 如果SQLSERVER存在要等待的资源，那么执行下
-- 面语句就会显示出会话中有多少个worker在等待
-------------------------------------------

SELECT TOP 10
    [session_id],
    [request_id],
    [start_time] AS '开始时间',
    [status] AS '状态',
    [command] AS '命令',
    dest.[text] AS 'sql语句', 
    DB_NAME([database_id]) AS '数据库名',
    [blocking_session_id] AS '正在阻塞其他会话的会话ID',
    der.[wait_type] AS '等待资源类型',
    [wait_time] AS '等待时间',
    [wait_resource] AS '等待的资源',
    [dows].[waiting_tasks_count] AS '当前正在进行等待的任务数',
    [reads] AS '物理读次数',
    [writes] AS '写次数',
    [logical_reads] AS '逻辑读次数',
    [row_count] AS '返回结果行数'
FROM sys.[dm_exec_requests] AS der 
INNER JOIN [sys].[dm_os_wait_stats] AS dows 
ON der.[wait_type]=[dows].[wait_type]
CROSS APPLY 
	sys.[dm_exec_sql_text](der.[sql_handle]) AS dest 
WHERE [session_id]>50 
ORDER BY [cpu_time] DESC
```



## 查询CPU占用最高的SQL语句

```mssql
--------------------------------------------
-- 查询CPU占用最高的SQL语句
--------------------------------------------

SELECT TOP 10
  total_worker_time/execution_count AS avg_cpu_cost, plan_handle,
  execution_count,
  (SELECT SUBSTRING(text, statement_start_offset/2 + 1,
   (CASE WHEN statement_end_offset = -1
     THEN LEN(CONVERT(nvarchar(max), text)) * 2
     ELSE statement_end_offset
   END - statement_start_offset)/2)
  FROM sys.dm_exec_sql_text(sql_handle)) AS query_text
FROM sys.dm_exec_query_stats
ORDER BY [avg_cpu_cost] DESC
```



## 索引缺失查询

```mssql
--------------------------------------------
-- 索引缺失查询
--------------------------------------------

SELECT 
  DatabaseName = DB_NAME(database_id)
  ,[Number Indexes Missing] = count(*) 
FROM sys.dm_db_missing_index_details
GROUP BY DB_NAME(database_id)
ORDER BY 2 DESC;

SELECT TOP 10 
    [Total Cost] = ROUND(avg_total_user_cost * avg_user_impact * (user_seeks + user_scans),0) 
    , avg_user_impact
    , TableName = statement
    , [EqualityUsage] = equality_columns 
    , [InequalityUsage] = inequality_columns
    , [Include Cloumns] = included_columns
FROM    sys.dm_db_missing_index_groups g 
INNER JOIN  sys.dm_db_missing_index_group_stats s 
    ON s.group_handle = g.index_group_handle 
INNER JOIN  sys.dm_db_missing_index_details d 
    ON d.index_handle = g.index_handle
ORDER BY [Total Cost] DESC;
```



## 打开 SERVER 代理

```mssql
-------------------------------------
-- 打开 SERVER 代理
-------------------------------------

exec sp_configure 'show advanced options', 1; 
GO 
RECONFIGURE; 
GO 
exec sp_configure 'Agent XPs', 1; 
GO 
RECONFIGURE 
GO
```



## TOP N 查询

### 按平均 CPU 时间返回排名前五个的查询

```mssql
-------------------------------------
-- 查找 TOP N 查询
-- 按平均 CPU 时间返回排名前五个的查询
-------------------------------------

SELECT TOP 5 query_stats.query_hash AS "Query Hash",   
    SUM(query_stats.total_worker_time) / SUM(query_stats.execution_count) AS "Avg CPU Time",  
    MIN(query_stats.statement_text) AS "Statement Text"  
FROM   
    (SELECT QS.*,   
    SUBSTRING(ST.text, (QS.statement_start_offset/2) + 1,  
    ((CASE statement_end_offset   
        WHEN -1 THEN DATALENGTH(ST.text)  
        ELSE QS.statement_end_offset END   
            - QS.statement_start_offset)/2) + 1) AS statement_text  
     FROM sys.dm_exec_query_stats AS QS  
     CROSS APPLY sys.dm_exec_sql_text(QS.sql_handle) as ST) as query_stats  
GROUP BY query_stats.query_hash  
ORDER BY 2 DESC;
```



### 查看CPU占用量最高的会话及SQL语句

```mssql
select spid,cmd,cpu,physical_io,memusage,
(select top 1 [text] from ::fn_get_sql(sql_handle)) sql_text
from master..sysprocesses order by cpu desc,physical_io desc
```



### 查看缓存重用次数少，内存占用大的SQL语句

```mssql
SELECT TOP 100 usecounts, objtype, p.size_in_bytes,[sql].[text] 
FROM sys.dm_exec_cached_plans p OUTER APPLY sys.dm_exec_sql_text (p.plan_handle) sql 
ORDER BY usecounts,p.size_in_bytes  desc
```



## sys.dm_exec_query_stats

```mssql
-------------------------------------------------
-- 
-- 源自：https://social.technet.microsoft.com/wiki/contents/articles/3214.monitoring-disk-usage.aspx
-------------------------------------------------
SELECT TOP 25 
	execution_count, plan_generation_num, last_execution_time,
    total_worker_time, last_worker_time, min_worker_time, max_worker_time,
    total_logical_reads, last_logical_reads, min_logical_reads, max_logical_reads,
    total_physical_reads, last_physical_reads, min_physical_reads, max_physical_reads,
    total_logical_writes, last_logical_writes, min_logical_writes, max_logical_writes,
    total_elapsed_time, last_elapsed_time, min_elapsed_time, max_elapsed_time,
    (SUBSTRING(s2.text,  statement_start_offset / 2, ( (CASE WHEN statement_end_offset = -1 THEN (LEN(CONVERT(nvarchar(max),s2.text)) * 2) ELSE statement_end_offset END)  - statement_start_offset) / 2)  )  AS sql_statement,
    text, p.query_plan
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.plan_handle) s2
CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) P
ORDER BY total_physical_reads DESC
```



```mssql
select * from sys.sysperfinfo 
  where 
  --object_name = 'SQLServer:Databases' and 
  instance_name = '_Total';
use master;
```



## 内存使用

```mssql
-- ===============================================
-- 内存使用
-- ===============================================
Tasklist /FI "IMAGENAME eq sqlservr.exe"
-- output
映像名称            PID 会话名       会话#    内存使用
========================= ======== ================ =========== ============
sqlservr.exe         1616 Services          0  698,432 K
```



## 进程信息

```mssql
-- ===============================================
-- 进程信息
-- ===============================================
wmic process where caption="sqlservr.exe"
```



## 操作系统相关

```mssql
-- 返回一组有关计算机和有关 SQL Server 可用资源及其已占用资源的有用杂项信息
select * from sys.dm_os_sys_info;

-- 从操作系统返回内存信息
select * from sys.dm_os_sys_memory;

-- 返回在 SQL Server 进程中运行的所有 SQL Server 操作系统线程的列表
select* from sys.dm_os_threads;

-- 操作系统版本信息
select * from sys.dm_os_windows_info;
```



## 连接数

### 最大连接数

```mssql
-- ================================
-- 查最大连接数
-- ================================
SELECT @@MAX_CONNECTIONS
```



### 各数据库的连接数

```mssql
-- ================================
-- 查所有数据库的连接数
-- ================================
SELECT name ,count(*) FROM (
SELECT b.name,a.* FROM [Master].[dbo].[SYSPROCESSES] a 
INNER JOIN [Master].[dbo].[SYSDATABASES] b 
ON a.dbid=b.dbid
)t 
GROUP BY t.name
```



### 指定数据库的连接数查询

```mssql
-- ================================
-- 当前数据库连接数
-- ================================
SELECT * FROM 
[Master].[dbo].[SYSPROCESSES] WHERE [DBID] 
IN 
(
  SELECT 
   [DBID]
  FROM 
   [Master].[dbo].[SYSDATABASES] 
  WHERE 
   NAME='你的数据库名称'
)
```



### 并发连接数

```mssql
-- 并发连接数
select hostname,count(*) hostconncount from master.dbo.sysprocesses
group by hostname order by count(*) desc;
```



## 查询数据库

```mssql
-- ================================
-- 查询非系统的数据库
-- ================================
select * FROM master..sysdatabases WHERE name not in ('master','model','msdb','tempdb');
-- 等价于
SELECT * from sys.Databases WHERE name not in ('master','model','msdb','tempdb');

-- 查当前实例下的所有数据库
select * from sys.databases;

-- 同上，查看所有数据库名称与大小
exec sp_helpdb;
-- 或者
SELECT database_id AS DataBaseId ,
       DB_NAME(database_id) AS DataBaseName ,
       CAST(SUM(SIZE) * 8.0 / 1024 AS DECIMAL(8, 4)) AS [Size(MB)]
  FROM sys.master_files 
  GROUP BY database_id;

-- 同上，查看数据库的信息
select * from sys.sysdatabases;

-- 查看表的信息
exec sp_help N'apple.dbo.Table_1';
```



## 当前数据库中某对象的用户权限或语句权限的信息

```mssql
use [apple]
GO

EXEC sp_helprotect;
GO
```

## 返回 SQL Server 固定服务器角色的列表

```mssql
exec SP_HELPSRVROLE;
```

## SQL Server 固定服务器角色成员的信息

```mssql
exec sp_helpsrvrolemember;

exec sp_helprolemember 'db_owner';
```

## 返回当前数据库中有关角色的信息

```
exec sp_helpuser;
```

## 当前数据库中数据库级主体的信息

```mssql
USE [orange];
exec sp_helpuser;

-- or
exec sp_helpuser N'orange';
```

## 列出明确对数据库主体授予或拒绝的权限

```mssql
-- 列出明确对数据库主体授予或拒绝的权限
SELECT pr.principal_id, pr.name, pr.type_desc,   
   pr.authentication_type_desc, pe.state_desc, pe.permission_name  
FROM sys.database_principals AS pr  
JOIN sys.database_permissions AS pe  
   ON pe.grantee_principal_id = pr.principal_id; 
```



## 查当前数据库的所有用户和角色，及其授权情况

```mssql
-- 查当前数据库的所有用户和角色，及其授权情况
use [apple];
-- https://docs.microsoft.com/zh-cn/sql/relational-databases/system-catalog-views/sys-database-principals-transact-sql?view=sql-server-2016
select * from sys.database_principals;

-- https://docs.microsoft.com/zh-cn/sql/relational-databases/system-catalog-views/sys-database-permissions-transact-sql?view=sql-server-2016
select * from sys.database_permissions;
```

## 每个数据库中的登录名以及与其相关的用户的信息

```mssql
-- 查看所有登录名信息
-- 结果集有两个：一是登录名本身具有的基本属性；二是登录名在数据库下映射的数据库用户、角色的基本信息
exec sp_helplogins;
-- 也可指定登录名
exec sp_helplogins N'yuan';
```

### 指定数据库或所有数据库的信息

```mssql
exec sp_helpdb N'apple';
```

## 查看所有的登录名、会话、进程

```mssql
-- 查看所有的登录名、会话、进程
-- https://docs.microsoft.com/zh-cn/sql/relational-databases/system-stored-procedures/sp-who-transact-sql?view=sql-server-2016
EXEC sp_who;
 
-- 查看指定登录名及进程
EXEC sp_who 'baidu';
-- 查看所有活动进程
EXEC sp_who 'active';
```



## 查看数据库中对象的磁盘使用情况

```mssql
use apple;
-- 查看数据库中对象的磁盘使用情况，未指定对象时，返回整个数据库的结果
-- https://docs.microsoft.com/zh-cn/sql/relational-databases/system-stored-procedures/sp-spaceused-transact-sql?view=sql-server-2016
EXEC sp_spaceused @oneresultset=1;
-- 指定对象
EXEC sp_spaceused @objname=N'Table_1';
```

## 查看数据库启动的相关参数

```mssql
-- 查看数据库启动的相关参数
EXEC sp_configure;
```

## 查看数据库启动的相关参数

```mssql
-- 查看数据库启动的相关参数
EXEC sp_configure;
```

## 查看服务器启动时间

```mssql
-- 查看服务器启动时间
SELECT CONVERT(VARCHAR(30), LOGIN_TIME,120) AS StartDateTime
FROM master..sysprocesses WHERE spid=1;
```

## 查看所有登录名所属的服务器角色（不包含public）信息

```mssql
-- 查看所有登录名所属的服务器角色（不包含public）信息
exec sp_helpsrvrolemember;
-- 查看链接服务器
EXEC sp_helplinkedsrvlogin;
```

## 查看数据库的数据文件信息

```mssql
-- 查看数据库实例各个数据库的数据文件信息
SELECT database_id                 AS DataBaseId,
    DB_NAME(database_id)           AS DataBaseName,
    Name                           AS LogicalName,
    type_desc                      AS FileTypeDesc,
    Physical_Name                  AS PhysicalName,
    State_Desc                     AS StateDesc ,
    CASE WHEN max_size = 0  THEN N'不允许增长'
         WHEN max_size = -1 THEN N'自动增长'
         ELSE LTRIM(STR(max_size * 8.0 / 1024 / 1024, 14, 2)) + 'G'
    END                            AS MaxSize ,
    CASE WHEN is_percent_growth = 1
         THEN RTRIM(CAST(Growth AS CHAR(10))) + '%'
         ELSE RTRIM(CAST(Growth AS CHAR(10))) + 'M'
    END                            AS Growth ,
    Is_Read_Only                   AS IsReadOnly ,
    Is_Percent_Growth              AS IsPercentGrowth ,
    CAST(size * 8.0 / 1024 AS DECIMAL(8, 4)) AS [Size(MB)]
FROM sys.master_files;

-- 通过数据库名称查看数据文件
SELECT fileid      AS FileId,
     groupid      AS GroupId,
     size         AS DataBaseSize,
     growth       AS Growth, 
     perf         AS Perf,
     name         AS NAME,
     filename     AS FILENAME
FROM  apple.dbo.sysfiles ;
```



## 查服务器名称

```mssql
-- 查服务器名称
SELECT @@SERVERNAME AS SERVERNAME;
SELECT SERVERPROPERTY('servername') AS ServerName;
SELECT srvname AS ServerName FROM sys.sysservers;
```

### 查命名实例

```mssql
SELECT ISNULL(SERVERPROPERTY('InstanceName'),'MSSQLSERVER') AS InstanceName;

-- 只对命名实例有效
SELECT SUBSTRING(@@SERVERNAME,CHARINDEX('\', @@SERVERNAME)+1,100) AS InstantName;

SELECT SUBSTRING(srvname, CHARINDEX('\', srvname) +1, 100) AS InstantName FROM sys.sysservers;
```

## 查看数据库版本号

```mssql
-- 查看数据库版本号
SELECT  SERVERPROPERTY('productversion') AS ProductVersion ,
        SERVERPROPERTY('productlevel') AS ProductLevel ,
        SERVERPROPERTY('edition') AS Edition;
        
SELECT @@VERSION AS PRODUCT_VERSION;
```



## 查看数据库服务器各数据库日志文件的大小及利用率/状态

```mssql
-- 查看数据库服务器各数据库日志文件的大小及利用率/状态
DBCC SQLPERF(LOGSPACE);
-- 或
EXEC ('DBCC SQLPERF(LOGSPACE)');
```



## 查看当前数据库的文件状态

```mssql
-- 查看当前数据库的文件状态
EXEC ('DBCC showfilestats');
```

## 查看数据库存储过程

```mssql
-- 查看数据库存储过程
-- 方法1
EXEC sp_stored_procedures;
 
-- 方法2
SELECT * FROM sys.procedures;
 
-- 方法3
SELECT * FROM sys.sysobjects WHERE xtype='P';
```

## 查看存储过程基本信息

```mssql
-- 查看存储过程基本信息
EXEC sp_help 'sp_who';
```

## 检查数据库完整性

```mssql
-- 检查数据库完整性
DBCC checkdb(apple);
```

## 查看数据库所在机器操作系统参数

```mssql
-- 查看数据库所在机器操作系统参数
-- xp_msver 还返回有关服务器的实际内部版本号的信息以及服务器环境的有关信息，例如处理器类型(不能获取具体型号)， RAM 的容量等等
EXEC master..xp_msver;
```

## 查看数据库服务器磁盘分区剩余空间

```mssql
-- 查看数据库服务器磁盘分区剩余空间
EXEC master.dbo.xp_fixeddrives;
```

## 查看数据库服务器CPU/内存的信息

```mssql
-- 查看数据库服务器CPU/内存的信息
SELECT  cpu_count                     AS [Logical CPU Count] ,
     hyperthread_ratio               AS [Hyperthread Ratio] ,
     cpu_count / hyperthread_ratio   AS [Physical CPU Count],
     physical_memory_kb / 1024       AS [Physical Memory (MB)] ,
     sqlserver_start_time
FROM sys.dm_os_sys_info
OPTION  ( RECOMPILE ) ;
```





## 备份

### 备份与恢复

```mssql
-- 完整备份
use [apple];
use [master];
BACKUP DATABASE [apple] 
	TO  DISK = N'C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\Backup\apple\apple.bak' 
	WITH  DESCRIPTION = N'完整备份', 
		NOFORMAT, 
		INIT,  -- 覆盖现有备份集
		NAME = N'apple-完整', 
		SKIP, 
		REWIND, 
		NOUNLOAD, 
		COMPRESSION,  
		STATS = 10
GO

use [apple];
use [master];
--  事务日志备份，截断日志
BACKUP LOG [apple] 
	TO  DISK = N'C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\Backup\apple\apple.trn' 
	WITH  
		DESCRIPTION = N'事务日志备份，截断日志', 
		NOFORMAT, 
		INIT,  
		NAME = N'apple-完整', 
		SKIP, 
		REWIND, 
		NOUNLOAD, 
		COMPRESSION,  
		STATS = 10
GO

USE [master];

ALTER DATABASE [apple] SET OFFLINE WITH ROLLBACK IMMEDIATE -- 关闭连接
ALTER DATABASE [apple] SET ONLINE -- 开启连接

ALTER DATABASE [apple] SET SINGLE_USER WITH ROLLBACK IMMEDIATE -- 设置单用户模式
BACKUP LOG [apple]  -- 进行数据库结尾日志备份
	TO  
		DISK = N'C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\Backup\log\applelog.bak' 
	WITH 
		NOFORMAT, 
		NOINIT,  
		NAME = N'applelog', 
		NOSKIP, 
		REWIND, 
		NOUNLOAD,  
		NORECOVERY , 
		STATS = 5

-- 恢复数据库
RESTORE DATABASE [apple] 
	FROM  
		DISK = N'C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\Backup\apple\apple.bak' 
	WITH  
		FILE = 1, 
		NORECOVERY, 
		NOUNLOAD,  
		REPLACE, 
		STATS = 5

-- 恢复日志
RESTORE LOG [apple] 
	FROM  
		DISK = N'C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\Backup\apple\apple.trn' 
	WITH  
		FILE = 1,  
		NOUNLOAD,  
		STATS = 5

ALTER DATABASE [apple] SET MULTI_USER -- 还原为多用户模式
GO

select * from [apple].dbo.Table_1;
```



### 计划和作业

```mssql
--------------------------------------------------------------------------
-- 目标路径：
-- C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\Backup

-- 备份报告路径：
-- C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\Log
--------------------------------------------------------------------------

USE [msdb]
GO
DECLARE @jobId BINARY(16)
EXEC  msdb.dbo.sp_add_job @job_name=N'hk', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_page=2, 
		@delete_level=0, 
		@category_name=N'Database Maintenance', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
select @jobId
GO
EXEC msdb.dbo.sp_add_jobserver @job_name=N'hk', @server_name = N'VMSQLSERVER2016'
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_add_jobstep @job_name=N'hk', @step_name=N'hk_backup_apple', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_fail_action=2, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'declare @path varchar(250) 
set @path=''C:\Backup\apple_''+ 
convert(varchar(50),getdate(),112)+''.bak''
BACKUP DATABASE [apple] TO 
DISK=@path WITH NOFORMAT,NOINIT, 
NAME = N''apple-完整 数据库 备份'',
SKIP,NOREWIND,NOUNLOAD', 
		@database_name=N'master', 
		@flags=0
GO
USE [msdb]
GO
EXEC msdb.dbo.sp_update_job @job_name=N'hk', 
		@enabled=1, 
		@start_step_id=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_page=2, 
		@delete_level=0, 
		@description=N'', 
		@category_name=N'Database Maintenance', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'', 
		@notify_page_operator_name=N''
GO
USE [msdb]
GO
DECLARE @schedule_id int
EXEC msdb.dbo.sp_add_jobschedule @job_name=N'hk', @name=N'hk_backup_apple_sche', 
		@enabled=1, 
		@freq_type=8, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20191213, 
		@active_end_date=99991231, 
		@active_start_time=220000, 
		@active_end_time=235959, @schedule_id = @schedule_id OUTPUT
select @schedule_id
GO


-- 删除
EXECUTE master.dbo.xp_delete_file 
	0,
	N'C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\Backup',
	N'bak',
	N'2019-11-19T09:10:13'
```



### 指定数据库最后20条事务日志备份信息

```mssql
-- 指定数据库最后20条事务日志备份信息
SELECT TOP 20 b.physical_device_name, a.backup_start_date, a.first_lsn, a.user_name FROM msdb..backupset a
INNER JOIN msdb..backupmediafamily b ON a.media_set_id = b.media_set_id
WHERE a.type = 'L'
ORDER BY a.backup_finish_date DESC
```



### 指定时间段的事务日志备份信息

```mssql
-- 指定时间段的事务日志备份信息
SELECT b.physical_device_name, a.backup_set_id, b.family_sequence_number, a.position, a.backup_start_date, a.backup_finish_date
FROM msdb..backupset a
INNER JOIN msdb..backupmediafamily b ON a.media_set_id = b.media_set_id
WHERE a.database_name = 'AdventureWorks'
AND a.type = 'L'
AND a.backup_start_date > '10-Jan-2007'
AND a.backup_finish_date < '16-Jan-2009 3:30'
ORDER BY a.backup_start_date, b.family_sequence_number
```



### 每个数据库近期的备份信息

```mssql
---- 每个数据库近期的备份信息
SELECT b.name, a.type, MAX(a.backup_finish_date) lastbackup
FROM msdb..backupset a
INNER JOIN master..sysdatabases b ON a.database_name COLLATE DATABASE_DEFAULT = b.name COLLATE DATABASE_DEFAULT
GROUP BY b.name, a.type
ORDER BY b.name, a.type
```



### 查询SQLServer还原历史

```mssql
---- 查询SQLServer还原历史
select bus.server_name as'server',rh.restore_date,bus.database_name as'database',
CAST(bus.first_lsn AS VARCHAR(50))as LSN_First,
CAST(bus.last_lsn AS VARCHAR(50))as LSN_Last,
CASE rh.[restore_type]
WHEN 'D'THEN'Database'
WHEN 'F'THEN'File'
WHEN 'G'THEN'Filegroup'
WHEN 'I'THEN'Differential'
WHEN 'L'THEN'Log'
WHEN 'V'THEN'Verifyonly'
END AS rhType
FROM msdb.dbo.backupset bus
INNER JOIN msdb.dbo.restorehistory rh ON rh.backup_set_id=bus.backup_set_id
```



### 查询SQL Server备份历史

```mssql
---- 查询SQL Server备份历史
SELECT
   CONVERT(CHAR(100),SERVERPROPERTY('Servername'))AS Server,
   bs.database_name,
   bs.backup_start_date,
   bs.backup_finish_date,
   bs.expiration_date,
   CASE bs.type
       WHEN 'D' THEN 'Database'
       WHEN 'L' THEN 'Log'
   END AS backup_type,
   bs.backup_size,
   bmf.logical_device_name,
   bmf.physical_device_name,  
   bs.name AS backupset_name,
   bs.description
FROM msdb.dbo.backupmediafamily bmf
   INNER JOIN msdb.dbo.backupset bs ON bmf.media_set_id=bs.media_set_id
ORDER BY
   bs.database_name,
   bs.backup_finish_date
```



### 删除备份记录

```mssql
--use msdb;
---- 清除20191218之前所有的备份记录
--EXEC msdb..sp_delete_backuphistory '20191218';
---- 删除 AdventureWorks 数据库的备份还原记录
--EXEC msdb..sp_delete_database_backuphistory 'AdventureWorks'
```



### 查所有备份记录

```mssql
-- 查所有备份记录
select * from msdb..backupset;
GO
```



## 包含MicrosoftSQL Server 数据库引擎可通过 Windows 系统监视器显示的内部性能计数器的表示形式

```mssql
select * from sys.sysperfinfo;
```



## 通过性能计数器获取指定的指标

```
Get-Counter -Counter "\process(sqlservr)\io read operations/sec" -SampleInterval 1 -MaxSamples 3600
```

