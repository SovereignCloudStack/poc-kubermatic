# SCS / POC / Kubermatic

![](https://docs.kubermatic.com/img/header-logo-kubermatic.png)

## Overview

All relevant steps for a setup and installation is located here. Credentials are located on `scs-secrets` repository.


## Links:

- Mainpage (k.ubermati.c)
  https://k8c.io
- Documentation (Overall) for kubeone,kubermatics,kubecarrier ...
  https://docs.kubermatic.com/
- kubeone
  https://docs.kubermatic.com/kubeone/
- kubermatic
  https://docs.kubermatic.com/kubermatic/

## Lab Setup

- Provider: Openstack (Betacloud)
- Project: SCS (shared Loodse/Kubermatic Project)
- Kubermatic v2.14.3 (current)


### Kubermatic Master Cluster

- Services:

  - DNS (on AWS route53) `*.poc-k8c.training.b1-systems.de` and `poc-k8c.training.b1-systems.de` ref. to IPAddr: `81.163.192.58` (current vm-lb)
  - 3x Control-Plane Nodes with OS-Flavor `2C-4G-40G`
  - 3x Worker Nodes with the same OS-Flavor `2C-4G-40G`
  - 1x Loadbalancer VM is used KubernetesAPI (:6443) and Ingress (:80,:443), Backend Nodes: all Controlplane VM's
  - a default StorageClass (SC) on K8s Master/Seed cluster `cinder-default`, see [Addons](./installation/addon/)
  - Kubermatic Dashboard https://poc-k8c.training.b1-systems.de

- Notes:

  - Beware a OpenStack example, at Betacloud we have more than one Avalabitity Zone (AZ),
    therefor the terraform HCL must be modified, or the machinedeployment must be set afterwards again!
  - at Betacloud we have no Loadbalancer-as-a-Service, we use a customized gobetween setup

- Prerequisites:

  This directory use some tool for faster development and onboarding people:

  - [direnv](https://direnv.net/)
  - [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/#install-kubectl-on-linux)
  - [terraform](https://releases.hashicorp.com/terraform/0.12.29/terraform_0.12.29_linux_amd64.zip)
  - [yq](https://github.com/mikefarah/yq)
  
- history and steps:

  ```shell=
  # all used tools are installed and running
  direnv allow
  
  # get release, with pre-compilied kubeone via curl, like
  # $ curl https://github.com/kubermatic/kubeone/releases/download/v1.0.0-rc.1/kubeone_1.0.0-rc.1_linux_amd64.zip -OL
  # and extract the kubeone.zip, mv kubeone to ./bin and the examples/openstack to openstack
    
  cd openstack
  ln -s ../work/terrafrom.tfvars .
  
  # create file secrets.d/scs-kubermatic-openrc.sh via gopass
  gopass <your-secret-storage>/poc-kubermatic/scs-kubermatic-openrc.sh > ../secure.d/scs-kubermatic-openrc.sh
  
  # enable the secrets for openstack
  source ../secure.d/scs-kubermatic-openrc.sh
  
  # start an ssh-agent add the ssh private-key for the remote-exec step
  # for the password see secrets repo
  eval $(ssh-agent)
  ssh-add ../work/poc-k8c
  
  # start the terraforming
  terraform init 
  terraform plan
  terraform apply -auto-approve
  
  # convert terraform output to json for kubeone
  terraform output -json > ../kubeone/tf.json
  
  # go to kubeone directory - step install kubernetes cluster via kubeone
  cd ../kubeone
  
  # generate kubeone config,
  # -n ... name => poc-k8c
  # -k ... kubernetes version => 1.18.8
  # -f ... full (print all config)
  # -p ... provider, in our case `openstack` - what else!
  kubeone config print -n poc-k8c -f -k 1.18.8 -p openstack > kubeone.yaml.tmpl
  
  # generate a cloud-config for openstack, use it from the secrets
  gopass <your-secret-storage>/poc-kubermatic/cloud-config > ../secure.d/cloud-config
  
  # add secret cloud-config to kubeone config via `yq`
  yq write kubeone.yaml.tmpl cloudProvider.cloudConfig "$(cat ../secure.d/cloud-config )" > ../secure.d/kubeone.yaml
  
  # install the kubernetes cluster
  kubeone install -t tf.json -m ../secure.d/kubeone.yaml
  
  # check the kubeconfig, set via direnv
  stat $KUBECONFIG
  
  # use the kubernetes-cli aka kubectl to check the cluster
  kubectl get nodes -o wide
  
  # the cluster-api resources on api-level
  kubectl api-resources --api-group cluster.k8s.io
  
  # get machinedeployments (md)
  kubectl get machinedeployments.cluster.k8s.io -n kube-system
  
  # set 3 worker nodes on the cluster
  kubectl scale machinedeployments.cluster.k8s.io poc-k8c-pool1 --replicas 3 --namespace kube-system
  
  # for destory, please remove the machinedeployments, via
  kubectl delete md --all-namespaces --all
  
  # or use kubeone for reset
  kubeone reset -t tf.json -m kubeone.yaml
  
  # destroy iaas layer objects, the virtual-machines, the router, the networks, the key-pair etc. pp.
  cd openstack
  terraform destroy -force
  
  ## Debugging
  
  on-failure:
    - check deployment for machinecontroller
    - check virtual-machines on IaaS Level
    - do the needful like you do on every kubernetes cluster :smile: 
  ```

## Kubermatic Master Pre-Deployments

Kubermatic needs an Ingress Controller (here ingress-nginx-controller), cert-manager and dex (oauth) for the kubermatic deployment.

- notes:
  - helm (Version 3.x), [Helm Install Guide](https://helm.sh/docs/intro/install/)
  - helm charts for [Kubermatic Release v2.14.3](https://github.com/kubermatic/kubermatic/releases/tag/v2.14.3) are installed at `installation/kubermatic-ce`
  - nginx IngressController, template has only hardcoded service, type `loadbalancer`
  - setup all value.yaml
  - setup a bcrypt hash for a password: `htpasswd -bnBC 10 "" $password | tr -d ':\n' | sed 's/$2y/$2a/'`


- history and steps:

  ```bash=
  cd installation/kubermatic-ce/charts/nginx-ingress-controller
  kubectl create ns nginx-ingress-controller
  helm upgrade --install nginx-ingress-controller . --namespace nginx-ingress-controller --values values.yaml
  

  cd installation/kubermatic-ce/charts/cert-manager
  kubectl create namespace cert-manager
  kubectl apply -f templates/crd.yaml
  helm upgrade --install cert-manager . --namespace cert-manager --values values.yaml

  
  cd installation/kubermatic-ce/charts/oauth
  kubectl create ns oauth
  helm upgrade --install oauth . --namespace oauth --values values.yaml
  ```

## Kubermatic Master Deployment/Operator

- history and steps:

  ```bash=
  cd installation/kubermatic-ce/charts/kubermatic-operator
  kubectl create ns kubermatic
  kubectl apply -f ../kubermatic/crd/
  helm upgrade --install kubermatic-operator . --namespace kubermatic --values values.yaml
  
  # configure KubermaticConfiguration, see examples
  # cp installation/kubermatic-ce/examples/kubermatic.example.ce.yaml installation/kubermatic-ce/examples/kubermatic.yaml
  kubectl apply -f installation/kubermatic-ce/examples/kubermatic.yaml

  # after some time, the Kubermatic Dashboard can be accessed at https://poc-k8c.training.b1-systems.de
  # check deployment,pods and ingress object status at kubermatic namespace
  kubectl -n kubermatic get deploy,po,ing
  ```

## Kubermatic Seed Cluster


- history and steps:

  ```bash=
  ```

