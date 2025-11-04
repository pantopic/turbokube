resource "digitalocean_droplet" "kube" {
  count = 3

  name     = "kube-${count.index}"
  region   = var.region
  vpc_uuid = var.vpc_uuid

  image     = "ubuntu-22-04-x64"
  size      = var.control_node_class
  ssh_keys  = [var.ssh_key]
  user_data = file("setup.sh")
}

resource "digitalocean_loadbalancer" "kube" {
  name     = "kube"
  region   = var.region
  vpc_uuid = var.vpc_uuid

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

output "ext" {
  value = zipmap(digitalocean_droplet.kube.*.name, digitalocean_droplet.kube.*.ipv4_address)
}

output "int" {
  value = zipmap(digitalocean_droplet.kube.*.name, digitalocean_droplet.kube.*.ipv4_address_private)
}

output "lb" {
  value = zipmap([digitalocean_loadbalancer.kube.name], [digitalocean_loadbalancer.kube.ip])
}
