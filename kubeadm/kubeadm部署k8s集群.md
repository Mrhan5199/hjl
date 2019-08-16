修改主机名：
#master节点:
hostnamectl set-hostname k8s-master
#node1节点：
hostnamectl set-hostname k8s-node1
#node2节点:
hostnamectl set-hostname k8s-node2
#node3节点
hostnamectl set-hostname k8s-node3

基本配置：
#修改/etc/hosts文件
cat >> /etc/hosts << EOF
192.168.2.43 k8s-master
192.168.2.42 k8s-node3
192.168.2.41 k8s-node2
192.168.2.40 k8s-node1
EOF

#关闭防火墙和selinux
systemctl stop firewalld && systemctl disable firewalld
sed -i 's/^SELINUX=enforcing$/SELINUX=disabled/' /etc/selinux/config && setenforce 0
#关闭swap
swapoff -a
yes | cp /etc/fstab /etc/fstab_bak
cat /etc/fstab_bak |grep -v swap > /etc/fstab
配置时间同步
配置master节点与网络NTP服务器同步时间，所有node节点与master节点同步时间。
更新时区(亚洲-中国-上海)
timedatectl set-timezone Asia/Shanghai
yum -y install ntp ntpdate  
ntpdate cn.pool.ntp.org && hwclock --systohc

设置网桥包经过iptalbes
RHEL / CentOS 7上的一些用户报告了由于iptables被绕过而导致流量路由不正确的问题。创建/etc/sysctl.d/k8s.conf文件，添加如下内容：
cat <<EOF >  /etc/sysctl.d/k8s.conf
vm.swappiness = 0
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
# 使配置生效
modprobe br_netfilter
sysctl -p /etc/sysctl.d/k8s.conf

kube-proxy开启ipvs的前提条件
由于ipvs已经加入到了内核的主干，所以为kube-proxy开启ipvs的前提需要加载以下的内核模块：
在所有的Kubernetes节点执行以下脚本:
cat > /etc/sysconfig/modules/ipvs.modules <<EOF
#!/bin/bash
modprobe -- ip_vs
modprobe -- ip_vs_rr
modprobe -- ip_vs_wrr
modprobe -- ip_vs_sh
modprobe -- nf_conntrack_ipv4
EOF
#执行脚本
chmod 755 /etc/sysconfig/modules/ipvs.modules && bash /etc/sysconfig/modules/ipvs.modules && lsmod | grep -e ip_vs -e nf_conntrack_ipv4

上面脚本创建了/etc/sysconfig/modules/ipvs.modules文件，保证在节点重启后能自动加载所需模块。 使用lsmod | grep -e ip_vs -e nf_conntrack_ipv4命令查看是否已经正确加载所需的内核模块。
接下来还需要确保各个节点上已经安装了ipset软件包。 为了便于查看ipvs的代理规则，最好安装一下管理工具ipvsadm。
yum install ipset ipvsadm -y
安装Docker
Kubernetes默认的容器运行时仍然是Docker，使用的是kubelet中内置dockershim CRI实现。需要注意的是，Kubernetes 1.13最低支持的Docker版本是1.11.1，最高支持是18.06，而Docker最新版本已经是18.09了，故我们安装时需要指定版本为18.06.1-ce。
#配置docker yum源
yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
#安装指定版本，这里安装18.06
yum list docker-ce --showduplicates | sort -r
yum install -y docker-ce-18.06.1.ce-3.el7
systemctl start docker && systemctl enable docker

安装kubeadm、kubelet、kubectl
#配置kubernetes.repo的源，由于官方源国内无法访问，这里使用阿里云yum源
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF

#在所有节点上安装指定版本 kubelet、kubeadm 和 kubectl
yum install -y kubelet-1.13.1 kubeadm-1.13.1 kubectl-1.13.1
#启动kubelet服务
systemctl enable kubelet && systemctl start kubelet
2.部署master节点
kubeadm init \
    --apiserver-advertise-address=192.168.92.56 \
    --image-repository registry.aliyuncs.com/google_containers \
    --kubernetes-version v1.13.1 \
    --pod-network-cidr=10.244.0.0/16
初始化命令说明：
--apiserver-advertise-address
指明用 Master 的哪个 interface 与 Cluster 的其他节点通信。如果 Master 有多个 interface，建议明确指定，如果不指定，kubeadm 会自动选择有默认网关的 interface。
--pod-network-cidr
指定 Pod 网络的范围。Kubernetes 支持多种网络方案，而且不同网络方案对 --pod-network-cidr 有自己的要求，这里设置为 10.244.0.0/16 是因为我们将使用 flannel 网络方案，必须设置成这个 CIDR。
--image-repository
Kubenetes默认Registries地址是 k8s.gcr.io，在国内并不能访问 gcr.io，在1.13版本中我们可以增加–image-repository参数，默认值是 k8s.gcr.io，将其指定为阿里云镜像地址：registry.aliyuncs.com/google_containers。
--kubernetes-version=v1.13.1 
关闭版本探测，因为它的默认值是stable-1，会导致从https://dl.k8s.io/release/stable-1.txt下载最新的版本号，我们可以将其指定为固定版本（最新版：v1.13.1）来跳过网络请求。
(注意记录下初始化结果中的kubeadm join命令，部署worker节点时会用到)

初始化过程说明：

[preflight] kubeadm 执行初始化前的检查。
[kubelet-start] 生成kubelet的配置文件”/var/lib/kubelet/config.yaml”
[certificates] 生成相关的各种token和证书
[kubeconfig] 生成 KubeConfig 文件，kubelet 需要这个文件与 Master 通信
[control-plane] 安装 Master 组件，会从指定的 Registry 下载组件的 Docker 镜像。
[bootstraptoken] 生成token记录下来，后边使用kubeadm join往集群中添加节点时会用到
[addons] 安装附加组件 kube-proxy 和 kube-dns。
Kubernetes Master 初始化成功，提示如何配置常规用户使用kubectl访问集群。
提示如何安装 Pod 网络。
提示如何注册其他节点到 Cluster。
配置 kubectl

kubectl 是管理 Kubernetes Cluster 的命令行工具，前面我们已经在所有的节点安装了 kubectl。Master 初始化完成后需要做一些配置工作，然后 kubectl 就能使用了。
依照 kubeadm init 输出的最后提示，推荐用 Linux 普通用户执行 kubectl。

root用户配置
echo "export KUBECONFIG=/etc/kubernetes/admin.conf" >> ~/.bash_profile
source ~/.bash_profile

非root用户
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
需要这些配置命令的原因是：Kubernetes 集群默认需要加密方式访问。所以，这几条命令，就是将刚刚部署生成的 Kubernetes 集群的安全配置文件，保存到当前用户的.kube 目录下，kubectl 默认会使用这个目录下的授权信息访问 Kubernetes 集群。
如果不这么做的话，我们每次都需要通过 export KUBECONFIG 环境变量告诉 kubectl 这个安全配置文件的位置。
配置完成后centos用户就可以使用 kubectl 命令管理集群了。
集群初始化如果遇到问题，可以使用kubeadm reset命令进行清理然后重新执行初始化

部署网络插件
要让 Kubernetes Cluster 能够工作，必须安装 Pod 网络，否则 Pod 之间无法通信。
Kubernetes 支持多种网络方案，这里我们使用 flannel
执行如下命令部署 flannel：
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
3.部署worker节点
Kubernetes 的 Worker 节点跟 Master 节点几乎是相同的，它们运行着的都是一个 kubelet 组件。唯一的区别在于，在 kubeadm init 的过程中，kubelet 启动后，Master 节点上还会自动运行 kube-apiserver、kube-scheduler、kube-controller-manger 这三个系统 Pod。
在 k8s-node1 和 k8s-node2 上分别执行如下命令，将其注册到 Cluster 中：
kubeadm join 192.168.2.43:6443 --token emucsf.6sme0oanzsdmuvgj --discovery-token-ca-cert-hash sha256:cc041b2d569cb6f703763a98b998de369e1f9b83f8fca14b171ee24c11a34e02
#如果执行kubeadm init时没有记录下加入集群的命令，可以通过以下命令重新创建
kubeadm token create --print-join-command
