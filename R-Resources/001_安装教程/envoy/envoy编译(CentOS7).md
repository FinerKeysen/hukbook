

[TOC]

## 0、参考

[如何在CentOS上编译envoy](https://blog.csdn.net/netyeaxi/article/details/109174309)

[GOPROXY.IO - 一个全球代理 为 Go 模块而生](https://goproxy.io/zh/)



## 1、准备 envoy

下载

```shell
git clone https://github.com/envoyproxy/envoy
```



示例使用 `release/v1.15`

```shell
git checkout -b release/v1.15 origin/release/v1.15
```



查看 `.bazelversion`准备相应版本的bazel

参见 [bazel安装](..\dep_compile_run_devtools\bazel安装.md)



## 2、准备依赖

### 2.1、gcc开发工具

envoy1.15需要gcc7以上，这里使用`scl`

安装使用scl参见 [devtoolset安装与切换.md](..\dep_compile_run_devtools\devtoolset安装与切换.md)



### 2.2、scl-git准备

参见 [scl-git安装](..\dep_compile_run_devtools\git(scl)安装.md)



### 2.3、cmake准备

参见 [cmake安装](..\dep_compile_run_devtools\cmake安装.md)



### 2.4、python3装备

参见 [python安装](..\dep_compile_run_devtools\python安装.md)



### 2.5、automake autoconf libtool准备

```shell
sudo yum -y install automake autoconf libtool
```



### 2.6、ninja准备

参见 [ninja安装](..\dep_compile_run_devtools\ninja安装.md)



## 3、编译 envoy

### 3.1、初始化软件环境

> scl enable devtoolset-8 bash
> scl enable rh-git227 bash



### 3.2、初始化系统参数

> export CC=/opt/rh/devtoolset-8/root/usr/bin/gcc
> export LD_LIBRARY_PATH=/opt/rh/devtoolset-8/root/usr/bin:/opt/rh/devtoolset-8/root/usr/lib/gcc/x86_64-redhat-linux/8:/opt/rh/devtoolset-8/root/usr/libexec/gcc/x86_64-redhat-linux/8



### 3.3、执行编译

注：受限于国内网络，避免bazel拉取相关依赖库时超时，需要设置GOPROXY

参见 https://goproxy.io/zh/ 配置 GOPROXY 环境变量

临时使用或者添加至`~/.bash_profile`或者`/etc/profile`

> export GOPROXY=https://proxy.golang.com.cn,direct



`cd envoy`

最简单的编译命令

> bazel build -c opt //source/exe:envoy-static



1).如果需要在生产环境上编译，可以先把依赖的工程下载到本地，下载方式：

> bazel fetch --repository_cache=/path/to/repo_cache  //source/exe:envoy-static

然后，编译时指定使用此本地库：

> bazel build -c opt //source/exe:envoy-static --repository_cache=/path/to/repo_cache



2).如果要指定编译参数，可以使用--cxxopt

> bazel build -c opt //source/exe:envoy-static --cxxopt="-Wno-error=maybe-uninitialized" --cxxopt="-Wno-error=uninitialized" --cxxopt="-DENVOY_IGNORE_GLIBCXX_USE_CXX11_ABI_ERROR=1"



 3).如果要查看编译报错的详细信息可以使用 --sandbox_debug --verbose_failures

> bazel build --sandbox_debug --verbose_failures -c opt //source/exe:envoy-static



最终使用的编译命令：

> bazel build --sandbox_debug --verbose_failures -c opt //source/exe:envoy-static --cxxopt="-Wno-error=maybe-uninitialized" --cxxopt="-Wno-error=uninitialized" --cxxopt="-DENVOY_IGNORE_GLIBCXX_USE_CXX11_ABI_ERROR=1" --repository_cache=/mnt/hgfs



编译结果形如

```shell
Target //source/exe:envoy-static up-to-date:
  bazel-bin/source/exe/envoy-static
INFO: Elapsed time: 4044.779s, Critical Path: 478.12s
INFO: 3582 processes: 3582 processwrapper-sandbox.
INFO: Build completed successfully, 4614 total actions
```



## 4、报错

### 4.1、_GLIBCXX_USE_CXX11_ABI

```shell
Use --sandbox_debug to see verbose messages from the sandbox
In file included from source/exe/main_common.cc:10:
bazel-out/k8-fastbuild/bin/source/common/common/_virtual_includes/compiler_requirements_lib/common/common/compiler_requirements.h:14:2: error: #error "Your toolchain has set _GLIBCXX_USE_CXX11_ABI to a value that usesa std::string " "implementation that is not thread-safe. This may cause rare and difficult-to-debug errors " "if std::string is passed between threads in any way. If you accept this risk, you may define " "ENVOY_IGNORE_GLIBCXX_USE_CXX11_ABI_ERROR=1 in your build."
 #error "Your toolchain has set _GLIBCXX_USE_CXX11_ABI to a value that uses a std::string
```

参考

> https://github.com/envoyproxy/envoy/issues/3303

添加编译参数 `--cxxopt="-DENVOY_IGNORE_GLIBCXX_USE_CXX11_ABI_ERROR=1"`



