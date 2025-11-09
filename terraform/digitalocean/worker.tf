resource "digitalocean_droplet" "worker-control-plane" {
  name     = "worker-contro-planel"
  region   = var.region
  vpc_uuid = digitalocean_vpc.turbokube.id
  tags     = ["turbokube"]

  image     = "ubuntu-22-04-x64"
  size      = var.node_class.worker-control-plane
  ssh_keys  = [var.ssh_key]
  user_data = file("setup.sh")
}

resource "digitalocean_droplet_autoscale" "worker" {
  name = "worker"

  config {
    min_instances             = 3
    max_instances             = 24
    target_cpu_utilization    = 0.8
    target_memory_utilization = 0.8
    cooldown_minutes          = 5
  }
  droplet_template {
    size               = var.node_class.worker
    region             = var.region
    image              = "ubuntu-22-04-x64"
    ssh_keys           = [var.ssh_key]
    with_droplet_agent = true
    user_data          = format("%s%s", file("setup.sh"), file("worker.sh"))
    vpc_uuid           = digitalocean_vpc.turbokube.id
  }
}
