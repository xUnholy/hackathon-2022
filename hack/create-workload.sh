#!/usr/bin/env bash

set -eou pipefail
export PLATFORM="gcp"

source ./hack/e2e.sh

export CAPI_VERSION="${CAPI_VERSION:-1.1.4}"
export CAPA_VERSION="${CAPA_VERSION:-1.4.1}"
export CAPG_VERSION="${CAPG_VERSION:-1.1.0}"

export CABPT_NS="cabpt-system"

export GCP_VM_SVC_ACCOUNT=cluster-api@rising-capsule-353505.iam.gserviceaccount.com
export GCP_PROJECT=rising-capsule-353505
export GCP_REGION=us-central1
export GCP_NETWORK=default

export CILIUM_VERSION="1.11.5"

export GITHUB_USER="xunholy"
export GITHUB_REPO="hackathon-2022"
export GITHUB_BRANCH="master"

WORKDIR='./workdir'

function createWorkload() {
    if [ $# == 0 ]
    then
        echo "No version passed to createWorkload" 1>&2
        exit 1
    fi 
    VERSION=$1
    CLUSTER_NAME="platform-$VERSION"
    FL_KUBECONFIG=$KUBECONFIG
    mkdir -p "${WORKDIR}/${CLUSTER_NAME}"
    clusterctl generate cluster $CLUSTER_NAME \
        --kubeconfig ${FL_KUBECONFIG} \
        --from templates/gcp/v$VERSION/template.yaml > "${WORKDIR}/${CLUSTER_NAME}/capi.yaml"

    kubectl apply -f "${WORKDIR}/${CLUSTER_NAME}/capi.yaml"
    
    sleep 3
    
    FL_KUBECONFIG=$CLUSTER_NAME.kubeconfig
    clusterctl get kubeconfig $CLUSTER_NAME > $FL_KUBECONFIG
    clusterctl generate cluster "${CLUSTER_NAME}" --from templates/gcp/standard/template.yaml > "k8s/clusters/${CLUSTER_NAME}/cluster.yaml"
    helm repo add cilium https://helm.cilium.io/ --force-update
    helm template cilium cilium/cilium --version "${CILIUM_VERSION}" --namespace=kube-system --values=templates/gcp/test/integrations/cilium/values.yaml --dry-run > "${WORKDIR}/${CLUSTER_NAME}/cni.yaml"
    kubectl apply -f "${WORKDIR}/${CLUSTER_NAME}/cni.yaml" --kubeconfig "${FL_KUBECONFIG}"

    sleep 3

    flux bootstrap github \
        --owner="${GITHUB_USER}" \
        --repository="${GITHUB_REPO}" \
        --path="templates/gcp/v${VERSION}" \
        --branch="${GITHUB_BRANCH}" \
        --network-policy=false \
        --personal=true \
        --private=false \
        --kubeconfig=${FL_KUBECONFIG}
}

function createAllWorkloads {
    for d in ./templates/gcp/*/ ; do
        name=$(basename $d)
        if [[ $name =~ ^v ]]
        then
            name=$(echo $name | tr -d 'v')
            createWorkload $name
        fi
    done
}

createAllWorkloads