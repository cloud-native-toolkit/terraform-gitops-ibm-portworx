#!/usr/bin/env bash

RED='\033[0;31m'
YELLOW='\033[0;33m'
WHITE='\033[0;37m'
NC='\033[0m'

CLUSTER="$1"

echo "Checking for prereqs"

if ! command -v ibmcloud 1> /dev/null 2> /dev/null; then
  echo -e "${YELLOW}ibmcloud cli not found.${NC}"
  echo -e "  The cli can be installed from ${WHITE}https://cloud.ibm.com/docs/cli?topic=cli-getting-started#step1-install-idt${NC}" >&2
  exit 1
fi

if ! ibmcloud account show 1> /dev/null 2> /dev/null; then
  echo -e "Not logged in. Use '${YELLOW}ibmcloud login${NC}' to log in." >&2
  exit 1
fi

CURRENT_REGION=$(ibmcloud target --output JSON | jq -r '.region.name // empty')
if [[ -z "${CURRENT_REGION}" ]]; then
  echo -e "  No current region set. Defaulting to ${YELLOW}us-east${NC}"
  ibmcloud target -r us-east 1> /dev/null 2> /dev/null
fi

if ! ibmcloud is --help 1> /dev/null 2> /dev/null; then
  echo -e "${YELLOW}ibmcloud is plugin not found.${NC}"
  echo -e "  The plugin can be installed by running ${WHITE}ibmcloud plugin install infrastructure-service${NC}" >&2
  exit 1
fi

if ! ibmcloud ks --help 1> /dev/null 2> /dev/null; then
  echo -e "${YELLOW}ibmcloud ks plugin not found.${NC}"
  echo -e "  The plugin can be installed by running ${WHITE}ibmcloud plugin install container-service${NC}" >&2
  exit 1
fi

if ! command -v jq 1> /dev/null 2> /dev/null; then
  echo -e "${YELLOW}jq cli not found${NC}" >&2
  echo -e "  The jq cli can be installed from ${WHITE}https://stedolan.github.io/jq/download/${NC}"
  exit 1
fi

echo -e "Getting information for cluster: ${YELLOW}${CLUSTER}${NC}"
CLUSTER_INFO=$(ibmcloud ks cluster get --cluster "${CLUSTER}" --output JSON 2> /dev/null)

if [[ -z "${CLUSTER_INFO}" ]]; then
  echo -e "${RED}Cluster not found:${NC} ${CLUSTER}" >&2
  exit 1
fi

CLUSTER_ID=$(echo "${CLUSTER_INFO}" | jq -r '.id')
CLUSTER_REGION=$(echo "${CLUSTER_INFO}" | jq -r '.region')

ibmcloud target -r "${CLUSTER_REGION}" 1> /dev/null 2> /dev/null
echo -e "  Looking up volumes for cluster ${YELLOW}${CLUSTER_ID}${NC} in region ${YELLOW}${CLUSTER_REGION}${NC}"

CLUSTER_VOLUMES=$(ibmcloud is volumes --output JSON | \
  jq --arg CLUSTER_TAG "clusterid:${CLUSTER_ID}" -c '.[] | select(.user_tags[] | contains($CLUSTER_TAG))')

if [[ -z "${CLUSTER_VOLUMES}" ]]; then
  echo "  No volumes found for cluster"
  exit 0
fi

echo -e "${WHITE}Cluster volumes:${NC}"
echo "${CLUSTER_VOLUMES}" | jq -r '.name'
