export GCP_PROJECT=rising-capsule-353505
export CLUSTER_NAME_PREFIX="cluster"
export CLUSTER_NAME_SUFFIX="01"

# gcloud auth activate-service-account --key-file "$(pwd)/.secrets/gcp-credentials-cluster-api.json"

# gcloud iam service-accounts create dns01-solver --display-name "dns01-solver"

# gcloud config set project "${GCP_PROJECT}"

# gcloud projects add-iam-policy-binding "${GCP_PROJECT}" \
#    --member serviceAccount:dns01-solver@"${GCP_PROJECT}".iam.gserviceaccount.com \
#    --role roles/dns.admin

# gcloud iam service-accounts keys create key.json \
#    --iam-account dns01-solver@"${GCP_PROJECT}".iam.gserviceaccount.com

kubectl create secret generic clouddns-dns01-solver-svc-acct \
   --from-file=key.json -n network-system --kubeconfig .secrets/"${CLUSTER_NAME_PREFIX}-${CLUSTER_NAME_SUFFIX}"
