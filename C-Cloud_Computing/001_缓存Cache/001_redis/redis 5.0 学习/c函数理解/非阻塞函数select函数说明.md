# 非阻塞函数select函数说明

## 场景

在编程的过程中，经常会遇到许多阻塞的函数，好像read和网络编程时使用的recv, recvfrom函数都是阻塞的函数，当函数不能成功执行的时候，程序就会一直阻塞在这里，无法执行下面的代码。这是就需要用到非阻塞的编程方式，使用[select函数](https://blog.csdn.net/liitlefrogyyh/article/details/52101999)就可以实现非阻塞编程。

**select函数是一个轮循函数，循环询问文件节点，可设置超时时间，超时时间到了就跳过代码继续往下执行。**

## 原理

select需要驱动程序的支持，驱动程序实现fops内的poll函数。select通过每个设备文件对应的poll函数提供的信息判断当前是否有资源可用(如可读或写)，如果有的话则返回可用资源的文件描述符个数，没有的话则睡眠，等待有资源变为可用时再被唤醒继续执行。详细的原理请看[这里](http://blog.csdn.net/liitlefrogyyh/article/details/52104120)

## 定义

```c
#include <sys/time.h>
#include <unistd.h>

int select(int maxfd, fd_set *rdset, fd_set *wrset, fd_set *exset, struct timeval *timeout);
```

参数

```
int maxfdp：集合中所有文件描述符的范围，为所有文件描述符的最大值加1。
fd_set *readfds：要进行监视的读文件集。
fd_set *writefds ：要进行监视的写文件集。
fd_set *errorfds：用于监视异常数据。
struct timeval* timeout：select的超时时间，它可以使select处于三种状态：
第一，若将NULL以形参传入，即不传入时间结构，就是 将select置于阻塞状态，一定等到监视文件描述符集合中某个文件描述符发生变化为止；
第二，若将时间值设为0秒0毫秒，就变成一个纯粹的非阻塞函数， 不管文件描述符是否有变化，都立刻返回继续执行，文件无变化返回0，有变化返回一个正值；
第三，timeout的值大于0，这就是等待的超时时间，即 select在timeout时间内阻塞，超时时间之内有事件到来就返回了，否则在超时后不管怎样一定返回。
```

返回值

```
返回对应位仍然为1的fd的总数。注意啦：只有那些可读，可写以及有异常条件待处理的fd位仍然为1。否则为0，错误时返回SOCKET_ERROR
```

示例

理解select模型的关键在于理解`fd_set`,为说明方便，取fd_set长度为1字节，`fd_set`中的每一bit可以对应一个文件描述符fd。则1字节长的`fd_set`最大可以对应8个fd。
  （1）执行`fd_set ` set; `FD_ZERO(&set);`则set用位表示是0000,0000。
  （2）若fd＝5,执行`FD_SET(fd,&set);`后set变为0001,0000(第5位置为1)
  （3）若再加入fd＝2，fd=1,则set变为0001,0011
  （4）执行`select(6,&set,0,0,0)`阻塞等待
  （5）若fd=1,fd=2上都发生可读事件，则select返回，此时set变为0000,0011。注意：没有事件发生的fd=5被清空。

基于上面的讨论，可以轻松得出`select`模型的特点：
  （1)可监控的文件描述符个数取决与`sizeof(fd_set)`的值。
  （2）可以有效突破`select`可监控的文件描述符上限。
  （3）将fd加入`select`监控集的同时，还要再使用一个数据结构`array`保存放到`select`监控集中的fd，一是用于再`select `返回后，`array`作为源数据和`fd_set`进行`FD_ISSET`判断。二是`select`返回后会把以前加入的但并无事件发生的fd清空，则每次开始 select前都要重新从array取得fd逐一加入（`FD_ZERO`最先），扫描`array`的同时取得fd最大值`maxfd`，用于`select`的第一个 参数。
  （4）可见`select`模型必须在`select`前循环`array`（加fd，取`maxfd`），`select`返回后循环`array`（`FD_ISSET`判断是否有时间发生）。

使用select函数的过程一般是：

先调用宏`FD_ZERO`将指定的`fd_set`清零，然后调用宏`FD_SET`将需要测试的fd加入`fd_set`，接着调用函数`select`测试`fd_set`中的所有fd，最后用宏`FD_ISSET`检查某个fd在函数`select`调用后，相应位是否仍然为1。

以下是一个测试单个文件描述字可读性的例子：

```c
int isready(int fd)
{
    int rc;
    fd_set fds;
    struct tim tv;
    FD_ZERO(&fds);
    FD_SET(fd,&fds);
    tv.tv_sec = tv.tv_usec = 0;
    rc = select(fd+1, &fds, NULL, NULL, &tv);
    if (rc < 0) //error
    return -1;
    return FD_ISSET(fd,&fds) ? 1 : 0;
}
```

