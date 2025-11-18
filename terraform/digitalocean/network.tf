resource "digitalocean_vpc" "turbokube" {
  region   = var.region
  name     = "turbokube"
  ip_range = "10.0.0.0/16"
}

# The only publicly exposed port in the VPC is IP whitelisted port 22
# All nodes can talk to each other and call out to the internet freely
resource "digitalocean_firewall" "turbokube" {
  name = "turbokube"
  inbound_rule {
    protocol         = "tcp"
    port_range       = "all"
    source_addresses = ["10.0.0.0/8"]
  }
  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = [var.ip_address]
  }
  inbound_rule {
    protocol         = "tcp"
    port_range       = "10250"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }
  outbound_rule {
    protocol              = "tcp"
    port_range            = "all"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
  outbound_rule {
    protocol              = "udp"
    port_range            = "all"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
  outbound_rule {
    protocol              = "icmp"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
  depends_on = [digitalocean_tag.turbokube]
  tags       = ["turbokube"]
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
  droplet_tag = "api-server"
}
