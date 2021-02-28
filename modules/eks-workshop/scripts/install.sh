echo "Start Installation and Configuration of Cloud9"
  
sudo yum -y update

sudo yum -y install jq gettext bash-completion

export AWS_DEFAULT_REGION=$(curl -s 169.254.169.254/latest/dynamic/instance-identity/document | jq -r '.region')

# Specify the desired volume size in GiB as a command-line argument. If not specified, default to 20 GiB.
SIZE=${1:-20}

# Get the ID of the environment host Amazon EC2 instance.
INSTANCEID=$(curl http://169.254.169.254/latest/meta-data//instance-id)

# Get the ID of the Amazon EBS volume associated with the instance.
VOLUMEID=$(aws ec2 describe-instances \
  --instance-id $INSTANCEID \
  --query "Reservations[0].Instances[0].BlockDeviceMappings[0].Ebs.VolumeId" \
  --output text)

# Resize the EBS volume.
aws ec2 modify-volume --volume-id $VOLUMEID --size $SIZE

# Wait for the resize to finish.
while [ \
  "$(aws ec2 describe-volumes-modifications \
    --volume-id $VOLUMEID \
    --filters Name=modification-state,Values="optimizing","completed" \
    --query "length(VolumesModifications)"\
    --output text)" != "1" ]; do
sleep 1
echo "Waiting for EBS volume size increase!"
done

if [ $(readlink -f /dev/xvda) = "/dev/xvda" ]
then
  # Rewrite the partition table so that the partition takes up all the space that it can.
  sudo growpart /dev/xvda 1

  # Expand the size of the file system.
  sudo resize2fs /dev/xvda1

else
  # Rewrite the partition table so that the partition takes up all the space that it can.
  sudo growpart /dev/nvme0n1 1

  # Expand the size of the file system.
  sudo resize2fs /dev/nvme0n1p1
fi

echo "Disk size increased to 20GB"

echo "------------------------------------------------------"
cd /home/ec2-user/environment

for command in kubectl jq envsubst
  do
    which $command &>/dev/null && echo "$command in path" || echo "$command NOT FOUND"
  done

export ACCOUNT_ID=$(aws sts get-caller-identity --output text --query Account)
export AWS_REGION=$(curl -s 169.254.169.254/latest/dynamic/instance-identity/document | jq -r '.region')
echo "export ACCOUNT_ID=${ACCOUNT_ID}" | tee -a /home/ec2-user/.bash_profile
echo "export AWS_REGION=${AWS_REGION}" | tee -a /home/ec2-user/.bash_profile
echo "export export AWS_DEFAULT_REGION=${AWS_REGION}" | tee -a /home/ec2-user/.bash_profile
aws configure set default.region ${AWS_REGION}
aws configure get default.region

echo "Setup environment variables"
echo "------------------------------------------------------"

export KUBECTL_VERSION=v1.16.12
sudo curl --silent --location -o /usr/local/bin/kubectl https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl
sudo chmod +x /usr/local/bin/kubectl

echo "Installed Kubectl and util tools"

echo "------------------------------------------------------"

export EKSCTL_VERSION=0.23.0
curl --silent --location "https://github.com/weaveworks/eksctl/releases/download/${EKSCTL_VERSION}/eksctl_Linux_amd64.tar.gz" | tar xz -C /tmp
sudo mv -v /tmp/eksctl /usr/local/bin


echo "Downloaded and installed eksctl"

echo "------------------------------------------------------"

rm -vf ${HOME}/.aws/credentials

aws sts get-caller-identity

eksctl version

eksctl create cluster --version=1.16 --name=eksworkshop-eksctl --node-private-networking  --managed --nodes=2 --alb-ingress-access --region=${AWS_REGION} --node-labels="lifecycle=OnDemand,intent=control-apps" --asg-access

aws eks update-kubeconfig --name eksworkshop-eksctl

kubectl get nodes

NODE_GROUP_NAME=$(eksctl get nodegroup --cluster eksworkshop-eksctl -o json | jq -r '.[].Name')
ROLE_NAME=$(aws eks describe-nodegroup --cluster-name eksworkshop-eksctl --nodegroup-name $NODE_GROUP_NAME | jq -r '.nodegroup["nodeRole"]' | cut -f2 -d/)
echo "export ROLE_NAME=${ROLE_NAME}" >> /home/ec2-user/.bash_profile

echo "Setup eks cluster"

echo "------------------------------------------------------"

curl -sSL https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash

helm version --short

helm repo add stable https://charts.helm.sh/stable
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

helm search repo stable

echo "Completed setup of Helm"

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

echo "------------------------------------------------------"


curl -Lo ec2-instance-selector https://github.com/aws/amazon-ec2-instance-selector/releases/download/v1.3.0/ec2-instance-selector-`uname | tr '[:upper:]' '[:lower:]'`-amd64 && chmod +x ec2-instance-selector
sudo mv ec2-instance-selector /usr/local/bin/
ec2-instance-selector --version

echo "Installed EC2 instance selector"

echo "------------------------------------------------------"

echo "aws eks update-kubeconfig --name eksworkshop-eksctl" | tee -a /home/ec2-user/.bash_profile

echo "export LAB_CLUSTER_ID=eksworkshop-eksctl" | tee -a /home/ec2-user/.bash_profile

echo "Update kubeconfig"

echo "------------------------------------------------------"