

安装scl源

> yum install centos-release-scl

查找可以安装的git版本

> yum list all --enablerepo='centos-sclo-rh' | grep git

安装

> yum install rh-git227

激活git的打开bash

> scl enable rh-git227 bash

