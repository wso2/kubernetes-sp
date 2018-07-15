# Kubernetes Test Resources for a Fully Distributed Deployment of WSO2 Stream Processor

Kubernetes Test Resources for a [fully distributed deployment of WSO2 Stream Processor](https://docs.wso2.com/display/SP420/Fully+Distributed+Deployment) contain artifacts,
which can be used to test the core Kubernetes resources provided for a fully distributed deployment of WSO2 Stream Processor.

## Contents

* [Prerequisites](#prerequisites)
* [Quick Start Guide](#quick-start-guide)

## Prerequisites

* In order to use WSO2 Kubernetes resources, you need an active WSO2 subscription. If you do not possess an active
WSO2 subscription already, you can sign up for a WSO2 Free Trial Subscription from [here](https://wso2.com/free-trial-subscription).<br><br>

* Install [Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git) and [Kubernetes client](https://kubernetes.io/docs/tasks/tools/install-kubectl/) (compatible with v1.10)
in order to run the steps provided in the following quick start guide.<br><br>

* An already setup [Kubernetes cluster](https://kubernetes.io/docs/setup/pick-right-solution/).<br><br>

* A pre-configured Network File System (NFS) to be used as the persistent volume for artifact sharing and persistence.
In the NFS server instance, create a Linux system user account named `wso2carbon` with user id `802` and a system group named `wso2` with group id `802`.
Add the `wso2carbon` user to the group `wso2`.

```
groupadd --system -g 802 wso2
useradd --system -g 802 -u 802 wso2carbon
```

## Quick Start Guide

>In the context of this document, `KUBERNETES_HOME` will refer to a local copy of the [`wso2/kubernetes-sp`](https://github.com/wso2/kubernetes-sp/)
Git repository.<br>

##### 1. Clone Kubernetes Resources for WSO2 Stream Processor Git repository.

```
git clone https://github.com/wso2/kubernetes-sp.git
```

##### 2. Deploy Kubernetes Ingress resource.

The WSO2 Stream Processor Kubernetes Ingress resource uses the NGINX Ingress Controller.

In order to enable the NGINX Ingress controller in the desired cloud or on-premise environment,
please refer the official documentation, [NGINX Ingress Controller Installation Guide](https://kubernetes.github.io/ingress-nginx/deploy/).

##### 3. Setup a Network File System (NFS) to be used for persistent storage.

Create and export unique directories within the NFS server instance for each Kubernetes Persistent Volume resource defined in the
`<KUBERNETES_HOME>/pattern-distributed/volumes/persistent-volumes.yaml` file.

Grant ownership to `wso2carbon` user and `wso2` group, for each of the previously created directories.

```
sudo chown -R wso2carbon:wso2 <directory_name>
```

Grant read-write-execute permissions to the `wso2carbon` user, for each of the previously created directories.

```
chmod -R 700 <directory_name>
```

Update each Kubernetes Persistent Volume resource with the corresponding NFS server IP (`NFS_SERVER_IP`) and exported, NFS server directory path (`NFS_LOCATION_PATH`).

##### 4. Setup product database(s).

For **evaluation purposes**,

* You can use Kubernetes resources provided in the directory `<KUBERNETES_HOME>/pattern-distributed/extras/rdbms/mysql`
for deploying the product databases, using MySQL in Kubernetes. However, this approach of product database deployment is
**not recommended** for a production setup.

* For using these Kubernetes resources,

  Here, a Network File System (NFS) is needed to be used for persisting MySQL DB data.    
  
  Create and export a directory within the NFS server instance.
        
  Provide read-write-execute permissions to other users for the created folder.
        
  Update the Kubernetes Persistent Volume resource with the corresponding NFS server IP (`NFS_SERVER_IP`) and exported,
  NFS server directory path (`NFS_LOCATION_PATH`) in `<KUBERNETES_HOME>/pattern-distributed/extras/rdbms/volumes/persistent-volumes.yaml`.
  
In a **production grade setup**,

* Setup the external product databases. Please refer to WSO2's official documentation [1](https://docs.wso2.com/display/SP420/Fully+Distributed+Deployment) on creating the required databases for the deployment.
  
  Provide appropriate connection URLs, corresponding to the created external databases and the relevant driver class names for the data sources defined in
  the following files under `wso2.datasources` configurations:
  
  * `<KUBERNETES_HOME>/pattern-distributed/confs/sp-manager/conf/deployment.yaml`
  * `<KUBERNETES_HOME>/pattern-distributed/confs/sp-worker/conf/deployment.yaml`

  Please refer WSO2's [official documentation](https://docs.wso2.com/display/SP420/Configuring+Datasources) on configuring data sources.

##### 5. Deploy Kubernetes resources.

Change directory to `<KUBERNETES_HOME>/sp-distributed/scripts` and execute the `deploy.sh` shell script on the terminal, with the appropriate configurations as follows:

```
./deploy.sh --wso2-username=<WSO2_USERNAME> --wso2-password=<WSO2_PASSWORD> --cluster-admin-password=<K8S_CLUSTER_ADMIN_PASSWORD>
```

* A Kubernetes Secret named `wso2creds` in the cluster to authenticate with the [`WSO2 Docker Registry`](https://docker.wso2.com), to pull the required images.
The following details need to be replaced in the relevant command.

`WSO2_USERNAME`: Your WSO2 username<br>
`WSO2_PASSWORD`: Your WSO2 password

* A Kubernetes role and a role binding necessary for the Kubernetes API requests made from Kubernetes membership scheme.

`K8S_CLUSTER_ADMIN_PASSWORD`: Kubernetes cluster admin password

>To un-deploy, be on the same directory and execute the `undeploy.sh` shell script on the terminal.

##### 6. Access Management Consoles.

Obtain the external IP (`EXTERNAL-IP`) of the Ingress resources by listing down the Kubernetes Ingresses (using `kubectl get ing`).

e.g.

```
NAME                                             HOSTS                     ADDRESS        PORTS     AGE
wso2sp-dashboard-ingress                         wso2sp-dashboard          <EXTERNAL-IP>  80, 443   2m
wso2sp-manager-1-ingress                         wso2sp-manager-1          <EXTERNAL-IP>  80, 443   2m
wso2sp-manager-2-ingress                         wso2sp-manager-2          <EXTERNAL-IP>  80, 443   2m
```

2. Add the above host as an entry in /etc/hosts file as follows:

```
<EXTERNAL-IP>	wso2sp-dashboard
<EXTERNAL-IP>	wso2sp-manager-1
<EXTERNAL-IP>	wso2sp-manager-2
```

##### 7. Siddhi applications should be deployed to the manager cluster using one of the following methods.

a. Dropping the .siddhi file in to the `/data/pattern-distributed/siddhi-files` in the NFS node directory before or after starting the manager node.

b. Sending a "POST" request to `http://<host>:<port>/siddhi-apps`, with the Siddhi App attached as a file in the request as shown in the example below.
Refer [Stream Processor REST API Guide](https://docs.wso2.com/display/SP420/Stream+Processor+REST+API+Guide) for more information on using WSO2 Strean Processor APIs.

```
curl -X POST "https://wso2sp-manager-1/siddhi-apps" -H "accept: application/json" -H "Content-Type: text/plain" -d @TestSiddhiApp.siddhi -u admin:admin -k
```

Default deployment will expose two publicly accessible hosts, namely: <br>

1. `wso2sp-manager-1` - To expose Manager Node 1 <br>
2. `wso2sp-manager-2` - To expose Manager Node 2 <br>

##### 8. Access Status Dashboard.

Try navigating to `https://wso2sp-dashboard/monitoring` from your favorite browser.
