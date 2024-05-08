#
# script to be executed as Jenkins user !
#

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
kubectl apply -f tls-cluster-issuer-prod.yaml
