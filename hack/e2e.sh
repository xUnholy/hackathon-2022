# This file contains common environment variables and setup logic for all test
# scripts. It assumes that the following environment variables are set by the
# Makefile:
#  - PLATFORM
#  - TAG
#  - SHA
#  - ARTIFACTS
#  - TALOSCTL
#  - INTEGRATION_TEST
#  - KUBECTL
#  - SHORT_INTEGRATION_TEST
#  - CUSTOM_CNI_URL
#  - IMAGE
#  - INSTALLER_IMAGE
#
# Some environment variables set in this file (e. g. TALOS_VERSION and KUBERNETES_VERSION)
# are referenced by https://github.com/talos-systems/cluster-api-templates.
# See other e2e-*.sh scripts.

set -eoux pipefail

TMP="/tmp/e2e/${PLATFORM}"
mkdir -p "${TMP}"
cp ~/.kube/config "${TMP}/kubeconfig"

# Env vars for cloud accounts
set +x
export GCP_B64ENCODED_CREDENTIALS=$( cat $(pwd)/.secrets/gcp-credentials-cluster-api.json | base64 | tr -d '\n' )
set -x

# Talos

export TALOSCONFIG="${TMP}/talosconfig"
export TALOS_VERSION=v1.0.6
export KUBECONFIG="${TMP}/kubeconfig"
export KUBECTL="kubectl"
export TALOSCTL="talosctl"
export CILIUM_VERSION="1.11.5"

export CLUSTER_NAME="cluster-00"
export GITHUB_USER="xunholy"
export GITHUB_REPO="hackathon-2022"
export GITHUB_BRANCH="master"
export CLI_ARGS=""

# Kubernetes

export KUBERNETES_VERSION=${KUBERNETES_VERSION:-1.23.7}

export CLUSTER_NAME_PREFIX="cluster"
export CLUSTER_NAME_SUFFIX="00"
export TIMEOUT=1200
export NUM_NODES=2
export TEMPLATE_TYPE=test

# TODO make a create_cluster_capi vs a non-capi cluster; This latter func just needs to template and commit the cluster.yaml to a flux managed dir

# Create a cluster via CAPI.
function create_cluster_capi {
  # Wait for first controlplane machine to have a name
  timeout=$(($(date +%s) + ${TIMEOUT}))
  until [ -n "$(${KUBECTL} --kubeconfig ${KUBECONFIG} get machine -l cluster.x-k8s.io/control-plane,cluster.x-k8s.io/cluster-name=${CLUSTER_NAME_PREFIX}-${CLUSTER_NAME_SUFFIX} --all-namespaces -o json | jq -re '.items[0].metadata.name | select (.!=null)')" ]; do
    [[ $(date +%s) -gt $timeout ]] && exit 1
    sleep 10
    ${KUBECTL} --kubeconfig ${KUBECONFIG} get machine -l cluster.x-k8s.io/control-plane,cluster.x-k8s.io/cluster-name=${CLUSTER_NAME_PREFIX}-${CLUSTER_NAME_SUFFIX} --all-namespaces
  done

  FIRST_CP_NODE=$(${KUBECTL} --kubeconfig ${KUBECONFIG} get machine -l cluster.x-k8s.io/control-plane,cluster.x-k8s.io/cluster-name=${CLUSTER_NAME_PREFIX}-${CLUSTER_NAME_SUFFIX} --all-namespaces -o json | jq -r '.items[0].metadata.name')

  # Wait for first controlplane machine to have a talosconfig ref
  timeout=$(($(date +%s) + ${TIMEOUT}))
  until [ -n "$(${KUBECTL} --kubeconfig ${KUBECONFIG} get machine ${FIRST_CP_NODE} -o json | jq -re '.spec.bootstrap.configRef.name | select (.!=null)')" ]; do
    [[ $(date +%s) -gt $timeout ]] && exit 1
    sleep 10
  done

  FIRST_CP_TALOSCONFIG=$(${KUBECTL} --kubeconfig ${KUBECONFIG} get machine ${FIRST_CP_NODE} -o json | jq -re '.spec.bootstrap.configRef.name')

  # Wait for talosconfig in cm then dump it out
  timeout=$(($(date +%s) + ${TIMEOUT}))
  until [ -n "$(${KUBECTL} --kubeconfig ${KUBECONFIG} get talosconfig ${FIRST_CP_TALOSCONFIG} -o jsonpath='{.status.talosConfig}')" ]; do
    [[ $(date +%s) -gt $timeout ]] && exit 1
    sleep 10
  done
  ${KUBECTL} --kubeconfig ${KUBECONFIG} get talosconfig ${FIRST_CP_TALOSCONFIG} -o jsonpath='{.status.talosConfig}' > ${TALOSCONFIG}

  # Wait until we have an IP for first controlplane node
  timeout=$(($(date +%s) + ${TIMEOUT}))
  until [ -n "$(${KUBECTL} --kubeconfig ${KUBECONFIG} get machine -o go-template --template='{{range .status.addresses}}{{if eq .type "ExternalIP"}}{{.address}}{{end}}{{end}}' ${FIRST_CP_NODE})" ]; do
    [[ $(date +%s) -gt $timeout ]] && exit 1
    sleep 10
  done

  MASTER_IP=$(${KUBECTL} --kubeconfig ${KUBECONFIG} get machine -o go-template --template='{{range .status.addresses}}{{if eq .type "ExternalIP"}}{{.address}}{{end}}{{end}}' ${FIRST_CP_NODE})
  "${TALOSCTL}" config endpoint "${MASTER_IP}"
  "${TALOSCTL}" config node "${MASTER_IP}"

  # Wait for the kubeconfig from first cp node
  timeout=$(($(date +%s) + ${TIMEOUT}))
  until get_kubeconfig; do
    [[ $(date +%s) -gt $timeout ]] && exit 1
    sleep 10
  done

  # Wait for nodes to check in

  timeout=$(($(date +%s) + ${TIMEOUT}))
  until ${KUBECTL} get nodes -o go-template='{{ len .items }}' --kubeconfig "${TMP}/kubeconfig-${CLUSTER_NAME_SUFFIX}" | grep ${NUM_NODES} >/dev/null; do
    [[ $(date +%s) -gt $timeout ]] && exit 1
    ${KUBECTL} get nodes -o wide --kubeconfig "${TMP}/kubeconfig-${CLUSTER_NAME_SUFFIX}" && :
    sleep 10
  done

  url=$(cat "${TMP}/kubeconfig-${CLUSTER_NAME_SUFFIX}" | yq '.clusters[].cluster.server')
  foo=${url#"https://"}
  foo=${foo%":443"}
  echo "LB IP address : ${foo}"

  mkdir -p "k8s/clusters/${CLUSTER_NAME_PREFIX}-${CLUSTER_NAME_SUFFIX}"
  clusterctl generate cluster "${CLUSTER_NAME_PREFIX}-${CLUSTER_NAME_SUFFIX}" --from templates/gcp/standard/template.yaml > "k8s/clusters/${CLUSTER_NAME_PREFIX}-${CLUSTER_NAME_SUFFIX}/cluster.yaml"
  helm repo add cilium https://helm.cilium.io/ --force-update
  helm template cilium cilium/cilium --version "${CILIUM_VERSION}" --namespace=kube-system --values=templates/gcp/${TEMPLATE_TYPE}/integrations/cilium/values.yaml --set k8sServiceHost=${foo} --dry-run > "k8s/clusters/${CLUSTER_NAME_PREFIX}-${CLUSTER_NAME_SUFFIX}/cni.yaml"
  kubectl apply -f "k8s/clusters/${CLUSTER_NAME_PREFIX}-${CLUSTER_NAME_SUFFIX}/cni.yaml" --kubeconfig "${TMP}/kubeconfig-${CLUSTER_NAME_SUFFIX}"

  # Wait for nodes to be ready
  timeout=$(($(date +%s) + ${TIMEOUT}))
  until ${KUBECTL} wait --timeout=1s --for=condition=ready=true --all nodes --kubeconfig "${TMP}/kubeconfig-${CLUSTER_NAME_SUFFIX}" > /dev/null; do
    [[ $(date +%s) -gt $timeout ]] && exit 1
    ${KUBECTL} get nodes -o wide --kubeconfig "${TMP}/kubeconfig-${CLUSTER_NAME_SUFFIX}" && :
    sleep 10
  done

  flux bootstrap github \
        --owner="${GITHUB_USER}" \
        --repository="${GITHUB_REPO}" \
        --path="k8s/clusters/${CLUSTER_NAME_PREFIX}-${CLUSTER_NAME_SUFFIX}" \
        --branch="${GITHUB_BRANCH}" \
        --network-policy=false \
        --personal=true \
        --private=false \
        --kubeconfig="${TMP}/kubeconfig-${CLUSTER_NAME_SUFFIX}" \
        "${CLI_ARGS}"

  # Verify that we have an HA controlplane
  # timeout=$(($(date +%s) + ${TIMEOUT}))
  # until ${KUBECTL} get nodes -l node-role.kubernetes.io/master='' -o go-template='{{ len .items }}' | grep 3 > /dev/null; do
  #   [[ $(date +%s) -gt $timeout ]] && exit 1
  #   ${KUBECTL} get nodes -l node-role.kubernetes.io/master='' && :
  #   sleep 10
  # done
}

function pivot_cluster_capi {
  clusterctl move --to-kubeconfig="${TMP}/kubeconfig-${CLUSTER_NAME_SUFFIX}"
}

function run_kubernetes_conformance_test {
  "${TALOSCTL}" conformance kubernetes --mode="${1}"
}

function run_kubernetes_integration_test {
  "${TALOSCTL}" health --run-e2e
}

function run_control_plane_cis_benchmark {
  ${KUBECTL} apply -f ${PWD}/hack/cis/kube-bench-master.yaml
  ${KUBECTL} wait --timeout=300s --for=condition=complete job/kube-bench-master > /dev/null
  ${KUBECTL} logs job/kube-bench-master
}

function run_worker_cis_benchmark {
  ${KUBECTL} apply -f ${PWD}/hack/cis/kube-bench-node.yaml
  ${KUBECTL} wait --timeout=300s --for=condition=complete job/kube-bench-node > /dev/null
  ${KUBECTL} logs job/kube-bench-node
}

function get_kubeconfig {
  clusterctl get kubeconfig ${CLUSTER_NAME_PREFIX}-${CLUSTER_NAME_SUFFIX} > "${TMP}/kubeconfig-${CLUSTER_NAME_SUFFIX}"
}

function dump_cluster_state {
  nodes=$(${KUBECTL} get nodes -o jsonpath="{.items[*].status.addresses[?(@.type == 'InternalIP')].address}" | tr [:space:] ',')
  "${TALOSCTL}" -n ${nodes} services
  ${KUBECTL} get nodes -o wide
  ${KUBECTL} get pods --all-namespaces -o wide
}

