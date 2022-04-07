# 分支使用方法

[TOC]

## 创建分支

```
# 创建本地 dev 分支
$ git branch dev

# 创建远程分支 remote-dev
# git push origin [local_name]:[remote_name]
$ git push origin dev:remote-dev
```

## 切换分支

```
# 切换到 dev 分支
$ git checkout dev

# 创建并切换到 dev 分支
$ git checkout -b dev
```

## 合并分支

假设需要将 dev 分支合并到 master 分支

```
# 先切回 master
$ git checkout master
# 再合并 dev 分支到 当前分支(master)
$ git merge dev
```

## 同步分支

### 同步分支列表

```
git fetch 
```

### 拉取分支最新信息

```
git pull
```



## 删除本地分支

```
# 删除本地 dev 分支
$ git branch -d dev

# 删除远程分支
# 方式1，git push origin [空的local]:[remote]
$ git push origin :remote-dev

# 方式2，git push origin --delete [remote]
$ git push origin --delete remote-dev
```

## 查看分支列表

### 本地分支

```
# 星号指示当前分支
$ git branch
# 或者
$ git branch -l
  master                ea2d619 增加鉴权失败次数和命令最大时延
  master-2.7            fc536cb Merge remote-tracking branch 'origin/master-2.7' into master-2.7
* release-2.8.1_Rocksdb a938d11 rename interface lib name to libredis_rocks
```

### 远程分支

```
$ git branch -r
  origin/HEAD -> origin/master
  origin/master
  origin/master-2.7
  origin/release-2.8.1
  origin/release-2.8.1_Lmdb
  origin/release-2.8.1_Rocksdb
```

### 所有分支(本地和远程)

```
# 远程分支带有 remote/xxx
$ git branch -a
  master
  master-2.7
* release-2.8.1_Rocksdb
  remotes/origin/HEAD -> origin/master
  remotes/origin/master
  remotes/origin/master-2.7
  remotes/origin/release-2.8.1
  remotes/origin/release-2.8.1_Lmdb
  remotes/origin/release-2.8.1_Rocksdb
```

### 分支最新的提交信息

```
# 查看本地所有分支的最后一次操作
$ git branch -v
  master                ea2d619 增加鉴权失败次数和命令最大时延
  master-2.7            fc536cb Merge remote-tracking branch 'origin/master-2.7' into master-2.7
* release-2.8.1_Rocksdb a938d11 rename interface lib name to libredis_rocks

# 查看所有分支的最后一次操作
$ git branch -av
  master                               ea2d619 增加鉴权失败次数和命令最大时延
  master-2.7                           fc536cb Merge remote-tracking branch 'origin/master-2.7' into master-2.7
* release-2.8.1_Rocksdb                a938d11 rename interface lib name to libredis_rocks
  remotes/origin/HEAD                  -> origin/master
  remotes/origin/master                ea2d619 增加鉴权失败次数和命令最大时延
  remotes/origin/master-2.7            fc536cb Merge remote-tracking branch 'origin/master-2.7' into master-2.7
  remotes/origin/release-2.8.1         7b40e91 fix 不落盘问题
  remotes/origin/release-2.8.1_Lmdb    180f1a2 提交LMDB 存储引擎包
  remotes/origin/release-2.8.1_Rocksdb a938d11 rename interface lib name to libredis_rocks

# 查看远程所有分支的最后一次操作
$ git branch -v
  master                ea2d619 增加鉴权失败次数和命令最大时延
  master-2.7            fc536cb Merge remote-tracking branch 'origin/master-2.7' into master-2.7
* release-2.8.1_Rocksdb a938d11 rename interface lib name to libredis_rocks

# 两个v,显示关联的上游(远程)分支
$ git branch -vv
  master                ea2d619 [origin/master] 增加鉴权失败次数和命令最大时延
  master-2.7            fc536cb [origin/master-2.7] Merge remote-tracking branch 'origin/master-2.7' into master-2.7
* release-2.8.1_Rocksdb a938d11 [origin/release-2.8.1_Rocksdb] rename interface lib name to libredis_rocks
```

