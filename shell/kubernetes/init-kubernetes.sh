#!/bin/bash

sudo kubeadm config images pull --cri-socket unix:///var/run/containerd/containerd.sock

sudo systemctl stop kubelet
# rm -f /etc/kubernetes/manifests/{kube-apiserver.yaml,kube-controller-manager.yaml,kube-scheduler.yaml,etcd.yaml}

sudo kubeadm init --pod-network-cidr 10.244.0.0/16
sudo kubeadm init --pod-network-cidr 10.244.0.0/16 --apiserver-advertise-address=192.168.56.111 --cri-socket unix:///var/run/containerd/containerd.sock


##### Verify #####
kubeadm certs check-expiration


# Install the bash-completion framework
sudo apt-get install -y bash-completion
# Output bash completion
sudo sh -c 'kubeadm completion bash > /etc/bash_completion.d/kubeadm'
sudo sh -c 'kubectl completion bash > /etc/bash_completion.d/kubectl'
sudo sh -c 'crictl completion > /etc/bash_completion.d/crictl'
# Load the completion code for bash into the current shell
source /etc/bash_completion

### Kubernetes Documentation - Ports and Protocols : https://kubernetes.io/docs/reference/networking/ports-and-protocols/





