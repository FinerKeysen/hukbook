`install`经常在Makefile中使用，用来安装目标文件到指定目录。

语法

```
install [OPTION]... [-T] SOURCE DEST

install [OPTION]... SOURCE... DIRECTORY

install [OPTION]... -t DIRECTORY SOURCE...

install [OPTION]... -d DIRECTORY...
```



常用的参数

```shell
--backup[=CONTROL]：为每个已存在的目的地文件进行备份。 
-b：类似 --backup，但不接受任何参数。 
-d, --directory：所有参数都作为目录处理，而且会创建指定目录的所有主目录(逐级创建缺失的目标目录)。 
-D, 创建<目的地>前的所有主目录，然后将<来源>复制至 <目的地>；在第一种使用格式中有用。 
-g, --group=组：自行设定所属组，而不是进程目前的所属组。 
-m, --mode=模式：自行设定权限模式 (像chmod)，而不是rwxr-xr-x。 
-o, --owner=所有者：自行设定所有者 (只适用于超级用户)。 
-p, --preserve-timestamps：以<来源>文件的访问/修改时间作为相应的目的地文件的时间属性。 
-s, --strip：用strip命令删除symbol table，只适用于第一及第二种使用格式。 
-S, --suffix=后缀：自行指定备份文件的<后缀>
-t, --target-directory=目录 将源文件所有参数复制到指定目录
-T, --no-target-directory source dest 将每一个源文件拷贝到指定的目录，目标文件名与SOURCE文件名相同
```



示例

```shell
# 创建目录
install -d /usr/bin
# 将源文件复制到目标文件，后面的参数是文件
install source_file dest_file
# 将源文件复制到目标目录，后面的参数是目录，如果目录不存在，则会当做文件处理
install source_file dest_dir
# 将源文件复制到目标目录，后面的参数是目录，如果目录不存在，则命令失败
install source_file dest_dir/

# 复制文件，并设置文件权限，自动创建目标目录
@install -p -D -m 0755 targets /usr/bin/targets
# 相当于
@mkdir -p /usr/bin
@cp targets /usr/bin
@chmod 755 /usr/bin/targets
@touch /usr/bin/targets       # 更新文件时间戳

# @前缀的意思是不在控制台输出结果
```



`install`和`cp`的相同功能就是拷贝文件，但它们之间也有很多不同，区别主要如下：

- 最重要的一点，如果目标文件存在，cp会先清空文件后往里写入新文件，而install则会先删除掉原先的文件然后写入新文件。这是因为往正在使用的文件中写入内容可能会导致一些问题，比如说写入正在执行的文件可能会失败，再比如说往已经在持续写入的文件句柄中写入新文件会产生错误的文件。而使用install先删除后写入（会生成新的文件句柄）的方式去安装就能避免这些问题了；
- install命令会恰当地处理文件权限的问题；
- install命令可以打印出更多更合适的debug信息，还会自动处理SElinux上下文的问题。





参考

[1] https://lingxiankong.github.io/2014-01-06-linux-install.html