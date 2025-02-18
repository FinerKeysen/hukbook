# SQL Server 创建数据库脚本解析

该脚本通过 MSSMS（Microsoft SQL Server Management Studio）创建数据库时生成

示例：创建名为 db_study 的数据库

```
CREATE DATABASE [db_study]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'db_study', FILENAME = N'/var/opt/mssql/data/db_study.mdf' , SIZE = 8192KB , FILEGROWTH = 65536KB )
 LOG ON 
( NAME = N'db_study_log', FILENAME = N'/var/opt/mssql/data/db_study_log.ldf' , SIZE = 8192KB , FILEGROWTH = 65536KB )
 COLLATE SQL_Latin1_General_CP1251_CI_AS --字符集排序规则
GO
ALTER DATABASE [db_study] SET COMPATIBILITY_LEVEL = 140 --兼容级别
GO
ALTER DATABASE [db_study] SET ANSI_NULL_DEFAULT OFF -- ANSI NULL 默认值 不启用
GO
ALTER DATABASE [db_study] SET ANSI_NULLS OFF -- ANSI NULLS 不启用
GO
ALTER DATABASE [db_study] SET ANSI_PADDING OFF -- ANSI 填充 不启用
GO
ALTER DATABASE [db_study] SET ANSI_WARNINGS OFF -- ANSI 警告 不启用
GO
ALTER DATABASE [db_study] SET ARITHABORT OFF -- 算术中止 不启用
GO
ALTER DATABASE [db_study] SET AUTO_CLOSE OFF -- 自动关闭 不启用
GO
ALTER DATABASE [db_study] SET AUTO_SHRINK OFF -- 自动收缩 不启用
GO
ALTER DATABASE [db_study] SET AUTO_CREATE_STATISTICS ON(INCREMENTAL = OFF) -- 自动创建统计信息 启用
GO
ALTER DATABASE [db_study] SET AUTO_UPDATE_STATISTICS ON -- 自动更新统计信息 启用
GO
ALTER DATABASE [db_study] SET CURSOR_CLOSE_ON_COMMIT OFF -- 提交时关闭游标功能 不启用
GO
ALTER DATABASE [db_study] SET CURSOR_DEFAULT  GLOBAL -- 默认游标 GLOBAL
GO
ALTER DATABASE [db_study] SET CONCAT_NULL_YIELDS_NULL OFF -- 串联的 NULL 结果为 NULL 不启用
GO
ALTER DATABASE [db_study] SET NUMERIC_ROUNDABORT OFF -- 数值舍入中止 不启用
GO
ALTER DATABASE [db_study] SET QUOTED_IDENTIFIER OFF -- 允许带引号的标识符 不启用 
GO
ALTER DATABASE [db_study] SET RECURSIVE_TRIGGERS OFF -- 递归触发器 不启用
GO
ALTER DATABASE [db_study] SET  DISABLE_BROKER -- Broker 不启用
GO
ALTER DATABASE [db_study] SET AUTO_UPDATE_STATISTICS_ASYNC OFF -- 自动异步更新统计信息 不启用
GO
ALTER DATABASE [db_study] SET DATE_CORRELATION_OPTIMIZATION OFF -- 日期相关性优化 不启用
GO
ALTER DATABASE [db_study] SET PARAMETERIZATION SIMPLE -- 参数化 SIMPLE
GO
ALTER DATABASE [db_study] SET READ_COMMITTED_SNAPSHOT OFF -- 读提交快照处于打开状态 不启用
GO
ALTER DATABASE [db_study] SET  READ_WRITE -- 数据库可读写
GO
ALTER DATABASE [db_study] SET RECOVERY FULL -- 恢复模式 完整
GO
ALTER DATABASE [db_study] SET  MULTI_USER -- 限制访问 多用户
GO
ALTER DATABASE [db_study] SET PAGE_VERIFY CHECKSUM  -- 页验证 CHECKSUM
GO
ALTER DATABASE [db_study] SET TARGET_RECOVERY_TIME = 60 SECONDS -- 目标恢复时间(秒) 60
GO
ALTER DATABASE [db_study] SET DELAYED_DURABILITY = DISABLED -- 延迟持久性 Disabled
GO


USE [db_study]
GO
ALTER DATABASE SCOPED CONFIGURATION SET LEGACY_CARDINALITY_ESTIMATION = Off; -- 早期基数估计 关闭
GO
ALTER DATABASE SCOPED CONFIGURATION FOR SECONDARY SET LEGACY_CARDINALITY_ESTIMATION = Primary; -- 辅助早期基数估计 主要
GO
ALTER DATABASE SCOPED CONFIGURATION SET MAXDOP = 0; -- Max DOP 0
GO
ALTER DATABASE SCOPED CONFIGURATION FOR SECONDARY SET MAXDOP = PRIMARY; -- 辅助 Max DOP 主要
GO
ALTER DATABASE SCOPED CONFIGURATION SET PARAMETER_SNIFFING = On; -- 参数探查 打开
GO
ALTER DATABASE SCOPED CONFIGURATION FOR SECONDARY SET PARAMETER_SNIFFING = Primary; -- 辅助参数探查 主要
GO
ALTER DATABASE SCOPED CONFIGURATION SET QUERY_OPTIMIZER_HOTFIXES = Off; -- 查询优化器修补程序 关闭
GO
ALTER DATABASE SCOPED CONFIGURATION FOR SECONDARY SET QUERY_OPTIMIZER_HOTFIXES = Primary; -- 辅助查询优化器修补程序 主要
GO

-- 文件组设置
USE [db_study]
GO
IF NOT EXISTS (SELECT name FROM sys.filegroups WHERE is_default=1 AND name = N'PRIMARY') ALTER DATABASE [db_study] MODIFY FILEGROUP [PRIMARY] DEFAULT
GO

```

