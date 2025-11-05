resource "digitalocean_droplet" "turbo" {
  name     = "turbo"
  region   = var.region
  vpc_uuid = var.vpc_uuid

  image     = "ubuntu-22-04-x64"
  size      = var.turbo_node_class
  ssh_keys  = [var.ssh_key]
  user_data = file("setup.sh")
}

output "turbo" {
  value = zipmap(["ext", "int"], [digitalocean_droplet.turbo.ipv4_address, digitalocean_droplet.turbo.ipv4_address_private])
}

resource "digitalocean_droplet_autoscale" "worker" {
  name = "worker"

  config {
    min_instances             = 3
    max_instances             = 24
    target_cpu_utilization    = 0.5
    target_memory_utilization = 0.5
    cooldown_minutes          = 5
  }
  droplet_template {
    size               = var.worker_node_class
    region             = var.region
    image              = "ubuntu-22-04-x64"
    ssh_keys           = [var.ssh_key]
    with_droplet_agent = true
    user_data          = format("%s%s", file("setup.sh"), file("worker.sh"))
    vpc_uuid           = var.vpc_uuid
  }
}
