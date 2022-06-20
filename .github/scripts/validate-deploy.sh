#!/usr/bin/env bash

SCRIPT_DIR=$(cd $(dirname "$0"); pwd -P)

GIT_REPO=$(cat git_repo)
GIT_TOKEN=$(cat git_token)

BIN_DIR=$(cat .bin_dir)

export PATH="${BIN_DIR}:${PATH}"

source "${SCRIPT_DIR}/validation-functions.sh"

export IBMCLOUD_API_KEY=$(cat .api_key)

if ! command -v oc 1> /dev/null 2> /dev/null; then
  echo "oc cli not found" >&2
  exit 1
fi

if ! command -v kubectl 1> /dev/null 2> /dev/null; then
  echo "kubectl cli not found" >&2
  exit 1
fi

if ! command -v ibmcloud 1> /dev/null 2> /dev/null; then
  echo "ibmcloud cli not found" >&2
  exit 1
fi

if [[ -z "${IBMCLOUD_API_KEY}" ]]; then
  echo "IBM Cloud API Key missing" >&2
  exit 1
fi

export KUBECONFIG=$(cat .kubeconfig)
NAMESPACE=$(cat .namespace)
COMPONENT_NAME=$(jq -r '.name // "my-module"' gitops-output.json)
BRANCH=$(jq -r '.branch // "main"' gitops-output.json)
SERVER_NAME=$(jq -r '.server_name // "default"' gitops-output.json)
LAYER=$(jq -r '.layer_dir // "2-services"' gitops-output.json)
TYPE=$(jq -r '.type // "base"' gitops-output.json)
RESOURCE_GROUP_ID=$(jq -r '.resource_group_id // empty' gitops-output.json)

mkdir -p .testrepo

git clone https://${GIT_TOKEN}@${GIT_REPO} .testrepo

cd .testrepo || exit 1

find . -name "*"

set -e

validate_gitops_content "${NAMESPACE}" "${LAYER}" "${SERVER_NAME}" "${TYPE}" "${COMPONENT_NAME}" "values.yaml"
validate_gitops_content "${NAMESPACE}" "${LAYER}" "${SERVER_NAME}" "${TYPE}" "${COMPONENT_NAME}" "templates/operator-secret.yaml"
validate_gitops_content "${NAMESPACE}" "${LAYER}" "${SERVER_NAME}" "${TYPE}" "${COMPONENT_NAME}" "templates/etcd-connection.yaml"

check_k8s_namespace "${NAMESPACE}"

check_k8s_resource "${NAMESPACE}" "sealedsecret" "ibmcloud-operator-secret"
check_k8s_resource "${NAMESPACE}" "secret" "ibmcloud-operator-secret"
check_k8s_resource "${NAMESPACE}" "secret" "etcd_credentials"
check_k8s_resource "${NAMESPACE}" "job" "portworx-ibm-portworx-job"
check_k8s_resource "${NAMESPACE}" "daemonset" "portworx-ibm-portworx"
check_k8s_resource "${NAMESPACE}" "services.ibmcloud" "portworx-ibm-portworx"
check_k8s_resource "${NAMESPACE}" "storageclass" "portworx-couchdb-sc"

SERVICE_NAME="portworx-ibm-portworx"

echo "Getting instance id of service: ${NAMESPACE}/${SERVICE_NAME}"
INSTANCE_ID=$(oc get services.ibmcloud -n "${NAMESPACE}" "${SERVICE_NAME}" -o json | jq -r '.status.instanceId // empty')

if [[ -z "${INSTANCE_ID}" ]]; then
  echo "INSTANCE_ID not found for service ${NAMESPACE}/${SERVICE_NAME}" >&2
  exit 1
fi

echo "Checking on service status"
SERVICE_STATE=$(oc get services.ibmcloud -n "${NAMESPACE}" "${SERVICE_NAME}" -o json | jq -r '.status.state // empty')
while [[ "${SERVICE_STATE}" == "provisioning" ]]; do
  echo "${SERVICE_NAME} is still provisioning. Waiting..."
  sleep 30
  SERVICE_STATE=$(oc get services.ibmcloud -n "${NAMESPACE}" "${SERVICE_NAME}" -o json | jq -r '.status.state // empty')
done

if [[ "${SERVICE_STATE}" != "Online" ]]; then
  echo "Failed to provision service instance ${SERVICE_NAME}: ${SERVICE_STATE}" >&2
  exit 1
fi

ibmcloud login || exit 1

echo "Listing volumes"
if [[ $(ibmcloud is volumes --output JSON | jq -r '.[] | select(.name | test("^pwx-")) | .name' | wc -l) -eq 0 ]]; then
  echo "No volumes found" >&2
  exit 1
else
  ibmcloud is volumes --output JSON | jq -r '.[] | .name'
fi

cat > ./pvc.yaml << EOM
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: persistent-volume-claim-test
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 5Gi
  selector:
    matchLabels:
      pv: local
  storageClassName: portworx-rwx-gp3-sc
EOM

echo "*** Creating test PVC"
oc apply -n "${NAMESPACE}" -f ./pvc.yaml

sleep 60

echo "*** Getting test PVC"
oc get pvc persistent-volume-claim-test -n "${NAMESPACE}" -o yaml

count=0
PHASE=$(oc get pvc persistent-volume-claim-test -n "${NAMESPACE}" -o json | jq -r '.status.phase')
while [[ "${PHASE}" == "Pending" ]] && [[ "${count}" -lt 40 ]]; do
  echo "Waiting for PVC to be bound. Sleeping..."
  count=$((count + 1))
  sleep 30
  PHASE=$(oc get pvc persistent-volume-claim-test -n "${NAMESPACE}" -o json | jq -r '.status.phase')
done

#PV_NAME=$(oc get pvc persistent-volume-claim-test -n "${NAMESPACE}" -o json | jq -r '.status.phase')
#kubectl patch pv <your-pv-name> -p '{"spec":{"persistentVolumeReclaimPolicy":"Retain"}}'

oc get pvc persistent-volume-claim-test -n "${NAMESPACE}" -o yaml

echo "Deleting pvc"
oc delete pvc persistent-volume-claim-test -n "${NAMESPACE}"

if [[ "${PHASE}" != "Bound" ]]; then
  echo "The PVC is not bound" >&2
  sleep 600
  exit 1
fi

cd ..
rm -rf .testrepo
