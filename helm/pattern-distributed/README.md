# Helm Chart for a Fully Distributed Deployment of WSO2 Stream Processor

## Contents

* [Prerequisites](#prerequisites)
* [Quick Start Guide](#quick-start-guide)

## Prerequisites

* In order to use WSO2 Helm resources, you need an active WSO2 subscription. If you do not possess an active WSO2
  subscription already, you can sign up for a WSO2 Free Trial Subscription from [here](https://wso2.com/free-trial-subscription).<br><br>

* Install [Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git), [Helm](https://github.com/kubernetes/helm/blob/master/docs/install.md)
(and Tiller) and [Kubernetes client](https://kubernetes.io/docs/tasks/tools/install-kubectl/) (compatible with v1.10) in order to run the 
steps provided in the following quick start guide.<br><br>

* An already setup [Kubernetes cluster](https://kubernetes.io/docs/setup/pick-right-solution/).<br><br>

* Install [NGINX Ingress Controller](https://kubernetes.github.io/ingress-nginx/deploy/). This can be done via
 
  ```
  helm install stable/nginx-ingress --name nginx-wso2sp-pattern-distributed --set rbac.create=true
  ```
  
* A pre-configured Network File System (NFS) to be used as the persistent volume for artifact sharing and persistence.
In the NFS server instance, create a Linux system user account named `wso2carbon` with user id `802` and a system group named `wso2` with group id `802`.
Add the `wso2carbon` user to the group `wso2`.

  ```
   groupadd --system -g 802 wso2
   useradd --system -g 802 -u 802 wso2carbon
  ```
  
## Quick Start Guide

>In the context of this document, <br>
>* `KUBERNETES_HOME` will refer to a local copy of the [`wso2/kubernetes-sp`](https://github.com/wso2/kubernetes-sp/)
Git repository. <br>
>* `HELM_HOME` will refer to `<KUBERNETES_HOME>/helm/pattern-distributed`. <br>

##### 1. Clone Kubernetes Resources for WSO2 Stream Processor Git repository.

  ```
  git clone https://github.com/wso2/kubernetes-sp.git
  ```
  
##### 2. Setup a Network File System (NFS) to be used for persistent storage.

Create and export unique directories within the NFS server instance for each of the following Kubernetes Persistent Volume
resources defined in the `<HELM_HOME>/pattern-distributed/values.yaml` file:

* `sharedSiddhiFilesLocationPath`

Grant ownership to `wso2carbon` user and `wso2` group, for each of the previously created directories.

  ```
  sudo chown -R wso2carbon:wso2 <directory_name>
  ```

Grant read-write-execute permissions to the `wso2carbon` user, for each of the previously created directories.

  ```
  chmod -R 700 <directory_name>
  ```

##### 3. Provide configurations.

a. The default product configurations are available at `<HELM_HOME>/pattern-distributed/confs` folder. Change the
configurations as necessary.

b. Open the `<HELM_HOME>/pattern-distributed/values.yaml` and provide the following values.

| Parameter                       | Description                                                                               |
|---------------------------------|-------------------------------------------------------------------------------------------|
| `username`                      | Your WSO2 username                                                                        |
| `password`                      | Your WSO2 password                                                                        |
| `email`                         | Docker email                                                                              |
| `namespace`                     | Kubernetes Namespace in which the resources are deployed                                  |
| `svcaccount`                    | Kubernetes Service Account in the `namespace` to which product instance pods are attached |
| `serverIp`                      | NFS Server IP                                                                             |
| `sharedSiddhiFilesLocationPath` | NFS location path for shared Siddhi file directory(`<SP_HOME>/deployment/siddhi-files/`)  |


##### 4. Deploy product database(s) using MySQL in Kubernetes.

  ```
  helm install --name sp-rdbms -f <HELM_HOME>/mysql/values.yaml stable/mysql --namespace <NAMESPACE>
  ```
  
  `NAMESPACE` should be same as `step 3.b`.
  
  For a serious deployment (e.g. production grade setup), it is recommended to connect product instances to a user owned and managed RDBMS instance.

##### 5. Deploy the fully distributed deployment of WSO2 Stream Processor.

  ```
  helm install --name <RELEASE_NAME> <HELM_HOME>/pattern-distributed --namespace <NAMESPACE>
  ```

  `NAMESPACE` should be same as `step 3.b`.
  
##### 6. Access Management Consoles.

a. Obtain the external IP (`EXTERNAL-IP`) of the Ingress resources by listing down the Kubernetes Ingresses.

  ```
  kubectl get ing -n <NAMESPACE>
  ```

  e.g.

  ```
  NAME                                             HOSTS                     ADDRESS        PORTS     AGE
  wso2sp-dashboard-ingress                         wso2sp-dashboard          <EXTERNAL-IP>  80, 443   2m
  wso2sp-manager-1-ingress                         wso2sp-manager-1          <EXTERNAL-IP>  80, 443   2m
  wso2sp-manager-2-ingress                         wso2sp-manager-2          <EXTERNAL-IP>  80, 443   2m
  ```

b. Add the above host as an entry in /etc/hosts file as follows:

  ```
  <EXTERNAL-IP>	wso2sp-dashboard
  <EXTERNAL-IP>	wso2sp-manager-1
  <EXTERNAL-IP>	wso2sp-manager-2
  ```

##### 7. Siddhi applications should be deployed to the manager cluster using one of the following methods.

a. Dropping the .siddhi file in to the `/data/pattern-distributed/siddhi-files` in the NFS node directory before or after starting the manager node.

b. Sending a "POST" request to `http://<host>:<port>/siddhi-apps`, with the Siddhi App attached as a file in the request as shown in the example below.
Refer [Stream Processor REST API Guide](https://docs.wso2.com/display/SP430/Stream+Processor+REST+API+Guide) for more information on using WSO2 Stream Processor APIs.

  ```
  curl -X POST "https://wso2sp-manager-1/siddhi-apps" -H "accept: application/json" -H "Content-Type: text/plain" -d @TestSiddhiApp.siddhi -u admin:admin -k
  ```

Default deployment will expose two publicly accessible hosts, namely: <br>

* `wso2sp-manager-1` - To expose Manager Node 1 <br>
* `wso2sp-manager-2` - To expose Manager Node 2 <br>

##### 8. Access Status Dashboard.

Try navigating to `https://wso2sp-dashboard/monitoring` from your favorite browser.

