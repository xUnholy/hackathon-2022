export CLUSTER_NAME_PREFIX="cluster"
export CLUSTER_NAME_SUFFIX="02"
export CILIUM_VERSION="1.11.5"
export TEMPLATE_TYPE=test


export CLUSTER_NAME="cluster-00"
export GITHUB_USER="xunholy"
export GITHUB_REPO="hackathon-2022"
export GITHUB_BRANCH="master"
export CLI_ARGS=""

TMP="/tmp/e2e/gcp"

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