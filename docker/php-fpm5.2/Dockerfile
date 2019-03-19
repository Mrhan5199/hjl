FROM centos:6.9
MAINTAINER mrhan
RUN yum install libedit-devel gcc perl sqlite-devel  libcurl-devel  pcre pcre-devel speex  speex-devel libldns-dev alsa-lib libogg  postgresql libtheora  libtiff  libvorbis autoconf automake libtool gcc-c++ ncurses-devel make expat-devel zlib zlib-devel libjpeg-devel   libedit-devel sqlite-devel sqlite libcurl-devel libpcre pcre pcre-devle  pcre-devel  httpd mysql-server unixODBC-devel freetype libpng t1lib  libXpm  openssl-devel libxslt libc-client-devel -y
RUN useradd zswitch && usermod -G root zswitch
RUN sed -i s/Listen\ 80/Listen\ 8086/g /etc/httpd/conf/httpd.conf && sed -i "s/Group apache/Group zswitch/" /etc/httpd/conf/httpd.conf &&\
    sed -i "s/User apache/User zswitch/" /etc/httpd/conf/httpd.conf
ADD phpx86.tar.gz /usr/local/src
RUN rpm -ivh /usr/local/src/phpx86/*.rpm
RUN chown -R zswitch:zswitch  /var/lib/php/session
COPY apc.ini /etc/php.d/
COPY entrypoint.sh /entrypoint.sh
ADD APC-3.1.9.tgz /usr/local/src
WORKDIR /usr/local/src/APC-3.1.9
RUN phpize && ./configure --enable-apc --enable-apc-mmap --with-php-config=/usr/bin/php-config && make && make install && make test
EXPOSE 8086
WORKDIR  /var/www/html
CMD ["/bin/bash","/entrypoint.sh"]
