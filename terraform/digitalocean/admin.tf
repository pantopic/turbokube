resource "digitalocean_droplet" "admin" {
  name     = "metrics"
  region   = var.region
  vpc_uuid = digitalocean_vpc.turbokube.id
  tags     = ["turbokube"]

  image     = "ubuntu-22-04-x64"
  size      = var.node_class.admin
  ssh_keys  = [var.ssh_key]
  user_data = file("setup.sh")
}
