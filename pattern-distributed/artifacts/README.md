# WSO2 Stream Processor 4.1.0 Distributed Deployment Kubernetes Resources 

*Kubernetes Resources for container-based distributed deployment of WSO2 Stream Processor (SP)*

## Prerequisites

* In order to use these Kubernetes resources, you will need an active [Free Trial Subscription](https://wso2.com/free-trial-subscription)
from WSO2 since the referring Docker images hosted at docker.wso2.com contains the latest updates and fixes for WSO2 Enterprise Integrator.
You can sign up for a Free Trial Subscription [here](https://wso2.com/free-trial-subscription).<br><br>

* Install [Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git), [Docker](https://www.docker.com/get-docker)
(version 17.09.0 or above) and [Kubernetes client](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
in order to run the steps provided<br>in the following quick start guide.<br><br>

* An already setup [Kubernetes cluster](https://kubernetes.io/docs/setup/pick-right-solution/)<br><br>

* Network File System (NFS) is used as the persistent volume for Stream Processor manager nodes. Therefore setting up NFS is required to deploy the pattern.
   Complete the following.  
   
     1. Update the NFS server IP in `KUBERNETES_HOME/pattern-distributed/artifacts/volumes/persistent-volumes.yaml'
     2. Create required directories in NFS server as mentioned in `KUBERNETES_HOME/pattern-distributed/artifacts/volumes/persistent-volumes.yaml`
        eg: create directories as '/data/pattern-distributed/siddhi-files'
      
  * It is recommend to use a mysql or any database cluster in a production environment. Only 1 mysql container is used with host path mount in these deployments.

## Quick Start Guide

>In the context of this document, `KUBERNETES_HOME` will refer to a local copy of the [`wso2/kubernetes-sp`](https://github.com/wso2/kubernetes-sp/)
Git repository.<br>

##### 1. Checkout Kubernetes Resources for WSO2 Enterprise Integrator Git repository:

```
git clone https://github.com/wso2/kubernetes-sp.git

```
##### 2. Deploy Kubernetes Ingress resource:

The WSO2 Enterprise Integrator Kubernetes Ingress resource uses the NGINX Ingress Controller.

In order to enable the NGINX Ingress controller in the desired cloud or on-premise environment,
please refer the official documentation, [NGINX Ingress Controller Installation Guide](https://kubernetes.github.io/ingress-nginx/deploy/).

##### 3. Update the deploy_kubernetes.sh file with the [`WSO2 Docker Registry`](https://docker.wso2.com) credentials and Kubernetes cluster admin password.

Replace the relevant placeholders in `KUBERNETES_HOME/pattern-distributed/artifacts/deploy_kubernetes.sh` file with appropriate details, as described below.

* A Kubernetes Secret named `wso2creds` in the cluster to authenticate with the WSO2 Docker Registry, to pull the required images.
The following details need to be replaced in the relevant command.

```
kubectl create secret docker-registry wso2creds --docker-server=docker.wso2.com --docker-username=<username> --docker-password=<password> --docker-email=<email>
```

`username`: Username of your Free Trial Subscription<br>
`password`: Password of your Free Trial Subscription<br>
`email`: Docker email

Please see [Kubernetes official documentation](https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/#create-a-secret-in-the-cluster-that-holds-your-authorization-token)
for further details.

* A Kubernetes role and a role binding necessary for the Kubernetes API requests made from Kubernetes membership scheme.

`cluster-admin-password`: Kubernetes cluster admin password

##### 4. Deploy Kubernetes Resources:

Change directory to `KUBERNETES_HOME/pattern-distributed/artifacts` and execute the `deploy_kubernetes.sh` shell script on the terminal.

```
./deploy_kubernetes.sh
```
>To un-deploy, be on the same directory and execute the `undeploy-kubernetes.sh` shell script on the terminal.

##### 5. Siddhi applications should be deployed to the manager cluster using one of the following methods:

a. Dropping the .siddhi file in to the /data/pattern-distributed/siddhi-files in the NFS node directory before or after starting the manager node.

b. Sending a "POST" request to http://\<host\>:\<port\>/siddhi-apps, with the Siddhi App attached as a file in the request as shown in the example below. Refer [Stream Processor REST API Guide](https://docs.wso2.com/display/SP400/Stream+Processor+REST+API+Guide) for more information on using WSO2 Strean Processor APIs.

```
curl -X POST "https://wso2sp-manager-1/siddhi-apps" -H "accept: application/json" -H "Content-Type: text/plain" -d @TestSiddhiApp.siddhi -u admin:admin -k
```

Default deployment will expose two publicly accessible hosts, namely: <br>
1. `wso2sp-manager-1` - To expose Manager Node 1 <br>
2. `wso2sp-manager-2` - To expose Manager Node 2 <br>

<br>

> Tested in Kubernetes v1.8.8

> NFS is tested in Kubernetes v1.8.8

**For detailed instructions to configure Fully Distributed WSO2 SP cluster refer [Deployment Guide](https://docs.wso2.com/display/SP400/Fully+Distributed+Deployment)**