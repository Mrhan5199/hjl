# centos7 certbot证书生成

### 启用 EPEL repo 源 
```shell
wget -O /etc/yum.repos.d/epel-aliyun.repo https://mirrors.aliyun.com/repo/epel-7.repo
```
### 安装配置依赖
```shell
yum -y install yum-utils
yum-config-manager --enable rhui-REGION-rhel-server-extras rhui-REGION-rhel-server-optional
```
### 安装 Certbot
```shell
yum install certbot python2-certbot-nginx
```
### 开始配置证书
+ 关闭nginx端口，确认80端口不被占用
```shell
certbot certonly --standalone -d cls.cdqidian.cn -d cls-1.cdqidian.cn -m 849272199@qq.com --agree-tos
```
+ 证书生成目录
```shell
[root@206 conf.d]# cd /etc/letsencrypt/
[root@206 letsencrypt]# ls
accounts  archive  csr  keys  live  renewal  renewal-hooks
[root@206 letsencrypt]# cd live/
[root@206 live]# ls
cls.cdqidian.cn  README
[root@206 live]# cd cls.cdqidian.cn/
[root@206 cls.cdqidian.cn]# ls
cert.pem  chain.pem  fullchain.pem  privkey.pem  README
```
+ 配置nginx
```shell
server {
    listen       443;
    ssl on;
    ssl_certificate     /etc/letsencrypt/live/cls.cdqidian.cn/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/cls.cdqidian.cn/privkey.pem;
    server_name  cls.cdqidian.cn;
    location / {
	root   /data/policysys/code/dist;
    	index  index.html index.htm;
	try_files $uri $uri/ /index.html;
    }
}
server {
    if ($host = cls.cdqidian.cn) {
        return 301 https://$host$request_uri;
    } # managed by Certbot
    listen       80;
    server_name  cls.cdqidian.cn;
    return 404; # managed by Certbot

}
```
+ 启动nginx
```shell
service nginx start
```
+ certbot默认生成的证书有效期90天，配置脚本自动续期
```shell
cat /etc/letsencrypt/renewal/cls.cdqidian.cn.conf

renew_before_expiry = 89 days
version = 1.0.0
archive_dir = /etc/letsencrypt/archive/cls.cdqidian.cn
cert = /etc/letsencrypt/live/cls.cdqidian.cn/cert.pem
privkey = /etc/letsencrypt/live/cls.cdqidian.cn/privkey.pem
chain = /etc/letsencrypt/live/cls.cdqidian.cn/chain.pem
fullchain = /etc/letsencrypt/live/cls.cdqidian.cn/fullchain.pem
# Options used in the renewal process
[renewalparams]
authenticator = standalone
account = 0e1d5cecf54c1dd94c41e0f978f1e15e
server = https://acme-v02.api.letsencrypt.org/directory
```
+ 设置定时任务跟新证书
```shell
00 00 1 * * /usr/bin/certbot renew --force-renewal --pre-hook "systemctl stop nginx" --post-hook "systemctl start nginx" >> /var/log/letsencrypt/letsencrypt.log 2>&1
```