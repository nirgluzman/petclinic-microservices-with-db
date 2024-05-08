#! /bin/bash

# update os
dnf update -y

# set server hostname as jenkins-server
hostnamectl set-hostname jenkins-server

# install git
dnf install git -y

# install java 11
dnf install fontconfig java-11-amazon-corretto -y

# install jenkins
wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
dnf upgrade
dnf install jenkins -y
systemctl enable jenkins
systemctl start jenkins

# give a shell for the jenkins user
usermod -s /bin/bash jenkins 

# install docker
dnf install docker -y
systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user
usermod -a -G docker jenkins

# configure docker as cloud agent for jenkins
cp /lib/systemd/system/docker.service /lib/systemd/system/docker.service.bak
sed -i 's/^ExecStart=.*/ExecStart=\/usr\/bin\/dockerd -H tcp:\/\/127.0.0.1:2376 -H unix:\/\/\/var\/run\/docker.sock/g' /lib/systemd/system/docker.service
systemctl daemon-reload
systemctl restart jenkins

# install docker compose
curl -SL https://github.com/docker/compose/releases/download/v2.26.0/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# install python 3
dnf install -y python3-pip python3-devel

# install ansible
pip3 install ansible

# install boto3
pip3 install boto3 botocore

# install terraform
wget https://releases.hashicorp.com/terraform/1.8.0/terraform_1.8.0_linux_amd64.zip
unzip terraform_1.8.0_linux_amd64.zip -d /usr/local/bin

# install Kompose
curl -L https://github.com/kubernetes/kompose/releases/download/v1.32.0/kompose-linux-amd64 -o kompose
chmod +x kompose
mv ./kompose /usr/local/bin/kompose

# install Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# install ``Helm S3 plugin`` for Amazon S3 as ec2-user
su - ec2-user -c "helm plugin install https://github.com/hypnoglow/helm-s3.git"

# install ``Helm S3 plugin`` as Jenkins user in order to be able to use S3 with Jenkins pipeline script
su - jenkins -c "export PATH=$PATH:/usr/local/bin"
su - jenkins -c "helm plugin install https://github.com/hypnoglow/helm-s3.git"

# install eksctl
curl --silent --location "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
mv /tmp/eksctl /usr/local/bin

# install kubectl
curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.29.0/2024-01-04/bin/linux/amd64/kubectl
chmod +x ./kubectl
mv kubectl /usr/local/bin

# install RKE (Rancher Kubernetes Engine)
curl -SsL "https://github.com/rancher/rke/releases/download/v1.5.6/rke_linux-amd64" -o "rke_linux-amd64"
mv rke_linux-amd64 /usr/local/bin/rke
chmod +x /usr/local/bin/rke

# install `Rancher CLI`
curl -SsL "https://github.com/rancher/cli/releases/download/v2.8.0/rancher-linux-amd64-v2.8.0.tar.gz" -o "rancher-cli.tar.gz"
tar -zxvf rancher-cli.tar.gz
mv ./rancher*/rancher /usr/local/bin/rancher
chmod +x /usr/local/bin/rancher

# Customize Bash Prompt, show git branch in commandline
# https://medium.com/@chiraggandhi70726/how-to-add-git-branch-name-to-bash-prompt-b112b93606e
echo "parse_git_branch() {
     git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
}" >> /home/ec2-user/.bashrc
echo 'export PS1="\u@\h \[\033[32m\]\w\[\033[33m\]\$(parse_git_branch)\[\033[00m\] $ "' >> /home/ec2-user/.bashrc

# Clone GitHub repository
git clone https://${GITHUB_TOKEN}@github.com/${GITHUB_USER}/${GITHUB_REPOSITORY}.git /home/ec2-user/${GITHUB_REPOSITORY}
chown -R ec2-user:ec2-user /home/ec2-user/${GITHUB_REPOSITORY}

# Configure Git username/email
su - ec2-user -c "git config --global user.name 'Nir Gluzman'"
su - ec2-user -c "git config --global user.email 'nir.gluzman@gmail.com'"

