provider "google" {
  version = "3.5.0"

  credentials = file("terraform_gcp.json")

  project = "hive-415108 "
  region  = "europe-west9"
  zone    = "europe-west9-b"
}

resource "google_compute_instance" "appserver" {
  name = "secondary-application-server"
  machine_type = "e2-micro"

  boot_disk {
   initialize_params {
     image = "debian-cloud/debian-12"
   }
}
 network_interface {
   network = "hiveback"
}
}