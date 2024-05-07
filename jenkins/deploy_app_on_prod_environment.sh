echo 'Deploying App on Kubernetes'
envsubst < k8s/petclinic_chart/values-template.yaml > k8s/petclinic_chart/values.yaml
sed -i s/HELM_VERSION/${BUILD_NUMBER}/ k8s/petclinic_chart/Chart.yaml
AWS_REGION=$AWS_REGION helm repo add stable-petclinic s3://petclinic-helm-charts-25042024/stable/myapp/ || echo "repository name already exists"
AWS_REGION=$AWS_REGION helm repo update
helm package k8s/petclinic_chart
AWS_REGION=$AWS_REGION helm s3 push --force petclinic_chart-${BUILD_NUMBER}.tgz stable-petclinic
kubectl create ns petclinic-prod-ns || echo "namespace petclinic-prod-ns already exists"
kubectl delete secret regcred -n petclinic-prod-ns || echo "there is no regcred secret in petclinic-prod-ns namespace"
kubectl create secret generic regcred -n petclinic-prod-ns \
    --from-file=.dockerconfigjson=/var/lib/jenkins/.docker/config.json \
    --type=kubernetes.io/dockerconfigjson
AWS_REGION=$AWS_REGION helm repo update
AWS_REGION=$AWS_REGION helm upgrade --install \
    petclinic-app-release stable-petclinic/petclinic_chart --version ${BUILD_NUMBER} \
    --namespace petclinic-prod-ns

#######
# config cert-manager and SSL/TLS certificate required for HTTPS
#######

# create the namespace for cert-manager
kubectl create namespace cert-manager || echo "namespace cert-manager already exists"

# add Jetstack Helm repository
AWS_REGION=$AWS_REGION helm repo add jetstack https://charts.jetstack.io

# update the local Helm chart repository
AWS_REGION=$AWS_REGION helm repo update

# install the `Custom Resource Definition` resources for cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.14.4/cert-manager.crds.yaml

# install the cert-manager Helm chart
AWS_REGION=$AWS_REGION helm upgrade --install \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --version v1.14.4

# install ClusterIssuer
kubectl apply -f infrastructure/msp-28-eks-production-cert-manager/tls-cluster-issuer-prod.yml
