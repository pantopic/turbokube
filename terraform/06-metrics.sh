#!/bin/bash
set -e

# Prometheus + Grafana
# https://spacelift.io/blog/prometheus-kubernetes
curl -fsSL https://packages.buildkite.com/helm-linux/helm-debian/gpgkey | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/helm.gpg] https://packages.buildkite.com/helm-linux/helm-debian/any/ any main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install -y helm

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install kube-prometheus-stack \
  --create-namespace \
  --namespace kube-prometheus-stack \
  prometheus-community/kube-prometheus-stack

# --- kfqBdf8TxbLLUybwRJmzOPbpoM1vKz3Snk4NWxHS

kubectl --namespace kube-prometheus-stack get secrets kube-prometheus-stack-grafana -o jsonpath="{.data.admin-password}" | base64 -d ; echo
kubectl port-forward -n kube-prometheus-stack svc/kube-prometheus-stack-grafana 8080:80

helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
helm install grafana-k8s-monitoring \
  --create-namespace \
  --namespace grafana-k8s-monitoring \
  grafana/grafana-k8s-monitoring

# --- promql ---

# etcd requests by resource
# sum by (resource) (rate(etcd_requests_total[1m]))

# Percent lease renewals
# sum (rate(etcd_requests_total{resource="leases"}[1m])) / sum (rate(etcd_requests_total[1m])) * 100

# load apply
# for i in $(seq 1 500); do cat load.yml | sed "s/0000/00$i/" | k apply -f -; sleep 5; done
