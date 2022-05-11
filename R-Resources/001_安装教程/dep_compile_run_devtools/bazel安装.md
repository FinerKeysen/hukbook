

bazel info

> bazel官网
> https://bazel.build/install
> bazel源码：
> https://github.com/bazelbuild/bazel
> bazel下载
> https://github.com/bazelbuild/bazel/releases



bazel下载地址

> https://github.com/bazelbuild/bazel/releases



安装

> sudo ./bazel-xxx-installer-linux-x86_64.sh --prefix=/usr/local/bazel-xxx



添加环境变量 vi /etc/profile

> export PATH=$PATH:/usr/local/bazel-xxx/bin



验证

```shell
source /etc/profile
bazel --version
```



注：受限于国内网络，避免bazel拉取相关依赖库时超时，需要设置GOPROXY

参见 https://goproxy.io/zh/ 配置 GOPROXY 环境变量

临时使用或者添加至`~/.bash_profile`或者`/etc/profile`

> export GOPROXY=https://proxy.golang.com.cn,direct
