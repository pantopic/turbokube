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

# https://slugs.do-api.dev/
variable "node_class" {
  default = {
    apiserver : "g-4vcpu-16gb-intel"
    etcd : "g-4vcpu-16gb-intel"
    controller_manager : "s-4vcpu-16gb-amd"
    scheduler : "s-4vcpu-16gb-amd"
    metrics : "s-4vcpu-16gb-amd"
    turbo : "s-2vcpu-4gb"
    worker : "s-4vcpu-16gb-amd"
  }
}
