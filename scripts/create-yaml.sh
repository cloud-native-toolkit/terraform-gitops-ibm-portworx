#!/usr/bin/env bash

SCRIPT_DIR=$(cd $(dirname "$0"); pwd -P)
MODULE_DIR=$(cd "${SCRIPT_DIR}/.."; pwd -P)
CHART_DIR=$(cd "${MODULE_DIR}/charts/portworx"; pwd -P)

NAME="$1"
DEST_DIR="$2"

mkdir -p "${DEST_DIR}"

cp -R "${CHART_DIR}"/* "${DEST_DIR}"

if [[ -n "${VALUES_CONTENT}" ]]; then
  echo -n "${VALUES_CONTENT}" > "${DEST_DIR}/values.yaml"
fi
