# 在 VM 上安装 SQL Server 2016

# 准备

## 软件

1、Windows Server 2016镜像

```
ed2k://|file|cn_windows_server_2016_vl_x64_dvd_11636695.iso|6302720000|44742A3D464B9765203E2A4DB73FF704|/
```

2、SQL Server 2016镜像

```
ed2k://|file|cn_sql_server_2016_developer_with_service_pack_2_x64_dvd_12195013.iso|3217154048|AC379F2A852760E54316A2CDAEFCB42C|/
```

## 环境（Server Core）

参考：[安装服务器核心](https://docs.microsoft.com/zh-cn/windows-server/get-started/getting-started-with-server-core)

在虚机上安装 Windows Server 2016 系统

安装时，有以下安装选项：

- **在以下列表中，不带“桌面体验”的版本是服务器核心安装选项**

```
Windows Server Standard
带桌面体验的 Windows Server Standard
Windows Server Datacenter
带桌面体验的 Windows Server Datacenter
```

 使用“服务器核心”选项不会安装标准用户界面（桌面体验） ，将通过使用`命令行`、`Windows PowerShell `或`远程`方法来管理服务器。 

以下通过 Windows PowerShell 命令提示符进行 **本地安装、配置、卸载服务器角色** ，若使用远程方式，请进入上述参考链接。

- **Windows Server 2016 操作系统版本   KMS 客户端安装密钥**

```
Windows Server 2016 Datacenter   CB7KF-BWN84-R7R2Y-793K2-8XDDG
Windows Server 2016 Standard   WC2BQ-8NRM3-FDDYY-2BFGV-KHKQY
Windows Server 2016 Essentials   JCKRF-N37P4-C2D82-9YXRT-4M63B 
```

以管理员身份运行 Windows Powershell，根据对应版本执行以下命令

```
slmgr /ipk WC2BQ-8NRM3-FDDYY-2BFGV-KHKQY
slmgr /skms kms.03k.org
slmgr /ato
```

根据提示确认即可。

# 安装 SQL SERVER

## SQL SERVER 2017

参考：[在 Server Core 上安装 SQL Server](https://docs.microsoft.com/zh-cn/sql/database-engine/install-windows/install-sql-server-on-server-core?view=sql-server-ver15)

## SQL SERVER 2016

参考：[从命令提示符安装 SQL Server](https://docs.microsoft.com/zh-cn/sql/database-engine/install-windows/install-sql-server-from-the-command-prompt?view=sql-server-ver15)

通过命令提示符进行安装，请打开管理命令提示符，然后导航到 setup.exe 在 SQL Server 安装介质中所处的位置。 运行 `setup.exe` 命令，以及完成尝试执行的操作所必需的和可选的参数：

```
C:\SQLMedia\SQLServer2019> setup.exe /[Option] /[Option] = {value}
```



安装参数

```
/ACTION="install"  # 指示安装工作流，必需
/Q # 完全静默模式
/QS # 简单静默模式./QS 开关仅显示进度，不接受任何输入，也不显示错误消息（如果遇到）。 仅当指定 /Action=install 时才支持 /QS 参数。
/IACCEPTSQLSERVERLICENSETERMS # 必需，用于确认接受许可条款
/IACCEPTPYTHONLICENSETERMS # python支持，同上
/IACCEPTROPENLICENSETERMS # R支持，同上
/CONFIGURATIONFILE # 指定要使用的 ConfigurationFile 
```

配置文件： [configuration](https://docs.microsoft.com/zh-cn/sql/database-engine/install-windows/install-sql-server-2016-using-a-configuration-file?view=sql-server-ver15)

防火墙配置参考：[Configure the Windows Firewall to Allow SQL Server Access](https://docs.microsoft.com/zh-cn/sql/sql-server/install/configure-the-windows-firewall-to-allow-sql-server-access?redirectedfrom=MSDN&view=sql-server-ver15)





