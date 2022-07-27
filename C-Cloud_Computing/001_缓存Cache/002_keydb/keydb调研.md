# Keydb调研

 

目的：keydb的多活机制的特性研究，输出多活复制的原理和文档以及不适用的场景和使用限制

 

Keydb的开源项目地址：https://github.com/JohnSully/KeyDB

Keydb pro版：https://keydb.dev/keydb-pro.html

官方文档站点：https://docs.keydb.dev

 

## 产品比较 Keydb与redis

> https://keydb.dev/

![img](keydb%E8%B0%83%E7%A0%94.assets/wps1.jpg) 



## 官方文档阅读记录

### Active-Replication

> https://github.com/JohnSully/KeyDB/wiki/Active-Replication

#### 技术实现

在启动时，每个KeyDB实例将计算一个动态UUID。此UUID不会保存，仅在进程的生命周期中存在。当一个replica连接到其主数据库时，它将通知主数据库其UUID，而主数据库将以其自己的UUID答复。比较这两个UUID，以通知服务器这两个客户端是否来自同一个KeyDB实例（IP和端口不足，因为同一台计算机上可能存在不同的进程）。如果是我们的replica，则这些UUID用于防止将changes重新广播到发送给它们的masters。

 添加了一个新的配置选项以启用此模式，并且启用后，即使它是副本，KeyDB仍可写（默认情况下，它是禁用的）。除了防止循环中的客户端之间无限跳动查询的额外逻辑外，复制代码通常会执行。

####  特性

1、keydb支持active replication，不再需要将replication提升为active masters，从而大大简化故障转移方案。

2、Active replication支持用于在高写入情况下的分配负载

#### 运行模式

默认情况下，KeyDB与Redis一样，仅允许从主数据库到副本数据库的单向通信。

配置

active-replica=true

该模式下，即使KeyDB与主数据库断开连接，它也可接受副本。它还允许在两个节点彼此为主的情况下进行循环连接。

#### 脑裂

KeyDB可以处理分裂主服务器之间的连接但可以继续写入的裂脑方案。每个写入都带有时间戳，当连接恢复时，每个主机将共享其新数据。最新的写作将获胜。这样可以防止过时的数据覆盖断开连接后写入的新数据。

#### 使用步骤

以下步骤假定两个服务器A和B。

1. 两台服务器在各自的配置文件中都必须具有“ active-replica yes”

2. 在服务器B上执行命令“ replicaof [A地址] [A端口]”，服务器B将删除其数据库并加载服务器A的数据集

3. 在服务器A上执行命令“ replicaof [B地址] [B端口]”，服务器A将删除其数据库并加载服务器B的数据集（包括上一步中刚刚传输的数据）

4. 两台服务器现在将相互传播写操作。通过在服务器A上写入密钥并确保它在B上可见（反之亦然）进行测试。

### Active-replica配置

> https://docs.keydb.dev/docs/active-rep/

主动副本节点允许您读取和写入两个实例，这可以增加高负载下的读取，并让您的备份/副本节点在发生故障时准备就绪。设置就像设置代理服务器以指向正常实例一样简单。查看HAProxy部分中的示例配置，这些配置可以启用运行状况检查，以及不同的路由配置（轮询，优先等）。设置代理服务器很简单，而keydb的配置甚至更简单。配置文件示例：

- 实例 A配置文件：

```shell
# assuming below parameters were set and IP address of this instance is 10.0.0.2
port 6379
requirepass mypassword123
masterauth mypassword123
\# you will need to configure the following
active-replica yes
replicaof 10.0.0.3 6379
```

 

- 实例 B配置文件：

```shell
# assuming below parameters were set and IP address of this instance is 10.0.0.3
port 6379
requirepass mypassword123
masterauth mypassword123
\# you will need to configure the following
active-replica yes
replicaof 10.0.0.2 6379
```

 

- 可以附加到配置文件 

```
keydb-server --active-replica yes --replicaof <ipaddress> <port>
```

 

#### 测试主动复制

写入一个节点的任何命令都将在另一节点上看到。如果服务器出现故障，则时间戳将确保副本在恢复联机后不会覆盖较新的写入。这样能设置脚本，cron等，以根据需要自动重启失败的实例，而不会覆盖新数据。在极高的负载下，可能会有轻微的潜伏期，但数据同步仍然很低（几乎可以忽略不计）。

### MultiMaster-Suport 多主支持

> https://github.com/JohnSully/KeyDB/wiki/Multimaster-Support

在复制时，keydb支持多个主机，允许多个节点彼此为主的情况下进行循环连接。

配置

multi-master yes

当KeyDB与多个主机连接时，其行为与传统复制不同：

- 多次调用copyofof命令将导致添加其他主机，而不是替换当前主机

- 与主数据库同步时，KeyDB不会删除其数据库

- KeyDB会将来自主机的任何读/写合并到其自己的内部数据库

- KeyDB将默认为最后一次操作获胜

 

这意味着具有多个master的replica将包含其所有master数据的超集。如果两个master具有相同密钥的值，则不确定将采用哪个密钥。如果一个master删除另一个master上存在的密钥，则replica将不再包含该密钥的副本。

#### MultiMaster-Suport配置

多主节点设置与活动副本设置非常相似，但是允许多个副本节点（所有主节点）。它可以读取和写入所有实例，这些实例可以在高负载下增加读取次数，并让其他主节点在一个失败的情况下准备就绪。

使用多主机设置，可以使每个主机成为其他节点的副本。这可以接受许多拓扑，您可以对环形拓扑进行不同的变化，也可以使每个主副本成为所有其他主副本的副本。如果不是全部都同步，请考虑故障情况，并确保一个中断不会导致其他中断。

配置示例

实例A的配置文件：

```
# assuming below parameters were set and IP address of this instance is 10.0.0.2
port 6379
requirepass mypassword123
masterauth mypassword123
\# you will need to configure the following
multi-master yes
active-replica yes
replicaof 10.0.0.3 6379
replicaof 10.0.0.4 6379
```

 

实例B的配置文件：

```
# assuming below parameters were set and IP address of this instance is 10.0.0.3
port 6379
requirepass mypassword123
masterauth mypassword123
\# you will need to configure the following
multi-master yes
active-replica yes
replicaof 10.0.0.2 6379
replicaof 10.0.0.4 6379
```

 

实例C配置文件：

```
# assuming below parameters were set and IP address of this instance is 10.0.0.4
port 6379
requirepass mypassword123
masterauth mypassword123
\# you will need to configure the following
multi-master yes
active-replica yes
replicaof 10.0.0.2 6379
replicaof 10.0.0.3 6379
```

也可附加配置文件：

```
keydb-server --multi-master yes --active-replica yes --replicaof <ipaddress> <port> --replicaof
```

### Redis Replication和KeyDB Active Replication

> https://docs.keydb.dev/blog/2019/08/05/blog-post/

KeyDB可以与Redis模块，API协议完全兼容，因此可以用作Redis替换数据库的替代品。KeyDB具有Redis开源提供的所有功能，但是在其开源基础代码中还有许多其他强大而免费的选项，例如闪存支持，主动复制，完整多线程，aws s3备份等。KeyDB在其[稳定版本5.0](https://github.com/JohnSully/KeyDB/tree/RELEASE_5)中引入了主动复制，该版本实质上允许两个主节点具有同步读/写和故障转移支持。这允许对两个主节点进行读取和写入的负载平衡。主节点是彼此的副本，彼此同步时都充当主节点。

keyDB在replica上的基础结构是相似的，在[keyDB官网上介绍的replication](https://docs.keydb.dev/docs/replication/)与[Redis官网上介绍的replication](https://redis.io/topics/replication)描述基本相同。只是在redis上master-master结构是付费的，而keydb开源版本支持master-master架构（[见文中Active-replication章节](#_Active-Replication)），且易于操作。

#### keyDB的replication

> https://docs.keydb.dev/docs/replication/

主服务器上的持久性关闭时replication的安全性

在使用KeyDB复制的设置中，强烈建议在主服务器和从服务器中打开持久性。如果不可能（例如，由于磁盘速度非常慢而导致延迟问题），则应将实例配置为避免重启后自动重启。

为了更好地理解为什么将持久性关闭的主服务器配置为自动重启是危险的，请检查以下故障模式，其中擦除了主服务器及其所有从服务器上的数据：

1. 我们有一个设置，其中节点A充当主节点，而持久性已关闭，并且节点B和C从节点A复制。

2. 节点A挂了，但是它具有一些自动重新启动系统，该系统可以重新启动进程。但是，由于关闭了持久性，因此节点将使用空数据集重新启动。

3. 节点B和C将从节点A复制，该节点为空，因此它们将有效销毁其数据副本。

当KeyDB Sentinel用于高可用性时，关闭主服务器上的持久性以及自动重新启动进程也是很危险的。例如，主服务器可以足够快速地重新启动，以使Sentinel不会检测到故障，从而发生上述故障模式。

每当数据安全很重要，并且在配置为不具有持久性的主服务器上使用复制时，都应禁用实例的自动重启。

### 在高可用上的比较

> https://docs.keydb.dev/blog/2019/08/05/blog-post/

#### Redis高可用设置基本架构

![img](keydb%E8%B0%83%E7%A0%94.assets/wps2.jpg)

此设置包含一个主节点和一个副本节点，以及3个用于确定和管理故障转移的哨兵节点（独立的机器），也可以设置客户端以平衡对副本的读取以进一步利用资源。更多的移动部件和自动重新配置会增加复杂性，并增加其他步骤和监视实践以维护这些部件。Redis的主动-主动复制可用于企业客户。

 

#### keyDB高可用设置基本架构

![img](keydb%E8%B0%83%E7%A0%94.assets/wps3.jpg)

此设置有两个相同的主节点互相复制（启用了主动副本）。可以在两者之间进行负载平衡。发生故障时，您只能从活动主控器进行读/写操作。时间戳记涵盖了裂脑场景。无需重新配置节点，当恢复失败的节点/连接时，它将像以前一样同步并运行。

通过HAproxy进行的基准测试负载平衡

![img](keydb%E8%B0%83%E7%A0%94.assets/wps4.jpg)

### 关于KeyDB的限制

目前使用keyDB的人不多，能够找到的资料非常有限，以下限制或问题是从官方的[FAQ](https://docs.keydb.dev/docs/faq/)中整理得到

1、 KeyDB是内存中的，但在磁盘数据库上具有持久性，因此它代表了一种不同的折衷，即在数据集不能大于内存的情况下实现很高的读写速度。

2、 要运行大型KeyDB服务器，或多或少都需要64位系统。替代方法是分片。

3、 Q：我喜欢KeyDB的高级操作和功能，但我不喜欢它占用了内存中的所有内容，而且我无法拥有更大的内存数据集。计划改变这个？

A：“闪存上的KeyDB”是一种解决方案，能够对较大的数据集使用混合RAM /闪存方法。DRAM每GB的价格比非易失性内存（例如FLASH）贵得多。启用后，KeyDB可以将访问频率较低的数据存储在非易失性存储中，而不是RAM中。KeyDB会根据需要主动在非易失性存储中进出数据。当然，您也可以使用普通旋转磁盘，但不建议这样做，因为性能会很差。KeyDB希望基础设备具有良好的随I/O性能。FLASH存储仅用于临时数据，其行为类似于RAM。持久性仍然可以通过常规机制实现。当使用“ free”命令查看内存时，KeyDB使用的内存将显示为“ buff / cache”。KeyDB依靠内核的分页策略来决定要在磁盘上放置什么内容。

4、 有什么办法可以降低KeyDB的内存使用率？

如果可以，请使用KeyDB 32位实例。还可以充分利用小哈希值，列表，排序集和整数集，因为KeyDB能够以更为紧凑的方式在少数元素的特殊情况下表示这些数据类型。

内存使用率高或容易产生内存不足的问题

5、 

 

## 博客参考

> [走进KeyDB](https://yq.aliyun.com/articles/705239?utm_content=g_100006242)

这篇博客简单介绍了一下几点：

- keydb的多线程架构

KeyDB将redis原来的主线程拆分成了主线程和worker线程。每个worker线程都是io线程，负责监听端口，accept请求，读取数据和解析协议。

![img](keydb%E8%B0%83%E7%A0%94.assets/wps5.jpg)

- 链接管理

在redis中所有链接管理都是在一个线程中完成的。在KeyDB的设计中，每个worker线程负责一组链接，所有的链接插入到本线程的链接列表中维护。

- 锁机制 fastlock

- 多活机制的特点

每个replica可设置成可写非只读，replica之间互相同步数据。主要特性有：

- 每个replica有个uuid标志，用来去除环形复制
- 新增加rreplay API，将增量命令打包成rreplay命令，带上本地的uuid
- key，value加上时间戳版本号，作为冲突校验，如果本地有相同的key且时间戳版本号大于同步过来的数据，新写入失败。采用当前时间戳向左移20位，再加上后44位自增的方式来获取key的时间戳版本号。

> [从两个具有同步读/写和故障转移支持的主节点（keyDB）创建高可用性Redis（如群集）的经验（英文）](https://medium.com/faun/failover-redis-like-cluster-from-two-masters-with-keydb-9ab8e806b66c)

## 测试

官网上给的测试方式

利用[Memtier](https://docs.keydb.dev/docs/benchmarking/)进行多线程基准测试

 