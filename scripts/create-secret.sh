#!/usr/bin/env bash

NAMESPACE="$1"
APIKEY_NAME="$2"
ETCD_SECRET="$3"
OUTPUT_DIR="$4"

if [[ -n "${BIN_DIR}" ]]; then
  export PATH="${BIN_DIR}:${PATH}"
fi

mkdir -p "${OUTPUT_DIR}"

kubectl create secret generic "${APIKEY_NAME}" \
  -n "${NAMESPACE}" \
  --from-literal="api-key=${IBMCLOUD_API_KEY}" \
  --dry-run=client \
  --output=json | \
  kubectl annotate -f - \
  "argocd.argoproj.io/sync-wave=-5" \
  "helm.sh/hook-weight=-5" \
  --local=true \
  --dry-run=client \
  --output=json \
  > "${OUTPUT_DIR}/operator-secret.yaml"

if [[ -n "${ETCD_CERTIFICATE_BASE64}" ]]; then
  CA_DECODE=$(echo "${ETCD_CERTIFICATE_BASE64}" | base64 -d)
  CA_LITERAL="--from-literal='ca.pem=${CA_DECODE}'"
fi

if [[ -n "${ETCD_USERNAME}" ]] && [[ -n "${ETCD_PASSWORD}" ]] && [[ -n "${ETCD_CONNECTION_URL}" ]]; then
  kubectl create secret generic "${ETCD_SECRET}" \
    -n "${NAMESPACE}" \
    --from-literal="url=etcd:${ETCD_CONNECTION_URL}" \
    --from-literal="username=${ETCD_USERNAME}" \
    --from-literal="password=${ETCD_PASSWORD}" \
    ${CA_LITERAL} \
    --dry-run=client \
    --output=json | \
    kubectl annotate -f - \
    "argocd.argoproj.io/sync-wave=-5" \
    "helm.sh/hook-weight=-5" \
    --local=true \
    --dry-run=client \
    --output=json \
    > "${OUTPUT_DIR}/${ETCD_SECRET}.yaml"
fi
