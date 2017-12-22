Steps:


# set namespace
kubectl config set-context $(kubectl config current-context) --namespace=wso2
# volumes
kubectl create -f volumes/persistent-volumes.yaml
# Configuration Maps
kubectl create configmap sp-manager-conf --from-file=../confs/sp-manager/conf/
kubectl create configmap sp-worker-conf --from-file=../confs/sp-worker/conf/
# databases
kubectl create -f rdbms/rdbms-persistent-volume-claim.yaml
kubectl create -f rdbms/rdbms-service.yaml
kubectl create -f rdbms/rdbms-deployment.yaml
# nfs
kubectl create -f nfs/nfs-persistent-volume-claim.yaml
kubectl create -f nfs/nfs-service.yaml
kubectl create -f nfs/nfs-deployment.yaml
# zookeeper
kubectl create -f zookeeper/zookeeper-service.yaml
kubectl create -f zookeeper/zookeeper-deployment.yaml  
# kafka
kubectl create -f kafka/kafka-service.yaml
kubectl create -f kafka/kafka-deployment.yaml

# sp
kubectl create -f sp/wso2sp-mgt-volume-claim.yaml
kubectl create -f sp/wso2sp-manager-1-service.yaml
kubectl create -f sp/wso2sp-manager-2-service.yaml
kubectl create -f sp/wso2sp-manager-service.yaml
kubectl create -f sp/wso2sp-worker-service.yaml
kubectl create -f sp/wso2sp-manager-1-deployment.yaml
kubectl create -f sp/wso2sp-manager-2-deployment.yaml
kubectl create -f sp/wso2sp-worker-deployment.yaml

