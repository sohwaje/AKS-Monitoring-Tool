#!/bin/sh
###########
NS="monitoring"

get_ns()
{
  if kubectl get ns | grep -iq $NS;
  then
      echo "Namespace $NS already exists";
  else
      echo "Creating namespace $NS"
      kubectl create namespace $NS;
  fi
}

get_ns
echo "Installing/Upgrading Prometheus"

#* rbac: 자격증명 AKS와 연동할 때는 반드시 자격증명을 사용(true)
cd ./prometheus &&
  helm install prometheus . \
  --namespace $NS --set rbac.create=true && \
  SVC_IP=$(kubectl get svc --namespace $NS -l \
  "app=prometheus,component=server" -o \
  jsonpath="{.items[0].spec.clusterIP}")

cd ../grafana && \
  helm install grafana . \
  --set persistence.enabled=true \
  --set persistence.accessModes={ReadWriteOnce} \
  --set persistence.size=5Gi --namespace $NS

export POD_NAME=$(kubectl get pods --namespace monitoring -l "app.kubernetes.io/name=grafana,app.kubernetes.io/instance=grafana " -o jsonpath="{.items[0].metadata.name}")

# The Grafana dashboard username is admin and for password execute this CMD
kubectl get secret --namespace $NS grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo

# port-forward for prometheus: kubectl port-forward 는 프롬프트를 리턴하지 않는다.
kubectl -n $NS port-forward --address localhost,10.1.10.5 $POD_NAME 9090

kubectl -n monitoring get all

# port-forward for prometheus
# kubectl -n $NS port-forward --address localhost,10.1.10.5 prometheus-server-85b447d9b7-4g76n


######## delete ##########
# kubectl -n monitoring delete crd --all
# kubectl delete namespace monitoring --cascade=true
