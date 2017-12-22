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

set -e
# Copy the backed up artifacts from ${HOME}/tmp/server/. Copying the initial artifacts to ${HOME}/tmp/server/ is done in the 
# Dockerfile. This is to preserve the initial artifacts in a volume mount (the mounted directory can be empty initially). 
# The artifacts will be copied to the CARBON_HOME/repository/deployment/server location before the server is started.
carbon_home=${HOME}/${WSO2_SERVER}-${WSO2_SERVER_VERSION}/wso2/${WSO2_SERVER_PROFILE}
server_artifact_location=${carbon_home}/deployment
if [[ -d ${HOME}/tmp/server/ ]]; then
   if [[ ! "$(ls -A ${server_artifact_location}/)" ]]; then
      # There are no artifacts under CARBON_HOME/deployment; copy them.
      echo "copying artifacts from ${HOME}/tmp/server/ to ${server_artifact_location}/ .."
      cp -rf ${HOME}/tmp/server/* ${server_artifact_location}/
   fi
   rm -rf ${HOME}/tmp/server/
fi
# Copy customizations done by user do the CARBON_HOME location. 
if [[ -d ${HOME}/tmp/carbon/ ]]; then
   echo "copying custom configurations and artifacts from ${HOME}/tmp/carbon/ to ${carbon_home}/ .."
   cp -rf ${HOME}/tmp/carbon/* ${carbon_home}/
   rm -rf ${HOME}/tmp/carbon/
fi

# Copy ConfigMaps
server_conf=${carbon_home}/../../conf/${WSO2_SERVER_PROFILE}
# Mount any ConfigMap to ${carbon_home}-conf location
if [ -e ${carbon_home}-conf/resources-security ]
 then cp ${carbon_home}-conf/resources-security/* ${carbon_home}/../../resources/security/
fi

if [ -e ${carbon_home}-conf/conf ]; then 
 cp ${carbon_home}-conf/conf/* ${server_conf}/
fi


# unique node id
export local_docker_ip=$(ip route get 1 | awk '{print $NF;exit}')
deployment_yaml_location=${server_conf}/deployment.yaml
if [[ ! -z ${local_docker_ip} ]]; then
   sed -i "s#wso2-sp#wso2-sp${local_docker_ip}#" "${deployment_yaml_location}"
   sed -i "s#NODE_IP#${local_docker_ip}#" "${deployment_yaml_location}"
   if [[ $? == 0 ]]; then
      echo "Successfully updated node with ${local_docker_ip}"
   else
      echo "Error occurred while updating node with ${local_docker_ip}"
   fi
fi

# Start the carbon server.
${HOME}/${WSO2_SERVER}-${WSO2_SERVER_VERSION}/bin/${WSO2_SERVER_PROFILE}.sh
