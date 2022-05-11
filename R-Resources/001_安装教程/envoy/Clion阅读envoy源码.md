[TOC]

# Clion阅读Envoy源码

> `bazel`是`envoy`官方的构建方式，但是这种方式对开发不友好，因此还需要将`bazel`工程转为`cmake`，这样可以使用`clion`打开项目，更方便阅读代码。



## envoy 编译

参见 [envoy编译(CentOS7)](.\envoy编译(CentOS7).md)



## bazel-cmakelists 工程转换

### 工具适配

使用工具 [bazel-cmakelists](https://github.com/lizan/bazel-cmakelists.git) 得到 CMakelist

```bash
git clone https://github.com/lizan/bazel-cmakelists.git
```



修改 `bazel-cmakelists` 代码

原始文件

```python
if __name__ == "__main__":
  ...
  parser.add_argument('--targets', default=['//...'], nargs='+')
  ...
```

修改后

```python
if __name__ == "__main__":
  ...
  parser.add_argument('--targets', default=['//source/exe:envoy-static'], nargs='+')
  ...
```



### 执行转换

**前提已经执行过了编译**

在 envoy 源码根目录执行命令

> /path_to_bazel-cmakelists/bazel-cmakelists --skip_build





### 执行报错记录

1、访问方式

> ERROR: An error occurred during the fetch of repository 'boringssl_fips':
>    java.io.IOException: Error downloading [https://commondatastorage.googleapis.com/chromium-boringssl-fips/boringssl-ae223d6138807a13006342edfeef32e813246b39.tar.xz] to /home/hukai/.cache/bazel/_bazel_hukai/b0206a11a3d78723278cc0a8463ebb22/external/boringssl_fips/boringssl-ae223d6138807a13006342edfeef32e813246b39.tar.xz: connect timed out

办法

- 第一种，服务器上配备科学上网条件
- 第二种，在本地下载上述文件，将其上传至网络(如github)，然后修改`bazel/repository_locations.bzl`对应依赖项的url为github的下载地址。

`bazel/repository_locations.bzl`文件中`boringssl_fips`的dict info

```python
# 原始文件
boringssl_fips = dict(
        sha256 = "3b5fdf23274d4179c2077b5e8fa625d9debd7a390aac1d165b7e47234f648bb8",
        # fips-20190808
        urls = ["https://commondatastorage.googleapis.com/chromium-boringssl-fips/boringssl-ae223d6138807a13006342edfeef32e813246b39.tar.xz"],
        use_category = ["dataplane"],
        cpe = "N/A",
    ),
```

修改后

```python
# 修改为
boringssl_fips = dict(
        sha256 = "3b5fdf23274d4179c2077b5e8fa625d9debd7a390aac1d165b7e47234f648bb8",
        # fips-20190808
        urls = ["https://github.com/FinerKeysen/katacoda-practice/raw/main/boringssl-ae223d6138807a13006342edfeef32e813246b39.tar.xz"],
        use_category = ["dataplane"],
        cpe = "N/A",
    ),
```



注意：从github下载单文件时，应该在打开文件后，选择复制按钮`raw`或者`download`的地址，而不是直接拷贝浏览器地址栏上暴露的地址（该地址下载下来的是一个快照，不是原文件）



## 参考

[Envoy Redis 源码分析 第1章 · x-lambda/note Wiki (github.com)](https://github.com/x-lambda/note/wiki/Envoy-Redis-源码分析-第1章)





