安装 git



> wget https://mirrors.edge.kernel.org/pub/software/scm/git/git-2.23.0.tar.xz
> tar xvf git-2.23.0.tar.xz
> cd git-2.23.0/
> make prefix=/usr/local/git install
> echo "export PATH=$PATH:/usr/local/git/bin" >> /etc/profile
> source /etc/profile