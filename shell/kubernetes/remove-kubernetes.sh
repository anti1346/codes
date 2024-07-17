#!/bin/bash

sudo apt-get purge -y --allow-change-held-packages kubeadm kubelet kubectl kubernetes-cni containerd


sudo apt-mark unhold kubelet kubeadm kubectl

sudo apt-get purge -y kubelet kubeadm kubectl kubernetes-cni
sudo apt-get autoremove -y

sudo rm -rf /etc/kubernetes \
    /var/lib/etcd \
    /var/lib/kubelet \
    /etc/systemd/system/kubelet.service.d \
    rm -rf ~/.kube


### 
sudo kubeadm reset

###
sudo rm -f /etc/kubernetes/manifests/{kube-apiserver.yaml,kube-controller-manager.yaml,kube-scheduler.yaml,etcd.yaml}

