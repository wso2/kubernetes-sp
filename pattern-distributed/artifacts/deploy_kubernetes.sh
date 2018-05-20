#!/bin/bash

# ------------------------------------------------------------------------
# Copyright 2017 WSO2, Inc. (http://wso2.com)
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License
# ------------------------------------------------------------------------

# create a new Kubernetes Namespace
kubectl create namespace wso2

# create a new service account in 'wso2' Kubernetes Namespace
kubectl create serviceaccount wso2svcacct -n wso2

# set namespace
kubectl config set-context $(kubectl config current-context) --namespace=wso2

kubectl create secret docker-registry wso2creds --docker-server=docker.wso2.com --docker-username=<username> --docker-password=<password> --docker-email=<email>

# create Kubernetes role and role binding necessary for the Kubernetes API requests made from Kubernetes membership scheme
kubectl create --username=admin --password=<cluster-admin-password> -f ../rbac/rbac.yaml

# volumes
echo 'deploying persistence volumes ...'
kubectl create -f volumes/pv.yaml

# Configuration Maps
echo 'deploying config maps ...'
kubectl create configmap sp-manager-conf --from-file=../confs/sp-manager/conf/
kubectl create configmap sp-worker-conf --from-file=../confs/sp-worker/conf/
kubectl create configmap mysql-conf --from-file=../confs/rdbms/conf/
kubectl create configmap mysql-dbscripts --from-file=../confs/rdbms/dbscripts/

sleep 30s

# databases
echo 'deploying databases ...'
kubectl create -f rdbms/rdbms-persistent-volume-claim.yaml
kubectl create -f rdbms/rdbms-service.yaml
kubectl create -f rdbms/rdbms-deployment.yaml

#zookeeper
echo 'deploying Zookeeper ...'
kubectl create -f zookeeper/zookeeper-deployment.yaml
kubectl create -f zookeeper/zookeeper-service.yaml

#kafka
echo 'deploying Kafka ...'
kubectl create -f kafka/kafka-deployment.yaml
kubectl create -f kafka/kafka-service.yaml

echo 'deploying volume claims...'
kubectl create -f sp/wso2sp-mgt-volume-claim.yaml

echo 'deploying Stream Processor manager profile and services...'
kubectl create -f sp/wso2sp-manager-1-service.yaml
kubectl create -f sp/wso2sp-manager-2-service.yaml
kubectl create -f sp/wso2sp-manager-1-deployment.yaml
kubectl create -f sp/wso2sp-manager-2-deployment.yaml

sleep 30s

echo 'deploying Stream Processor worker profile and services...'
kubectl create -f sp/wso2sp-worker-service.yaml
kubectl create -f sp/wso2sp-worker-deployment.yaml

# deploying the ingress resource
echoBold 'Deploying Ingress...'
kubectl create -f ingresses/wso2sp  -ingress.yaml
sleep 20s

echoBold 'Finished'

