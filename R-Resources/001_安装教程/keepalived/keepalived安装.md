[TOC]

# Use keepalived in CentOS

Q：为什么不用yum直接安装?

A：不同的源中，keepalived版本不同，通常也不是最新版本，甚至版本还比较低。

已知官方源keepalived的版本是1.3.5，且版本中存在以下问题

==不能进行TCP和HTTP的后端检测==，在正确的配置文件下，一开keepalived进程也会在/var/log/message中报错，如下

```shell
...
8月 07 16:24:44 localhost.localdomain Keepalived_healthcheckers[97686]: TCP socket bind failed. Rescheduling.
8月 07 16:24:46 localhost.localdomain Keepalived_healthcheckers[97686]: TCP socket bind failed. Rescheduling.
8月 07 16:24:50 localhost.localdomain Keepalived_healthcheckers[97686]: TCP socket bind failed. Rescheduling.
8月 07 16:24:52 localhost.localdomain Keepalived_healthcheckers[97686]: TCP socket bind failed. Rescheduling.
...
```

为避免此方面的问题，最好根据需要选择合适的源码版本进行编译安装。

## install by compiling

###  prepare

#### dependencies

```shell
yum -y install openssl-devel
yum -y install libnl libnl-devel
yum -y install libnfnetlink-devel
yum -y install net-tools
```

####  package

源码 https://www.keepalived.org/download.html

以2.2.7为例 keepalived-2.2.7.tar.gz

解压

```shell
tar -zxvf keepalived-2.2.7.tar.gz
cd keepalived-2.2.7
```

### install

#### 编译

```sh
./configure
make
```

##### configure的error

```shell
configure: error: libnfnetlink headers missing
```

办法，安装依赖libnfnetlink-devel，重新configure

```bash
[root@localhost keepalived-2.0.7]# yum install -y libnfnetlink-devel
```

得到以下信息

```shell
[root@localhost keepalived-2.0.7]# ./configure --prefix=/usr/local/keepalived
checking for a BSD-compatible install... /usr/bin/install -c
checking whether build environment is sane... yes
checking for a thread-safe mkdir -p... /usr/bin/mkdir -p
checking for gawk... gawk

...
...
...

Keepalived configuration
------------------------
Keepalived version       : 2.0.7
Compiler                 : gcc
Preprocessor flags       :  -I/usr/include/libnl3 
Compiler flags           : -Wall -Wunused -Wstrict-prototypes -Wextra -Winit-self -g -D_GNU_SOURCE -fPIE -Wformat -Werror=format-security -Wp,-D_FORTIFY_SOURCE=2 -fexceptions -fstack-protector-strong --param=ssp-buffer-size=4 -grecord-gcc-switches -O2  
Linker flags             :  -pie
Extra Lib                :  -lcrypto  -lssl  -lnl-genl-3 -lnl-3 
Use IPVS Framework       : Yes
IPVS use libnl           : Yes
IPVS syncd attributes    : No
IPVS 64 bit stats        : No
HTTP_GET regex support   : No
fwmark socket support    : Yes
Use VRRP Framework       : Yes
Use VRRP VMAC            : Yes
Use VRRP authentication  : Yes
With ip rules/routes     : Yes
Use BFD Framework        : No
SNMP vrrp support        : No
SNMP checker support     : No
SNMP RFCv2 support       : No
SNMP RFCv3 support       : No
DBUS support             : No
SHA1 support             : No
Use Json output          : No
libnl version            : 3
Use IPv4 devconf         : No
Use libiptc              : No
Use libipset             : No
init type                : systemd
Strict config checks     : No
Build genhash            : Yes
Build documentation      : No
[root@localhost keepalived-2.0.7]#
```



#### install

```sh
make install
```

权限不够时，使用`sudo`执行

完成后会在以下路径生成：

```sh
/usr/local/etc/keepalived/keepalived.conf
/usr/local/etc/sysconfig/keepalived
/usr/local/sbin/keepalived
```



#### initialize

将配置文件放到默认路径下：

```
mkdir /etc/keepalived
cp /usr/local/keepalived/keepalived/etc/keepalived/keepalived.conf /etc/keepalived/
```

将keepalived启动脚本（源码目录下），放到/etc/init.d/目录下：

```
cp /usr/local/keepalived/keepalived/etc/init.d/keepalived /etc/rc.d/init.d/
```

将keepalived启动脚本变量引用文件放到/etc/sysconfig/目录下：

```
cp /usr/local/keepalived/keepalived/etc/sysconfig/keepalived /etc/sysconfig/
```

将keepalived主程序加入到环境变量/usr/sbin/目录下：

```
cp /usr/local/sbin/keepalived /usr/sbin/
```

### use

####  start/stop

启动keepalived：

```
service keepalived start
```

停止：

```
service keepalived stop //停止服务
```

查服务状态：

```
service keepalived status //查看服务状态
```

#### configuration

停止keepalived服务，修改keepalived.conf配置文件（第3步中的/etc/keepalived/keepalived.conf ）并重新启动keepalived服务加载配置文件。配置属性说明可参照keepalived.conf文件，在具体使用中可参考修改：

```
! Configuration File for keepalived
# 全局定义块
global_defs {
   # 邮件通知配置，用于服务有故障时发送邮件报警，可选项
   notification_email {
     541223550@qq.com
   }
   # 通知邮件从哪里发出
   notification_email_from root@localhost
   # 通知邮件的smtp地址
   smtp_server 127.0.0.1
   # 连接smtp服务器的超时时间
   smtp_connect_timeout 30
   # 标识本节点的字条串，通常为hostname，但不一定非得是hostname。故障发生时，邮件通知会用到
   router_id LVS_DEVEL
}
# 做健康检查的脚本配置，当时检查失败时会将vrrp_instance的priority减少相应的值
vrrp_script chk_haproxy {
    # 待执行脚本
    script "/etc/keepalived/chk_nginx.sh"
    # 执行间隔
    interval 2
    # 控制priority增减
    weight 2
}
# VRRP实例定义块
vrrp_instance VI_1 {
    # 标识当前节点的状态，可以是MASTER或BACKUP，当其他节点keepalived启动时会将priority比较大的节点选举为MASTER
    state MASTER
    # 节点固有IP（非VIP）的网卡，用来发VRRP包
    interface ens192
    # 取值在0-255之间，用来区分多个instance的VRRP组播。同一网段中virtual_router_id的值不能重复，否则会出错
    virtual_router_id 100
    # 用来选举master的，要成为master，那么这个选项的值最好高于其他机器50个点，该项取值范围是[1-254]（在此范围之外会被识别成默认值100）
    priority 200
    # 发VRRP包的时间间隔，即多久进行一次master选举（可以认为是健康查检时间间隔）
    advert_int 1
    # 认证区域，认证类型有PASS和HA（IPSEC），推荐使用PASS（密码只识别前8位）
    authentication {
        auth_type PASS
        auth_pass 1111
    }
    # 调用chk_http_port中定义的脚本，当使用track_script时可以不用加nopreempt，只需要加上preempt_delay 5，这里的间隔时间要大于vrrp_script中定义的时长
    track_script {
        chk_haproxy
    }
    # 允许一个priority比较低的节点作为master，即使有priority更高的节点启动。nopreemt必须在state为BACKUP的节点上才生效（因为是BACKUP节点决定是否来成为MASTER的）
    nopreempt
    # 启动多久之后进行接管资源（VIP/Route信息等），前提是没有nopreempt选项
    preempt_delay 300
    # 虚拟ip地址
    virtual_ipaddress {
        192.168.26.34
    }
}
# 虚拟服务定义块
virtual_server 192.168.26.34 9999{
    # 延迟轮询时间（单位秒）
    delay_loop 6
    # 后端调试算法
    lb_algo wrr
    # LVS调度类型NAT/DR/TUN
    lb_kind DR
    # nat掩码
    nat_mask 255.255.255.0
    # 持久化超时时间，保持客户端的请求在这个时间段内全部发到同一个真实服务器，解决客户连接的相关性问题
    persistence_timeout 1
    # 传输协议
    protocol TCP
    # 真实提供服务的服务器
    real_server 192.168.26.36 9999 {
        # 权重
        weight 1
        # 健康检查方式 HTTP_GET|SSL_GET|TCP_CHECK|SMTP_CHECK|MISC_CHECK
        TCP_CHECK {
            # 连接超时时间
            connect_timeout 10
            # 检测失败后的重试次数，若达到重试次数还是失败则将其从服务器池中移除
            nb_get_retry 3
            # 下次重试的时间延迟
            delay_before_retry 3
            # 连接端口
            connect_port 9999 
        }   
    }   
    real_server 192.168.26.54 9999 {
        weight 1
        TCP_CHECK {
            connect_timeout 10
            nb_get_retry 3
            delay_before_retry 3
            connect_port 9999
        }
    }
}

virtual_server 192.168.26.34 3306{
    delay_loop 6
    lb_algo wrr
    lb_kind DR
    nat_mask 255.255.255.0
    persistence_timeout 1
    protocol TCP
    real_server 192.168.26.36 3306 {
        weight 1
        TCP_CHECK {
            connect_timeout 10
            nb_get_retry 3
            delay_before_retry 3
            connect_port 3306
        }
    }
    real_server 192.168.26.54 3306 {
        weight 1
        TCP_CHECK {
            connect_timeout 10
            nb_get_retry 3
            delay_before_retry 3
            connect_port 3306
        }
    }
}
```

修改完之后重新启动



### lvs strategy choose

参考

https://blog.csdn.net/lvshaorong/article/details/81205451

#### DR（Direct Route）

DR模式确实有其优点，尤其是对于负载均衡器压力更小。DR模式下不仅需要配置keepalived的服务器，还需要需要修改后端服务器的arp策略并在lo网卡上配置虚拟IP。

#### NAT模式，官网推荐

NAT模式是将负载均衡服务器当做路由器来用，装keepalived的服务器至少要有两个网卡，且要分别处于不同的网段。NAT的优点是仅需配置装有keepalived的负载均衡服务器，而后端的real server是0配置；

NAT模式也有缺点，一是当real server很多的时候会成为瓶颈，不过这一点不容易碰到，因为有这么大流量的场合基本都换成硬件负载均衡器了。第二就是要求有两个不同网段的网络或者VLAN，因为NAT的缘故，所以如果我们手上只有一个网段的话，是无法部署成NAT的
