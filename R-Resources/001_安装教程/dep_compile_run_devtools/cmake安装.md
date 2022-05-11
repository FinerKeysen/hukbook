[TOC]

# Linux下安装有三种方式

## 1、仓库安装

```shell
sudo yum install cmake
```

该方式版本可能会比较旧



## 2、使用编译好的版本

在[官网](https://cmake.org/download/)下载已编译的版本(Binary distributions)

| **Platform**           | **Files**                                                    |
| ---------------------- | ------------------------------------------------------------ |
| Windows x64 Installer  | [cmake-3.23.1-windows-x86_64.msi](https://github.com/Kitware/CMake/releases/download/v3.23.1/cmake-3.23.1-windows-x86_64.msi) |
| Windows x64 ZIP        | [cmake-3.23.1-windows-x86_64.zip](https://github.com/Kitware/CMake/releases/download/v3.23.1/cmake-3.23.1-windows-x86_64.zip) |
| Windows i386 Installer | [cmake-3.23.1-windows-i386.msi](https://github.com/Kitware/CMake/releases/download/v3.23.1/cmake-3.23.1-windows-i386.msi) |
| Windows i386 ZIP       | [cmake-3.23.1-windows-i386.zip](https://github.com/Kitware/CMake/releases/download/v3.23.1/cmake-3.23.1-windows-i386.zip) |
| macOS 10.13 or later   | [cmake-3.23.1-macos-universal.dmg](https://github.com/Kitware/CMake/releases/download/v3.23.1/cmake-3.23.1-macos-universal.dmg) |
|                        | [cmake-3.23.1-macos-universal.tar.gz](https://github.com/Kitware/CMake/releases/download/v3.23.1/cmake-3.23.1-macos-universal.tar.gz) |
| macOS 10.10 or later   | [cmake-3.23.1-macos10.10-universal.dmg](https://github.com/Kitware/CMake/releases/download/v3.23.1/cmake-3.23.1-macos10.10-universal.dmg) |
|                        | [cmake-3.23.1-macos10.10-universal.tar.gz](https://github.com/Kitware/CMake/releases/download/v3.23.1/cmake-3.23.1-macos10.10-universal.tar.gz) |
| Linux x86_64           | [cmake-3.23.1-linux-x86_64.sh](https://github.com/Kitware/CMake/releases/download/v3.23.1/cmake-3.23.1-linux-x86_64.sh) |
|                        | [cmake-3.23.1-linux-x86_64.tar.gz](https://github.com/Kitware/CMake/releases/download/v3.23.1/cmake-3.23.1-linux-x86_64.tar.gz) |
| Linux aarch64          | [cmake-3.23.1-linux-aarch64.sh](https://github.com/Kitware/CMake/releases/download/v3.23.1/cmake-3.23.1-linux-aarch64.sh) |
|                        | [cmake-3.23.1-linux-aarch64.tar.gz](https://github.com/Kitware/CMake/releases/download/v3.23.1/cmake-3.23.1-linux-aarch64.tar.gz) |



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

[官网](https://cmake.org/download/)下载源码Source distributions:

| **Platform**                          | **Files**                                                    |
| ------------------------------------- | ------------------------------------------------------------ |
| Unix/Linux Source (has \n line feeds) | [cmake-3.23.1.tar.gz](https://github.com/Kitware/CMake/releases/download/v3.23.1/cmake-3.23.1.tar.gz) |
| Windows Source (has \r\n line feeds)  | [cmake-3.23.1.zip](https://github.com/Kitware/CMake/releases/download/v3.23.1/cmake-3.23.1.zip) |



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

`:wq`后：

```bash
source ~/.bash_aliases
或
. ~/.bash_aliases
```

使用

```bash
cmake -version
```