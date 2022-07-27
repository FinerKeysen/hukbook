## 查看帮助

- [命令]/? ，如 dir/?
- help [命令]，如 help dir

## 查看盘符

在 diskpart 程序中查询，`list` 选项有：

- DISK ：显示磁盘列表。例如，LIST DISK。
- PARTITION ：显示所选磁盘上的分区列表。例如，LIST PARTITION。
- VOLUME：显示卷列表。例如，LIST VOLUME。
- VDISK：显示虚拟磁盘列表。

输入 diskpart –> 输入 list volume

## 查看 .NET Framework 版本

在 C:\Windows\Microsoft.NET\Framework 文件夹下可以看到多个文件夹，最高版本号就是当前Net Framework版本

## 修改当前计算机名称和计算机组名

 更改计算机名 AAA 为 BBB

```powershell
wmic computersystem where “name=’AAA’” call rename BBB 
```

 更改工作组 WORKGROUP 为MyGroup

```powershell
wmic computersystem where “name=’WORKGROUP’” call joindomainorworkgroup “”,”",”MyGroup”,1 
```

##  创建文件/文件夹

### 文件

#### 1、创建文件

我们可以使用 cd>a.txt，type nul>a.txt，copy nul>a.txt 三种方式创建空文件；

用 echo [file content]>a.txt 创建非空文件

```powershell
type nul > filename # 创建空文件 filename，或者清空 filename

copy nul filename # 创建空文件，或者清空 filename

echo nul > filename
```

#### 2、追加文件内容

```powershell
echo [file content] >> a.txt # 向文件a.txt中追加内容[file content]
```



#### 3、删除文件

使用del a.txt;



### 文件夹

#### 1、创建文件夹

我们可以使用` md <folderName>`或`mkdir <folderName>`命令来创建，其中md和mkdir都是建立新目录make directory的意思，

完整命令是`md [盘符:\][路径\]新目录名`，比如：`md c:\test\myfolder`

#### 2、删除文件夹

我们可以使用` rd <folderName>或rmdir <folderName>`命令来删除空文件夹(rd:remove directory)；

使用命令` rd/s <folderName>`或`rmdir/s <folderName>`命令删除文件夹(不管是否为空)，会提示是否删除，输入y才能删除；

使用命令 `rd/s/q <folderName>`或`rmdir/s/q <folderName>`命令删除文件夹(不管是否为空)，可以直接删除(/q，即quiet，安静模式;/s:subdirectory,子目录)；



## 文件下载

参考：https://blog.csdn.net/qq_42176520/article/details/82979964

在 `powershell `中我们输入一下命令

```powershell
$client = new-object System.Net.WebClient

$client.DownloadFile('#1', '#2')
```

其中， #1的位置填写文件下载地址，#2的位置填写下载的保存路径（注意一点要使用英文键盘的单引号）。

示例，下载地址#1的文件到#2，并重命名为test.msi

```powershell
$client = new-object System.Net.WebClient
$client.DownloadFile('https://www.7-zip.org/a/7z1900-x64.exe', 'C:\Users\Administrator\Documents\user_packages\7z_x64.exe')
```



## 查看权限

cacls /？

Icacls /？

## 添加服务

sc /？

开始---运行---cmd---回车，在弹出的窗体中输入如下命令：

sc create Debug binPath= D:\Debug\authSender.exe start= auto，其中Debug为将要创建的服务名。要删除创建的服务也很简单，使用以下命令即可：sc delete ServiceName

## 添加环境变量

[添加环境变量（path）](https://www.cnblogs.com/jffun-blog/p/8513994.html)



## [使用Windows命令行启动关闭服务(net,sc用法)](https://www.cnblogs.com/qlqwjy/p/8010598.html)



## 查看进程及端口

-  netstat：查看本地连接信息

```powershell
netstat /?

显示协议统计信息和当前 TCP/IP 网络连接。

NETSTAT [-a] [-b] [-e] [-f] [-n] [-o] [-p proto] [-r] [-s] [-x] [-t] [interval]

  -a            显示所有连接和侦听端口。
  -b            显示在创建每个连接或侦听端口时涉及的
                可执行程序。在某些情况下，已知可执行程序承载
                多个独立的组件，这些情况下，
                显示创建连接或侦听端口时
                涉及的组件序列。在此情况下，可执行程序的
                名称位于底部 [] 中，它调用的组件位于顶部，
                直至达到 TCP/IP。注意，此选项
                可能很耗时，并且在你没有足够
                权限时可能失败。
  -e            显示以太网统计信息。此选项可以与 -s 选项
                结合使用。
  -f            显示外部地址的完全限定
                域名(FQDN)。
  -n            以数字形式显示地址和端口号。
  -o            显示拥有的与每个连接关联的进程 ID。
  -p proto      显示 proto 指定的协议的连接；proto
                可以是下列任何一个: TCP、UDP、TCPv6 或 UDPv6。如果与 -s
                选项一起用来显示每个协议的统计信息，proto 可以是下列任何一个:
                IP、IPv6、ICMP、ICMPv6、TCP、TCPv6、UDP 或 UDPv6。
  -q            显示所有连接、侦听端口和绑定的
                非侦听 TCP 端口。绑定的非侦听端口
                 不一定与活动连接相关联。
  -r            显示路由表。
  -s            显示每个协议的统计信息。默认情况下，
                显示 IP、IPv6、ICMP、ICMPv6、TCP、TCPv6、UDP 和 UDPv6 的统计信息;
                -p 选项可用于指定默认的子网。
  -t            显示当前连接卸载状态。
  -x            显示 NetworkDirect 连接、侦听器和共享
                终结点。
  -y            显示所有连接的 TCP 连接模板。
                无法与其他选项结合使用。
  interval      重新显示选定的统计信息，各个显示间暂停的
                间隔秒数。按 CTRL+C 停止重新显示
                统计信息。如果省略，则 netstat 将打印当前的
                配置信息一次。
```

- tasklist：显示本地或远程机器上当前运行的进程列表。 

```powershell
tasklist /?

TASKLIST [/S system [/U username [/P [password]]]]
         [/M [module] | /SVC | /V] [/FI filter] [/FO format] [/NH]

描述:
    该工具显示在本地或远程机器上当前运行的进程列表。


参数列表:
   /S     system           指定连接到的远程系统。

   /U     [domain\]user    指定应该在哪个用户上下文执行这个命令。

   /P     [password]       为提供的用户上下文指定密码。如果省略，则
                           提示输入。

   /M     [module]         列出当前使用所给 exe/dll 名称的所有任务。
                           如果没有指定模块名称，显示所有加载的模块。

   /SVC                    显示每个进程中主持的服务。

   /APPS 显示 Microsoft Store 应用及其关联的进程。

   /V                      显示详细任务信息。

   /FI    filter           显示一系列符合筛选器
                           指定条件的任务。

   /FO    format           指定输出格式。
                           有效值: "TABLE"、"LIST"、"CSV"。

   /NH                     指定列标题不应该
                           在输出中显示。
                           只对 "TABLE" 和 "CSV" 格式有效。

   /?                      显示此帮助消息。

筛选器:
    筛选器名称     有效运算符           有效值
    -----------     ---------------           --------------------------
    STATUS          eq, ne                    RUNNING | SUSPENDED
                                              NOT RESPONDING | UNKNOWN
    IMAGENAME       eq, ne                    映像名称
    PID             eq, ne, gt, lt, ge, le    PID 值
    SESSION         eq, ne, gt, lt, ge, le    会话编号
    SESSIONNAME     eq, ne                    会话名称
    CPUTIME         eq, ne, gt, lt, ge, le    CPU 时间，格式为
                                              hh:mm:ss。
                                              hh - 小时，
                                              mm - 分钟，ss - 秒
    MEMUSAGE        eq, ne, gt, lt, ge, le    内存使用(以 KB 为单位)
    USERNAME        eq, ne                    用户名，格式为
                                              [域\]用户
    SERVICES        eq, ne                    服务名称
    WINDOWTITLE     eq, ne                    窗口标题
    模块         eq, ne                    DLL 名称

注意: 当查询远程计算机时，不支持 "WINDOWTITLE" 和 "STATUS"
      筛选器。

Examples:
    TASKLIST
    TASKLIST /M
    TASKLIST /V /FO CSV
    TASKLIST /SVC /FO LIST
    TASKLIST /APPS /FI "STATUS eq RUNNING"
    TASKLIST /M wbem*
    TASKLIST /S system /FO LIST
    TASKLIST /S system /U 域\用户名 /FO CSV /NH
    TASKLIST /S system /U username /P password /FO TABLE /NH
    TASKLIST /FI "USERNAME ne NT AUTHORITY\SYSTEM" /FI "STATUS eq running"
```

-  taskkill：按照进程IP（PID）或映像名称终止任务 

```powershell
taskkill /?

TASKKILL [/S system [/U username [/P [password]]]]
         { [/FI filter] [/PID processid | /IM imagename] } [/T] [/F]

描述:
    使用该工具按照进程 ID (PID) 或映像名称终止任务。

参数列表:
    /S    system           指定要连接的远程系统。

    /U    [domain\]user    指定应该在哪个用户上下文执行这个命令。

    /P    [password]       为提供的用户上下文指定密码。如果忽略，提示
                           输入。

    /FI   filter           应用筛选器以选择一组任务。
                           允许使用 "*"。例如，映像名称 eq acme*

    /PID  processid        指定要终止的进程的 PID。
                           使用 TaskList 取得 PID。

    /IM   imagename        指定要终止的进程的映像名称。通配符 '*'可用来
                           指定所有任务或映像名称。

    /T                     终止指定的进程和由它启用的子进程。

    /F                     指定强制终止进程。

    /?                     显示帮助消息。

筛选器:
    筛选器名      有效运算符                有效值
    -----------   ---------------           -------------------------
    STATUS        eq, ne                    RUNNING |
                                            NOT RESPONDING | UNKNOWN
    IMAGENAME     eq, ne                    映像名称
    PID           eq, ne, gt, lt, ge, le    PID 值
    SESSION       eq, ne, gt, lt, ge, le    会话编号。
    CPUTIME       eq, ne, gt, lt, ge, le    CPU 时间，格式为
                                            hh:mm:ss。
                                            hh - 时，
                                            mm - 分，ss - 秒
    MEMUSAGE      eq, ne, gt, lt, ge, le    内存使用量，单位为 KB
    USERNAME      eq, ne                    用户名，格式为 [domain\]user
    MODULES       eq, ne                    DLL 名称
    SERVICES      eq, ne                    服务名称
    WINDOWTITLE   eq, ne                    窗口标题

    说明
    ----
    1) 只有在应用筛选器的情况下，/IM 切换才能使用通配符 '*'。
    2) 远程进程总是要强行 (/F) 终止。
    3) 当指定远程机器时，不支持 "WINDOWTITLE" 和 "STATUS" 筛选器。

例如:
    TASKKILL /IM notepad.exe
    TASKKILL /PID 1230 /PID 1241 /PID 1253 /T
    TASKKILL /F /IM cmd.exe /T
    TASKKILL /F /FI "PID ge 1000" /FI "WINDOWTITLE ne untitle*"
    TASKKILL /F /FI "USERNAME eq NT AUTHORITY\SYSTEM" /IM notepad.exe
    TASKKILL /S system /U 域\用户名 /FI "用户名 ne NT*" /IM *
    TASKKILL /S system /U username /P password /FI "IMAGENAME eq note*"
```



