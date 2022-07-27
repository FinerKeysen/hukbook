> 还可参考：
>
> [SQLSERVER 数据库性能的的基本](https://www.cnblogs.com/lyhabc/p/3623240.html)
>
> ​	看性能计数器的字段解释
>
> [SQL Server数据库引擎性能调优基础](https://blogs.msdn.microsoft.com/indrajit/2013/12/12/sql-server-database-engine-performance-tuning-basics/)
>
> 



# Buffer manager/buffer cache hit ratio

指可在缓冲池中找到而不需要从磁盘中读取(物理I/O)的页面的百分比。如果该值较低则可能存在内存不足或不正确的索引



# General statistics object/user connections

指系统中活动的SQL连接数。该计数器的信息可以用于确定系统得最大并发用户数



# Locks/lock requests/sec

指每秒请求的锁个数。通过优化查询来减少读取次数，可以减少该计数器的值。



# Locks/lock timeouts/sec

指每秒由于等待对锁的授权的锁请求数，理想情况下，该计数器的值为0 



# Locks/lock waits/sec

指每秒无法立刻得到授权而超时的锁请求数，理想情况下，该计数器的值应该尽可能为0



# Locks/number of deadlocks/sec

指每秒导致死锁的锁请求数。死锁对于应用程序的可伸缩性非常有害，并且会导致恶劣的用户体验。该计数器必须为0 



# Memory manager/memory grants pending

指每秒等待工作空间内存授权的进程数。该计数器应该尽可能接近0，否则预示可能存在着内存瓶颈



# SQL statistics/ SQL compilations/sec

指每秒编译数。理想状态下该计数器的值应该低，如果batch requests/sec计数器的值非常接近该计数器，那么可能存在大量的特殊SQL调用



# SQL statistics/ re- compilations/sec

指每秒的重新编译数。该计数器的值越低越好。存储过程在理想情况下应该只编译一次，然后被他们的执行计划重复利用。如果该计数器的值较高，或许需要换个方式编写存储过程，从而减少重编译的次数



# SQL statistics/batch requests/sec 

指每秒向服务器提交批的请求次数。该计数器被用来确定系统的负载大小