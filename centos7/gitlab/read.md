## 使用Docker部署GitLab服务并启用HTTPS
- [官方地址](https://docs.gitlab.com/omnibus/docker/#pre-configure-docker-container)
- 使用官方提供的 Docker 镜像部署 GitLab 非常方便，相关的安装配置文档也非常详细。本文主要是对一次成功的部署流程进行记录，方便下次快捷部署
### 部署方式
- 本文采用docker-compose方式部署
```
version: '3'
services:
  gitlab:
    image: gitlab/gitlab-ce:latest
    container_name: gitlab
    hostname: 'gitlab.mrhan.cloud'
    restart: always
    environment:
      GITLAB_OMNIBUS_CONFIG: |
        external_url 'https://gitlab.mrhan.cloud'
        gitlab_rails['gitlab_ssh_host'] = 'gitlab.mrhan.cloud'
        gitlab_rails['gitlab_shell_ssh_port'] = 8022
        nginx['redirect_http_to_https'] = true
        nginx['ssl_certificate'] = "/etc/gitlab/trusted-certs/fullchain1.pem"
        nginx['ssl_certificate_key'] = "/etc/gitlab/trusted-certs/privkey1.pem"
    ports:
      - "8001:443"
      - "8022:22"
    volumes:
      - /etc/letsencrypt/archive/gitlab.mrhan.cloud:/etc/gitlab/trusted-certs
      - /srv/gitlab/config:/etc/gitlab
      - /srv/gitlab/logs:/var/log/gitlab
      - /srv/gitlab/data:/var/opt/gitlab
    networks:
      - gitlab-network
  gitlab-runner:
    image: gitlab/gitlab-runner:latest
    container_name: gitlab-runner
    restart: always
    volumes:
      - /srv/gitlab-runner/config:/etc/gitlab-runner
      - /var/run/docker.sock:/var/run/docker.sock
    networks:
      - gitlab-network
    links:
      - gitlab
networks:
  gitlab-network:
    driver: bridge 
```
### 开启https
- external_url会影响 GitLab 中创建项目的 URL 地址，如果不配置，则默认使用容器的 hostname，即容器 ID，这里需要配置为 GitLab 服务的域名。
ssl_certificate和ssl_certificate_key用于配置 HTTPS 所需要的证书，这两份证书需要在启动 GitLab 时挂载到容器中。注意，如果external_url使用 https，那么这里就必须自己生成证书挂载进来，而不能依赖容器内部的 Nginx 自动生成证书，否则将无法访问 GitLab。
```
external_url 'https://gitlab.mrhan.cloud'
nginx['ssl_certificate'] = "/etc/gitlab/trusted-certs/fullchain1.pem"
nginx['ssl_certificate_key'] = "/etc/gitlab/trusted-certs/privkey1.pem"
```
### 邮件配置
- vim /srv/gitlab/config/gitlab.rb
```
gitlab_rails['gitlab_email_from'] = '849272199@qq.com'
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "smtp.qq.com"
gitlab_rails['smtp_port'] = 465
gitlab_rails['smtp_user_name'] = "849272199@qq.com"
gitlab_rails['smtp_password'] = "iqiappklagrdbfec"
gitlab_rails['smtp_domain'] = "smtp.qq.com"
gitlab_rails['smtp_authentication'] = "login"
gitlab_rails['smtp_enable_starttls_auto'] = true
gitlab_rails['smtp_tls'] = true
```
- 测试，进入容器
```
root@gitlab:/# gitlab-rails console
--------------------------------------------------------------------------------
 GitLab:       12.10.6 (833223f2a7f) FOSS
 GitLab Shell: 12.2.0
 PostgreSQL:   11.7
--------------------------------------------------------------------------------
Loading production environment (Rails 6.0.2)
irb(main):001:0>  Notify.test_email('849272199@qq.com', 'test', 'mrhan').deliver_now
```

### gitlab-runner部署
1. 进入容器
```
docker exec -it gitlab-runner bash
```
2. 注册到gitlab
```
gitlab-runner register
```
3. 获取token
```
在GitLab web界面 用户设置->ci/cd->runner 中获取注册信息
在 Runner 设置时指定以下 URL： https://gitlab.mrhan.cloud/ 
在安装过程中使用以下注册令牌： zLi1LSBjsfPTsun8kcSX 
```
### 宿主机 Nginx 配置
- 采用nginx对gitlab服务做反向代理，配置示例如下
```
server {
    listen 443 ssl;
    ssl_certificate     /etc/letsencrypt/live/gitlab.mrhan.cloud/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/gitlab.mrhan.cloud/privkey.pem;
    server_name gitlab.mrhan.cloud;
    location / {
	proxy_redirect off;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
	proxy_pass https://127.0.0.1:8001;
    }
    location ~ .*.(js|css|png)$ {
	proxy_pass https://127.0.0.1:8001;
    }
}
server {
    listen 80;
    server_name gitlab.mrhan.cloud;
    rewrite ^(.*) https://$host$1 permanent;
}

```
### ci配置文件.gitlab-ci.yml
```
image: docker:19.03.8
services:
  - docker:dind

before_script:
  - docker login -u $DOCKER_REGISTRY_USER -p $DOCKER_REGISTRY_PASSWD $DOCKER_REGISTRY

stages:
  - build

build_devel:
    stage: build
    tags:
        - han
    script:
        - echo "bulid devel dokcer image."
        - docker build -t $DOCKER_REGISTRY/devel/tmcustomer:latest-dev .

    only:
        - devel

variables:
  DOCKER_HOST: tcp://docker:2375
  DOCKER_TLS_CERTDIR: ""

```