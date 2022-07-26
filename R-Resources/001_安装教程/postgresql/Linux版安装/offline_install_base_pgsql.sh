# !/bin/sh

# 组件名
compenent_name=pgsql
compenent_1=postgresql
compenent_2=pgpool-II
# 版本，如 10
postgresql_version=10
pgpool_version=4
# 源码地址
postgresql_url=https://ftp.postgresql.org/pub/source/v10.10/postgresql-10.10.tar.gz
pgpool_url=http://www.pgpool.net/mediawiki/images/pgpool-II-4.0.6.tar.gz
# 连接端口，如 15010
pgport=15010
# ssh 用户也是数据库默认超级用户,如 ctgcache
my_user=ctgcache
# ssh 用户密码
my_passwd=XXXX
# 数据库默认超级用户,如 ctgcache
sp_dbuser=$my_user
# 数据库密码，如 pg1235
sp_dbuser_password=pg1235

$原始根目录
home=`pwd`

# 安装、数据空间、脚本的根目录
install_root_path=$home/ctg-$compenent_name/opt
pgdata_root_path=$home/ctg-$compenent_name/usr/$compenent_name/pgdata
scripts_root_path=$home/ctg-$compenent_name/usr/scripts/

# postgresql 安装路径
postgresql_install_path=$install_root_path/$compenent_name-$postgresql_version
# postgresql 数据空间路径
postgresql_data_path=$pgdata_root_path/$postgresql_version/data
# postgresql 数据空间归档路径
postgresql_archive_path=$pgdata_root_path/$postgresql_version/archive
# postgresql 实例管理脚本路径
pg_inst_manage_scripts_path=$scripts_root_path/inst_manage_scripts
# postgresql 实例监控脚本路径
pg_monitor_scripts_path=$scripts_root_path/monitor_scripts
# postgresql 实例监控记录路径
pg_monitor_record_path=$scripts_root_path/monitor_scripts/record
# postgresql 数据库SQL执行脚本路径
pg_db_sql_scripts_path=$scripts_root_path/sql_scripts

#=================================================#
#                  安装依赖、工具                 #
#=================================================#
yum install -y gcc wget
yum install -y readline-devel zlib-devel

# 要在某用户下安装 postgresql
# 先创建用户、授权(可有可无)
# 参考博客：https://www.cnblogs.com/woshimrf/p/5906084.html
useradd $my_user
passwd $my_user
input new password:
type new password again:

#=================================================================#
#               以下步骤通过 my_user 账户来操作                   #
#=================================================================#
# 配置相关路径
create_dir_str= ctg-$compenent_name/{softwares,usr/{pgsql/pgdata/$postgresql_version/{archive,backup,data},scripts/{inst_manage_scripts,monitor_scripts/record,sql_scripts}},lib,log,opt/pgsql-$postgresql_version,$compenent_2-$pgpool_version}
mkdir -p $create_dir_str

# 安装包路径
package_path=$home/softwares

# 准备安装包
cd $package_path
wget $postgresql_url
wget $pgpool_url

#  解压所有的源码包
for bag in (ls *.tar.gz); tar -xf $i; done 

#====================================#
#           安装 postgresql          #
#====================================#
cd $package_path
cd postgresql-10.10
./configure --prefix=$postgresql_install_path --with-pgport=$pgport
make world -j8
make install-world -j8

# 添加环境变量
#===========================#
#           示例            #
#===========================#
# export PGPORT=15010
# export PGHOME=/root/ctg-pgsql/opt/pgsql-10.10
# export PGPATH=$PGHOME/bin
# export PGDATA=/root/ctg-pgsql/usr/pgsql/pgdata/10.10/data

export PGPORT=$pgport
export PGHOME=$postgresql_install_path
export PGPATH=$PGHOME/bin
export PGDATA=$postgresql_data_path
export PGDATA=$postgresql_archive_path

export PGPOOLHOME=/home/ctgcache/ctg-pgsql/opt/pgpool-II-4
export PGPOOLPATH=$PGPOOLHOME/bin

export PATH=$PATH:$HOME/bin:$PGHOME:$PGPATH:$PGPOOLHOME:$PGPOOLPATH

# 改 postgresql.conf

# 改 pg_hba.conf

# 主库上添加 replication 用户

# 在备库上复制数据

# 更改备库 data 的权限
cd $PGDATA/..
chmod 0700 data

# 相关脚本
# 监控脚本
cd $pg_monitor_scripts_path
touch monitor.sh
chmod 0775 monitor.sh
# 添加内容 参见 monitor.sh


#===================================#
#             安装 pgpool           #
#===================================#
cd $package_path
cd pgpool-II-4.0.6
./configure --prefix=$PGPOOLHOME
make 
make install

# 主库上安装扩展
cd $package_path/pgpool-II-4.0.6
cd src/sql
make
make install
cd pgpool-regclass/
psql -d postgres -U ctgcache -f pgpool-regclass.sql
# 安装 insert 扩展
cd ../../sql/
psql -d postgres -U ctgcache -f insert_lock.sql
# 安装 C 语言函数扩展
cd pgpool-recovery/
make install
psql -d postgres -U ctgcache -f pgpool-recovery.sql


# 相关配置
mkdir -p {run/pgpool,log/pgpool,scripts}
cd $PGPOOLHOME/etc
cp pgpool.conf.sample pgpool.conf
cp pool_hba.conf.sample pool_hba.conf
cp pcp.conf.sample pcp.conf
# 改 pgpool.conf pool_hba.conf pcp.conf

# 添加 pgpool 认证
pg_md5 -m -u $USER $sp_dbuser_password
pg_md5 -m -u repl 123456


# 添加 failover.sh 脚本
cd $PGPOOLHOME/scripts
touch failover.sh
chmod 0775 failover.sh
