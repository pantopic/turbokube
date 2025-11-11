# see terraform.tfvars
variable "region" {}
variable "ip_address" {}
variable "ssh_key" {}
variable "etcd_replicas" {}

terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.68.0"
    }
  }
}
provider "digitalocean" {
  # set env var DIGITALOCEAN_ACCESS_TOKEN
}

resource "digitalocean_project" "turbokube" {
  name        = "turbokube"
  description = "Tha whistles go WOOO"
  purpose     = "Education"
  environment = "Staging"
  is_default  = true
}

resource "digitalocean_tag" "turbokube" {
  name = "turbokube"
}
resource "digitalocean_tag" "api-server" {
  name = "api-server"
}

# https://slugs.do-api.dev/
variable "node_class" {
  default = {
    api-server : "g-4vcpu-16gb-intel"
    etcd : "g-4vcpu-16gb-intel"
    controller-manager : "s-4vcpu-16gb-amd"
    scheduler : "s-4vcpu-16gb-amd"
    metrics : "s-4vcpu-16gb-amd"
    worker-control-plane : "s-2vcpu-4gb"
    worker : "s-4vcpu-16gb-amd"
    admin : "s-2vcpu-4gb"
  }
}
