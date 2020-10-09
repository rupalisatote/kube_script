#!/bin/bash

sudo apt-get update -y


# Install docker
echo "[TASK 1] Install docker"
apt-get install -y docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-get update
apt-get install -y docker-ce
systemctl status docker

# add user to docker
groupadd docker
usermod -a -G docker ubuntu

systemctl restart docker
systemctl enable docker.service

sudo apt-get install -y apt-transport-https

# Add key to repository
echo "[TASK 2] Add key to repository"
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -

# add kubernetes dependency
echo "[TASK 3] Add kubernetes dependency"
cat <<EOF > /etc/apt/sources.list.d/kubernetes.list
> deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF

sudo apt-get update -y

# Install kubectl, kubeadm, kubelet, kubernetes.cni
echo "[TASK 3] Install kubectl, kubeadm, kubelet, kubernetes.cni"
apt-get install -y kubelet kubeadm kubernetes.cni

cat etc/systemd/system/kubelet.service.d/10-kubeadm.conf<<EOF
Environment="cgroup-driver=systemd/cgroup-driver=cgroupfs"
EOF

sysctl net.bridge.bridge-nf-call-iptables=1


# Initialise kubernetes cluster with flannel cidr
echo "[TASK 3] Initialise kubernetes cluster"
kubeadm init --pod-network-cidr=10.240.0.0/16

mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

kubectl version | base64 | tr -d '\n'
export kubeserver=$( kubectl version | base64 | tr -d '\n')

echo "[TASK 3] Apply Flannel network"
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/2140ac876ef134e0ed5af15c65e414cf26827915/Documentation/kube-flannel.yml

echo "[TASK 3] kubeadm join command"
kubeadm token create --print-join-command > /joincluster.sh
