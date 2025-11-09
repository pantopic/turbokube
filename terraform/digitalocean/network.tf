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
    source_addresses = ["10.0.0.0/16"]
  }
  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = [var.ip_address]
  }
  outbound_rule {
    protocol              = "tcp"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
  outbound_rule {
    protocol              = "udp"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
  outbound_rule {
    protocol              = "icmp"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
  tags = ["turbokube"]
}
