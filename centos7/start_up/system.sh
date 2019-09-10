#cenots7安装系统
#!/bin/bash
yum install openssl-devel pciutils lsof usbutils acpid wget ntp ntpdate dmidecode parted lrzsz iptables-services iptables mysql php net-tools -y
##关闭自带防火墙
systemctl disable firewalld && systemctl stop firewalld
sed -i s/SELINUX=enforcing/SELINUX=disabled/g /etc/selinux/config
setenforce 0
##更改ssh端口
sed -i s/#Port\ 22/Port\ 8022/g /etc/ssh/sshd_config
##添加防火墙规则
/bin/bash /usr/local/src/iptables.sh
###配置web
mkdir -p /var/www/html/ 
mkdir -p /usr/local/freeswitch
cd /var/www/html/
mv /usr/local/src/zsitsms.tar.gz ./
tar -zxvf zsitsms.tar.gz
###安装docker
wget -O /etc/yum.repos.d/docker-ce.repo  https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
yum -y install docker-ce-18.06.1.ce-3.el7
systemctl start docker && systemctl enable docker
###安装docker-compose执行服务
curl -L https://github.com/docker/compose/releases/download/1.23.0/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
###登录并拉取镜像
docker login --username=849272199@qq.com --password=han849272199 registry.cn-hangzhou.aliyuncs.com
docker-compose -f /usr/local/src/docker-compose.yaml up -d
###添加freeswitch防火墙规则
CIP=$(docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' freeswitch)
iptables -A DOCKER -t nat -p udp -m udp ! -i docker0 --dport 16384:32768 -j DNAT --to-destination $CIP:16384-32768
iptables -A DOCKER -p udp -m udp -d $CIP/32 ! -i docker0 -o docker0 --dport 16384:32768 -j ACCEPT
iptables -A POSTROUTING -t nat -p udp -m udp -s $CIP/32 -d $CIP/32 --dport 16384:32768 -j MASQUERADE
###定时脚本执行
echo "*/10 * * * * /usr/sbin/ntpdate cn.pool.ntp.org && /usr/sbin/ntpdate time.windows.com && /usr/sbin/hwclock -w
00 18 * * 5 /bin/rm -fr /usr/local/freeswitch/log/freeswitch.log.*
10 18 * * 5 /bin/ls /usr/local/freeswitch/log/xml_cdr|xargs -n 10 rm -fr ls
00 19 * * * /usr/local/src/backsql.sh zsitsms
10 09 * * * chmod -R 755 /usr/local/freeswitch/recordings/" >/var/spool/cron/root
