echo "------------------------------------------------------"


kubectl create namespace metrics
helm install metrics-server \
    stable/metrics-server \
    --version 2.10.0 \
    --namespace metrics

kubectl get apiservice v1beta1.metrics.k8s.io -o yaml

helm install kube-ops-view \
stable/kube-ops-view \
--set service.type=LoadBalancer \
--set nodeSelector.intent=control-apps \
--set rbac.create=True
--version 1.2.1

helm list

kubectl get svc kube-ops-view | tail -n 1 | awk '{ print "Kube-ops-view URL = http://"$4 }'


echo "Installed Metrics server and kube ops view"