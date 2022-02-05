#!/usr/bin/env bash

clear 
if ! type "pv" > /dev/null; then
  echo ""
  echo "This demo requires pv (pipe viewer), please install via your package manager"
  exit
fi
source ./util.sh

export namespace=postgres-demo
desc ""
desc "First lets create a namespace to run our application and switch context to it"
run "kubectl create ns $namespace"


run "kubectl config set-context --current --namespace=$namespace"

desc "Now lets configure and enable Autopilot"
run "cat autopilot-configmap.yaml"
run "kubectl -n kube-system create -f autopilot-configmap.yaml"

desc "Let's look at the Autopilot rule we are going to use for our application"
run "cat grow-pvc-rule.yaml"

desc ""
desc "Our rule requires that we lable the namespace, let's do that"
run "kubectl label namespaces $namespace type=db --overwrite=true"
desc ""
desc "Let's create a storage class for our application."
desc "Storage classes allow Kubernetes to tell the underlying volume driver how to set up the volumes for capabilites such as IO profiles, HA levels, etc."
run "cat px-repl3-sc-demotemp.yaml"
run "kubectl create -f px-repl3-sc-demotemp.yaml"

desc ""
desc "Now create a volume for the application."

run "cat px-postgres-pvc.yaml"
run "kubectl apply -f px-postgres-pvc.yaml"

echo -n postgres123 > password.txt
kubectl create secret generic postgres-pass --from-file=password.txt 2>&1 >/dev/null


desc ""
desc "And now we'll take a look at the application in YAML format and deploy it (hit CTRL-C to stop watching the application when it's up)"
run "cat postgres-app.yaml"
run "kubectl create -f postgres-app.yaml"
watch kubectl get pods -l app=postgres -o wide

#clear the screen
clear


desc ""
desc "We are going to exec into the Postgres pod and run a command to populate data, and then get the count"
run "kubectl get pods -l app=postgres"
POD=$(kubectl get pods -l app=postgres | grep Running | grep 1/1 | awk '{print $1}')
export POD
desc "Our pod is called $POD"
desc ""
desc "Create the database"
run "kubectl exec -i $POD -- psql << EOF
create database pxdemo;
\l
\q
EOF"

desc ""
desc "Populate the database with test data"
run "kubectl exec -i $POD -- pgbench -i -s 50 pxdemo;"

##########
# get count
##########
desc ""
desc "Let's get the count of records from the database table"

POD=$(kubectl get pods -l app=postgres | grep Running | grep 1/1 | awk '{print $1}')
export POD
run "kubectl exec -i $POD -- psql pxdemo<< EOF
select count(*) from pgbench_accounts;
\q
EOF"
##########




