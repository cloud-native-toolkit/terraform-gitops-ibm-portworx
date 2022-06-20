#!/usr/bin/env bash

RED='\033[0;31m'
YELLOW='\033[0;33m'
WHITE='\033[0;37m'
NC='\033[0m'

DELETE="$1"

if ! command -v ibmcloud 1> /dev/null 2> /dev/null; then
  echo -e "${YELLOW}ibmcloud cli not found.${NC}"
  echo -e "  The cli can be installed from ${WHITE}https://cloud.ibm.com/docs/cli?topic=cli-getting-started#step1-install-idt${NC}" >&2
  exit 1
fi

if ! ibmcloud account show 1> /dev/null 2> /dev/null; then
  echo -e "Not logged in. Use '${YELLOW}ibmcloud login${NC}' to log in." >&2
  exit 1
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

REGION=$(ibmcloud target --output JSON | jq -r '.region.name')
echo "Retrieving volumes for region: ${REGION}"

ibmcloud is volumes --output JSON | \
  jq -c '[.[] | {"id": .id, "clusterId": .user_tags[] | select(. | test("^clusterid")) | capture("clusterid:(?<clusterid>.+)").clusterid, "zone": .zone.name, "region": .zone.name | capture("(?<region>.+)-[0-9]").region, "volumeAttachments": .volume_attachments}] | group_by(.clusterId)[] | {"clusterId": .[0].clusterId, "volumes": .}' | \
  while read -r clusterVolumes;
do
  clusterId=$(echo "${clusterVolumes}" | jq -r '.clusterId // empty')
  volumes=$(echo "${clusterVolumes}" | jq -c '.volumes // []')

  if [[ -z "${clusterId}" ]]; then
    continue
  fi

  if ! ibmcloud ks cluster get --cluster "${clusterId}" 1> /dev/null 2> /dev/null; then
    echo "Cluster does not exist: ${clusterId}"

    volumeNames=$(echo "${volumes}" | jq -r '.[] | .name' | tr '\n' ' ')

    if [[ -n "${DELETE}" ]]; then
      volumeIds=$(echo "${volumes}" | jq -r '.[] | .id' | tr '\n' ' ')
      echo "  Deleting volumes: ${volumeNames}"

      ibmcloud is volume-delete ${volumeIds} -f
    else
      echo "  Associated volumes: ${volumeNames}"
    fi
  fi
done
