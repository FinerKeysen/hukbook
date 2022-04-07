# Git 合并多个 commit

**参考博客**

https://www.jianshu.com/p/964de879904a



**适用场景**

对某个功能的开发周期相对较长，或者基于某一功能需要改动的文件较多，进行了多次提交。

假设有三个commit记录，并且hash number如下

```shell
# hashC
commitC: third 
# hashB
commitB: second
# hashA
commitA: first
```

需要将C与B合并

1、抽取A之后的commit（不包含A）

```shell
$ git rebase -i hashA
```

会出现编辑页面，使用vim或者编辑器

```
pick hashC Add third
pick hashB Add second
```



2、pick 和 squash

- `pick` 的意思是要会执行这个 commit
- `squash` 的意思是这个 commit 会被合并到前一个commit

将待合并的commit改为squash，编辑结果如下：

```
pick hashC Add third
squash hashB Add second
```

`:wq`保存后退出当前编辑页，跳转至commit message编辑页

保留或更改需要的commit message之后再`:wq`保存退出，完成commit合并。
