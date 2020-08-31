variable developer_project {

        default = "dev-project-287706"
}

variable production_project {

        default = "driven-strength-287313"
}
resource "google_compute_network" "network1"{
name="my-vpc-1"
project = var.production_project
 routing_mode="GLOBAL"
auto_create_subnetworks="false"

}

resource "google_compute_network" "network2"{
name="my-vpc-2"
project = var.developer_project
 routing_mode="GLOBAL"
auto_create_subnetworks="false"

}

resource "google_compute_subnetwork" "subnetwork2"{
ip_cidr_range="10.10.12.0/24"
name="my-subnet-2"
network =google_compute_network.network2.name
project=var.developer_project
region="us-west1"

}
resource "google_compute_subnetwork" "subnetwork1"{
ip_cidr_range="10.10.11.0/24"
name="my-subnet-1"
network =google_compute_network.network1.name
project=var.production_project
region="us-east1"

}

resource "google_compute_firewall" "default" {
  name    = "test-firewall"
  network = google_compute_network.network1.name
  project= var.production_project
  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["80", "8080", "1000-2000","22"]
  }

  source_tags = ["web"]
  source_ranges=["0.0.0.0/0"]
}
resource "google_compute_instance" "default22" {
  name         = "test"
  machine_type = "n1-standard-1"
  zone         = "us-west1-c"
  project=var.production_project
  tags = ["foo", "bar"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }
network_interface {
    network = google_compute_network.network1.name
    subnetwork=google_compute_subnetwork.subnetwork1.name
    subnetwork_project="driven-strength-287313"
     access_config{

}

  }
}
resource "google_compute_network_peering" "peering1" {
  name         = "peering1"
  network      = google_compute_network.network1.id
  peer_network = google_compute_network.network2.id
  
}
resource "google_compute_network_peering" "peering2" {
  name         = "peering1"
  network      = google_compute_network.network2.id
  peer_network = google_compute_network.network1.id

}

resource "google_compute_firewall" "default1" {
  name    = "test-firewall"
  network = google_compute_network.network2.name
  project = "dev-project-287706"

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["80", "8080", "1000-2000","22"]
  }

  source_tags = ["web"]
  source_ranges=["0.0.0.0/0"]
}

resource "google_compute_instance" "default2" {
  name         = "test"
  machine_type = "n1-standard-1"
  zone         = "us-west1-c"
  project="dev-project-287706"
  tags = ["foo", "bar"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }
network_interface {
    network = google_compute_network.network2.name
    subnetwork=google_compute_subnetwork.subnetwork2.name
    subnetwork_project="dev-project-287706"
     access_config{

}
}
}

resource "google_container_cluster" "primary" {
  name               = "marcellus-wallace"
  location           = "us-central1-a"
  initial_node_count = 3
  project="dev-project-287706"
  master_auth {
    username = ""
    password = ""

    client_certificate_config {
      issue_client_certificate = false
    }
  }

  node_config {
    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]

    metadata = {
      disable-legacy-endpoints = "true"
    }

    labels = {
      foo = "bar"
    }

    tags = ["foo", "bar"]
  }

  timeouts {
    create = "30m"
    update = "40m"
  }


}
resource "null_resource" "nullremote1"  {
depends_on=[google_container_cluster.primary] 
provisioner "local-exec" {
            command = "gcloud container clusters get-credentials ${google_container_cluster.primary.name} --zone ${google_container_cluster.primary.location}  --project ${google_container_cluster.primary.project}"
        }


}

resource "kubernetes_service" "example" {

depends_on=[null_resource.nullremote1]  

metadata {
    name = "terraform-example"
  }
  spec {
    selector = {
      app = "${kubernetes_pod.example.metadata.0.labels.app}"
    }
    session_affinity = "ClientIP"
    port {
      port        = 80
      target_port = 80
    }

    type = "LoadBalancer"
  }
}

resource "kubernetes_pod" "example" {

depends_on=[null_resource.nullremote1] 
metadata {
    name = "mywordp"
    labels = {
      app = "MyApp"
    }
  }

  spec {
    container {
      image = "wordpress"
      name  = "example"
    }
  }
}

output "wordpressip" {
          value = kubernetes_service.example.load_balancer_ingress
  }


resource "google_sql_database" "database" {
  name     = "my-database1"
  instance = google_sql_database_instance.master.name
  project=var.production_project
}

resource "google_sql_database_instance" "master" {
  name             = "instance15"
  database_version = "MYSQL_5_7"
  region           = "us-central1"
 
  project=var.production_project



  settings {
    # Second-generation instance tiers are based on the machine
    # type. See argument reference below.
    tier = "db-f1-micro"
    
    
ip_configuration{
ipv4_enabled ="true"

authorized_networks{
name="public network"
value="0.0.0.0/0"
}
}




  }
}


resource "google_sql_user" "users" {
  name     = "myuser"
  instance = google_sql_database_instance.master.name
project=var.production_project
 
  password = "redhat"
}
