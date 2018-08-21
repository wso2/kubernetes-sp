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

set -e

ECHO=`which echo`
KUBECTL=`which kubectl`

echo 'Un-deploying Kubernetes Resources...'
${KUBECTL} delete deployments,pod,services,PersistentVolume,PersistentVolumeClaim,rc,configmap,Ingress -l pattern=wso2sp-pattern-distributed -n wso2

sleep 40s

# delete the created Kubernetes Namespace
${KUBECTL} delete namespace wso2

# switch the context to default namespace
${KUBECTL} config set-context $(kubectl config current-context) --namespace=default

echo 'Finished'

