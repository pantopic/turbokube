#!/bin/bash
set -e

# Prometheus + Grafana
curl -fsSL https://packages.buildkite.com/helm-linux/helm-debian/gpgkey | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/helm.gpg] https://packages.buildkite.com/helm-linux/helm-debian/any/ any main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo NEEDRESTART_MODE=a apt-get install -y helm
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

cat <<EOF > values.yml
# Disable components typically focused on worker nodes and general cluster metrics
kubeStateMetrics:
  enabled: false
nodeExporter:
  enabled: false
grafana:
  enabled: false
alertmanager:
  enabled: false
prometheus-operator:
  admissionWebhooks:
    enabled: false # Optional: Disable if you have issues with GKE private clusters

# Configure Prometheus specifically for control plane components
prometheus:
  # Optionally disable the installation of the default Prometheus server instance, 
  # if you plan to use an external Prometheus or another setup
  # enabled: false 

  # Ensure the ServiceMonitors for core components are enabled (they are by default, but confirm)
  # The stack is designed to scrape these out-of-the-box in standard setups
  kubeApiServer:
    enabled: true
  kubelet:
    enabled: true # Kubelet runs on all nodes (control plane and workers), good to keep
  kubeControllerManager:
    enabled: true
    # For self-managed clusters, you might need to adjust targetPort
    # service:
    #   targetPort: 10257 
  kubeScheduler:
    enabled: true
    # For self-managed clusters, you might need to adjust targetPort
    # service:
    #   targetPort: 10259
  kubeEtcd:
    enabled: true
    # For self-managed clusters, you might need to adjust targetPort
    # service:
    #   targetPort: 2381

# Disable default collection for user workloads
defaultRules:
  create: false # Do not create default rules for general workloads
EOF

helm install monitoring prometheus-community/kube-prometheus-stack \
  --create-namespace \
  --namespace monitoring \
  -f values.yml
  

# kubectl port-forward -n monitoring svc/monitoring-kube-prometheus-prometheus 9095:9090

# https://docs.victoriametrics.com/guides/k8s-monitoring-via-vm-single/
# helm repo add vm https://victoriametrics.github.io/helm-charts/
# helm repo add grafana https://grafana.github.io/helm-charts
# helm repo update

# curl https://docs.victoriametrics.com/guides/examples/guide-vmsingle-values.yaml -o vm.values.yml
# sed -i 's/- role: node/- role: node\n              selectors:\n              - role: node\n                label: "type != virtual-kubelet"/g' vm.values.yml
# helm install vmsingle vm/victoria-metrics-single -f vm.values.yml

# cat <<EOF | helm install grafana grafana/grafana -f -
#   datasources:
#     datasources.yaml:
#       apiVersion: 1
#       datasources:
#         - name: victoriametrics
#           type: prometheus
#           orgId: 1
#           url: http://vmsingle-victoria-metrics-single-server.default.svc.cluster.local:8428
#           access: proxy
#           isDefault: true
#           updateIntervalSeconds: 10
#           editable: true

#   dashboardProviders:
#    dashboardproviders.yaml:
#      apiVersion: 1
#      providers:
#      - name: 'default'
#        orgId: 1
#        folder: ''
#        type: file
#        disableDeletion: true
#        editable: true
#        options:
#          path: /var/lib/grafana/dashboards/default

#   dashboards:
#     default:
#       victoriametrics:
#         gnetId: 10229
#         revision: 22
#         datasource: victoriametrics
#       kubernetes:
#         gnetId: 14205
#         revision: 1
#         datasource: victoriametrics
# EOF

# kubectl get secret --namespace default my-grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
