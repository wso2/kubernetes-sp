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

echo 'Un-deploying Kubernetes Resources...'
kubectl delete deployments,pod,services,PersistentVolume,PersistentVolumeClaim,rc,Ingress -l pattern=wso2sp-pattern-distributed -n wso2

sleep 40s

# switch the context to default namespace
kubectl config set-context $(kubectl config current-context) --namespace=default

echo 'Finished'