## 环境准备

根据当前的系统版本选择

[下载 Windows 驱动程序工具包 (WDK)](https://docs.microsoft.com/zh-cn/windows-hardware/drivers/download-the-wdk)

[其他 WDK 下载](https://docs.microsoft.com/zh-cn/windows-hardware/drivers/other-wdk-downloads)



例如，当前系统版本为 Windows10 1809

软件：
IDE: Visual Studio 2017及以上版本

SDK: 独立安装，

WDK:  独立安装，[ 适用于 Windows 10 版本 1809 的 WDK](https://go.microsoft.com/fwlink/?linkid=2026156)



ERRORs

1、错误代码 MSB8040

报错信息：

> Spectre-mitigated libraries are required for this project. Install them from the Visual Studio installer (Individual components tab) for any toolsets and architectures being used. Learn more: https://aka.ms/Ofhn4c

解决

项目属性—常规—平台工具集—WindowsApplicationForDrivers10.0



2、错误代码 MSB4062

报错信息

> 未能从程序集 C:\Program Files (x86)\Windows Kits\10\build\bin\Microsoft.DriverKit.Build.Tasks.16.0.dll 加载任务“ValidateNTTargetVersion”。未能加载文件或程序集“file:///C:\Program Files (x86)\Windows Kits\10\build\bin\Microsoft.DriverKit.Build.Tasks.16.0.dll”或它的某一个依赖项。The system cannot find the file specified. 请确认 <UsingTask> 声明正确，该程序集及其所有依赖项都可用，并且该任务包含实现 Microsoft.Build.Framework.ITask 的公共类。	DriverCommunicate	



3、项目的附加库中添加WDK库的目录

4、错误代码 LNK1104

> 错误 LNK1104 无法打开文件“MSVCRTD.lib”

改错误与一个警告消息相关

> 警告MSB8038：已启用spectre缓解但找不到spectre缓解库
>
> 会导致致命错误 LNK1104

解决办法

打开visual studio 2017 installer，安装`VC++ 2017 version 15.9 v14.16 Libs for Spectre (x86 and x64)`



