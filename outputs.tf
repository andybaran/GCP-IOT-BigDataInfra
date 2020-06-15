output "cluster_client_cert" {
  value = module.module-gke.cluster_client_cert
  description = "Base64 encoded public certificate used by clients to authenticate to the cluster endpoint."
}

output "cluster_client_key" {
  value = module.module-gke.cluster_client_key
  description = "Base64 encoded private key used by clients to authenticate to the cluster endpoint."
}

output "cluster_ca_certificate" {
  value = module.module-gke.cluster_ca_certificate
  description = "Base64 encoded public certificate that is the root of trust for the cluster."
}

output "gke_endpoint" {
  value = module.module-gke.gke_endpoint
  description = "The IP address of this cluster's Kubernetes master."
}

output "cluster_name" {
  value = module.module-gke.cluster_name
  description = "The name of the cluster."
}

output "zone" {
  value = var.zone
  description = "GCP Zone the cluster is in."
}

output "region" {
  value = var.region
  description = "GCP Region the cluster is in."
}

output "gcloud_project" {
  value = data.terraform_remote_state.project.outputs.short_project_id
  description = "GCP project the cluser is in."
}