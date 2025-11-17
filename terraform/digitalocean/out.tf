
output "ext" {
  value = merge(
    zipmap(digitalocean_droplet.etcd.*.name, digitalocean_droplet.etcd.*.ipv4_address),
    zipmap(digitalocean_droplet.api-server.*.name, digitalocean_droplet.api-server.*.ipv4_address),
    {
      "admin" : digitalocean_droplet.admin.ipv4_address
      "metrics" : digitalocean_droplet.metrics.ipv4_address
      # "turbo" : digitalocean_droplet.worker-control-plane.ipv4_address
    }
  )
}
output "int" {
  value = merge(
    zipmap(digitalocean_droplet.etcd.*.name, digitalocean_droplet.etcd.*.ipv4_address_private),
    zipmap(digitalocean_droplet.api-server.*.name, digitalocean_droplet.api-server.*.ipv4_address_private),
    {
      "lb" : digitalocean_loadbalancer.kube.ip
      "admin" : digitalocean_droplet.admin.ipv4_address_private
      "metrics" : digitalocean_droplet.metrics.ipv4_address_private
      # "turbo" : digitalocean_droplet.worker-control-plane.ipv4_address_private
    }
  )
}
