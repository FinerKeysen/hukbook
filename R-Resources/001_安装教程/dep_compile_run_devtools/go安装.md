

go info

> 下载地址
> https://golang.org/dl/
> 打不开用这个备用地址 https://golang.google.cn/dl/
> 安装
> https://golang.google.cn/doc/install

包名标识

| 操作系统 | 包名                       |
| :------- | :------------------------- |
| Windows  | x.windows-amd64.msi        |
| Linuxx   | .linux-amd64.tar.gz        |
| Mac      | x.darwin-amd64-osx10.8.pkg |
| FreeBSD  | x.freebsd-amd64.tar.gz     |



示例

直接下载使用二进制包即可

>  go1.18.1.linux-amd64.tar.gz



解压至target 目录

> tar -C /usr/local -xzf go1.18.1.linux-amd64.tar.gz



设置环境变量

所有用户添加至 `/etc/profile`

当前用户添加至 `~/.bash_profile`

> export PATH=$PATH:/usr/local/go/bin



验证

```shell
source /etc/profile
go version
```

