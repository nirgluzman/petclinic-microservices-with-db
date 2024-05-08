#! /bin/bash
# update os
dnf update -y

# set server hostname
hostnamectl set-hostname petclinic-dev-server

# install Docker
dnf install docker -y
systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user
newgrp docker

# install Docker Compose
curl -SL https://github.com/docker/compose/releases/download/v2.26.0/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# install Git
dnf install git -y

# install Java
dnf install java-11-amazon-corretto -y

# customize Bash Prompt, show git branch in commandline
# https://medium.com/@chiraggandhi70726/how-to-add-git-branch-name-to-bash-prompt-b112b93606e
echo "parse_git_branch() {
     git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
}" >> /home/ec2-user/.bashrc
echo 'export PS1="\u@\h \[\033[32m\]\w\[\033[33m\]\$(parse_git_branch)\[\033[00m\] $ "' >> /home/ec2-user/.bashrc

# clone GitHub repository
git clone https://${GITHUB_TOKEN}@github.com/${GITHUB_USER}/${GITHUB_REPOSITORY}.git /home/ec2-user/${GITHUB_REPOSITORY}
chown -R ec2-user:ec2-user /home/ec2-user/${GITHUB_REPOSITORY}

# configure Git username/email
su - ec2-user -c "git config --global user.name 'Nir Gluzman'"
su - ec2-user -c "git config --global user.email 'nir.gluzman@gmail.com'"

# checkout dev branch
cd /home/ec2-user/${GITHUB_REPOSITORY}
git checkout dev

# define environment variable
cat >> /home/ec2-user/.bashrc << EOF
export GITHUB_USER="${GITHUB_USER}"
export GITHUB_REPOSITORY="${GITHUB_REPOSITORY}"
EOF
