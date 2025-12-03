#!/bin/bash
set -e

export NAME0="etcd-0"
export NAME1="etcd-1"
export NAME2="etcd-2"
export IP_ETCD_0=10.0.0.26
export IP_ETCD_1=10.0.0.25
export IP_ETCD_2=10.0.0.44

export APINAME0="apiserver-0"
export APINAME1="apiserver-1"
export APINAME2="apiserver-2"
export IP_APISERVER_0=10.0.0.23
export IP_APISERVER_1=10.0.0.28
export IP_APISERVER_2=10.0.0.21

export KRV_TLS_CRT=/etc/kubernetes/pki/etcd/server.crt
export KRV_TLS_KEY=/etc/kubernetes/pki/etcd/server.key
export HOST_IP=$(ip addr show dev eth1 | grep 10.0 | tail -n 1 | awk '{print $2}' | sed 's/\/.*//')

export KRV_PORT_API=2379
export KRV_PORT_ZONGZI=2380
export KRV_HOST_PEERS=${IP_ETCD_0}:${KRV_PORT_ZONGZI},${IP_ETCD_1}:${KRV_PORT_ZONGZI},${IP_ETCD_2}:${KRV_PORT_ZONGZI}
export KRV_HOST_NAME=${HOST_IP}
export KRV_HOST_TAGS="pantopic/krv=member"

# leader
mkdir -p /tmp/${IP_ETCD_0}/ /tmp/${IP_ETCD_1}/ /tmp/${IP_ETCD_2}/ /tmp/${IP_APISERVER_0}/ /tmp/${IP_APISERVER_1}/ /tmp/${IP_APISERVER_2}/

export HOSTS=(${IP_ETCD_0} ${IP_ETCD_1} ${IP_ETCD_2} ${IP_APISERVER_0} ${IP_APISERVER_1} ${IP_APISERVER_2})
export NAMES=(${NAME0} ${NAME1} ${NAME2} ${APINAME0} ${APINAME1} ${APINAME2})

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

kubeadm init phase certs etcd-server --config=/tmp/${IP_APISERVER_0}/kubeadmcfg.yaml
kubeadm init phase certs etcd-peer --config=/tmp/${IP_APISERVER_0}/kubeadmcfg.yaml
kubeadm init phase certs etcd-healthcheck-client --config=/tmp/${IP_APISERVER_0}/kubeadmcfg.yaml
kubeadm init phase certs apiserver-etcd-client --config=/tmp/${IP_APISERVER_0}/kubeadmcfg.yaml
cp -R /etc/kubernetes/pki /tmp/${IP_APISERVER_0}/
find /etc/kubernetes/pki -not -name ca.crt -not -name ca.key -type f -delete

kubeadm init phase certs etcd-server --config=/tmp/${IP_APISERVER_1}/kubeadmcfg.yaml
kubeadm init phase certs etcd-peer --config=/tmp/${IP_APISERVER_1}/kubeadmcfg.yaml
kubeadm init phase certs etcd-healthcheck-client --config=/tmp/${IP_APISERVER_1}/kubeadmcfg.yaml
kubeadm init phase certs apiserver-etcd-client --config=/tmp/${IP_APISERVER_1}/kubeadmcfg.yaml
cp -R /etc/kubernetes/pki /tmp/${IP_APISERVER_1}/
find /etc/kubernetes/pki -not -name ca.crt -not -name ca.key -type f -delete

kubeadm init phase certs etcd-server --config=/tmp/${IP_APISERVER_2}/kubeadmcfg.yaml
kubeadm init phase certs etcd-peer --config=/tmp/${IP_APISERVER_2}/kubeadmcfg.yaml
kubeadm init phase certs etcd-healthcheck-client --config=/tmp/${IP_APISERVER_2}/kubeadmcfg.yaml
kubeadm init phase certs apiserver-etcd-client --config=/tmp/${IP_APISERVER_2}/kubeadmcfg.yaml
cp -R /etc/kubernetes/pki /tmp/${IP_APISERVER_2}/
find /etc/kubernetes/pki -not -name ca.crt -not -name ca.key -type f -delete

kubeadm init phase certs etcd-server --config=/tmp/${IP_ETCD_2}/kubeadmcfg.yaml
kubeadm init phase certs etcd-peer --config=/tmp/${IP_ETCD_2}/kubeadmcfg.yaml
kubeadm init phase certs etcd-healthcheck-client --config=/tmp/${IP_ETCD_2}/kubeadmcfg.yaml
kubeadm init phase certs apiserver-etcd-client --config=/tmp/${IP_ETCD_2}/kubeadmcfg.yaml
cp -R /etc/kubernetes/pki /tmp/${IP_ETCD_2}/
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

scp -o "StrictHostKeyChecking=accept-new" -r /tmp/${IP_APISERVER_0}/* root@${IP_APISERVER_0}:/etc/kubernetes
scp -o "StrictHostKeyChecking=accept-new" -r /tmp/${IP_APISERVER_1}/* root@${IP_APISERVER_1}:/etc/kubernetes
scp -o "StrictHostKeyChecking=accept-new" -r /tmp/${IP_APISERVER_2}/* root@${IP_APISERVER_2}:/etc/kubernetes
scp -o "StrictHostKeyChecking=accept-new" -r /tmp/${IP_ETCD_1}/* root@${IP_ETCD_1}:/etc/kubernetes
scp -o "StrictHostKeyChecking=accept-new" -r /tmp/${IP_ETCD_2}/* root@${IP_ETCD_2}:/etc/kubernetes

/usr/bin/krv

export KRV_ENDPOINTS=https://${IP_ETCD_0}:2379,https://${IP_ETCD_1}:2379,https://${IP_ETCD_2}:2379
etcdctl --endpoints ${KRV_ENDPOINTS} endpoint health

wget https://raw.githubusercontent.com/ymdysk/iostat-csv/refs/heads/master/iostat-csv.sh
chmod +x iostat-csv.sh
./iostat-csv.sh > iostat.$(date +%Y%m%d%H%M).csv &

scp -o "StrictHostKeyChecking=accept-new" /usr/bin/krv root@${IP_APISERVER_0}:/usr/bin
scp -o "StrictHostKeyChecking=accept-new" /usr/bin/krv root@${IP_APISERVER_1}:/usr/bin
scp -o "StrictHostKeyChecking=accept-new" /usr/bin/krv root@${IP_APISERVER_2}:/usr/bin
scp -o "StrictHostKeyChecking=accept-new" /usr/bin/krv root@${IP_ETCD_1}:/usr/bin
scp -o "StrictHostKeyChecking=accept-new" /usr/bin/krv root@${IP_ETCD_2}:/usr/bin
