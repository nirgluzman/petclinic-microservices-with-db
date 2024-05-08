## GitHub repo
https://github.com/nirgluzman/petclinic-microservices-with-db


## Jenkins Pipeline overview

developer -> GitHub -> mvn -> JAR -> Dockerfile -> image -> AWS ECR -> K8s deployment -> Helm chart -> Helm chart repo (S3) -> Helm install -> NEW APP


## Terraform

- Security group - self reference

```code
    ingress {
    protocol = "tcp"
    from_port = 2379
    to_port = 2380
    self = true   --> Whether the security group itself will be added as a source to this ingress rule.
  }
```

## Kubernetes

- Ports and Protocols used by Kubernetes components, https://kubernetes.io/docs/reference/networking/ports-and-protocols/

- initContainers - containers that run before the main contianer is started.
  https://kubernetes.io/docs/concepts/workloads/pods/init-containers/

- Sidecar container vs. initContainer
  * initContainers run first to prepare the environment for the main container.
  * Sidecar works alongside the main container

### Pull an Image from a Private Registry
- We must authenticate with the private repository (e.g. ECR) before we can pull/push images.
- In this project, we create a kubernetes secret from exciting credentials in `~/.docker/config.json` (file that holds an authorization token).
  https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/

### Ingress
- Ingress exposes HTTP and HTTPS routes from outside the cluster to services within the cluster.
  https://kubernetes.io/docs/concepts/services-networking/ingress/
  https://kubernetes.github.io/ingress-nginx/deploy/

### Kompose
  https://kompose.io/
  Kompose is a conversion tool from docker-compose to Kubernetes manifest files.


## Jenkins

- Jenkins being slow - make the following change in:
Dashboard > Manage Jenkins > System > Jenkins Location    >>> http://jenkins:8080/


```bash (pwd : /home/ec2-user)
cat /etc/passwd       # Jenkins user exists  ===>>> does not have a shell (bin/bash) , because it is not a root or regular user.
cd /var/lib/jenkins   # Jenkins home directory.
ls                    # 'workspace' directory was created here because jenkins user run a job in this directory.
whoami                # ec2-user
```

```bash (pwd : /home/ec2-user)
sudo usermod -s /bin/bash jenkins # Give a shell for the jenkins user.
cat /etc/passwd                   # The jenkins user exists and has a shell (bin/bash)
sudo su - jenkins                 # Switch to the jenkins user and navigate to its home directory
whoami                            # jenkins
pwd                               # /var/lib/jenkins ===>>> jenkins's $HOME directory
echo $HOME                        # /var/lib/jenkins ===>>> jenkins's $HOME directory
printenv HOME                     # /var/lib/jenkins ===>>> jenkins's $HOME directory
cd workspace                      # Jenkins performs operations under this folder
ls                                # petclinic-ci-job
cd petclinic-ci-job               # /var/lib/jenkins/workspace/petclinic-ci-job  ===>>> `pwd`
ls                                # files and directories from github
```

- Jenkins Environment Variables, jenkins:8080/env-vars

- Create an environment variable within a Jenkins Pipeline
  ```env.ABC``` --> creates a variable ABC to be available across Jenkins stages.

- Switch user to `jenkins`:
```bash
sudo usermod -s /bin/bash jenkins
sudo su - jenkins
```


## Docker utility containers

- Utility containers are containers that are used to provide utility functions, rather than installing those services on local machines.
  These can be useful for simplifying the management and operation of containerized environments.

- Utility container to execute `mvn clean test` - see MSP 12:

```bash
docker run --rm -v $HOME/.m2:/root/.m2 -v `pwd`:/app -w /app maven:3.8-openjdk-11 mvn clean test
```
* maven:3.8-openjdk-11 Docker image includes two key components:
  -- Maven 3.8 build automation tool for Java projects.
  -- OpenJDK 11, Open Source Java Development Kit version 11.
  This Docker image provides a ready-made environment that includes both the tools needed to build and manage Java projects.

* When executing this command within Jenkis, it uses the Jenkins user context:
  -- Jenkins home directory, $HOME =/var/lib/jenkins
  -- Jenkins workspace where it executes the build, `pwd` = /var/lib/jenkins/workspace/petclinic-ci-job

* We use the following Docker bind mounts:
  -- `pwd`:/app -w /app
     Maven project files are downloaded from GitHub and stored in Jenkins workspace directory.
  -- $HOME/.m2:/root/.m2
     Local repository for Maven is stored in user home directory:
     Jenkins -> $HOME/.m2
     Docker container -> /root/.m2


## Sellenium Test Nightly - explained

1) Launch 3 instances (terraform)
2) Deploy Kubernetes cluster (ansible)
3) Create Docker images
4) Manifest files (kubernetes)
5) Helm chart (stored on S3)
6) Deploy application
7) run sellenium test
8) Delete infratructure


## Ansible

- Configration, https://docs.ansible.com/ansible/latest/reference_appendices/general_precedence.html
  Ansible offers many ways to control how Ansible behaves: how it connects to managed nodes, how it works once it has connected.

- Configuration settings include both values from the `ansible.cfg` file and environment variables.

- Pass variable from one playbook to another playbook:
  https://www.unixarena.com/2019/05/passing-variable-from-one-playbook-to-another-playbook-ansible.html/


## Helm
- `helm install` vs. `helm upgrade`
  https://kodekloud.com/community/t/helm-intall-vs-helm-upgrade/209362


### Set up a Helm chart repository in Amazon S3
- https://docs.aws.amazon.com/prescriptive-guidance/latest/patterns/set-up-a-helm-v3-chart-repository-in-amazon-s3.html
  https://artifacthub.io/packages/helm-plugin/s3/s3

- Install the helm-s3 plugin for Amazon S3.

```bash
helm plugin install https://github.com/hypnoglow/helm-s3.git
```

- On some systems (including in our case) we need to install ``Helm S3 plugin`` as Jenkins user in order to be able to use S3 with pipeline script.

``` bash
sudo su -s /bin/bash jenkins
export PATH=$PATH:/usr/local/bin
helm version
helm plugin install https://github.com/hypnoglow/helm-s3.git
exit
```
- ``Initialize`` the Amazon S3 Helm repository.
   This command creates an ``index.yaml`` file in the target to track all the chart information that is stored at that location.

```bash
AWS_REGION=us-east-1 helm s3 init s3://petclinic-helm-charts-<put-your-name>/stable/myapp
```

- Add the Amazon S3 repository to Helm on the client machine.

```bash
AWS_REGION=us-east-1 helm repo add stable-petclinicapp s3://petclinic-helm-charts-<put-your-name>/stable/myapp/
```


## Linux - General

- `Netcat` ( nc ) command is a command-line utility for reading and writing data between two computer networks.
  https://www.ucartz.com/clients/knowledgebase/658/How-to-Install-and-Use-netcat-Command-on-Linux.html

- `envsubst` to replace all referenced environment variables in a text file with their corresponding values.

```bash
envsubst < values-template.yaml > values.yaml
```
```text
values-template.yaml -> IMAGE_TAG_ADMIN_SERVER: "${IMAGE_TAG_ADMIN_SERVER}"
export IMAGE_TAG_ADMIN_SERVER=046402772087.dkr.ecr.us-east-1.amazonaws.com/admin-server:latest
```

## Rancher & RKE
https://ranchermanager.docs.rancher.com/
https://rke.docs.rancher.com/config-options/cloud-providers/aws

- Rancher is a Kubernetes management tool to deploy and run clusters.
- RKE solves the problem of installation complexity for Rancher.
- The process:
  * RKE (Jenkis Server) -> creates a K8s cluster on remote machines to be later used by Rancher.
  * Helm (Jenkins Server) -> installs Rancher on this cluster.


## Slack integration with Jenkins
https://medium.com/@skmswetha22/a-guide-to-integrating-slack-with-jenkins-d78bf43f131e
https://kunzleigh.com/creating-a-slack-notifier-using-jenkins-pipeline/
https://plugins.jenkins.io/slack/
https://www.jenkins.io/doc/pipeline/steps/slack/

Configurations in Slack:
- Configure Webhook in Slack

Configurations in Jenkins:
- Required plugins:
  * Slack Notification Plugin (Integrates Jenkins with Slack, allows publishing build statuses, messages and files to Slack channels)
  * Script Security Plugin (?)
  * Display URL API (?)

- Add Slack Token as `Global Credential` (Secret text).

- Slack settings in `System`.

- Set the Slack notification in Jenkins file.

```groovy
        success {
            script {
               slackSend channel: '#petclinic', color: ' #439FE0', message: 'Nightly-pipeline has completed successfully !', teamDomain: 'devopstrainin-gm12494', tokenCredentialId: 'jenkins-slack'
            }
        }
```


## Let's Encrypt (Automated Certificate Management Environment)
https://letsencrypt.org/about/

- Let’s Encrypt is a free, automated, and open certificate authority (CA), run for the public’s benefit.

- Note that there are `Rate Limits` for certificates by Let's Enccrypt, https://letsencrypt.org/docs/rate-limits/
  For example, Renewals are treated specially: they don’t count against your Certificates per Registered Domain limit, but they are subject to a Duplicate Certificate limit of 5 per week. Exceeding the Duplicate Certificate limit is reported with the error message too many certificates already issued for exact set of domains.

- Therefore, if we add the certificate part to the pipeline, it might result in some problems.


## Resizing EC2 EBS
https://docs.aws.amazon.com/ebs/latest/userguide/recognize-expanded-volume-linux.html
https://medium.com/@nikhil.nagarajappa/configuring-jenkins-to-use-additional-disks-558affaac95c

- After you increase the size of an EBS volume, you must extend the partition and file system to the new, larger size.
