#!/bin/bash

sudo apt-mark unhold kubelet kubeadm kubectl

sudo apt-get purge -y kubelet kubeadm kubectl
sudo apt-get autoremove -y

sudo rm -rf /etc/kubernetes \
    /var/lib/etcd \
    /var/lib/kubelet \
    /etc/systemd/system/kubelet.service.d \
    rm -rf ~/.kube


### 
# sudo kubeadm reset


sudo rm -f /etc/kubernetes/manifests/kube-apiserver.yaml \
    /etc/kubernetes/manifests/kube-controller-manager.yaml \
    /etc/kubernetes/manifests/kube-scheduler.yaml \
    /etc/kubernetes/manifests/etcd.yaml
