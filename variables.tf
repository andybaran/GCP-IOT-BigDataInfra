variable "region" {
  description = "GCP region"
}

variable "zone" {
  description = "GCP zone, needed by dataflow"
}

variable "bq_dataset" {
    description = "BigQuery Dataset"
}

variable "bq_table" {
    description = "BigQuery Table"
}

variable "pub_sub_sub" {
    description = "Pub/Sub Subscription"
}
