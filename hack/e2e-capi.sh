#!/usr/bin/env bash

set -eou pipefail

source ./hack/e2e.sh

export CAPI_VERSION="${CAPI_VERSION:-1.1.4}"
export CAPA_VERSION="${CAPA_VERSION:-1.4.1}"
export CAPG_VERSION="${CAPG_VERSION:-1.1.0}"


# CABPT
export CABPT_NS="cabpt-system"

trap 'failure' ERR

failure() {
  clusterctl delete --all
}

clusterctl init \
    --config hack/clusterctl.yaml \
    --core "cluster-api:v${CAPI_VERSION}" \
    --control-plane "talos" \
    --infrastructure "gcp:v${CAPG_VERSION}"  \
    --bootstrap "talos" --kubeconfig /tmp/e2e/gcp/kubeconfig-00

gcloud auth activate-service-account --key-file "$(pwd)/.secrets/gcp-credentials-cluster-api.json"

# Wait for the talosconfig
timeout=$(($(date +%s) + ${TIMEOUT}))
until ${KUBECTL} wait --timeout=1s --for=condition=Ready -n ${CABPT_NS} pods --all; do
  [[ $(date +%s) -gt $timeout ]] && exit 1
  echo 'Waiting to CABPT pod to be available...'
  sleep 5
done
