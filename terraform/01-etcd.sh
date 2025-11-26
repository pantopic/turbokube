#!/bin/bash
set -e

export NAME0="etcd-0"
export NAME1="etcd-1"
export NAME2="etcd-2"
export IP_ETCD_0=10.0.0.6
export IP_ETCD_1=10.0.0.4
export IP_ETCD_2=10.0.0.23

# All nodes
mkdir -p /etc/systemd/system/kubelet.service.d
cat << EOF > /etc/systemd/system/kubelet.service.d/kubelet.conf
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
authentication:
  anonymous:
    enabled: false
  webhook:
    enabled: false
authorization:
  mode: AlwaysAllow
cgroupDriver: systemd
address: 127.0.0.1
containerRuntimeEndpoint: unix:///var/run/containerd/containerd.sock
staticPodPath: /etc/kubernetes/manifests
EOF

cat << EOF > /etc/systemd/system/kubelet.service.d/20-etcd-service-manager.conf
[Service]
ExecStart=
ExecStart=/usr/bin/kubelet --config=/etc/systemd/system/kubelet.service.d/kubelet.conf
Restart=always
EOF

systemctl daemon-reload
systemctl restart kubelet

# etcd-0
mkdir -p /tmp/${IP_ETCD_0}/ /tmp/${IP_ETCD_1}/ /tmp/${IP_ETCD_2}/

export HOSTS=(${IP_ETCD_0} ${IP_ETCD_1} ${IP_ETCD_2})
export NAMES=(${NAME0} ${NAME1} ${NAME2})

for i in "${!HOSTS[@]}"; do
HOST=${HOSTS[$i]}
NAME=${NAMES[$i]}
cat << EOF > /tmp/${HOST}/kubeadmcfg.yaml
---
apiVersion: "kubeadm.k8s.io/v1beta4"
kind: InitConfiguration
nodeRegistration:
    name: ${NAME}
localAPIEndpoint:
    advertiseAddress: ${HOST}
---
apiVersion: "kubeadm.k8s.io/v1beta4"
kind: ClusterConfiguration
etcd:
    local:
        serverCertSANs:
        - "${HOST}"
        peerCertSANs:
        - "${HOST}"
        extraArgs:
        - name: initial-cluster
          value: ${NAMES[0]}=https://${HOSTS[0]}:2380,${NAMES[1]}=https://${HOSTS[1]}:2380,${NAMES[2]}=https://${HOSTS[2]}:2380
        - name: initial-cluster-state
          value: new
        - name: name
          value: ${NAME}
        - name: listen-peer-urls
          value: https://${HOST}:2380
        - name: listen-client-urls
          value: https://${HOST}:2379
        - name: advertise-client-urls
          value: https://${HOST}:2379
        - name: initial-advertise-peer-urls
          value: https://${HOST}:2380
EOF
done

kubeadm init phase certs etcd-ca

kubeadm init phase certs etcd-server --config=/tmp/${IP_ETCD_2}/kubeadmcfg.yaml
kubeadm init phase certs etcd-peer --config=/tmp/${IP_ETCD_2}/kubeadmcfg.yaml
kubeadm init phase certs etcd-healthcheck-client --config=/tmp/${IP_ETCD_2}/kubeadmcfg.yaml
kubeadm init phase certs apiserver-etcd-client --config=/tmp/${IP_ETCD_2}/kubeadmcfg.yaml
cp -R /etc/kubernetes/pki /tmp/${IP_ETCD_2}/
# cleanup non-reusable certificates
find /etc/kubernetes/pki -not -name ca.crt -not -name ca.key -type f -delete

kubeadm init phase certs etcd-server --config=/tmp/${IP_ETCD_1}/kubeadmcfg.yaml
kubeadm init phase certs etcd-peer --config=/tmp/${IP_ETCD_1}/kubeadmcfg.yaml
kubeadm init phase certs etcd-healthcheck-client --config=/tmp/${IP_ETCD_1}/kubeadmcfg.yaml
kubeadm init phase certs apiserver-etcd-client --config=/tmp/${IP_ETCD_1}/kubeadmcfg.yaml
cp -R /etc/kubernetes/pki /tmp/${IP_ETCD_1}/
find /etc/kubernetes/pki -not -name ca.crt -not -name ca.key -type f -delete

kubeadm init phase certs etcd-server --config=/tmp/${IP_ETCD_0}/kubeadmcfg.yaml
kubeadm init phase certs etcd-peer --config=/tmp/${IP_ETCD_0}/kubeadmcfg.yaml
kubeadm init phase certs etcd-healthcheck-client --config=/tmp/${IP_ETCD_0}/kubeadmcfg.yaml
kubeadm init phase certs apiserver-etcd-client --config=/tmp/${IP_ETCD_0}/kubeadmcfg.yaml
# No need to move the certs because they are for IP_ETCD_0

# clean up certs that should not be copied off this host
find /tmp/${IP_ETCD_2} -name ca.key -type f -delete
find /tmp/${IP_ETCD_1} -name ca.key -type f -delete

scp -o "StrictHostKeyChecking=accept-new" -r /tmp/${IP_ETCD_1}/* root@${IP_ETCD_1}:/etc/kubernetes
scp -o "StrictHostKeyChecking=accept-new" -r /tmp/${IP_ETCD_2}/* root@${IP_ETCD_2}:/etc/kubernetes

kubeadm init phase etcd local --config=/tmp/${IP_ETCD_0}/kubeadmcfg.yaml

# etcd-1 /\ etcd-2
mv pki /etc/kubernetes/
kubeadm init phase etcd local --config=/etc/kubernetes/kubeadmcfg.yaml

ETCDCTL_API=3 etcdctl \
--cert /etc/kubernetes/pki/etcd/peer.crt \
--key /etc/kubernetes/pki/etcd/peer.key \
--cacert /etc/kubernetes/pki/etcd/ca.crt \
--endpoints https://${IP_ETCD_0}:2379,https://${IP_ETCD_1}:2379,https://${IP_ETCD_2}:2379 endpoint health

ETCDCTL_API=3 etcdctl \
--cert /etc/kubernetes/pki/etcd/peer.crt \
--key /etc/kubernetes/pki/etcd/peer.key \
--cacert /etc/kubernetes/pki/etcd/ca.crt \
--endpoints https://${IP_ETCD_0}:2379,https://${IP_ETCD_1}:2379,https://${IP_ETCD_2}:2379 endpoint status
