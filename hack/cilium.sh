export CLUSTER_NAME_PREFIX="cluster"
export CLUSTER_NAME_SUFFIX="01"
export CILIUM_VERSION="1.11.5"
export TEMPLATE_TYPE=test

TMP="/tmp/e2e/gcp"

 url=$(cat "${TMP}/kubeconfig-${CLUSTER_NAME_SUFFIX}" | yq '.clusters[].cluster.server')
  foo=${url#"https://"}
  foo=${foo%":443"}
  echo "LB IP address : ${foo}"

helm template cilium cilium/cilium --version "${CILIUM_VERSION}" --namespace=kube-system --values=templates/gcp/${TEMPLATE_TYPE}/integrations/cilium/values.yaml --set k8sServiceHost=${foo} --dry-run > "k8s/clusters/${CLUSTER_NAME_PREFIX}-${CLUSTER_NAME_SUFFIX}/cni.yaml"

kubectl apply -f "k8s/clusters/${CLUSTER_NAME_PREFIX}-${CLUSTER_NAME_SUFFIX}/cni.yaml" --kubeconfig "${TMP}/kubeconfig-${CLUSTER_NAME_SUFFIX}"