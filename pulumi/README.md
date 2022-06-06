# Pulumi

https://github.com/siderolabs/pulumi-provider-talos

## Intention

Pulumi will be utalised to deploy Cluster API, template the management cluster in the cloud, pivot the management cluster to the newly formed cluster and ensure all cloud resources exist that are deemed as prerequisites.

Pulumi will be responsible for retrieving cluster-apiserver loadbalancer IPs to store into Cilium helm values; If the IPs can be pre-allocated then this isn't required however it appears to be a current limitation; It will then apply the CNI to the cluster.

## Examples

https://github.com/pulumi/examples
