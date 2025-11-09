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

# kube-burner
wget https://raw.githubusercontent.com/kube-burner/kube-burner/refs/heads/main/hack/install.sh
sed -i 's/set -euo pipefail/set -eu pipefail/' install.sh
chmod +x install.sh
./install.sh
cp /root/.local/bin/kube-burner /usr/local/bin

# turbokube-cli


k get secret -n kube-prometheus-stack kube-prometheus-stack-grafana -o jsonpath="{.data.admin-password}" | base64 --decode
kubectl port-forward -n kube-prometheus-stack svc/kube-prometheus-stack-grafana 8080:80
kubectl port-forward -n kube-prometheus-stack svc/kube-prometheus-stack-grafana 8081:80
