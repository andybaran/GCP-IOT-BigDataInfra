output "cluster_client_cert" {
  value = module.module-gke.client_certificate
  description = "Base64 encoded public certificate used by clients to authenticate to the cluster endpoint."
}

output "cluster_client_key" {
  value = module.module-gke.client_key
  description = "Base64 encoded private key used by clients to authenticate to the cluster endpoint."
}

output "cluster_ca_certificate" {
  value = module.module-gke.cluster_ca_certificate
  description = "Base64 encoded public certificate that is the root of trust for the cluster."
}

output "gke_endpoint" {
  value = module.module-gke.endpoint
  description = "The IP address of this cluster's Kubernetes master."
}