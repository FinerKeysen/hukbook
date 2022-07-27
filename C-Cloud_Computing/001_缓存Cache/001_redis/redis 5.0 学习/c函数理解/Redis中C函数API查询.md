# Redis中调用的C函数

记录格式：

>   API 名
>
>   定义
>
>   说明
>
>   参数
>
>   返回值
>
>   示例



### strchr

**定义**

```c
char *struct(const char *str, int ch);
```

**说明**

在字符串 `str` 中找字符 `ch`

**参数**

`str`，指向待分析的字符串指针

`ch`，要搜索的字符

**返回值**

指向在 `str` 中找到字符 `ch` 的指针，若未找到则返回空指针

**示例**

```C
#include <stdio.h>
#include <string.h>

void strchr_test(void)
{
    const char *str = "Hello, my name is Hukai.";
    char ch = 'H';
    const char *result = str;

    while((result = strchr(result, ch)) != NULL)
    {
        printf("Found '%c' starting at '%s'\n", ch, result);
        ++result;
    }
}
/** output
Found 'H' starting at 'Hello, my name is Hukai.'
Found 'H' starting at 'Hukai.
*/
```



### snprintf

相关API查看 https://zh.cppreference.com/w/c/io/fprintf

**定义**

```C
int snprintf( char *restrict buffer, int bufsz,
              const char *restrict format, ... );
```

**说明**

写结果到字符串 `buffer` 。至多写 `buf_size` - 1 个字符。

**参数**

`buffer`，指向写入的字符串指针

`bufsz`，最多写入`bufsz-1`个字符，再加上空终止符

`format`，格式字符串

**返回值**

写入正常则无输出；若输出错误或编码错误，输出负值

**示例**

```C
char buf[21] = {'0'};
snprintf(buf, 3, "123.456.789.110:yuio");
printf("buf is: %s\n", buf);

/** output
buf is: 12
*/
```

### memcpy

**定义**

```c
void* memcpy( void *dest, const void *src, size_t count );
void* memcpy( void *restrict dest, const void *restrict src, size_t count );
```

**说明**

从 `src` 所指向的对象复制 `count` 个字符到 `dest` 所指向的对象。

**参数**

`dest`，指向要复制的对象的指针
`src`，指向复制来源对象的指针
`count` ，复制的字节数

**返回值**

无

**示例**

```C
void memcpy_test(void)
{
    // 简单用法
    char source[] = "once upon a midnight dreary...", dest[4];
    memcpy(dest, source, sizeof dest);
    for(size_t n = 0; n < sizeof dest; ++n)
        putchar(dest[n]);

    // 设置分配的内存的有效类型为 int
    int *p = malloc(3*sizeof(int));   // 分配的内存无有效类型
    int arr[3] = {1,2,3};
    memcpy(p,arr,3*sizeof(int));      // 分配的内存现在拥有有效类型

    // reinterpreting data
    double d = 0.1;
//    int64_t n = *(int64_t*)(&d); // 严格别名使用违规
    int64_t n;
    memcpy(&n, &d, sizeof d); // OK
    printf("\n%a is %" PRIx64 " as an int64_t\n", d, n);
}
/** output
once
0x1.99999ap-4 is 3fb999999999999a as an int64_t
*/
```

