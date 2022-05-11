

参考

[Linux下切换gcc版本](..\..\..\P-Programming\000_编程基础\Linux下切换gcc版本.md)



安装 scl 源

> yum install centos-release-scl scl-utils-build



列出scl可用源

> yum list all --enablerepo='centos-sclo-rh' | grep gcc



安装 gcc gcc-g++ gdb等

> yum -y install devtoolset-8-gcc.x86_64 devtoolset-8-gcc-c++.x86_64 devtoolset-8-gcc-gdb-plugin.x86_64



查看从 SCL 中安装的包的列表

> scl -l



切换版本

> scl enable devtoolset-8 bash



临时导入对应版本的环境变量

> export CC=/opt/rh/devtoolset-8/root/usr/bin/gcc
> export LD_LIBRARY_PATH=/opt/rh/devtoolset-8/root/usr/bin:/opt/rh/devtoolset-8/root/usr/lib/gcc/x86_64-redhat-linux/8:/opt/rh/devtoolset-8/root/usr/libexec/gcc/x86_64-redhat-linux/8
