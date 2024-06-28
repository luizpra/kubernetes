#!/bin/bash

kops create cluster \
	--cloud=digitalocean \
	--name=kubernetes.do.iztec.app \
	--networking=cilium \
	--zones=nyc3 \
	--ssh-public-key=~/.ssh/id_rsa.pub \
	--node-count=2 \
	--node-size=s-2vcpu-4gb \
	--node-volume-size=20 \
	--control-plane-count=3 \
	--control-plane-size=s-2vcpu-2gb \
	--control-plane-volume-size=10

	
kops validate cluster kubernetes.do.iztec.app
kops update cluster kubernetes.do.iztec.app --yes
kops export kubeconfig kubernetes.do.iztec.app --admin
kops delete cluster kubernetes.do.iztec.app --yes
