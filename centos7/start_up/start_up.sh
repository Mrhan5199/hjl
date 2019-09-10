#cenots7安装系统
#!/bin/bash
yum install libedit-devel gcc perl sqlite-devel libcurl-devel pcre pcre-devel speex  speex-devel libldns-dev alsa-lib libogg  postgresql libtheora libtiff libvorbis autoconf automake libtool gcc-c++ ncurses-devel make expat-devel zlib zlib-devel libjpeg-devel libpcre unixODBC-devel freetype libpng t1lib libXpm openssl-devel libxslt libc-client-devel  pciutils lsof usbutils acpid wget ntp ntpdate dmidecode parted lrzsz iptables-services mysql php net-tools git -y
##关闭防火墙
systemctl disable firewalld && systemctl stop firewalld
sed -i s/SELINUX=enforcing/SELINUX=disabled/g /etc/selinux/config
setenforce 0
##更改ssh端口
sed -i s/#Port\ 22/Port\ 8022/g /etc/ssh/sshd_config
##添加防火墙规则
/bin/bash /usr/local/src/iptables.sh
##安装fs
cd /usr/local/src
tar -zxvf freeswitch-1.4.13.tar.gz
mv /usr/local/src/json-c-0.9.tar.gz opus-1.1-p2.tar.gz ./freeswitch-1.4.13/libs
cd freeswitch-1.4.13
./configure && make && make install
cd /usr/local/freeswitch
rm -rf conf scripts
mv /usr/local/src/conf/  ./
mv /usr/local/src/scripts/  ./
mv /usr/local/src/freeswitch /etc/init.d/freeswitch
chmod a+x /etc/init.d/freeswitch
useradd zswitch
usermod -G root zswitch
chkconfig --add freeswitch
chkconfig freeswitch on
mkdir -p /usr/local/freeswitch/recordings/backup
chmod +x /usr/local/src/backsql.sh
###配置web
cd /var/www/html/
mv /usr/local/src/zsitsms.tar.gz ./
tar -zxvf zsitsms.tar.gz
cd /var/www/html/zsitsms
chmod -R 777 cache templates uploads
###安装docker
cd /etc/yum.repos.d/
wget https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
yum -y install docker-ce-18.06.1.ce-3.el7
systemctl start docker && systemctl enable docker
###安装docker-compose执行服务
curl -L https://github.com/docker/compose/releases/download/1.23.0/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
###登录并拉取镜像
docker login --username=849272199@qq.com --password=han849272199 registry.cn-hangzhou.aliyuncs.com
docker-compose -f /usr/local/src/docker-compose.yaml up -d
###定时脚本执行
echo "*/10 * * * * /usr/sbin/ntpdate cn.pool.ntp.org && /usr/sbin/ntpdate time.windows.com && /usr/sbin/hwclock -w
00 18 * * 5 /bin/rm -fr /usr/local/freeswitch/log/freeswitch.log.*
10 18 * * 5 /bin/ls /usr/local/freeswitch/log/xml_cdr|xargs -n 10 rm -fr ls
00 19 * * * /usr/local/src/backsql.sh zsitsms" >/var/spool/cron/root
