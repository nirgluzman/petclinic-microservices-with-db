#
# script to be executed as Jenkins user, so kubeconfig is created in Jenkis $HOME directory --> /var/lib/jenkins
#

# create an EKS cluster with `eksctl` utility
eksctl create cluster -f cluster.yaml

# install `ingress controller`
export PATH=$PATH:$HOME/bin
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.10.0/deploy/static/provider/cloud/deploy.yaml



####
# config cert-manager and SSL/TLS certificate required for HTTPS --> see config-cert-manager-and-certificate.sh
####
