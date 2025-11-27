# hosts regex replace
#   .*"([^"]+)".*"([^"]+)"
#   $2 $1

# Useful commands
#
#   watch kubectl get all -A
#
#   cat /var/log/cloud-init-output.log
#   tail /var/log/cloud-init-output.log -f
#
#   kubeadm init phase upload-certs --upload-certs
#   kubeadm init phase upload-config kubeadm
#
#   k get secret -n kube-prometheus-stack kube-prometheus-stack-grafana -o jsonpath="{.data.admin-password}" | base64 --decode
#   kubectl port-forward -n kube-prometheus-stack svc/kube-prometheus-stack-grafana 8080:80
#   kubectl port-forward -n kube-prometheus-stack svc/kube-prometheus-stack-grafana 8081:80
#
#   doctl registry kubernetes-manifest
#
## Source - https://stackoverflow.com/a/59667608
# kubectl get namespace "turbokube-0003" -o json \
#  | tr -d "\n" | sed "s/\"finalizers\": \[[^]]\+\]/\"finalizers\": []/" \
#  | kubectl replace --raw /api/v1/namespaces/turbokube-0003/finalize -f -

kubeadm join 10.0.0.43:6443 --token xd75hh.xv5ax9hnmfzv573u \
        --discovery-token-ca-cert-hash sha256:e1ae3456c79c71244ce649169e14862fa121f07687e48ff7f70254c91ae910ac \
        --control-plane --certificate-key f38345bc383e360b72d63ebb2dca9440d6a8a19b34c6e80951c5a3b207a79a69