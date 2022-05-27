#!/bin/bash


# Docs for cleaning up Portworx installation at: https://cloud.ibm.com/docs/containers?topic=containers-portworx#portworx_cleanup
# Additional utilities for cleaning up Portworx installation available at https://github.com/IBM/ibmcloud-storage-utilities/blob/master/px-utils/px_cleanup/px-wipe.sh

if [[ -n "${BIN_DIR}" ]]; then
  export PATH="${BIN_DIR}:${PATH}"
fi

curl  -fSsL https://raw.githubusercontent.com/IBM/ibmcloud-storage-utilities/master/px-utils/px_cleanup/px-wipe.sh | bash -s -- --talismanimage icr.io/ext/portworx/talisman --talismantag 1.1.0 --wiperimage icr.io/ext/portworx/px-node-wiper --wipertag 2.5.0 --force

echo "removing the portworx helm from the cluster"
_rc=0
helm_release=$(helm ls -a --output json | jq -r '.[]|select(.name=="portworx") | .name')
if [ -z "$helm_release" ];
then
  echo "Unable to find helm release for portworx.  Ensure your helm client is at version 3 and has access to the cluster.";
else
  helm uninstall portworx || _rc=$?
  if [ $_rc -ne 0 ]; then
    echo "error removing the helm release"
    #exit 1;
  fi
fi

echo "removing all portworx storage classes"
kubectl get sc | grep portworx | awk '{ print $1 }' | while read in; do
  kubectl delete sc "$in"
done

echo "removing portworx artifacts"
kubectl delete clusterrole,clusterrolebinding -l app.kubernetes.io/instance=portworx
kubectl delete serviceaccount,service,job,configmap,deployment,daemonset,statefulset -n kube-system -l app.kubernetes.io/instance=portworx
kubectl delete deployment portworx-pvc-controller -n kube-system --ignore-not-found=true
kubectl delete sa portworx-pvc-controller-account -n kube-system --ignore-not-found=true

# use the following command to verify all portworks resources are gone.  If you see a result here, it didn't work
# kubectl get all -A | grep portworx
