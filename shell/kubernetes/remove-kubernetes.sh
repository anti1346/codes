#!/bin/bash

sudo apt-get purge -y --allow-change-held-packages kubeadm kubelet kubectl kubernetes-cni containerd containerd.io docker-ce

---
sudo apt-mark unhold kubelet kubeadm kubectl
sudo apt-get purge -y kubelet kubeadm kubectl kubernetes-cni
---

sudo apt-get autoremove -y

sudo rm -rf /etc/{docker,kubernetes} \
    /var/lib/{kubelet,etcd,docker} \
    /etc/systemd/system/kubelet.service.d \
    /run/docker \
    rm -rf ~/.kube

### 
sudo kubeadm reset

###
sudo rm -rf /etc/kubernetes/manifests/{kube-apiserver.yaml,kube-controller-manager.yaml,kube-scheduler.yaml,etcd.yaml}
sudo rm -rf /opt/{cni,containerd}

