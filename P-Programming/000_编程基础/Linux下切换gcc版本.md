[TOC]

## devtoolset对应gcc的版本

> devtoolset-3对应gcc4.x.x版本
> devtoolset-4对应gcc5.x.x版本
> devtoolset-6对应gcc6.x.x版本
> devtoolset-7对应gcc7.x.x版本
> ...

安装

```shell
$ yum -y install centos-release-scl     #Software Collections
$ yum -y install devtoolset-9-gcc devtoolset-9-gcc-c++ devtoolset-9-binutils
```

激活

```shell
$ scl enable devtoolset-9 bash     #切换当前gcc版本，仅仅可以在当前shell切换
```



## gcc/g++ 支持的std版本

参考:http://c.biancheng.net/view/8053.html

指定版本

```shell
gcc/g++ -std=编译标准
```

**注意，表头表示的是各个编译标准的名称，而表格内部的则为 -std 可用的值，例如 -std=c89、-std=c11、-std=gnu90 等（表 2 也是如此）**

![Snipaste_2022-03-01_17-37-28](Linux%E4%B8%8B%E5%88%87%E6%8D%A2gcc%E7%89%88%E6%9C%AC.assets/Snipaste_2022-03-01_17-37-28.png)

表 1、2 中，有些版本对应的同一编译标准有 2 种表示方式，例如对于 8.4~10.1 版本的 GCC 编译器来说，-std=c89 和 -std=c90 是一样的，使用的都是 C89/C90 标准。另外，GCC 编译器还有其他版本，详情可查阅[ GCC文档](https://gcc.gnu.org/onlinedocs/)

![Snipaste_2022-03-01_17-39-53](Linux%E4%B8%8B%E5%88%87%E6%8D%A2gcc%E7%89%88%E6%9C%AC.assets/Snipaste_2022-03-01_17-39-53.png)

