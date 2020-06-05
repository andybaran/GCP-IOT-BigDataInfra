data "terraform_remote_state" "project" {
  backend = "remote"

  config = {
    hostname = "app.terraform.io"
    organization = var.organization-name
    workspaces = {
      name = var.workspace-name
    }
  }
}

provider "google" {
  credentials = base64decode(data.terraform_remote_state.project.outputs.service_account_token)
  project     = data.terraform_remote_state.project.outputs.short_project_id
  region = var.region
  zone = var.zone
}

# ****************************************************************************
# GKE via module
# ****************************************************************************

module "module-gke" {
  source  = "app.terraform.io/akb-test/module-gke/gcp"
  region = var.region
  zone = var.zone
  bq-cluster-usage-dataset = var.bq-cluster-usage-dataset
  organization-name = var.organization-name
  primary-cluster = var.primary-cluster
  primary-node-count = var.primary-node-count
  primary-node-machine-type = var.primary-node-machine-type
  primary-node-pool = var.primary-node-pool
  workspace-name = var.workspace-name
}

# ****************************************************************************
#  K8's provider to conenct to GKE
# ****************************************************************************

data "google_container_cluster" "mygke" {
  name = var.primary-cluster
  location = var.region
}

provider "kubernetes" {
  load_config_file = "false"

  host = ""
}



# ****************************************************************************
# Consul  
# ****************************************************************************

resource "helm_release" "helm_consul" {

  name = "consul"
  repository = "https://helm.releases.hashicorp.com"
  chart = "hashicorp/consul-enterprise"
  version = "1.7.3-ent"

  set {
    name = "server.replicas"
    value = 3
  }

  set {
    name = "server.bootstrapExpect"
    value = 3
  }
  
  set {
    name = "ui.service.type"
    value = "LoadBalancer"
  }

  set {
    name = "server.enterpriseLicense.secretName"
    value = "consul-license"
  }

  set {
    name = "server.enterpriseLicense.secretKey"
    value = "key"
  }

  set {
    name = "server.connect"
    value = true
  }

  set {
    name = "client.grpc"
    value = true
  }

  set {
    name = "connectInject.enabled"
    value = true
  }

  set {
    name = "connectInject.default"
    value = false
  }

}

# ****************************************************************************
# BigQuery
# ****************************************************************************

resource "google_bigquery_dataset" "obd2info" {

    dataset_id = var.bq_dataset
    friendly_name = var.bq_dataset
    description = "Dataset containing tables related to OBD2 obdii logs"
    location = "US"

    //  user_project_override = true

   /* access {
        role = "projects/${data.terraform_remote_state.project.outputs.short_project_id}/roles/bigquery.admin"
        special_group = "projectOwners"
    }

    access {
        role = "projects/${data.terraform_remote_state.project.outputs.short_project_id}/roles/bigquery.dataEditor"
        special_group = "projectWriters"
    }

    access {
        role = "projects/${data.terraform_remote_state.project.outputs.short_project_id}/roles/bigquery.dataViewer"
        special_group = "projectReaders"
    }

    access {
        role = "projects/${data.terraform_remote_state.project.outputs.short_project_id}/roles/bigquery.jobUser"
        special_group = "projectWriters"
    }

    access {
        role = "projects/${data.terraform_remote_state.project.outputs.short_project_id}/bigquery.jobUser"
        special_group = "projectReaders"
    }*/
}

resource "google_bigquery_table" "obd2logging" {

    dataset_id = google_bigquery_dataset.obd2info.dataset_id
    table_id = var.bq_table


    schema = <<EOF
    [
    {
        "mode": "NULLABLE", 
        "name": "VIN", 
        "type": "STRING"
      }, 
      {
        "mode": "NULLABLE", 
        "name": "collectedAt", 
        "type": "STRING"
      }, 
      {
        "mode": "NULLABLE", 
        "name": "PID_RPM", 
        "type": "FLOAT"
      }, 
      {
        "mode": "NULLABLE", 
        "name": "PID_ENGINE_LOAD", 
        "type": "FLOAT"
      }, 
      {
        "mode": "NULLABLE", 
        "name": "PID_COOLANT_TEMP", 
        "type": "FLOAT"
      }, 
      {
        "mode": "NULLABLE", 
        "name": "PID_ABSOLUTE_ENGINE_LOAD", 
        "type": "FLOAT"
      }, 
      {
        "mode": "NULLABLE", 
        "name": "PID_TIMING_ADVANCE", 
        "type": "FLOAT"
      }, 
      {
        "mode": "NULLABLE", 
        "name": "PID_ENGINE_OIL_TEMP", 
        "type": "FLOAT"
      }, 
      {
        "mode": "NULLABLE", 
        "name": "PID_ENGINE_TORQUE_PERCENTAGE", 
        "type": "FLOAT"
      }, 
      {
        "mode": "NULLABLE",
        "name": "PID_ENGINE_REF_TORQUE", 
        "type": "FLOAT"
      }, 
      {
        "mode": "NULLABLE",   
        "name": "PID_INTAKE_TEMP", 
        "type": "FLOAT"
      },
      {
        "mode": "NULLABLE",   
        "name": "PID_MAF_FLOW", 
        "type": "FLOAT"
      },
      {
        "mode": "NULLABLE", 
        "name": "PID_BAROMETRIC", 
        "type": "FLOAT"
      }, 
      {
        "mode": "NULLABLE",  
        "name": "PID_SPEED", 
        "type": "FLOAT"
      }, 
      {
        "mode": "NULLABLE",   
        "name": "PID_RUNTIME", 
        "type": "FLOAT"
      },
      {
        "mode": "NULLABLE",   
        "name": "PID_DISTANCE", 
        "type": "FLOAT"
      }
    ]
    EOF
}

# ****************************************************************************
# PubSub
# ****************************************************************************

resource "google_pubsub_topic" "pst_obdii_data" {

    name = "obdii_data"
}

resource "google_pubsub_subscription" "pst_obdii_data_sub" {

    depends_on = [google_pubsub_topic.pst_obdii_data]
    name = var.pub_sub_sub
    topic = google_pubsub_topic.pst_obdii_data.name
    
    message_retention_duration = "86400s"
    retain_acked_messages = true
}

# ****************************************************************************
# IOT Core
# ****************************************************************************

resource "google_cloudiot_registry" "iot_registry" {

    depends_on = [google_pubsub_topic.pst_obdii_data]
    name = "obd2_devices"

    event_notification_configs {
        pubsub_topic_name = "projects/${data.terraform_remote_state.project.outputs.short_project_id}/topics/obdii_data"
    }
    mqtt_config = {
        mqtt_enabled_state = "MQTT_ENABLED"
    }
    http_config = {
        http_enabled_state = "HTTP_ENABLED"
    }
}


resource "google_storage_bucket" "dataflow_bucket" {
   
  name = join("",["dataflow-", data.terraform_remote_state.project.outputs.short_project_id])
  location = "US"

}

# ****************************************************************************
# Dataflow
# ****************************************************************************

resource "google_dataflow_job" "collect_OBD2_data" {

  name              = "OBD2-Data-Collection"
  template_gcs_path = "gs://dataflow-templates/latest/PubSub_Subscription_to_BigQuery"
  temp_gcs_location = "${google_storage_bucket.dataflow_bucket.url}/tmp_dir"
  on_delete = "drain"

  parameters = {
    inputSubscription = "projects/${data.terraform_remote_state.project.outputs.short_project_id}/subscriptions/${var.pub_sub_sub}"
    outputTableSpec = "${data.terraform_remote_state.project.outputs.short_project_id}:${var.bq_dataset}.${var.bq_table}"
    #flexRSGoal = "COST_OPTIMIZED"
  }
}