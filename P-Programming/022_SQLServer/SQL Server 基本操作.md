# SQL Server 基础操作

[TOC]



> 参考
>
> [创建和查询数据](https://docs.microsoft.com/zh-cn/sql/linux/quickstart-install-connect-red-hat?view=sql-server-linux-2017#create-and-query-data)

逐步介绍如何使用 sqlcmd  新建数据库、添加数据并运行简单查询。

## [新建数据库](https://docs.microsoft.com/zh-cn/sql/relational-databases/databases/create-a-database?view=sql-server-2016)

以下步骤创建一个名为 `TestDB` 的新数据库。

1、在 sqlcmd  命令提示符中，粘贴以下 Transact-SQL 命令以创建测试数据库

```mssql
CREATE DATABASE TestDB
```

2、在下一行中，编写一个查询以返回服务器上所有数据库的名称

```mssql
SELECT Name from sys.Databases
```

3、前两个命令没有立即执行。 必须在新行中键入 `GO` 才能执行以前的命令

```mssql
GO
```

若要详细了解如何编写 Transact-SQL 语句和查询，请参阅[教程：编写 Transact-SQL 语句](https://docs.microsoft.com/zh-cn/sql/t-sql/tutorial-writing-transact-sql-statements?view=sql-server-ver15)。

### 插入数据

接下来创建一个新表 `Inventory`，然后插入两个新行

1、在 sqlcmd  命令提示符中，将上下文切换到新的 `TestDB` 数据库

```mssql
USE TestDB
```

2、创建名为 `Inventory` 的新表

```mssql
CREATE TABLE Inventory (id INT, name NVARCHAR(50), quantity INT)
```

3、将数据插入新表

```mssql
INSERT INTO Inventory VALUES (1, 'banana', 150); 
INSERT INTO Inventory VALUES (2, 'orange', 154);
```

4、要执行上述命令的类型 `GO`

```mssql
GO
```

### 选择数据

运行查询以从 `Inventory` 表返回数据

1、通过 sqlcmd  命令提示符输入查询，以返回 `Inventory` 表中数量大于 152 的行

```mssql
SELECT * FROM Inventory WHERE quantity > 152;
```

2、执行命令

```mssql
GO
```

3、退出 sqlcmd 命令提示符

要结束 sqlcmd  会话，请键入 `QUIT`

```mssql
QUIT
```

## 查看所有数据库名,表名,字段名

### 获取所有数据库名

```
SELECT name FROM master..sysdatabases ORDER BY name 
```

### 获取所有表名

```
SELECT  name FROM databasename..sysobjects WHERE XType='U' ORDER BY name
XType='U':表示所有用户表;
XType='S':表示所有系统表;
```

### 获取所有字段名

```
SELECT name FROM syscolumns WHERE id=Object_Id('TableName')
```

### 查询各个磁盘分区的剩余空间

```
Exec master.dbo.xp_fixeddrives
```

### 查询数据库的数据文件及日志文件的相关信息

（包括文件组、当前文件大小、文件最大值、文件增长设置、文件逻辑名、文件路径等

```
select * from [数据库名].[dbo].[sysfiles]
```

转换文件大小单位为MB

```
select name, convert(float,size) * (8192.0/1024.0)/1024. from [数据库名].dbo.sysfiles
```

### 查询当前数据库的磁盘使用情况

```
Exec sp_spaceused
```

### 通过查询 sys.database_files 显示数据库的数据和日志空间信息

```
SELECT file_id, name, type_desc, physical_name, size, max_size  
FROM sys.database_files ;
```



### 查询数据库服务器各数据库日志文件的大小及利用率

```
DBCC SQLPERF(LOGSPACE)
```



## [重命名数据库](https://docs.microsoft.com/zh-cn/sql/relational-databases/databases/rename-a-database?view=sql-server-2016)

步骤包括：将数据库置于单用户模式，重命名，然后将数据库恢复多用户模式。 

```
USE master;  
GO  
ALTER DATABASE MyTestDatabase SET SINGLE_USER WITH ROLLBACK IMMEDIATE
GO
ALTER DATABASE MyTestDatabase MODIFY NAME = MyTestDatabaseCopy ;
GO  
ALTER DATABASE MyTestDatabaseCopy SET MULTI_USER
GO
```

### [单用户模式](https://docs.microsoft.com/zh-cn/sql/relational-databases/databases/set-a-database-to-single-user-mode?view=sql-server-2016)

- 如果其他用户在您将数据库设置为单用户模式时连接到了数据库，则他们与数据库的连接将被关闭，且不发出警告。
- 即使设置此选项的用户已注销，数据库仍保持单用户模式。 这时，其他用户（但只能是一个）可以连接到数据库。

## [查询设置兼容级别](https://docs.microsoft.com/zh-cn/sql/relational-databases/databases/view-or-change-the-compatibility-level-of-a-database?view=sql-server-2016)



## [备份与还原](https://docs.microsoft.com/zh-cn/sql/relational-databases/backup-restore/quickstart-backup-restore-database?view=sql-server-2016)

