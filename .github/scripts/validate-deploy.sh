#!/usr/bin/env bash

SCRIPT_DIR=$(cd $(dirname "$0"); pwd -P)

GIT_REPO=$(cat git_repo)
GIT_TOKEN=$(cat git_token)

BIN_DIR=$(cat .bin_dir)

export PATH="${BIN_DIR}:${PATH}"

source "${SCRIPT_DIR}/validation-functions.sh"

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

export KUBECONFIG=$(cat .kubeconfig)
NAMESPACE=$(cat .namespace)
COMPONENT_NAME=$(jq -r '.name // "my-module"' gitops-output.json)
BRANCH=$(jq -r '.branch // "main"' gitops-output.json)
SERVER_NAME=$(jq -r '.server_name // "default"' gitops-output.json)
LAYER=$(jq -r '.layer_dir // "2-services"' gitops-output.json)
TYPE=$(jq -r '.type // "base"' gitops-output.json)

mkdir -p .testrepo

git clone https://${GIT_TOKEN}@${GIT_REPO} .testrepo

cd .testrepo || exit 1

find . -name "*"

set -e

validate_gitops_content "${NAMESPACE}" "${LAYER}" "${SERVER_NAME}" "${TYPE}" "${COMPONENT_NAME}" "values.yaml"
validate_gitops_content "${NAMESPACE}" "${LAYER}" "${SERVER_NAME}" "${TYPE}" "${COMPONENT_NAME}" "templates/operator-secret.yaml"

check_k8s_namespace "${NAMESPACE}"

check_k8s_resource "${NAMESPACE}" "sealedsecret" "ibmcloud-operator-secret"
check_k8s_resource "${NAMESPACE}" "secret" "ibmcloud-operator-secret"
check_k8s_resource "${NAMESPACE}" "job" "portworx-ibm-portworx-job"
check_k8s_resource "${NAMESPACE}" "daemonset" "portworx-ibm-portworx"
check_k8s_resource "${NAMESPACE}" "services.ibmcloud" "portworx-ibm-portworx"
check_k8s_resource "${NAMESPACE}" "storageclass" "portworx-couchdb-sc"

echo "Listing volumes"
if [[ $(ibmcloud is volumes --output JSON | jq -r '.[] | select(.name | test("^pwx-")) | .name' | wc -l) -eq 0 ]]; then
  echo "No volumes found" >&2
  exit 1
else
  ibmcloud is volumes --output JSON | jq -r '.[] | .name'
fi

cd ..
rm -rf .testrepo