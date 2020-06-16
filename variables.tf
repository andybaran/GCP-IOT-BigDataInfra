variable "organization-name" {
  description = "TFE Organization name"
}

variable "workspace-name" {
  description = "TFE workspace name where project was created"
}

variable "region" {
  description = "GCP region"
}

variable "zone" {
  description = "GCP zone, needed by dataflow"
}

variable "bq_dataset" {
    description = "BigQuery Dataset for telemetry data"
}

variable "bq_table" {
    description = "BigQuery Table"
}

variable "pub_sub_sub" {
    description = "Pub/Sub Subscription"
}

variable "bq-cluster-usage-dataset" {
  description = "GCP dataset for cluster usage data"
}

variable "primary-cluster" {
  description = "Primary GKE cluster"
}

variable "primary-node-count" {
  description = "Primary GKE cluster node count"
}

variable "primary-node-machine-type" {
  description = "Primary GKE cluster node machine type"
}

variable "primary-node-pool" {
  description = "gke primary node pool"
}

variable "consul-enterprise-key" {
  description = "Consul enterprise licensing"
}
