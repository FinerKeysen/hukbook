# 包安装—在 CentOS 上安装 SQL Server 2017

> 参考
>
> [快速入门：在 Red Hat 上安装 SQL Server 并创建数据库](https://docs.microsoft.com/zh-cn/sql/linux/quickstart-install-connect-red-hat?view=sql-server-linux-2017)
>
> [Linux 上的 SQL Server 的安装指南](https://docs.microsoft.com/zh-cn/sql/linux/sql-server-linux-setup?view=sql-server-ver15&viewFallbackFrom=sql-server-2016)
>
> [对 Linux 上的 SQL Server 进行故障排除](https://docs.microsoft.com/zh-cn/sql/linux/sql-server-linux-troubleshooting-guide?view=sql-server-ver15#connection)

## 准备

- 如果以前安装了 SQL Server 2017 的 CTP 或 RC 版本，则必须先删除旧存储库，然后再执行这些步骤。 有关详细信息，请参阅[为 SQL Server 2017 和 2019 配置 Linux 存储库](https://docs.microsoft.com/zh-cn/sql/linux/sql-server-linux-change-repo?view=sql-server-ver15)

- centos 7.6 x64 
  参阅 [Linux 上的 SQL Server 的系统要求](https://docs.microsoft.com/zh-cn/sql/linux/sql-server-linux-setup?view=sql-server-ver15#system)

## 安装 SQL Server

1、如果没有 root 权限，那么可以在某用户（如 ctgcache）下用 sudo 来提升权限，但前提是该用户已被授权，也即是在 /etc/sudoers 中有备案，备案的过程需要 root 权限

添加某用户并授权的方法：[Centos7添加用户和用户组，并加sudo权限](https://blog.csdn.net/qq_40384985/article/details/90055394)

2、下载 Microsoft SQL Server 2017 Red Hat 存储库配置文件

```bash
sudo curl -o /etc/yum.repos.d/mssql-server.repo https://packages.microsoft.com/config/rhel/7/mssql-server-2017.repo
```

3、运行以下命令以安装 SQL Server

```bash
sudo yum install -y mssql-server
```

以下 SQL Server 2017 版本是免费许可的：Evaluation、Developer 和 Express。请确保为 SA 帐户指定强密码（最少 8 个字符，包括大写和小写字母、十进制数字和/或非字母数字符号）。

4、包安装完成后，运行 **mssql-conf setup**，按照提示设置 SA 密码并选择版本

```bash
sudo /opt/mssql/bin/mssql-conf setup
```

5、完成配置后，验证服务是否正在运行

```bash
sudo systemctl status mssql-server
```

6、若要允许远程连接，请在 RHEL 的防火墙上打开 SQL Server 端口。 默认的 SQL Server 端口为 TCP 1433。 如果为防火墙使用的是 **FirewallD**，则可以使用以下命令

```bash
sudo firewall-cmd --zone=public --add-port=1433/tcp --permanent
sudo firewall-cmd --reload
```

启动、停止、重启

```bash
sudo systemctl start mssql-server
sudo systemctl stop mssql-server
sudo systemctl restart mssql-server
```



## 安装 SQL Server 命令行工具

若要创建数据库，需使用可在 SQL Server 上运行 Transact-SQL 语句的工具进行连接。 以下步骤将安装 SQL Server 命令行工具：[sqlcmd](https://docs.microsoft.com/zh-cn/sql/tools/sqlcmd-utility?view=sql-server-ver15) 和 [bcp](https://docs.microsoft.com/zh-cn/sql/tools/bcp-utility?view=sql-server-ver15)

1、下载 Microsoft Red Hat 存储库配置文件

```bash
sudo curl -o /etc/yum.repos.d/msprod.repo https://packages.microsoft.com/config/rhel/7/prod.repo
```

2、如果安装了早期版本的 **mssql-tools**，请删除所有旧的 unixODBC 包

```bash
sudo yum remove unixODBC-utf16 unixODBC-utf16-devel
```

3、运行以下命令，以使用 unixODBC 开发人员包安装 **mssql-tools**

```bash
sudo yum install -y mssql-tools unixODBC-devel
```

4、为方便起见，向 **PATH** 环境变量添加 `/opt/mssql-tools/bin/`。 这样就可以在不指定完整路径的情况下运行工具。 运行以下命令，以修改登录会话和交互式/非登录会话的 **PATH**

```bash
echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bash_profile
echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bashrc
source ~/.bashrc
```

## 本地连接

示例：使用 sqlcmd  本地连接到新的 SQL Server 实例

1、使用 SQL Server 名称 (-S)，用户名 (-U) 和密码 (-P) 的参数运行 sqlcmd  。 在本教程中，用户进行本地连接，因此服务器名称为 `localhost/127.0.0.1/本机ip`。 用户名为 `SA`，密码是在安装过程中为 SA 帐户提供的密码

```bash
sqlcmd -S localhost -U SA -P '<YourPassword>'
```

可以在命令行上省略密码，以收到密码输入提示。如果以后决定进行远程连接，请指定 -S  参数的计算机名称或 IP 地址，并确保防火墙上的端口 1433 已打开。

2、如果成功，应会显示 sqlcmd  命令提示符：`1>`。

3、如果连接失败，先尝试诊断错误消息中所述的问题。 然后查看[连接故障排除建议](https://docs.microsoft.com/zh-cn/sql/linux/sql-server-linux-troubleshooting-guide?view=sql-server-ver15#connection)。

## 远程连接

同上，连接要操作的主机 ip ，初始数据库为 master， 默认端口 1433

在使用 navicat premium 12.1.22 来连接 SQL Server 时连接错误信息

```
[navicat premium] [IM002] [Microsoft][ODBC 驱动程序管理器] 未发现数据源名称并且未指定默认驱动程序
```

解决办法

在安装目录下找到 navicat 自带 sqlncli_x64.msi 驱动程序即可



