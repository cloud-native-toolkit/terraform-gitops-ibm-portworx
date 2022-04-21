#!/usr/bin/env bash

NAMESPACE="$1"
NAME="$2"
OUTPUT_DIR="$3"

mkdir -p "${OUTPUT_DIR}"

kubectl create secret generic "${NAME}" \
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
