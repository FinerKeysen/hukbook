

# C/C++编译器

[TOC]

## 初识

编译器默认的动作：

1、预处理,生成 .i 的文件[预处理器cpp]

2、将预处理后的文件转换成汇编语言, 生成文件 .s [编译器egcs]

3、有汇编变为目标代码(机器代码)生成 .o 的文件[汇编器as]

4、连接目标代码, 生成可执行程序 [链接器ld]

### 编译选项

详情参见

https://gcc.gnu.org/onlinedocs/

https://www.runoob.com/w3cnote/gcc-parameter-detail.html



| 选项          | 释义                                                         |
| ------------- | ------------------------------------------------------------ |
| -c            | 只激活预处理,编译,和汇编。只把程序做成obj文件，不是可执行文件（因为没有链接,有的程序中也没有main入口） |
| -S            | 只激活预处理和编译，就是只把文件编译成为汇编代码。生成.s的汇编代码 |
| -E            | 只激活预处理,不生成文件,你需要把它重定向到一个输出文件里面 例子：gcc -E hello.c > pianoapan.txt |
| -o            | 指定输出，缺省的时候,gcc 编译出来的文件是a.out               |
| -Wall         | 显示所有警告信息                                             |
| -w            | 不生成任何警告信息。                                         |
| -Wextra       | 打印出更多的警告信息，比开启 -Wall 打印的还多                |
| -ansi         | 关闭gnu c中与ansi c不兼容的特性,激活ansi c的专有特性(包括禁止一些asm inline typeof关键字,以及UNIX,vax等预处理宏 |
| -include file | 包含某个代码,简单来说,就是便于某个文件需要另一个文件的时候,就可以用它设 定,功能就相当于在代码中使用#include |
| -Idir         | 添加dir目录为头文件搜索路径，如-I./ 在当前目录查找头文件     |
| -I-           | 取消前一个参数的功能,所以一般在-Idir之后使用                 |
| -llib         | 指定编译的时候使用的库，gcc -lcurses hello.c 使用库curses进行编译 |
| -std=         | 编译的标准,包括GNU99，c++11,c99,等等                         |
| -O2           | 编译器的优化选项的4个级别，-O0表示没有优化,-O1为缺省值，-O3优化级别最高 |
| -Ldir         | 链接的时候，搜索库的路径 -L./ 在当前目录搜说                 |
| -g            | 产生调试信息，可以使用gdb调试可执行文件                      |
| -ggdb         | 此选项将尽可能的生成gdb的可以使用的调试信息.                 |
| -static       | 禁止使用动态库，所以，编译出来的东西，一般都很大，也不需要什么 |
| -share        | 此选项将尽量使用动态库，所以生成文件比较小，但是需要系统由动态库. |
| -shared       | 创建一个动态链接库（不指定的话输出的是obj文件）gcc -fPIC -shared func.c -o libfunc.s |
| -rdynamic     | 动态连接符号信息，用于动态连接功能。所有符号添加到动态符号表中（目的是能够通过使用 dlopen 来实现向后跟踪） |
| -pedantic     | 用于保证代码规范满足ISO C和ISO C++标准, 不允许使用任何扩展以及不满足ISO C和C++的代码, 遵守 -std 选项指定的标准 |
| -pthread      | 支持多线程, 使用pthread库                                    |
| -fPIC         | PIC 是 position-independent code的意思, 此选项去除独立位置代码, 适合于动态链接 |
| -x            | `-x language-name`，设定文件所使用的语言, 使后缀名无效, 对以后的多个有效<br />`-x none-name`，让gcc根据文件名后缀，自动识别文件类型 |

### 静态库

静态库是编译器生成的一系列对象文件的集合。链接一个程序时用库中的对象文件还是目录中的对象文件都是一样的。库中的成员包括普通函数，类定义，类的对象实例等等。静态库的另一个名字叫归档文件(archive)，管理这种归档文件的工具叫 ar 。

```shell
#这里的ar相当于tar的作用，将多个目标打包。 makefile中用于创建静态链接库（就是把多个目标文件打包成一个）
ar -r libhello.a hello.o
```



### 动态库



## 示例

### 示例1：单个源文件

```c++
/* helloworld.cpp */
#include <iostream>
int main(int argc,char *argv[])
{
    std::cout << "hello, world" << std::endl;
    return(0);
}
```

编译

```shell
$ g++ helloworld.cpp
```

由于命令行中未指定可执行程序的文件名，编译器采用默认的 a.out。

普遍的做法是通过 -o 选项指定可执行程序的文件名

```shell
$ g++ helloworld.cpp -o helloworld
```

g++ 是将 gcc 默认语言设为 C++ 的一个特殊的版本，链接时它自动使用 C++ 标准库而不用 C 标准库。通过遵循源码的命名规范并指定对应库的名字。所以用 gcc 来编译链接 C++ 程序是可行的，但是需要指明所依赖的C++库，示例：

```shell
$ gcc helloworld.cpp -lstdc++ -o helloworld
```

### 示例2：多个源文件

多于一个的源码文件在 g++ 命令中指定，都将被编译并被链接成一个单一的可执行文件

```c++
/* speak.h */
#include <iostream>
class Speak
{
    public:
        void sayHello(const char *);
};

/* speak.cpp */
#include "speak.h"
void Speak::sayHello(const char *str)
{
    std::cout << "Hello " << str << "\n";
}

/* hellospeak.cpp */
#include "speak.h"
int main(int argc,char *argv[])
{
    Speak speak;
    speak.sayHello("world");
    return(0);
}
```

编译

```c++
$ g++ hellospeak.cpp speak.cpp -o hellospeak
```

编译时，未指定 speak.h 文件的原因是：在 speak.cpp 中包含有`#include "speak.h"`这句代码。它的意思是搜索系统头文件目录之前将先在当前目录中搜索文件 speak.h 。而 speak.h 正在该目录中，因此不需要在命令中额外指定了。
