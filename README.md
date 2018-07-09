# Kubernetes Resources for WSO2 Stream Processor
*Kubernetes Resources for container-based deployments of WSO2 Stream Processor (SP) deployment patterns*

This repository contains Kubernetes resources required for,

* [A fully distributed deployment of WSO2 Stream Processor](pattern-distributed)

## How to update configurations

Kubernetes resources for WSO2 products use Kubernetes [ConfigMaps](https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/)
to pass on the minimum set of configurations required to setup a product deployment pattern.

For example, the minimum set of configurations required to setup a fully distributed deployment of WSO2 Stream Processor can be found
in `<KUBERNETES_HOME>/pattern-distributed/confs` directory. The Kubernetes ConfigMaps are generated from these files.

If you intend to pass on any additional files with configuration changes, third-party libraries, OSGi bundles and security
related artifacts to the Kubernetes cluster, you may mount the desired content to `/home/wso2carbon/wso2-server-volume` directory path within
a WSO2 product Docker container.

The following example depicts how this can be achieved when passing additional configurations to WSO2 Stream Processor Manager
in a fully distributed deployment of WSO2 Stream Processor:

a. In order to apply the updated configurations, WSO2 product server instances need to be restarted. Hence, un-deploy all the Kubernetes resources
corresponding to the product deployment, if they are already deployed.

b. Create and export a directory within the NFS server instance.
   
c. Add the additional configuration files, third-party libraries, OSGi bundles and security related artifacts, into appropriate
folders matching that of the relevant WSO2 product home folder structure, within the previously created directory.

d. Grant ownership to `wso2carbon` user and `wso2` group, for the directory created in step (b).
      
   ```
   sudo chown -R wso2carbon:wso2 <directory_name>
   ```
      
e. Grant read-write-execute permissions to the `wso2carbon` user, for the directory created in step (b).
      
   ```
   chmod -R 700 <directory_name>
   ```

f. Map the directory created in step (b) to a Kubernetes [Persistent Volume](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)
in the `<KUBERNETES_HOME>/pattern-distributed/volumes/persistent-volumes.yaml` file. For example, append the following entry to the file:

```
apiVersion: v1
kind: PersistentVolume
metadata:
  name: sp-fully-distributed-additional-config-pv
  labels:
    purpose: sp-additional-configs
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteMany
  persistentVolumeReclaimPolicy: Retain
  nfs:
    server: <NFS_SERVER_IP>
    path: "<NFS_LOCATION_PATH>"
```

Provide the appropriate `NFS_SERVER_IP` and `NFS_LOCATION_PATH`.

g. Create a Kubernetes Persistent Volume Claim to bind with the Kubernetes Persistent Volume created in step e. For example, append the following entry
to the file `<KUBERNETES_HOME>/pattern-distributed/sp/wso2sp-mgt-volume-claim.yaml`:

```
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: sp-fully-distributed-additional-config-volume-claim
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 1Gi
  storageClassName: ""
  selector:
    matchLabels:
      purpose: sp-additional-configs
```

h. Update the appropriate Kubernetes [Deployment](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/) resource(s).
For example in the discussed scenario, update the volumes (`spec.template.spec.volumes`) and volume mounts (`spec.template.spec.containers[wso2sp-manager-{node-number}].volumeMounts`) in
`<KUBERNETES_HOME>/pattern-distributed/sp/wso2sp-manager-1-deployment.yaml` and `<KUBERNETES_HOME>/pattern-distributed/sp/wso2sp-manager-2-deployment.yaml` files
as follows:

```
volumeMounts:
...
- name: sp-additional-config-storage-volume
  mountPath: "/home/wso2carbon/wso2-server-volume"

volumes:
...
- name: sp-additional-config-storage-volume
  persistentVolumeClaim:
    claimName: sp-fully-distributed-additional-config-volume-claim
```

i. Deploy the Kubernetes resources as defined in section **Quick Start Guide** for the fully distributed deployment of WSO2 Stream Processor.
