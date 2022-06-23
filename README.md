# Hackathon 2022

# Summary

## Prerequisite

Install all the tools required.

[task](https://taskfile.dev/installation/)

[kubectl](https://kubernetes.io/docs/tasks/tools/)

[clusterapi](https://cluster-api.sigs.k8s.io/user/quick-start.html#install-clusterctl)

[talosctl](https://www.talos.dev/v1.0/introduction/getting-started/#talosctl)

[gcloud](https://cloud.google.com/sdk/docs/install  )

[yq](https://github.com/mikefarah/yq#install)

## Capabilities

## User Journey

Create Business case and benefits for the users

> Many factors drive multi-cluster topologies, including close user proximity for apps, cluster and regional high availability, security and organizational separation, cluster migration, and data locality. These use cases are rarely isolated. As the reasons for multiple clusters grow, the need for a formal and productized multi-cluster platform becomes more urgent.

TODO

### Cluster Mesh

https://docs.cilium.io/en/stable/gettingstarted/clustermesh/clustermesh/#gs-clustermesh

Requirements

* PodCIDR ranges in all clusters and all nodes must be non-conflicting and unique IP addresses.

* Nodes in all clusters must have IP connectivity between each other. This requirement is typically met by establishing peering or VPN tunnels between the networks of the nodes of each cluster.

* The network between clusters must allow the inter-cluster communication. The exact ports are documented in the Firewall Rules section.

### Service Mesh

TBC

## GCP Setup

The following must be done to setup your GCP project.

1. Create GCP project
2. Enable required APIs (*compute engine)
3. Create `cluster-api` GSA and provide it with `role/Owner` (*scope could be smaller but for simplicity Owner is sufficent)
4. Create GCS bucket called `talos-images-01` - name needs to be globally unique so a UID suffix would be best
5. Create the VM images using `task talos:image`
6. Update FW rules to include TCP ports for `6443,50000` which is used by Talos to connect and bootstrap nodes (* see Limitation section about I/O Timeouts)

WIP

## Limitations

### I/O Timeout During Bootstrap

Currently the default FW rules created in GCP don't expose port 50000 which is used by the talos bootstrap provider and therefore the cluster is stuck in a pending state to bootstrap, therefore it's required that this must be managed currently outside of the CAPI implementation until it's solved upstream.

https://github.com/siderolabs/cluster-api-control-plane-provider-talos/issues/127

Recommendation is to create your own existing network: https://github.com/kubernetes-sigs/cluster-api-provider-gcp/blob/main/docs/book/src/topics/prerequisites.md#setup-a-network-and-cloud-nat

### AWS Template CNI

> Calico is the only supported CNI right now. The AWS Cluster API provider sets up Calico rules by default in its created security groups. Other CNIs can likely be used, but it will take some extra work on setting up the groups manually and specifying them as extra groups in the cluster manifests.

https://github.com/siderolabs/cluster-api-templates/tree/main/aws#assumptions-and-caveats

### PodSecurity

Default enabled in 1.23.x

https://kubernetes.io/docs/concepts/security/pod-security-admission/#pod-security-levels

## Stretch Goals

Creating multi-regional clusters.
