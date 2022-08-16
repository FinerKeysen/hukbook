# Ruby安装

需要科学上网

## 1、使用RVM安装

> RVM（Ruby版本管理器）是一个命令行工具，可让您轻松地安装，管理和使用多个Ruby环境。

### 安装RVM所需依赖

```shell
sudo yum install curl gpg gcc gcc-c++ make patch autoconf automake bison libffi-devel libtool patch readline-devel sqlite-devel zlib-devel openssl-devel
```

### 安装RVM

```shell
sudo gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
curl -sSL https://get.rvm.io | bash -s stable
```

### RVM的Q&A

（1）不能curl下来时，可使用离线文件 [get-rvm.sh](./assets/rvm/get_rvm.sh)

然后执行`chmod +x get-rvm.sh && bash get-rvm.sh stable`

（2）签名问题

```shell
gpg: 于 2021年01月16日 星期六 02时46分22秒 CST 创建的签名，使用 RSA，钥匙号 39499BDB
gpg: 无法检查签名：没有公钥
GPG signature verification failed for '/home/ctyun/.rvm/archives/rvm-1.29.12.tgz' - 'https://github.com/rvm/rvm/releases/download/1.29.12/1.29.12.tar.gz.asc'! Try to install GPG v2 and then fetch the public key:

    gpg2 --keyserver hkp://pool.sks-keyservers.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB

or if it fails:

    command curl -sSL https://rvm.io/mpapis.asc | gpg2 --import -
    command curl -sSL https://rvm.io/pkuczynski.asc | gpg2 --import -

In case of further problems with validation please refer to https://rvm.io/rvm/security
```

导入asc文件后重新执行get-rvm.sh

[mpapis.asc](./assets/mpapis.asc)、[pkuczynski.asc](./assets/pkuczynski.asc)

```shell
gpg2 --import mpapis.asc
gpg2 --import pkuczynski.asc
bash get_rvm.sh stable
```

### 执行source

```shell
bash get_rvm.sh stable
```

### 安装Ruby

```shell
# 以3.1.2版本为例
rvm install 3.1.2
```

#### 管理ruby版本

```shell
rvm use 3.1.2 --default
```



## 2、源码安装Ruby

### 准备源码包

去官网下载：http://www.ruby-lang.org/en/downloads/

以 ruby-2.7.3.tar.gz 为例

解压

```shell
tar zxf ruby-2.7.3.tar.gz
cd ruby-2.7.3
ls
```

### 配置安装路径

进入源码根目录后，通过configure配置

```shell
./configure --prefix=/usr/local/ruby 
# --prefix是将ruby安装到指定目录，也可以自定义
```

自定义目录在系统目录下时可能需要root权限创建对应路径，自定义在用户级目录下时，不需要root，可以直接安装

```shell
mkdir -p /usr/local/ruby/ruby-2.7.3
./configure --prefix=/usr/local/ruby/ruby-2.7.3
```

### 编译并安装

```shell
make -j8
```

![img](ruby%E5%AE%89%E8%A3%85.assets/ruby-compile.png)

```shell
# 安装目录若在用户权限下，直接执行
make install
# 安装目录若在root目录下，执行
sudo make install
```

### 环境变量配置

在"~/.bashrc"中添加"export PATH=/path/to/install-ruby/bin:$PATH"

在"/etc/profile"中添加"export PATH=/path/to/install-ruby/bin:$PATH"

#### 查看ruby版本

```shell
$ vim ~/.bashrc
$ source ~/.bashrc
$ vim /etc/profile
$ source /etc/profile
$ ruby -v
ruby 2.7.3p183 (2021-04-05 revision 6847ee089d) [x86_64-linux]
```

#### 查看gem版本

```shell
gem

gem -v
```

