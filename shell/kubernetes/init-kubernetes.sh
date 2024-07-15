#!/bin/bash

sudo kubeadm config images pull

sudo kubeadm init --pod-network-cidr 10.244.0.0/16 --cri-socket /run/containerd/containerd.sock




### Kubernetes Documentation - Ports and Protocols : https://kubernetes.io/docs/reference/networking/ports-and-protocols/