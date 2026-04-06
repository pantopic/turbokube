resource "digitalocean_droplet" "etcd" {
  count = var.node_count.etcd

  name     = "etcd-${count.index}"
  region   = var.region
  vpc_uuid = digitalocean_vpc.turbokube.id
  tags     = ["turbokube"]

  image     = "ubuntu-24-04-x64"
  size      = var.node_class.etcd
  ssh_keys  = [var.ssh_key]
  user_data = file("setup.sh")
}

resource "digitalocean_droplet" "apiserver" {
  count = var.node_count.apiserver

  name     = "apiserver-${count.index}"
  region   = var.region
  vpc_uuid = digitalocean_vpc.turbokube.id
  tags     = ["turbokube", "apiserver"]

  image     = "ubuntu-24-04-x64"
  size      = var.node_class.apiserver
  ssh_keys  = [var.ssh_key]
  user_data = file("setup.sh")
}

# resource "digitalocean_droplet" "scheduler" {
#   count = var.node_count.scheduler

#   name     = "scheduler-${count.index}"
#   region   = var.region
#   vpc_uuid = digitalocean_vpc.turbokube.id
#   tags     = ["turbokube"]

#   image     = "ubuntu-24-04-x64"
#   size      = var.node_class.scheduler
#   ssh_keys  = [var.ssh_key]
#   user_data = file("setup.sh")
# }

# resource "digitalocean_droplet" "controller-manager" {
#   name     = "controller-manager"
#   region   = var.region
#   vpc_uuid = digitalocean_vpc.turbokube.id
#   tags     = ["turbokube"]

#   image     = "ubuntu-24-04-x64"
#   size      = var.node_class.controller-manager
#   ssh_keys  = [var.ssh_key]
#   user_data = file("setup.sh")
# }

# resource "digitalocean_droplet" "metrics" {
#   name     = "metrics"
#   region   = var.region
#   vpc_uuid = digitalocean_vpc.turbokube.id
#   tags     = ["turbokube"]

#   image     = "ubuntu-24-04-x64"
#   size      = var.node_class.metrics
#   ssh_keys  = [var.ssh_key]
#   user_data = file("setup.sh")
# }
