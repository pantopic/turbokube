terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.68.0"
    }
  }
}

provider "digitalocean" {
  # set DIGITALOCEAN_ACCESS_TOKEN
}

variable "region" {
  default = "sfo3"
}

# https://cloud.digitalocean.com/account/security
variable "ssh_key" {
  default = "49:83:09:b4:e5:cd:87:ee:fa:2f:59:5d:ac:2f:e9:32"
}

# https://cloud.digitalocean.com/networking/vpc
variable "vpc_uuid" {
  default = "3a37baee-a150-46e2-93e7-758365306e22"
}

# https://slugs.do-api.dev/
variable "control_node_class" {
  default = "s-2vcpu-4gb"
}
variable "worker_node_class" {
  default = "s-2vcpu-4gb"
}
variable "turbo_node_class" {
  default = "s-2vcpu-4gb"
}
variable "metrics_node_class" {
  default = "s-2vcpu-4gb"
}
