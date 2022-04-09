原文：[https://www.yuque.com/docs/share/1ab4d4f0-52a2-4659-8439-a39902c59ead?#](https://www.yuque.com/docs/share/1ab4d4f0-52a2-4659-8439-a39902c59ead?#)
# 测试环境
操作系统版本：centos7
jdk：1.8.0
benchmarksql 5.0
PostgreSQL 12.6

# 安装部署教程
## 1. 部署Java环境
```
[ctgcache@cs4n4 ctg-pgsql]$ java -version
java version "1.8.0_151"
Java(TM) SE Runtime Environment (build 1.8.0_151-b12)
Java HotSpot(TM) 64-Bit Server VM (build 25.151-b12, mixed mode)
```
## 2. 安装ant工具
```bash
yum -y install ant
```
没有yum源的话也可到[https://ant.apache.org/bindownload.cgi](https://ant.apache.org/bindownload.cgi)自行下载apache-ant-1.9.14-bin.zip
## 3. 编译
下载地址 [https://sourceforge.net/projects/benchmarksql/](https://sourceforge.net/projects/benchmarksql/)
解压编译
```bash
unzip benchmarksql-5.0.zip
cd benchmarksql-5.0
# 编译
ant
```
## 4.测试步骤
### 1. 在pg中创建测试数据库和测试用户

### 2. 编辑配置文件
```bash
cd benchmarksql-5.0/run
cp props.pg my_postgres.properties
vi my_postgres.properties
```

配置文件详细介绍：
```bash
    db=postgres    //数据库类型，postgres代表我们对PG数据库进行测试，不需要更改
    driver=org.postgresql.Driver    //驱动，不需要更改
    conn=jdbc:postgresql://localhost:5432/postgres     //PG数据库连接字符串，正常情况下，需要更改localhost为对应PG服务IP、5432位对应PG服务端口、postgres为对应测试数据库名
    user=benchmarksql    //数据库用户名，通常建议用默认，这就需要我们提前在数据库中建立benchmarksql用户
    password=PWbmsql    //如上用户密码
    warehouses=1    //仓库数量，数量根据实际服务器内存配置，配置方法见第3步
    loadWorkers=4    //用于在数据库中初始化数据的加载进程数量，默认为4，实际使用过程中可以根据实际情况调整，加载速度会随worker数量的增加而有所提升
    terminals=1    //终端数，即并发客户端数量，通常设置为CPU线程总数的2～6倍

    //每个终端（terminal）运行的固定事务数量，例如：如果该值设置为10，意味着每个terminal运行10个事务，如果有32个终端，那整体运行320个事务后，测试结束。该参数配置为非0值时，下面的runMins参数必须设置为0
    runTxnsPerTerminal=10

    //要测试的整体时间，单位为分钟，如果runMins设置为60，那么测试持续1小时候结束。该值设置为非0值时，runTxnsPerTerminal参数必须设置为0。这两个参数不能同时设置为正整数，如果设置其中一个，另一个必须为0，主要区别是runMins定义时间长度来控制测试时间；runTxnsPerTerminal定义事务总数来控制时间。
    runMins=0

    //每分钟事务总数限制，该参数主要控制每分钟处理的事务数，事务数受terminals参数的影响，如果terminals数量大于limitTxnsPerMin值，意味着并发数大于每分钟事务总数，该参数会失效，想想也是如此，如果有1000个并发同时发起，那每分钟事务数设置为300就没意义了，上来就是1000个并发，所以要让该参数有效，可以设置数量大于并发数，或者让其失效，测试过程中目前采用的是默认300。
    //测试过程中的整体逻辑通过一个例子来说明：假如limitTxnsPerMin参数使用默认300，termnals终端数量设置为150并发，实际会计算一个值A=limitTxnsPerMin/terminals=2（此处需要注意，A为int类型，如果terminals的值大于limitTxnsPerMin，得到的A值必然为0，为0时该参数失效），此处记住A=2；接下来，在整个测试运行过程中，软件会记录一个事务的开始时间和结束时间，假设为B=2000毫秒；然后用60000（毫秒，代表1分钟）除以A得到一个值C=60000/2=30000，假如事务运行时间B<C，那么该事务执行完后，sleep C-B秒再开启下一个事务；假如B>C，意味着事务超过了预期时间，那么马上进行下一个事务。在本例子中，每分钟300个事务，设置了150个并发，每分钟执行2个并发，每个并发执行2秒钟完成，每个并发sleep 28秒，这样可以保证一分钟有两个并发，反推回来整体并发数为300/分钟。
    limitTxnsPerMin=300

    //终端和仓库的绑定模式，设置为true时可以运行4.x兼容模式，意思为每个终端都有一个固定的仓库。设置为false时可以均匀的使用数据库整体配置。TPCC规定每个终端都必须有一个绑定的仓库，所以一般使用默认值true。
    terminalWarehouseFixed=true

    //下面五个值的总和必须等于100，默认值为：45, 43, 4, 4 & 4 ，与TPC-C测试定义的比例一致，实际操作过程中，可以调整比重来适应各种场景。

    newOrderWeight=45
    paymentWeight=43
    orderStatusWeight=4
    deliveryWeight=4
    stockLevelWeight=4

    //测试数据生成目录，默认无需修改，默认生成在run目录下面，名字形如my_result_xxxx的文件夹。
    resultDirectory=my_result_%tY-%tm-%td_%tH%tM%tS

    //操作系统性能收集脚本，默认无需修改，需要操作系统具备有python环境
    osCollectorScript=./misc/os_collector_linux.py

    //操作系统收集操作间隔，默认为1秒
    osCollectorInterval=1

    //操作系统收集所对应的主机，如果对本机数据库进行测试，该参数保持注销即可，如果要对远程服务器进行测试，请填写用户名和主机名。
    //osCollectorSSHAddr=user@dbhost

    //操作系统中被收集服务器的网卡名称和磁盘名称，例如：使用ifconfig查看操作系统网卡名称，找到测试所走的网卡，名称为enp1s0f0，那么下面网卡名设置为net_enp1s0f0（net_前缀固定）；使用df -h查看数据库数据目录，名称为（/dev/sdb                33T   18T   16T   54% /hgdata），那么下面磁盘名设置为blk_sdb（blk_前缀固定）
    osCollectorDevices=net_eth0 blk_sda
```
### 3. 初始化测试数据
```bash
[ctgcache@cs4n4 run]$ ./runDatabaseBuild.sh my_postgres.properties
```
### 4. 运行测试
```shell
[ctgcache@cs4n4 run]$ ./runBenchmark.sh my_postgres.properties
```
### 5. 生成图表报告
需要安装R语言环境
```bash
[ctgcache@cs4n4 run]$ ./generateReport.sh my_result_2021-03-24_165905
```
整个测试流程完成；
### 5. 重新测试
执行runDatabaseDestroy.sh脚本带配置文件可以将所有的数据和表都删除，然后再重新修改配置文件，重新运行build和benchmark脚本进行新一轮测试。
```shell
[ctgcache@cs4n4 run]$ ./runDatabaseDestroy.sh my_postgres.properties
[ctgcache@cs4n4 run]$ ./runDatabaseBuild.sh my_postgres.properties
```
# 附件

![img](BenchmarkSQL%E6%B5%8B%E8%AF%95PostgreSQL.assets/metric.jpeg)



临时测试结果
测试条件：benchmarksql 
一主一从 

![image.png](BenchmarkSQL%E6%B5%8B%E8%AF%95PostgreSQL.assets/1m1s.png)

一主两从

![image.png](BenchmarkSQL%E6%B5%8B%E8%AF%95PostgreSQL.assets/1m2s.png)

