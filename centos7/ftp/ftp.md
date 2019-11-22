#Linux vsftp搭建
1. 安装ftp服务端
2. 安装PAM
3. 创建虚拟用户，配置PAM
4. 编写配置文件
5. 创建防火墙规则

- 安装ftp服务端  
`yum -y install vsftpd`
- 安装pam  
`yum install pam* libdb-utils libdb* -y`
- 创建虚拟用户，配置pam  
    1.`mkdir virtual_user.txt `   
    ````
    [root@206 vsftpd]# vi virtual_user.txt 
    [root@206 vsftpd]# cat virtual_user.txt
    admin
    qiDian@1912
    mrhan
    qwer1234
    ````  
    2 . 生成数据库文件
    ````
    db_load -T -t hash -f virtual_user.txt virtual_user.db
    chmod 700 virtual_user.db
    ````  
    ````
    [root@206 vsftpd]# cat /etc/pam.d/vsftpd
    auth        required    /lib64/security/pam_userdb.so db=/etc/vsftpd/virtual_user
    account     required    /lib64/security/pam_userdb.so db=/etc/vsftpd/virtual_user
    ````  
    3 . 创建虚拟用户
    ````
    useradd virtual -d /data/ftp/pub/ -s /sbin/nologin virtual
    chown -R virtual:virtual /data/ftp/pub/
    chmod -R 700 /data/ftp/pub/
    ````  
- 编写配置文件(被动模式)
    ````
    [root@206 vsftpd]# cat /etc/vsftpd/vsftpd.conf 
    anonymous_enable=no
    local_enable=YES
    write_enable=YES
    local_umask=022
    dirmessage_enable=YES
    xferlog_enable=YES
    connect_from_port_20=no
    xferlog_std_format=YES
    listen=NO
    listen_ipv6=YES
    pam_service_name=vsftpd
    userlist_enable=YES
    tcp_wrappers=YES
    guest_enable=YES
    guest_username=virtual
    user_config_dir=/etc/vsftpd/virtual_users_conf
    chroot_local_user=YES
    chroot_list_enable=NO
    allow_writeable_chroot=YES
    pasv_enable=YES
    pasv_min_port=60000
    pasv_max_port=60006
    ````  
    1. 编写用户配置文件
        ````
        [root@206 vsftpd]# cd virtual_users_conf/
        [root@206 virtual_users_conf]# cat mrhan 
        local_root=/data/ftp/pub/mrhan
        anon_world_readable_only=NO
        write_enable=YES
        anon_mkdir_write_enable=YES
        anon_upload_enable=YES
        anon_other_write_enable=YES
        ````   
     2. 设置目录访问权限
        ````
        chown -R virtual:virtual /data/ftp/pub/mrhan
        chmod -R 700 /data/ftp/pub/mrhan
        ````
- 创建防火墙规则
   ````
   iptables -A INPUT -p tcp -m state --state NEW -m tcp --dport 21 -j ACCEPT
   iptables -A INPUT -p tcp -m state --state NEW -m tcp --dport 60000:60006 -j ACCEPT
   ````
- 重启ftp服务
   ````
   service vsftpd restart
   ````