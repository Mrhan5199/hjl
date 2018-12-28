FROM centos
MAINTAINER mrhan-849272199@qq.com
RUN yum install -y pcre-devel wget net-tools gcc zlib zlib-devel make openssl-devel vim
RUN useradd -M -s /sbin/nologin nginx
ADD http://nginx.org/download/nginx-1.15.7.tar.gz /usr/local/src
WORKDIR  /usr/local/src
RUN tar zxvf nginx-1.15.7.tar.gz
RUN cd nginx-1.15.7 && ./configure --prefix=/usr/local/nginx --user=nginx --group=nginx --with-http_stub_status_module && make && make install
ENV PATH /usr/local/nginx/sbin:$PATH
RUN rm -rf /usr/local/src/*
WORKDIR /
expose 80
CMD ["nginx","-g","daemon off;"]
