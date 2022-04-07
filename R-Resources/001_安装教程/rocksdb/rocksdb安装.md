[TOC]



参考

https://blog.jeffli.me/blog/2016/12/02/getting-started-with-rocksdb-in-centos-7/



## 相关依赖

### 安装gflags

源码：git clone https://github.com/gflags/gflags.git

编译安装
```shell
cd gflags
mkdir build
cd build
cmake ..
make
# be root
make install
```

遇到问题

Q1：

```shell
-- The CXX compiler identification is unknown
-- Check for working CXX compiler: /usr/bin/c++
-- Check for working CXX compiler: /usr/bin/c++ -- broken
CMake Error at /usr/local/share/cmake-3.14/Modules/CMakeTestCXXCompiler.cmake:53 (message):
  The C++ compiler

    "/usr/bin/c++"

  is not able to compile a simple test program.

  It fails with the following output:

    Change Dir: /home/hukai/gflags/build/CMakeFiles/CMakeTmp

    Run Build Command(s):/usr/bin/gmake cmTC_c944e/fast
    /usr/bin/gmake -f CMakeFiles/cmTC_c944e.dir/build.make CMakeFiles/cmTC_c944e.dir/build
    gmake[1]: 进入目录“/home/hukai/gflags/build/CMakeFiles/CMakeTmp”
    Building CXX object CMakeFiles/cmTC_c944e.dir/testCXXCompiler.cxx.o
    /usr/bin/c++     -o CMakeFiles/cmTC_c944e.dir/testCXXCompiler.cxx.o -c /home/hukai/gflags/build/CMakeFiles/CMakeTmp/testCXXCompiler.cxx
    c++: error trying to exec 'cc1plus': execvp: 没有那个文件或目录
    gmake[1]: *** [CMakeFiles/cmTC_c944e.dir/testCXXCompiler.cxx.o] 错误 1
    gmake[1]: 离开目录“/home/hukai/gflags/build/CMakeFiles/CMakeTmp”
    gmake: *** [cmTC_c944e/fast] 错误 2
```

或者

```shell
gcc: error trying to exec 'cc1plus': execvp: 没有那个文件或目录
g++: error trying to exec 'cc1plus': execvp: 没有那个文件或目录
```

A1：gcc、g++、c++版本不一致
如果不一致则重新建立软链接至同一版本，如

````shell
# 假定 c++ 在 /usr/bin 中
cd /usr/bin
ls -ld c++
sudo rm c++
sudo ln -s /opt/rh/devtoolset-8/root/bin/c++ c++
ls -ld c++
````

### 压缩和解压缩的开发包

```undefined
# snappy
sudo yum install snappy snappy-devel

# zlib
sudo yum install zlib zlib-devel

# 基于Burrows-Wheeler 变换的无损压缩软件 bzip2
sudo yum install bzip2 bzip2-devel

# 压缩工具 lz4
sudo yum install lz4-devel

# 内存检测工具 asan
sudo yum install libasan

# 安装 zstandard
wget https://github.com/facebook/zstd/archive/v1.1.3.tar.gz
mv v1.1.3.tar.gz zstd-1.1.3.tar.gz
tar zxvf zstd-1.1.3.tar.gz
cd zstd-1.1.3
make && make install
```

## RocksDB编译安装

###  编译

以 `tag:v6.14.5` 为例

编译静态库，release mode，获得`librocksdb.a`

```go
make static_lib
```

编译动态库，release mode，获得``librocksdb.so.xxx`(带版本号)

```shell
make shared_lib
```

得到

```shell
lrwxrwxrwx 1 ... librocksdb.so -> librocksdb.so.6.14.5
lrwxrwxrwx 1 ... librocksdb.so.6 -> librocksdb.so.6.14.5
lrwxrwxrwx 1 ... librocksdb.so.6.14 -> librocksdb.so.6.14.5
-rwxrwxr-x 1 ... librocksdb.so.6.14.5
```

为方便使用可将动态库拷贝至系统库下或者某目录下再配置环境变量引用该库

（a）放置在 /usr/lib 下

```shell
# 当前在 rocksdb源码的根目录下
sudo cp librocksdb.so /usr/lib
# 添加相应版本的软链接
sudo ln -fs librocksdb.so.6.14.5 librocksdb.so.6.14
sudo ln -fs librocksdb.so.6.14.5 librocksdb.so.6
sudo ln -fs librocksdb.so.6.14.5 librocksdb.so

# 拷贝其头文件
sudo cp -r include/* /usr/include
```



（b）或者放置在某目录下

**注：需要配置环境变量，步骤（d）**

```shell
# 当前在 rocksdb源码的根目录下
sudo cp librocksdb.so /usr/local/lib
# 添加相应版本的软链接
sudo ln -fs librocksdb.so.6.14.5 librocksdb.so.6.14
sudo ln -fs librocksdb.so.6.14.5 librocksdb.so.6
sudo ln -fs librocksdb.so.6.14.5 librocksdb.so

# 拷贝其头文件
sudo cp -r include/* /usr/local/include
```

（c）执行安装以拷贝到指定目录

**注：需要配置环境变量，步骤（d）**

默认的安装目录

库文件位置：`/usr/local/lib`

头文件位置：`/usr/local/include`

```shell
# 安装动态链接库
sudo make install-shared

# 安装静态链接库
sudo make install-static

# 安装静态或动态链接库
sudo make install

# install动作会拷贝include/rocksdb到指定目录
```



（d）配置环境变量

```shell
# sudo vim /etc/profile
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib
```

刷新配置

```shell
source /etc/profile
```



注：这里按方式（c）进行配置



### 测试案例

> rocksdb_test.cpp

```cpp
#include <cstdio>
#include <string>

#include "rocksdb/db.h"
#include "rocksdb/slice.h"
#include "rocksdb/options.h"

using namespace std;
using namespace rocksdb;

const std::string PATH = "/kv/rocksdb_tmp"; //指定一个rocksDB的数据存储目录绝对路径

int main(){
    DB* db;
    Options options;
    options.create_if_missing = true;
    Status status = DB::Open(options, PATH, &db);
    assert(status.ok());
    Slice key("foo");
    Slice value("bar");
    
    std::string get_value;
    status = db->Put(WriteOptions(), key, value);
    if(status.ok()){
        status = db->Get(ReadOptions(), key, &get_value);
        if(status.ok()){
            printf("get %s\n", get_value.c_str());
        }else{
            printf("get failed\n"); 
        }
    }else{
        printf("put failed\n");
    }

    delete db;
}
```



编译

```shell
# 若方式(b)中没有拷贝include的子目录，则需要告诉编译器所需相关头文件的路径
# g++ -std=c++11 -o rocksdb_test rocksdb_test.cpp -lpthread -lrocksdb -I/path_to_rocksdb_src_root/include
g++ -std=c++11 -o rocksdb_test rocksdb_test.cpp -lpthread -lrocksdb
```

运行

```shell
./rocksdb_test
```

结果

```shell
get bar
```

