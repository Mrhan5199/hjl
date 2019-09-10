### 安装*iftop*

***安装EPEL源***

CentOS/RHEL 5 ：

rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-5.noarch.rpm

CentOS/RHEL 6 ：

rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-6.noarch.rpm

CentOS/RHEL 7 ：

rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm

yum -y install iftop

***二进制安装***

安装依赖：

yum install -y gcc flex byacc libpcap ncurses ncurses-devel libpcap-devel tcpdump

下载源码编译：

wget http://www.ex-parrot.com/pdw/iftop/download/iftop-0.17.tar.gz

tar zxvf iftop-0.17.tar.gz
cd iftop-0.17
./configure 
make
make install