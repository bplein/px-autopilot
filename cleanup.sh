#!/usr/bin/env bash

export namespace=postgres-demo

echo "========================================================"
echo "This will destroy everything in namespace $namespace!!!!"
echo " "
read -p "Hit CTRL-C to escape, press ENTER to continue... " -n1

kubectl -n portworx patch configmap autopilot-config --type=merge --patch '{"data":{"config.yaml":"providers:\n   - name: default\n     type: prometheus\n     params: url=http://px-prometheus:9090\nmin_poll_interval: 10"}}'
kubectl -n portworx delete -f grow-pvc-rule.yaml
kubectl delete ns $namespace
kubectl delete sc px-repl3-sc-demotemp