[TOC]

# Linux下安装有三种方式

## 1、仓库安装

```shell
sudo yum install cmake
```

该方式版本可能会比较旧



## 2、使用编译好的版本

在[官网](https://cmake.org/download/)下载已编译的版本

![image-20220216171036445](cmake%E5%AE%89%E8%A3%85.assets/image-20220216171036445-16450026413771.png)

解压并进入目录：

```shell
tar -zxvf cmake-xxx
cd cmake-xxx/bin
./cmake --version
```



为方便添加软链接

```shell
sudo ln -s cmake /usr/bin/cmake
```



## 3、编译安装

[官网](https://cmake.org/download/)下载源码

![image-20220216171507958](cmake%E5%AE%89%E8%A3%85.assets/image-20220216171507958-16450029096082.png)

解压并配置

```shell
tar -zxvf cmake-xxx
cd cmake-xxx/
./bootstrap --prefix=/usr/local/cmake
```

编译并安装

```
make
sudo make install
```

成功之后，在bash_aliases加个别名：

```bash
vim ~/.bash_aliases
```

加上

```bash
alias cmake=/usr/local/xxxxx/cmake/bin/cmake
```

:wq后：

```bash
source ~/.bash_aliases
或
. ~/.bash_aliases
```

使用

```bash
cmake -version
```