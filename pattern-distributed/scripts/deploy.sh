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
GREP=`which grep`
KUBERNETES_CLIENT=`which kubectl`
SED=`which sed`
TEST=`which test`

# methods
function echoBold () {
    ${ECHO} -e $'\e[1m'"${1}"$'\e[0m'
}

read -p "Do you have a WSO2 Subscription?(N/y)" -n 1 -r
${ECHO}

if [[ $REPLY =~ ^[Yy]$ ]]; then
    read -p "Enter Your WSO2 Username: " WSO2_SUBSCRIPTION_USERNAME
    ${ECHO}
    read -s -p "Enter Your WSO2 Password: " WSO2_SUBSCRIPTION_PASSWORD
    ${ECHO}

    HAS_SUBSCRIPTION=0

    if ! ${GREP} -q "imagePullSecrets" ../sp/wso2sp-dashboard-deployment.yaml; then
        if ! ${SED} -i.bak -e 's|wso2/|docker.wso2.com/|' \
            ../sp/wso2sp-dashboard-deployment.yaml  \
            ../sp/wso2sp-manager-1-deployment.yaml \
            ../sp/wso2sp-manager-2-deployment.yaml \
            ../sp/wso2sp-receiver-deployment.yaml \
            ../sp/wso2sp-worker-deployment.yaml; then
            echoBold "Could not configure to use the Docker image available at WSO2 Private Docker Registry (docker.wso2.com)"
            exit 1
        fi
        if ! ${SED} -i.bak -e '/serviceAccount/a \      imagePullSecrets:' \
            ../sp/wso2sp-dashboard-deployment.yaml  \
            ../sp/wso2sp-manager-1-deployment.yaml \
            ../sp/wso2sp-manager-2-deployment.yaml \
            ../sp/wso2sp-receiver-deployment.yaml \
            ../sp/wso2sp-worker-deployment.yaml; then
            echoBold "Could not configure Kubernetes Docker image pull secret: Failed to create \"imagePullSecrets:\" attribute"
            exit 1
        fi
        if ! ${SED} -i.bak -e '/imagePullSecrets/a \      - name: wso2creds' \
            ../sp/wso2sp-dashboard-deployment.yaml  \
            ../sp/wso2sp-manager-1-deployment.yaml \
            ../sp/wso2sp-manager-2-deployment.yaml \
            ../sp/wso2sp-receiver-deployment.yaml \
            ../sp/wso2sp-worker-deployment.yaml; then
            echoBold "Could not configure Kubernetes Docker image pull secret: Failed to create secret name"
            exit 1
        fi
    fi
elif [[ ${REPLY} =~ ^[Nn]$ || -z "${REPLY}" ]]; then
     HAS_SUBSCRIPTION=1

     if ! ${SED} -i.bak -e '/imagePullSecrets:/d' -e '/- name: wso2creds/d' \
         ../sp/wso2sp-dashboard-deployment.yaml  \
         ../sp/wso2sp-manager-1-deployment.yaml \
         ../sp/wso2sp-manager-2-deployment.yaml \
         ../sp/wso2sp-receiver-deployment.yaml \
         ../sp/wso2sp-worker-deployment.yaml; then
         echoBold "couldn't configure the \"- name: wso2creds\""
         exit 1
     fi

     if ! ${SED} -i.bak -e 's|docker.wso2.com|wso2|' \
      ../sp/wso2sp-dashboard-deployment.yaml  \
      ../sp/wso2sp-manager-1-deployment.yaml \
      ../sp/wso2sp-manager-2-deployment.yaml \
      ../sp/wso2sp-receiver-deployment.yaml \
      ../sp/wso2sp-worker-deployment.yaml; then
      echoBold "couldn't configure the docker.wso2.com"
      exit 1
     fi
else
    echoBold "You have entered an invalid option."
    exit 1
fi

# remove backup files
${TEST} -f ../sp/*.bak && rm ../sp/*.bak

# create a new Kubernetes Namespace
${KUBERNETES_CLIENT} create namespace wso2

# create a new service account in 'wso2' Kubernetes Namespace
${KUBERNETES_CLIENT} create serviceaccount wso2svcacct -n wso2

# set namespace
${KUBERNETES_CLIENT} config set-context $(${KUBERNETES_CLIENT} config current-context) --namespace=wso2

if [[ ${HAS_SUBSCRIPTION} -eq 0 ]]; then
    # create a Kubernetes Secret for passing WSO2 Private Docker Registry credentials
    ${KUBERNETES_CLIENT} create secret docker-registry wso2creds --docker-server=docker.wso2.com --docker-username=${WSO2_SUBSCRIPTION_USERNAME} --docker-password=${WSO2_SUBSCRIPTION_PASSWORD} --docker-email=${WSO2_SUBSCRIPTION_USERNAME}
fi

# create Kubernetes Role and Role Binding necessary for the Kubernetes API requests made from Kubernetes membership scheme
${KUBERNETES_CLIENT} create  -f ../../rbac/rbac.yaml

# volumes
echo 'deploying persistence volumes ...'
${KUBERNETES_CLIENT} create -f ../volumes/persistent-volumes.yaml
${KUBERNETES_CLIENT} create -f ../extras/rdbms/volumes/persistent-volumes.yaml

# Configuration Maps
echo 'deploying config maps ...'
${KUBERNETES_CLIENT} create configmap sp-manager-bin --from-file=../confs/sp-manager/bin/
${KUBERNETES_CLIENT} create configmap sp-manager-conf --from-file=../confs/sp-manager/conf/
${KUBERNETES_CLIENT} create configmap sp-worker-bin --from-file=../confs/sp-worker/bin/
${KUBERNETES_CLIENT} create configmap sp-worker-conf --from-file=../confs/sp-worker/conf/
${KUBERNETES_CLIENT} create configmap mysql-dbscripts --from-file=../extras/confs/mysql/dbscripts/

sleep 30s

# databases
echo 'deploying databases ...'
${KUBERNETES_CLIENT} create -f ../extras/rdbms/mysql/rdbms-persistent-volume-claim.yaml
${KUBERNETES_CLIENT} create -f ../extras/rdbms/mysql/rdbms-service.yaml
${KUBERNETES_CLIENT} create -f ../extras/rdbms/mysql/rdbms-deployment.yaml

#zookeeper
echo 'deploying Zookeeper ...'
${KUBERNETES_CLIENT} create -f ../extras/zookeeper/zookeeper-deployment.yaml
${KUBERNETES_CLIENT} create -f ../extras/zookeeper/zookeeper-service.yaml

#kafka
echo 'deploying Kafka ...'
${KUBERNETES_CLIENT} create -f ../extras/kafka/kafka-deployment.yaml
${KUBERNETES_CLIENT} create -f ../extras/kafka/kafka-service.yaml

echo 'deploying volume claims...'
${KUBERNETES_CLIENT} create -f ../sp/wso2sp-mgt-volume-claim.yaml

echo 'deploying Stream Processor manager profile and services...'
${KUBERNETES_CLIENT} create -f ../sp/wso2sp-manager-1-service.yaml
${KUBERNETES_CLIENT} create -f ../sp/wso2sp-manager-2-service.yaml
${KUBERNETES_CLIENT} create -f ../sp/wso2sp-dashboard-service.yaml
${KUBERNETES_CLIENT} create -f ../sp/wso2sp-manager-1-deployment.yaml
${KUBERNETES_CLIENT} create -f ../sp/wso2sp-manager-2-deployment.yaml
${KUBERNETES_CLIENT} create -f ../sp/wso2sp-dashboard-deployment.yaml

sleep 30s

echo 'deploying Stream Processor worker profile and services...'
${KUBERNETES_CLIENT} create -f ../sp/wso2sp-worker-service.yaml
${KUBERNETES_CLIENT} create -f ../sp/wso2sp-receiver-service.yaml
${KUBERNETES_CLIENT} create -f ../sp/wso2sp-worker-deployment.yaml
${KUBERNETES_CLIENT} create -f ../sp/wso2sp-receiver-deployment.yaml

# deploying the ingress resource
echo 'Deploying Ingress...'
${KUBERNETES_CLIENT} create -f ../ingresses/wso2sp-manager-1-ingress.yaml
${KUBERNETES_CLIENT} create -f ../ingresses/wso2sp-manager-2-ingress.yaml
${KUBERNETES_CLIENT} create -f ../ingresses/wso2sp-dashboard-ingress.yaml
sleep 20s

echoBold 'Finished'
echoBold 'To access the WSO2 Identity Server management console, try https://wso2is/carbon in your browser.'

