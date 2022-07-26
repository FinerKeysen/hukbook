

安装步骤

https://github.com/OpenAtomFoundation/pika/wiki/%E5%AE%89%E8%A3%85%E4%BD%BF%E7%94%A8



安装完

检查库

```shell
$ ldd ./output/bin/pika
	linux-vdso.so.1 =>  (0x00007fff42353000)
	libglog.so.0 => /lib64/libglog.so.0 (0x00007fd8af184000)
	libprotobuf.so.8 => /lib64/libprotobuf.so.8 (0x00007fd8aee72000)
	libpthread.so.0 => /lib64/libpthread.so.0 (0x00007fd8aec56000)
	librt.so.1 => /lib64/librt.so.1 (0x00007fd8aea4e000)
	libsnappy.so.1 => /lib64/libsnappy.so.1 (0x00007fd8ae848000)
	libgflags.so.2.1 => /lib64/libgflags.so.2.1 (0x00007fd8ae627000)
	libz.so.1 => /lib64/libz.so.1 (0x00007fd8ae411000)
	libbz2.so.1 => /lib64/libbz2.so.1 (0x00007fd8ae201000)
	liblz4.so.1 => /lib64/liblz4.so.1 (0x00007fd8adff2000)
	libzstd.so.1 => /usr/local/lib/libzstd.so.1 (0x00007fd8add60000)
	libstdc++.so.6 => /lib64/libstdc++.so.6 (0x00007fd8ada58000)
	libm.so.6 => /lib64/libm.so.6 (0x00007fd8ad756000)
	libgcc_s.so.1 => /lib64/libgcc_s.so.1 (0x00007fd8ad540000)
	libc.so.6 => /lib64/libc.so.6 (0x00007fd8ad172000)
	/lib64/ld-linux-x86-64.so.2 (0x00007fd8af3b4000)
```



启动报错

```
Compression type Snappy is not linked with the binary.
```



参考：https://blog.csdn.net/javeme/article/details/103753454

解决：缺少snappy动态库及头文件

1、重新安装snappy

2、拷贝可用的`libsnappy.so`到`/usr/lib64`或者`/usr/local/lib`下，拷贝snappy相关的头文件到`/usr/inlcude`下



安装完重新编译

```shell
$ make distclean

$ make -j8
```



也可以直接使用已编译的二进制文件，启动前检查依赖是否完备

```shell
ldd path/to/pika
```

缺少的动态依赖库，可从其他系统中拷贝，然后补充相应的链接即可启动

```shell
# 软链接命令
sudo ln -fs 实体源文件名 链接名
```

