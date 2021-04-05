#!/bin/sh
echo "Deleting Prometheus"
kubectl -n monitoring delete crd --all
kubectl delete namespace monitoring --cascade=true
