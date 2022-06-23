#!/usr/bin/env bash

set -eou pipefail

source ./hack/e2e.sh

function setup {
  set +x
  gcloud auth activate-service-account --key-file "$(pwd)/.secrets/gcp-credentials-cluster-api.json"
  set -x

  # gsutil cp ${ARTIFACTS}/gcp-amd64.tar.gz gs://talos-e2e/gcp-${SHA}.tar.gz
  # gcloud --quiet --project talos-testbed compute images delete talos-e2e-${SHA} || true
  # gcloud --quiet --project talos-testbed compute images create talos-e2e-${SHA} --source-uri gs://talos-e2e/gcp-${SHA}.tar.gz

  ## Cluster-wide vars
  export CLUSTER_NAME="${CLUSTER_NAME_PREFIX}-${CLUSTER_NAME_SUFFIX}"
  export GCP_PROJECT=rising-capsule-353505
  export GCP_REGION=us-central1
  export GCP_NETWORK=default
  export GCP_VM_SVC_ACCOUNT=cluster-api@${GCP_PROJECT}.iam.gserviceaccount.com


  ## Control plane vars
  export CONTROL_PLANE_MACHINE_COUNT=1
  export GCP_CONTROL_PLANE_MACHINE_TYPE=n1-standard-2
  export GCP_CONTROL_PLANE_VOL_SIZE=50
  export GCP_CONTROL_PLANE_IMAGE_ID=projects/${GCP_PROJECT}/global/images/talos-v1-0-6

  ## Worker vars
  export WORKER_MACHINE_COUNT=1
  export GCP_NODE_MACHINE_TYPE=n1-standard-2
  export GCP_NODE_VOL_SIZE=50
  export GCP_NODE_IMAGE_ID=projects/${GCP_PROJECT}/global/images/talos-v1-0-6

  clusterctl generate cluster ${CLUSTER_NAME} \
    --kubeconfig ${KUBECONFIG} \
    --from templates/gcp/test/template.yaml > ${TMP}/cluster.yaml

  kubectl apply -f ${TMP}/cluster.yaml
}

setup
create_cluster_capi gcp
# pivot_cluster_capi gcp