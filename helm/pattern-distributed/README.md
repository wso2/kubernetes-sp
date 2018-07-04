# Helm Chart for Stream Processor Fully Distributed Deployment

## Prerequisites

* In order to use WSO2 Helm resources, you need an active WSO2 subscription. If you do not possess an active WSO2
  subscription already, you can sign up for a WSO2 Free Trial Subscription from [here](https://wso2.com/free-trial-subscription).<br><br>

* Install [Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git), [Helm](https://github.com/kubernetes/helm/blob/master/docs/install.md)
(and Tiller) and [Kubernetes client](https://kubernetes.io/docs/tasks/tools/install-kubectl/) in order to run the 
steps provided in the following quick start guide.<br><br>

* Install [NGINX Ingress Controller](https://kubernetes.github.io/ingress-nginx/deploy/). This can be done via
 
  ```
  helm install stable/nginx-ingress --name nginx-wso2sp-pattern-distributed --set rbac.create=true
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

##### 2. Provide configurations.

1. The default product configurations are available at `<HELM_HOME>/pattern-distributed-conf/confs` folder. Change the 
configurations as necessary.

2. Open the `<HELM_HOME>/pattern-distributed-conf/values.yaml` and provide the following values.

    `username`: Your WSO2 username<br>
    `password`: Your WSO2 password<br>
    `email`: Docker email<br>
    `namespace`: Kubernetes Namespace in which the resources are deployed<br>
    `svcaccount`: Kubernetes Service Account in the `namespace` to which product instance pods are attached<br>
    `serverIp`: NFS Server IP<br>
    `locationPath`: NFS location path<br>
    `sharedSiddhiFilesLocationPath`: NFS location path for shared Siddhi file directory(`<SP_HOME>/deployment/siddhi-files/`)<br> 
   
3. Open the `<HELM_HOME>/pattern-distributed-deployment/values.yaml` and provide the following values.

    `namespace`: Kubernetes Namespace in which the resources are deployed<br>
    `svcaccount`: Kubernetes Service Account in the `namespace` to which product instance pods are attached<br>
    
##### 3. Deploy the configurations.

```
helm install --name <RELEASE_NAME> <HELM_HOME>/pattern-distributed-conf
```

##### 4. Deploy MySQL.

If there is an external product database(s), add those configurations as stated at `step 2.1`. Otherwise, run the below
command to create the product database.
 
```
helm install --name sp-rdbms -f <HELM_HOME>/mysql/values.yaml 
stable/mysql --namespace <NAMESPACE>
```

`NAMESPACE` should be the same as that of `step 2.2`.

##### 5. Deploy the fully distributed deployment of WSO2 Stream Processor.

```
helm install --name <RELEASE_NAME> <HELM_HOME>/pattern-distributed-deployment
```

##### 6. Access Management Console:

Default deployment will expose three publicly accessible hosts, namely:<br>

1. `wso2sp-manager-1` - To expose Manager Node 1 <br>
2. `wso2sp-manager-2` - To expose Manager Node 2 <br>
3. `wso2sp-dashboard` - To expose Dashboard Node <br>


To access the console in a test environment,

1. Obtain the external IP (`EXTERNAL-IP`) of the Ingress resources by listing down the Kubernetes Ingresses (using `kubectl get ing -n <NAMESPACE>`).

e.g.

```
NAME                            HOSTS              ADDRESS         PORTS     AGE
wso2sp-dashboard-ingress        wso2sp-dashboard   <EXTERNAL-IP>   80, 443   25m
wso2sp-manager-1-ingress        wso2sp-manager-1   <EXTERNAL-IP>   80, 443   25m
wso2sp-manager-2-ingress        wso2sp-manager-2   <EXTERNAL-IP>   80, 443   25m
```

2. Add the above three hosts as entries in /etc/hosts file as follows:

```
<EXTERNAL-IP>	wso2sp-dashboard
<EXTERNAL-IP>	wso2sp-manager-1
<EXTERNAL-IP>	wso2sp-manager-2
```

3. Try navigating to `https://wso2sp-dashboard/monitoring` from your favorite browser.

##### 7. Siddhi applications should be deployed to the manager cluster using one of the following methods:

a. Dropping the .siddhi file in to the `/data/pattern-distributed/siddhi-files` in the NFS node directory before or after starting the manager node.

b. Sending a "POST" request to http://\<host\>:\<port\>/siddhi-apps, with the Siddhi App attached as a file in the request as shown in the example below.
Refer [Stream Processor REST API Guide](https://docs.wso2.com/display/SP420/Stream+Processor+REST+API+Guide) for more information on using WSO2 Strean Processor APIs.

```
curl -X POST "https://wso2sp-manager-1/siddhi-apps" -H "accept: application/json" -H "Content-Type: text/plain" -d @TestSiddhiApp.siddhi -u admin:admin -k
```
