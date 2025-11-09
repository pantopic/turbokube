resource "digitalocean_droplet" "etcd" {
  count = var.etcd_replicas

  name     = "etcd-${count.index}"
  region   = var.region
  vpc_uuid = digitalocean_vpc.turbokube.id


  image     = "ubuntu-22-04-x64"
  size      = var.node_class.etcd
  ssh_keys  = [var.ssh_key]
  user_data = file("setup.sh")
}

resource "digitalocean_droplet_autoscale" "apiserver" {
  name = "apiserver"

  config {
    min_instances             = 3
    max_instances             = 24
    target_cpu_utilization    = 0.8
    target_memory_utilization = 0.8
    cooldown_minutes          = 5
  }
  droplet_template {
    size               = var.node_class.apiserver
    region             = var.region
    image              = "ubuntu-22-04-x64"
    ssh_keys           = [var.ssh_key]
    with_droplet_agent = true
    user_data          = format("%s%s", file("setup.sh"), file("worker.sh"))
    vpc_uuid           = digitalocean_vpc.turbokube.id
  }
}

resource "digitalocean_loadbalancer" "kube" {
  name     = "kube"
  region   = var.region
  vpc_uuid = digitalocean_vpc.turbokube.id

  network = "INTERNAL"
  type    = "REGIONAL_NETWORK"
  forwarding_rule {
    entry_port      = 6443
    entry_protocol  = "tcp"
    target_port     = 6443
    target_protocol = "tcp"
  }
  healthcheck {
    port     = 6443
    protocol = "https"
    path     = "/healthz"
  }
  droplet_ids = digitalocean_droplet.kube.*.id
}

resource "digitalocean_droplet" "metrics" {
  name     = "metrics"
  region   = var.region
  vpc_uuid = digitalocean_vpc.turbokube.id
  tags     = ["turbokube"]

  image     = "ubuntu-22-04-x64"
  size      = var.node_class.turbo
  ssh_keys  = [var.ssh_key]
  user_data = file("setup.sh")
}

resource "digitalocean_droplet" "scheduler" {
  name     = "scheduler"
  region   = var.region
  vpc_uuid = digitalocean_vpc.turbokube.id
  tags     = ["turbokube"]

  image     = "ubuntu-22-04-x64"
  size      = var.node_class.scheduler
  ssh_keys  = [var.ssh_key]
  user_data = file("setup.sh")
}

resource "digitalocean_droplet" "controller-manager" {
  name     = "controller-manager"
  region   = var.region
  vpc_uuid = digitalocean_vpc.turbokube.id
  tags     = ["turbokube"]

  image     = "ubuntu-22-04-x64"
  size      = var.node_class.controller_manager
  ssh_keys  = [var.ssh_key]
  user_data = file("setup.sh")
}
