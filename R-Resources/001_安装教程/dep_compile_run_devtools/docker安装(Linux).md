# 在CentOS 7下安装Docker CE版本

[TOC]



参考官网：https://docs.docker.com/install/linux/docker-ce/centos/

## 前期准备

- 要求CentOS 7的维护版本，历史版本不支持
- `centos-extras`仓库必须启用。默认状态是启用的，如果已禁用，则需要重新启用，查看[re-enable](https://wiki.centos.org/AdditionalResources/Repositories). 
- 建议使用`overlay2`存储驱动

### 卸载旧版本的Docker

旧版的Docker叫做`docker`或者`docker-engine`。如果安装了，需要卸载相关依赖项

```shell
sudo yum remove docker \
				docker-client \
				docker-client-latest \
				docker-common \
				docker-latest \
				docker-latest-logrotate \
				docker-logrotate \
				docker-engine
```

这里介绍的是设置仓库再安装的方式，其他方式如从RPM包安装、以脚本安装等，详情查看顶上的参考链接。第一次在新主机下安装Docker CE需要设置Docker存储仓库。最后你能够从该仓库安装并升级Docker。

### 卸载新版本的Docker

```shell
sudo yum remove docker-ce docker-ce-cli containerd.io

# 镜像、容器、卷、自定义配置等文件不会自动被删除。可通过以下命令删除所有的镜像、容器、卷等
sudo rm -rf /var/lib.docker
# 手动删掉任何已编辑的配置文件
sudo rm -rf /etc/docker/daemon.json
```

以下是在本地虚拟机上完成的步骤。

### Set up the repository

#### 1、安装所需依赖

`yum-utils`提供`yum-config-manager`工具

`device-mapper-persistent-data`和`lvm2`是`devicemapper`存储驱动所需要的。

```shell
sudo yum install -y yum-utils device-mapper-persistent-data lvm2
```

此外，根据自己几次安装的结果来看，也安装了其他的依赖包，如下：

在解决无法pull镜像时，尝试使用`bind-utils` 中 `dig` 命令

```shell
sudo yum install bind-utils
```

在安装过程中遇到问题：

```shell
Downloading packages:
Delta RPMs disabled because /usr/bin/applydeltarpm not installed.
```

安装相应的依赖：   

```shell
sudo yum install deltarpm
```

 

#### 2、设置稳定的仓库

```shell
sudo yum-config-manager \
--add-repo \ 
https://download.docker.com/linux/centos/docker-ce.repo
```

 

另外有一些可选项，如nigtly、test仓库等。这些仓库包含在`docker.repo`中，默认是禁用的，以下命令可开启这些服务。

```shell
sudo yum-config-manager --enable docker-ce-nightly
sudo yum-config-manager --enable docker-ce-test

## 禁用时，将`--enable`替换为`--disable`即可
```



## Install Docker CE

### 安装最新版本的Docker CE

```shell
sudo yum install docker-ce docker-ce-cli containerd.io

## yum install or yum update命令通常会安装当前可用的最高版本，不一定匹配个人所需
```



**安全校验**，提示是否接受GPG密钥，如果指纹匹配与`060A 61C5 1B55 8A7F 742B 77AA C52F EB6B 621E 9F35`符合，则接受。

接受之后，开始安装。

此时的docker已安装但是未启动。`docker`组已创建但是组内没有添加用户。

### 安装指定版本的Docker CE

#### a、首先搜索当前仓库可用的版本

```shell
yum list docker-ce --shoulduplicates | sort -r
```

#### b、安装指定版本

使用全量包名（docker-ce + 从版本号的第一个`:`之后的开始到第一个`-`结束之间的内容，并以`-`连接），如`docker-ce-18.09.1`、`docker-ce-18.06.3.ce`

```shell
sudo yum install docker-ce-<VERSION_STRING> docker-ce-cli-<VERSION_STRING> containerd.io
```

此时的docker已安装但是未启动。`docker`组已创建但是组内没有添加用户。

附：

- RPM包安装方式 https://docs.docker.com/install/linux/docker-ce/#install-from-a-package

- 利用便捷脚本安装 https://docs.docker.com/install/linux/docker-ce/#install-using-the-convenience-script



### 启动Docker

```shell
sudo systemctl start docker
```



可设置开机自启docker服务 https://docs.docker.com/install/linux/#configure-docker-to-start-on-boot

```shell
# 添加开机自启服务
sudo systemctl enable docker

## 禁止自启
sudo systemctl disable docker
```



### 测试

#### 查看版本信息

```shell
docker version
# or
docker -v

# 查看详细信息（包含部分配置信息）
docker info
```



#### 运行容器

运行`hello-world`镜像确认Docker CE是否正确安装

若本地没有该容器，则会自动从线上拉取后再运行  

```shell
sudo docker run hello-world
```

拉取容器/镜像

```shell
docker pull hello-world
```

运行Docker命令时需要用到sudo权限，可以通过添加用户组的形式，使得没有`sudo`也能运行docker

参考：https://docs.docker.com/install/linux/#manage-docker-as-a-non-root-user

### 建立docker用户组

默认情况下， docker 命令会使用 Unix socket 与 Docker 引擎通讯。而只有 root 用户和 docker 组的用户才可以访问 Docker 引擎的 Unix socket。出于安全考虑，一般 Linux 系统上不会直接使用root 用户。因此，更好地做法是将需要使用 docker 的用户加入 docker 用户组。  

a、创建名为`docker`的组

```shell
sudo groupadd docker
```

b、将用户添加到`docker`组中

```shell
sudo usermod -aG docker hukai
```

c、登出然后登入以重新评估组的成员关系

如果是在虚拟机上，最好重启电脑以生效；其他客户端，注销重新登入即可。

d、在不使用`sudo`的情况下测试

```shell
docker run hello-world
```

重启后，先启动docker服务，再运行实例

测试通过。

### Upgrade Docker CE

选择新版本安装即可。





