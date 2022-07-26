

1、安装 remote-ssh 插件

2、进入插件栏，打开配置

![image-20220512102548169](vscode%E8%BF%9C%E7%A8%8B%E7%BC%96%E8%BE%91%E3%80%81%E8%B0%83%E8%AF%95.assets/image-20220512102548169.png)

3、添加主机

![image-20220512103147653](vscode%E8%BF%9C%E7%A8%8B%E7%BC%96%E8%BE%91%E3%80%81%E8%B0%83%E8%AF%95.assets/image-20220512103147653.png)

- Host 标识主机别名
  - HostName
  - User
  - IdentifyFile 本机秘钥地址



4、将本机、远程机上的`id_rsa.pub`中的内容拷贝到对方机器`.ssh`目录下的`authorized_keys`文件中



5、连接到remote机器，打开工程文件



6、添加gdb配置文件

运行 > 添加配置

默认生成`launch.json`配置文件

```json
{
    // 使用 IntelliSense 了解相关属性。 
    // 悬停以查看现有属性的描述。
    // 欲了解更多信息，请访问: https://go.microsoft.com/fwlink/?linkid=830387
    "version": "0.2.0",
    "configurations": [
        {
            "name": "(gdb) 启动",
            "type": "cppdbg",
            "request": "launch",
            "program": "输入程序名称，例如 ${workspaceFolder}/a.out",
            "args": [],
            "stopAtEntry": false,
            "cwd": "${fileDirname}",
            "environment": [],
            "externalConsole": false,
            "MIMode": "gdb",
            "setupCommands": [
                {
                    "description": "为 gdb 启用整齐打印",
                    "text": "-enable-pretty-printing",
                    "ignoreFailures": true
                }
            ]
        }
    ]
}
```



