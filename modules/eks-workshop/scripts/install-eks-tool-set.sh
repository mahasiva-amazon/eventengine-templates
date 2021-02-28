echo "Install EKS toolset"
echo "------------------------------------------------------"

export KUBECTL_VERSION=v1.16.12
sudo curl --location -o /usr/local/bin/kubectl https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl
sudo chmod +x /usr/local/bin/kubectl

echo "Installed Kubectl and util tools"

echo "------------------------------------------------------"

export EKSCTL_VERSION=0.23.0
curl --location "https://github.com/weaveworks/eksctl/releases/download/${EKSCTL_VERSION}/eksctl_Linux_amd64.tar.gz" | tar xz -C /tmp
sudo mv -v /tmp/eksctl /usr/local/bin


echo "Downloaded and installed eksctl"

echo "------------------------------------------------------"

curl -sSL https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash

helm version --short

helm repo add stable https://charts.helm.sh/stable
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

helm search repo stable

echo "Completed setup of Helm"

echo "------------------------------------------------------"

curl -Lo ec2-instance-selector https://github.com/aws/amazon-ec2-instance-selector/releases/download/v1.3.0/ec2-instance-selector-`uname | tr '[:upper:]' '[:lower:]'`-amd64 && chmod +x ec2-instance-selector
sudo mv ec2-instance-selector /usr/local/bin/
ec2-instance-selector --version

echo "Installed EC2 instance selector"

echo "------------------------------------------------------"