

# C与C++混合编译



[TOC]

在 GCC 编译器中，可以将不同编程语言生成的目标文件混合在一起使用，但是操作起来非常的困难，因为不同的编程语言都有自己的特性。 混合使用时要处理好产生的各种问题，包括全局命名约定、命令、参数传递、数据类型转换、出错处理，以及两种语言标准运行时的库的混合。

参考

- http://c.biancheng.net/view/7494.html
- https://www.teddy.ch/c++_library_in_c/



C 程序和 C++ 程序可以自然的混合。C++ 可以看作是 C 语言的扩展，因此调用规则是相同的，而且数据类型也是基本相同。

唯一的区别主要体现在函数名上：C语言使用的是简单的参数名，不考虑参数的个数和类型，而 C++ 中的函数总会将它的参数类型列表当作函数名的一部分。

==使用`extern C`来告诉C++编译器按C风格命名，那么C编译器在编译时就能够找到正确的对象。==

## 在C++中调用C

源文件`hello.c`

```c
#include <stdio.h>
void sayhello(const char *str)
{
       printf("%s\n", str);
}
```

`main.cpp`

```shell
#include <iostream>
using namespace std;
extern "C" void sayhello(const char *str);
int main(int argc,char *argv[])
{
       sayhello("hello from cpp to c\n");
       return 0;
}
```

可以看到上述的代码中，在 C++ 程序中直接调用 C 程序中的函数，原因是在 C++ 程序中它的声明是 extern "C"。

那么如何编译文件呢？可以使用下面的命令：

```shell
$ g++ -c main.cpp -o main.o
$ gcc -c hello.c -o hello.o
# 最后的链接过程中要指定 C++ 库，因为使用的是 gcc 而不是 g++ 激活链接的
$ gcc main.o hello.o -lstdc++ -o main
```



如果使用 g++ 激活链接，那么就表示已经指定了 C++ 的库。

```shell
$ g++ main.o hello.o -o main
```



如果在头文件中声明函数，就要将整个头文件都声明为extern "C"，这是标准 C++ 语法。

## 一个C++的编程

源文件 `MyClass.h`

```c++
#ifndef __MYCLASS_H
#define __MYCLASS_H

class MyClass {
        private:
                int m_i;
        public:
                void int_set(int i);

                int int_get();
};

#endif
```

`MyClass.cc`

```c++
#include "MyClass.h"
void MyClass::int_set(int i) {
        m_i = i;
}

int MyClass::int_get() {
        return m_i;
}
```

`MyMain_c++.cc` 调用

```c++
#include "MyClass.h"
#include <iostream>

using namespace std;

int main(int argc, char* argv[]) {
        MyClass *c = new MyClass();
        c->int_set(3);
        cout << c->int_get() << endl;
        delete c;
}
```

编译

```shell
# compile MyClass.cc
g++ -c MyClass.cc -o MyClass.o

# compile MyMain_c++.cc
g++ -c MyMain_c++.cc -o MyMain_c++.o

# link MyMain_c++.o with MyClass.o and generate binary file MyMain_c++
g++ MyMain_c++.o MyClass.o -o MyMain_c++
```

执行

```sh
./MyMain_c++
```

## 在C中调用C++

在 C 程序中调用 C++ 程序时，C++ 程序提供的函数可以使用 C 语言的调用顺序，下面的例子展示如何在 C++ 程序中创建 C 函数。

C++源文件`MyWrapper.h`

```c++
#ifndef __MYWRAPPER_H
#define __MYWRAPPER_H

#ifdef __cplusplus
extern "C" {
#endif

typedef struct MyClass MyClass;

MyClass* newMyClass();

void MyClass_int_set(MyClass* v, int i);

int MyClass_int_get(MyClass* v);

void deleteMyClass(MyClass* v);

#ifdef __cplusplus
}
#endif
#endif
```

`MyWrapper.cc`

```c++
#include "MyClass.h"
#include "MyWrapper.h"

extern "C" {
        MyClass* newMyClass() {
                return new MyClass();
        }

        void MyClass_int_set(MyClass* v, int i) {
                v->int_set(i);
        }

        int MyClass_int_get(MyClass* v) {
                return v->int_get();
        }

        void deleteMyClass(MyClass* v) {
                delete v;
        }
}
```

C的源文件`MyMain_c.c`

在C中调用C++的函数

```c
#include "MyWrapper.h"
#include <stdio.h>

int main(int argc, char* argv[]) {
        struct MyClass* c = newMyClass();
        MyClass_int_set(c, 3);
        printf("%i\n", MyClass_int_get(c));
        deleteMyClass(c);
}
```

编译

```shell
# 使用C++ compile MyWrapper.cc
$ g++ -c MyWrapper.cc -o MyWrapper.o

# 使用C compile MyMain_c.c
$ gcc -c MyMain_c.c -o MyMain_c.o

# 使用C++ 链接相关对象
$ g++ MyMain_c.o MyWrapper.o MyClass.o -o MyMain_c
# 或用 gcc，但需要使用相关的c++库
$ gcc MyMain_c.c MyWrapper.o MyClass.o -lstdc++ -o MyMain_c
```

运行

```shell
$ ./MyMain_c
```



