resource "digitalocean_droplet" "etcd" {
  count = var.etcd_replicas

  name     = "etcd-${count.index}"
  region   = var.region
  vpc_uuid = digitalocean_vpc.turbokube.id
  tags     = ["turbokube"]

  image     = "ubuntu-22-04-x64"
  size      = var.node_class.etcd
  ssh_keys  = [var.ssh_key]
  user_data = file("setup.sh")
}

resource "digitalocean_droplet" "api-server" {
  count = 3

  name     = "api-server-${count.index}"
  region   = var.region
  vpc_uuid = digitalocean_vpc.turbokube.id
  tags     = ["turbokube", "api-server"]

  image     = "ubuntu-22-04-x64"
  size      = var.node_class.api-server
  ssh_keys  = [var.ssh_key]
  user_data = file("setup.sh")
}

resource "digitalocean_droplet" "metrics" {
  name     = "metrics"
  region   = var.region
  vpc_uuid = digitalocean_vpc.turbokube.id
  tags     = ["turbokube"]

  image     = "ubuntu-22-04-x64"
  size      = var.node_class.metrics
  ssh_keys  = [var.ssh_key]
  user_data = file("setup.sh")
}

# resource "digitalocean_droplet" "scheduler" {
#   name     = "scheduler"
#   region   = var.region
#   vpc_uuid = digitalocean_vpc.turbokube.id
#   tags     = ["turbokube"]

#   image     = "ubuntu-22-04-x64"
#   size      = var.node_class.scheduler
#   ssh_keys  = [var.ssh_key]
#   user_data = file("setup.sh")
# }

# resource "digitalocean_droplet" "controller-manager" {
#   name     = "controller-manager"
#   region   = var.region
#   vpc_uuid = digitalocean_vpc.turbokube.id
#   tags     = ["turbokube"]

#   image     = "ubuntu-22-04-x64"
#   size      = var.node_class.controller-manager
#   ssh_keys  = [var.ssh_key]
#   user_data = file("setup.sh")
# }
