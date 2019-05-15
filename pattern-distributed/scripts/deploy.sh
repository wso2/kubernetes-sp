#!/bin/bash

# ------------------------------------------------------------------------
# Copyright 2018 WSO2, Inc. (http://wso2.com)
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

ECHO=`which echo`
KUBECTL=`which kubectl`

# methods
function echoBold () {
    ${ECHO} -e $'\e[1m'"${1}"$'\e[0m'
}

read -p "Do you have a WSO2 Subscription?(N/y)" -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
 read -p "Enter Your WSO2 Username: " WSO2_SUBSCRIPTION_USERNAME
 echo
 read -s -p "Enter Your WSO2 Password: " WSO2_SUBSCRIPTION_PASSWORD
 echo
 HAS_SUBSCRIPTION=0
 if ! grep -q "imagePullSecrets" ../sp/wso2sp-dashboard-deployment.yaml; then
     if ! sed -i.bak -e 's|wso2/|gcr.io/research-n-development-209206/|' \
     ../sp/wso2sp-dashboard-deployment.yaml  \
     ../sp/wso2sp-manager-1-deployment.yaml \
     ../sp/wso2sp-manager-2-deployment.yaml \
     ../sp/wso2sp-receiver-deployment.yaml \
     ../sp/wso2sp-worker-deployment.yaml; then
     echo "couldn't configure the docker.wso2.com"
     exit 1
     fi
     if ! sed -i.bak -e '/serviceAccount/a \
    \      imagePullSecrets:' \
     ../sp/wso2sp-dashboard-deployment.yaml  \
     ../sp/wso2sp-manager-1-deployment.yaml \
     ../sp/wso2sp-manager-2-deployment.yaml \
     ../sp/wso2sp-receiver-deployment.yaml \
     ../sp/wso2sp-worker-deployment.yaml; then
     echo "couldn't configure the \"imagePullSecrets:\""
     fi
      if ! sed -i.bak -e '/imagePullSecrets/a \
    \      - name: wso2creds' \
     ../sp/wso2sp-dashboard-deployment.yaml  \
     ../sp/wso2sp-manager-1-deployment.yaml \
     ../sp/wso2sp-manager-2-deployment.yaml \
     ../sp/wso2sp-receiver-deployment.yaml \
     ../sp/wso2sp-worker-deployment.yaml; then
     echo "couldn't configure the \"- name: wso2creds\""
     fi
     # remove backup files
     rm ../sp/*.bak
 fi
elif [[ $REPLY =~ ^[Nn]$ || -z "$REPLY" ]]
then
 HAS_SUBSCRIPTION=1
else
 echo "Invalid option"
 exit 1
fi

# create a new Kubernetes Namespace
${KUBECTL} create namespace wso2

# create a new service account in 'wso2' Kubernetes Namespace
${KUBECTL} create serviceaccount wso2svcacct -n wso2

# set namespace
${KUBECTL} config set-context $(${KUBECTL} config current-context) --namespace=wso2

if [ ${HAS_SUBSCRIPTION} -eq 0 ]; then
 ${KUBECTL} create secret docker-registry wso2creds --docker-server=docker.wso2.com --docker-username=${WSO2_SUBSCRIPTION_USERNAME} --docker-password=${WSO2_SUBSCRIPTION_PASSWORD} --docker-email=${WSO2_SUBSCRIPTION_USERNAME}
fi
# create Kubernetes Role and Role Binding necessary for the Kubernetes API requests made from Kubernetes membership scheme
${KUBECTL} create  -f ../../rbac/rbac.yaml

# volumes
echo 'deploying persistence volumes ...'
${KUBECTL} create -f ../volumes/persistent-volumes.yaml
${KUBECTL} create -f ../extras/rdbms/volumes/persistent-volumes.yaml

# Configuration Maps
echo 'deploying config maps ...'
${KUBECTL} create configmap sp-manager-bin --from-file=../confs/sp-manager/bin/
${KUBECTL} create configmap sp-manager-conf --from-file=../confs/sp-manager/conf/
${KUBECTL} create configmap sp-worker-bin --from-file=../confs/sp-worker/bin/
${KUBECTL} create configmap sp-worker-conf --from-file=../confs/sp-worker/conf/
${KUBECTL} create configmap mysql-dbscripts --from-file=../extras/confs/mysql/dbscripts/

sleep 30s

# databases
echo 'deploying databases ...'
${KUBECTL} create -f ../extras/rdbms/mysql/rdbms-persistent-volume-claim.yaml
${KUBECTL} create -f ../extras/rdbms/mysql/rdbms-service.yaml
${KUBECTL} create -f ../extras/rdbms/mysql/rdbms-deployment.yaml

#zookeeper
echo 'deploying Zookeeper ...'
${KUBECTL} create -f ../extras/zookeeper/zookeeper-deployment.yaml
${KUBECTL} create -f ../extras/zookeeper/zookeeper-service.yaml

#kafka
echo 'deploying Kafka ...'
${KUBECTL} create -f ../extras/kafka/kafka-deployment.yaml
${KUBECTL} create -f ../extras/kafka/kafka-service.yaml

echo 'deploying volume claims...'
${KUBECTL} create -f ../sp/wso2sp-mgt-volume-claim.yaml

echo 'deploying Stream Processor manager profile and services...'
${KUBECTL} create -f ../sp/wso2sp-manager-1-service.yaml
${KUBECTL} create -f ../sp/wso2sp-manager-2-service.yaml
${KUBECTL} create -f ../sp/wso2sp-dashboard-service.yaml
${KUBECTL} create -f ../sp/wso2sp-manager-1-deployment.yaml
${KUBECTL} create -f ../sp/wso2sp-manager-2-deployment.yaml
${KUBECTL} create -f ../sp/wso2sp-dashboard-deployment.yaml

sleep 30s

echo 'deploying Stream Processor worker profile and services...'
${KUBECTL} create -f ../sp/wso2sp-worker-service.yaml
${KUBECTL} create -f ../sp/wso2sp-receiver-service.yaml
${KUBECTL} create -f ../sp/wso2sp-worker-deployment.yaml
${KUBECTL} create -f ../sp/wso2sp-receiver-deployment.yaml

# deploying the ingress resource
echo 'Deploying Ingress...'
${KUBECTL} create -f ../ingresses/wso2sp-manager-1-ingress.yaml
${KUBECTL} create -f ../ingresses/wso2sp-manager-2-ingress.yaml
${KUBECTL} create -f ../ingresses/wso2sp-dashboard-ingress.yaml
sleep 20s

echo 'Finished'

