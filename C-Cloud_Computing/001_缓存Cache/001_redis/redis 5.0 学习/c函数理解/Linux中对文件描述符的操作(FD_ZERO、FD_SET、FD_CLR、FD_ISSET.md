# Linux中对文件描述符的操作(FD_ZERO、FD_SET、FD_CLR、FD_ISSET

在Linux中，内核利用[文件描述符](https://blog.csdn.net/yanjun_1982/article/details/79421528)（File Descriptor）即文件句柄，来访问文件。文件描述符是非负整数，系统用户层可以根据它找到系统内核层的文件数据。打开现存文件或新建文件时，内核会返回一个文件描述符。读写文件也需要使用文件描述符来指定待读写的文件。宏FD_ZERO、FD_SET、FD_CLR、FD_ISSET中“FD”即为file descriptor的缩写。

## `fd_set`结构体

文件描述符由文件描述符集合及其操作函数来管理，文件描述符集合是一个结构体，本质是一个特别的数组。

在`/usr/include/sys/select.h`中

```c
typedef long int __fd_mask;


/* It's easier to assume 8-bit bytes than to get CHAR_BIT. */
#define __NFDBITS (8 * (int) sizeof (__fd_mask))
#define __FDELT(d) ((d) / __NFDBITS)
#define __FDMASK(d) ((__fd_mask) 1 << ((d) % __NFDBITS))

/* fd_set for select and pselect. */
typedef struct
  {
    /* XPG4.2 requires this member name. Otherwise avoid the name
       from the global namespace. */
#ifdef __USE_XOPEN
    __fd_mask fds_bits[__FD_SETSIZE / __NFDBITS];
# define __FDS_BITS(set) ((set)->fds_bits)
#else
    __fd_mask __fds_bits[__FD_SETSIZE / __NFDBITS];
# define __FDS_BITS(set) ((set)->__fds_bits)
#endif
  } fd_set;

/* Maximum number of file descriptors in `fd_set'. */
#define FD_SETSIZE __FD_SETSIZE   //__FD_SETSIZE等于1024

/* Access macros for `fd_set'.  */
#define FD_SET(fd, fdsetp)      __FD_SET (fd, fdsetp)
#define FD_CLR(fd, fdsetp)      __FD_CLR (fd, fdsetp)
#define FD_ISSET(fd, fdsetp)    __FD_ISSET (fd, fdsetp)
#define FD_ZERO(fdsetp)         __FD_ZERO (fdsetp)
```

那么`fd_set`可以简化为

```c
typedef struct
{
		long int fds_bits[32];
} fd_ser;
```

fd_set其实这是一个数组的宏定义，实际上是一long类型的数组，每一个数组元素都能与一打开的文件句柄(socket、文件、管道、设备等)建立联系，建立联系的工作由程序员完成，当调用select()时，由内核根据IO状态修改fd_set的内容，由此来通知执行了select()的进程哪个句柄可读。

## FD_SET、FD_CLR、FD_ISSET、FD_CLR函数

在`/usr/include/bit/select.h`中

```c
# define __FD_SET(d, set) (__FDS_BITS (set)[__FDELT (d)] |= __FDMASK (d))
# define __FD_CLR(d, set) (__FDS_BITS (set)[__FDELT (d)] &= ~__FDMASK (d))
# define __FD_ISSET(d, set) (__FDS_BITS (set)[__FDELT (d)] & __FDMASK (d))
```

再跟踪源码，以`FD_SET(fd, fdset)`为例

```c
#define FD_SET(fd, fdsetp)      __FD_SET (fd, fdsetp)
# define __FD_SET(d, set) (__FDS_BITS (set)[__FDELT (d)] |= __FDMASK (d))
# define __FDS_BITS(set) ((set)->__fds_bits)
#define __FDELT(d) ((d) / __NFDBITS)
#define __FDMASK(d) ((__fd_mask) 1 << ((d) % __NFDBITS))
```

再简化就得到

```c
#define FD_SET(fd,fdsetp)  fdsetp->__fds_bits[fd/32] |= (long int)1<<(d%32)
```

即将相应的位进行置位。

**1）FD_ZERO**

用法：`FD_ZERO(fd_set*);`

用来清空fd_set集合，即让fd_set集合不再包含任何文件句柄。

**2）FD_SET**

用法：`FD_SET(int ,fd_set *);`

用来将一个给定的文件描述符加入集合之中

**3）FD_CLR**

用法：`FD_CLR(int ,fd_set*);`

用来将一个给定的文件描述符从集合中删除

**4）FD_ISSET**

用法：`FD_ISSET(int ,fd_set*);`

检测fd在fdset集合中的状态是否变化，当检测到fd状态发生变化时返回真，否则，返回假（也可以认为集合中指定的文件描述符是否可以读写）。



> 具体调用场景参阅 select()函数的使用