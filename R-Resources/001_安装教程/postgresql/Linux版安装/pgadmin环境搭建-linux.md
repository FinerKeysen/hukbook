# pgadmin环境搭建-linux





# 硬件要求

- 内存要求4G
- 文档适用于centos7.4
- 科学上网 pgadmin4安装时 yarn install有3个包需要翻墙下载
- 安装postgreSql12
- 安装python3.6
- 安装pip==20.3.4（python2.7）
- 安装node 14 
- 安装yarn



## 安装脚本

使用安装脚本安装 .

运行用户需要sudo权限 

脚本将替换 ~/ .bash_profile。 若非新用户安装，需要对目录的.bash_profile修改



```
#上传tool文件夹 到服务器。 
#运行用户具备sudo权限 

#1. 执行postgresql安装
sh install_postgreSQL.sh
# 可选操作 配置pg, 创建pguser用户和exampledb数据库。 也可自行配置, 密码为123456
sh install_postgreSQL_config.sh    

#2. 安装相关软件
#注意会替换 ~/.bash_profile
sh install_sofeware.sh
source ~/.bash_profile 

#3. 安装pgadmin4
#设置科学上网，修改git代理地址
#若yarn install 因网络问题中断，可再执行重试
#python3 ./web/setup.py 时需创建登录帐号 邮箱+密码
git config --global https.proxy http://192.168.3.65:7890
git config --global http.proxy http://192.168.3.65:7890
sh install_pgadmin4.sh

#4. 访问pgadmin   http://192.168.3.67:5050/browser/
# 登录帐号 邮箱+密码
# 连接数据库  192.168.3.67:5432   pguser/123456

#5. 可选 启动pgadmin4
sh start_pgadmin4.sh
# 取消代理
git config --global --unset http.proxy
git config --global --unset https.proxy
```



## PostgreSQL安装 

参考： https://jingyan.baidu.com/article/fdffd1f8e0e700b2e88ca129.html



官网选择下载的版本, 安装12版本 

https://www.postgresql.org/download/linux/redhat/

```
# Install the repository RPM:
sudo yum install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm

# Install PostgreSQL:
sudo yum install -y postgresql12-server

# Optionally initialize the database and enable automatic start:
sudo /usr/pgsql-12/bin/postgresql-12-setup initdb
sudo systemctl enable postgresql-12
sudo systemctl start postgresql-12

#重启pg
sudo systemctl restart postgresql-12
```



启动后:

```
$ ps -efl| grep postmaster
4 S postgres  1713     1  0  80   0 - 98418 poll_s 19:53 ?        00:00:00 /usr/pgsql-12/bin/postmaster -D /var/lib/pgsql/12/data/
```

注： -D  /var/lib/pgsql/12/data/   数据库文件目录 



## Postgresql默认用户名与密码

参考http://www.ruanyifeng.com/blog/2013/12/getting_started_with_postgresql.html



初次安装后，默认生成一个名为postgres的数据库和一个名为postgres的数据库用户。这里需要注意的是，同时还生成了一个名为postgres的Linux系统用户。



- postgres 用户调整

```
#postgres 用户建登录目录
sudo mkdir /home/postgres
sudo chown -R postgres:postgres /home/postgres/
sudo usermod -d  /home/postgres  postgres

#修改postgres密码
sudo passwd postgres 
```



- 新建一个Linux新用户

```
sudo adduser pguser   #
sudo passwd pguser
```

- 创建数据库

```
sudo su - postgres
psql                  #登录控制台 

postgres=# \password postgres    #修改postgres用户的密码

postgres=# CREATE USER pguser WITH PASSWORD '123456'; #创建数据库用户，与linux系统用户一致

postgres=# CREATE DATABASE exampledb OWNER pguser;   #创建用户数据库

postgres=# GRANT ALL PRIVILEGES ON DATABASE exampledb to pguser;  #将exampledb数据库的所有权限都赋pguser
```



- pg允许用户登录 ，远程访问

参考 https://www.linuxidc.com/linux/2014-09/106772.htm

​         https://www.cnblogs.com/telwanggs/p/10494792.html

```
su - postgres
vi /var/lib/pgsql/12/data/pg_hba.conf

#1. 把这个配置文件中的认证 METHOD的ident修改为trust，可以实现用账户和密码来访问数据库，
host    all         all          127.0.0.1/32            trust
#2. 添加 表示允许所有主机使用所有合法的数据库用户名访问数据库，并提供加密的密码验证。
host  all    all    0.0.0.0/0    md5

vi  /var/lib/pgsql/12/data/postgresql.conf
listen_addresses=’*’        #许数据库服务器监听来自任何主机的连接请求

#重启pg
sudo systemctl restart postgresql-12

```

- 登录数据库

```
#本机登录
su - pguser
psql -U pguser -d exampledb -h 127.0.0.1 -p 5432

#远程登录
#pgadmin web端新建连接 
```



- psql基础操作

```
\l           # 查看数据库列表
\d           # 查看表列表
\c 数据库名   #  进入数据库
\d 表名       # 查看表信息
```







## python3 安装 

pgAdmin4/README.md 中说明需要python3环境    “Python version 3.5 and later are currently supported. ”



centos7安装python3 https://www.jianshu.com/p/e191f9dc1186

```
sudo yum -y install openssl-devel bzip2-devel expat-devel gdbm-devel readline-devel sqlite-devel
sudo yum -y install gcc gcc-g++

cd /home/gary/develop
wget https://www.python.org/ftp/python/3.6.5/Python-3.6.5.tgz

tar -zxvf Python-3.6.5.tgz
cd Python-3.6.5
./configure -prefix=/usr/local/python3
sudo make && sudo make install

sudo ln -s /usr/local/python3/bin/python3 /usr/bin/python3 #为python3创建软连接
sudo ln -s /usr/local/python3/bin/pip3 /usr/bin/pip3  #为pip3创建软连接

python3 -V # 输入
pip3 -V  #V大写
```





## 安装python虚拟环境 

虚拟环境的说明参考 https://www.jb51.net/article/189848.htm

​                                   https://blog.csdn.net/u010525694/article/details/82251216

​                                   https://blog.51cto.com/wutengfei/2296168

​                                   https://www.cnblogs.com/reaptem/p/13890122.html

```
#系统依赖（安装到系统环境）
sudo yum install gcc python-devel -y 

#安装python应用开发依赖（python/pip/virtualenv）
##使用centos7系统自带的python2.7即可 

#安装python2-pip（安装到系统python中） 
sudo yum -y install epel-release 
sudo yum -y install python2-pip 
pip -V #大V
##注意：python3配套的是python3-pip 

#升级pip  升级后为21.0.1 不可用，改用20.3.4
#pip install --upgrade pip
#sudo yum -y remove python2-pip 
#sudo yum -y install python2-pip 
sudo pip install --upgrade pip==20.3.4
```



```
#安装虚拟环境（安装到系统python中） 
sudo pip install virtualenv   #安装到python2中
sudo pip3 install virtualenv  #安装到python3中

#安装virtualenvwrapper   virtualenv 实际上已经足够优秀，但是在操作上稍稍有些繁琐。比如每次使用 source命令激活环境，忘记虚拟环境的地址等等。 virtualenvwrapper 这一工具会让你觉得环境管理是如此简单，优雅。
sudo pip install virtualenvwrapper   #安装到python2中
sudo pip3 install virtualenvwrapper   #安装到python3中

#指定虚拟环境的位置
vi ~/.bash_profile
export WORKON_HOME=/home/gary/develop/py3env
source /usr/local/python3/bin/virtualenvwrapper.sh

source ~/.bash_profile
```





## 安装nodejs

参考 https://www.cnblogs.com/klvchen/p/12923984.html

```
cd /home/gary/develop
#wget https://nodejs.org/download/release/v10.16.0/node-v10.16.0-linux-x64.tar.gz
#tar -zxvf node-v10.16.0-linux-x64.tar.gz
#需要大于10.17
https://nodejs.org/download/release/v14.16.0/node-v14.16.0-linux-x64.tar.gz 
tar -zxvf node-v14.16.0-linux-x64.tar.gz 

vi ~/.bash_profile
export NODEJS=/home/gary/develop/node-v14.16.0-linux-x64
export PATH=$PATH:$NODEJS/bin

. ~/.bash_profile
```

注：  nodejs 版本需要 12+



## 安装yarn

参考https://www.cnblogs.com/dousnl/p/12052834.html

```
cd /home/gary/develop
wget https://github.com/yarnpkg/yarn/releases/download/v1.21.0/yarn-v1.21.0.tar.gz
tar -zxvf yarn-v1.21.0.tar.gz 

vi ~/.bash_profile
PATH=$PATH:$HOME/.local/bin:$HOME/bin:/home/gary/develop/yarn-v1.21.0/bin

. ~/.bash_profile
```



## pgAdmin4  源码安装



源码地址：https://github.com/postgres/pgadmin4

官网说明： https://www.pgadmin.org/docs/pgadmin4/development/server_deployment.html

参考： https://zhuanlan.zhihu.com/p/98434824

​             https://www.jianshu.com/p/98c394f25cc4

​             https://www.tecmint.com/install-pgadmin4-in-centos-7/

​             https://zhuanlan.zhihu.com/p/98426676



pgAdmin4 是python开发的web应用程序，既可以部署为web模式通过浏览器访问，也可以部署为桌面模式独立运行。



```
#新建目录及赋用户权限 
sudo mkdir -p /var/lib/pgadmin
sudo mkdir -p /var/log/pgadmin
sudo chown -R $EXEC_USER:$EXEC_USER /var/lib/pgadmin   #将目录赋予pgadmin运行用户
sudo chown -R $EXEC_USER:$EXEC_USER /var/log/pgadmin  

#关闭防火墙
sudo systemctl stop firewalld.servic
sudo systemctl disable firewalld.service
sudo firewall-cmd --state


sudo yum -y install gcc-c++ make 
sudo yum -y install autoconf automake libtool
sudo yum -y install libpng libpng-devel 

```



```
#git clone https://github.com/postgres/pgadmin4.git
#解压代码包
tar -zxvf pgadmin4.tar.gz -C $WORKON_HOME
```



#config_local.py  作为安装配置文件，放到 pgadmin4/web/

    ```python
    from config import *
    
    # Debug mode
    DEBUG = True
    
    # App mode
    SERVER_MODE = True
    
    # Enable the test module
    MODULE_BLACKLIST.remove('test')
    
    # Log
    CONSOLE_LOG_LEVEL = DEBUG
    FILE_LOG_LEVEL = DEBUG
    
    DEFAULT_SERVER = '127.0.0.1'
    
    UPGRADE_CHECK_ENABLED = True
    
    # Use a different config DB for each server mode.
    if SERVER_MODE == False:
        SQLITE_PATH = os.path.join(
            DATA_DIR,
            'pgadmin4-desktop.db'
        )
    else:
        SQLITE_PATH = os.path.join(
            DATA_DIR,
            'pgadmin4-server.db'
        )



```
cd $WORKON_HOME
# 创建虚拟环境（ 注意--no-site-packages已被弃用） 
mkvirtualenv  -p /usr/bin/python3  pgadmin4     #使用python3创建虚拟环境 


#启动虚拟环境 
cd $WORKON_HOME/pgadmin4
#source bin/activate 
workon pgadmin4

#安装python依赖
#将pgadmin4/requirements.txt中的psycopg2修改为psycopg2-binary 
#vi requirements.txt 
#    psycopg2-binary==2.8.* #psycopg2==2.8.* 
perl -pi -e 's/psycopg2==/psycopg2-binary==/g' requirements.txt 
pip3 install -r requirements.txt 
```



```
#有三个包需要翻墙代理才能下载 jquery-aciTree
#git config --global https.proxy http://10.190.188.242:7890
#git config --global http.proxy http://10.190.188.242:7890
# 取消代理
#git config --global --unset http.proxy
#git config --global --unset https.proxy
#安装git，因为yarn install常用到git 
yum install -y git 

#cd  $WORKON_HOME/pgadmin4
#make install-node
#make bundle
#用npm太慢，经常卡住
#因为npm太慢，改用yarn
#安装前端依赖
cd  $WORKON_HOME/pgadmin4/web
yarn install
yarn run bundle

```

TODO: 新的环境如何使用已经下载的node_module



安装，启动

```
#安装配置库和配置文件 
cd $WORKON_HOME/pgadmin4
python3 ./web/setup.py 
#输入初始帐号（邮箱）、密码

#启动应用pgadmin4
python3 ./web/pgAdmin4.py 
#browse: http://localhost:5050/
```







### 问题记录

- pip install --upgrade pip 后 pip不可用

 File "/usr/lib/python2.7/site-packages/pip/_internal/cli/main.py", line 60
   sys.stderr.write(f"ERROR: {exc}")



直接更新的是21.0.1 , 降级安装是版本

```
sudo yum -y remove python2-pip 
sudo yum -y install python2-pip 

sudo install --upgrade pip==20.3.4
```



- ImportError: No module named importlib_metadata

importlib_metadata 新版要python3.8, 安装指定的旧版本

参考 https://zhuanlan.zhihu.com/p/195140891

```
sudo pip install importlib_metadata==1.5.0
```





- yarn install 有三个包不能下载， git 代理  

https://www.cnblogs.com/xueweihan/p/7242577.html

```
# 设置ss
git config --global http.proxy 'socks5://127.0.0.1:1080'
git config --global https.proxy 'socks5://127.0.0.1:1080'

# 设置代理
git config --global https.proxy http://127.0.0.1:1080
git config --global https.proxy https://127.0.0.1:1080

#查看代理
git config --global --get http.proxy
git config --global --get https.proxy

# 取消代理
git config --global --unset http.proxy
git config --global --unset https.proxy
```

有三个包需要翻墙代理才能下载 jquery-aciTree

git config --global https.proxy http://10.190.189.87:7890
git config --global http.proxy http://10.190.189.87:7890



- pgAdmin4启动后， ip:5050不能访问

要关闭防火墙

systemctl stop firewalld.service



- yarn run bundle 报内存溢出

Ineffective mark-compacts near heap limit Allocation failed - JavaScript heap out of memory

Node 是基于V8引擎，在一般的后端开发语言中，在基本的内存使用上没有什么限制，但是，**在 Node 中通过 JavaScript 使用内存时只能使用部分内存（64位系统下约为1.4 GB，32位系统下约为0.7 GB）**所以不管你电脑实际内存多大，在node运行JavaScript打包编译的时候所使用的内存大小，并不会因为你系统的实际内存大小改变而改变

```
#环境变量设置
export NODE_OPTIONS="--max-old-space-size=4096"
```

注：如果是虚拟机，要设置内存为4G以上



- npm install慢

改为进行web/目录    yarn install

npm 替换镜像源 https://blog.csdn.net/qwe435541908/article/details/93140354

```text
#查看当前安装源
npm config get registry 
#临时（安装时）换源：
npm install --registry=https://registry.npm.taobao.org 
#永久换源
npm config set registry http://registry.npm.taobao.org
```







