
output "ext" {
  value = merge(
    {
      "etcd" : digitalocean_droplet.etcd.ipv4_address
      "admin" : digitalocean_droplet.admin.ipv4_address
      "metrics" : digitalocean_droplet.metrics.ipv4_address
      "scheduler" : digitalocean_droplet.scheduler.ipv4_address
      "controller_manager" : digitalocean_droplet.controller_manager.ipv4_address
      "worker-control-plane" : digitalocean_droplet.worker-control-plane.ipv4_address
    }
  )
}
output "int" {
  value = merge(
    {
      "lb" : digitalocean_loadbalancer.kube.ip
      "etcd" : digitalocean_droplet.etcd.ipv4_address_private
      "admin" : digitalocean_droplet.admin.ipv4_address_private
      "metrics" : digitalocean_droplet.metrics.ipv4_address_private
      "scheduler" : digitalocean_droplet.scheduler.ipv4_address_private
      "controller_manager" : digitalocean_droplet.controller_manager.ipv4_address_private
      "worker-control-plane" : digitalocean_droplet.worker-control-plane.ipv4_address_private
    }
  )
}

