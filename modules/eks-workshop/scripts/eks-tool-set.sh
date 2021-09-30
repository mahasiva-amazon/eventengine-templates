echo "Install EKS toolset"
echo "------------------------------------------------------"

sudo curl --silent --location -o /usr/local/bin/kubectl https://amazon-eks.s3.us-west-2.amazonaws.com/1.19.6/2021-01-05/bin/linux/amd64/kubectl
sudo chmod +x /usr/local/bin/kubectl

echo "Installed Kubectl and util tools"

echo "------------------------------------------------------"

echo "Update AWS CLI and utilities"

sudo pip install --upgrade awscli && hash -r

sudo yum -y install jq gettext bash-completion moreutils

echo 'yq() {
  docker run --rm -i -v "${PWD}":/workdir mikefarah/yq "$@"
}' | tee -a ~/.bashrc && source ~/.bashrc

echo 'export LBC_VERSION="v2.0.0"' >>  /home/ec2-user/.bash_profile

echo "------------------------------------------------------"

aws kms create-alias --alias-name alias/eksworkshop --target-key-id $(aws kms create-key --query KeyMetadata.Arn --output text)

export MASTER_ARN=$(aws kms describe-key --key-id alias/eksworkshop --query KeyMetadata.Arn --output text)

echo "export MASTER_ARN=${MASTER_ARN}" | tee -a  /home/ec2-user/.bash_profile

echo "Setup master key complete"

echo "------------------------------------------------------"

curl --silent --location "https://github.com/weaveworks/eksctl/releases/download/0.62.0/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv -v /tmp/eksctl /usr/local/bin

echo "Downloaded and installed eksctl"

echo "------------------------------------------------------"

curl -sSL https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash

helm version --short

helm repo add stable https://charts.helm.sh/stable
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

echo "helm repo add stable https://charts.helm.sh/stable" | tee -a /home/ec2-user/.bash_profile
echo "helm repo add stable https://charts.helm.sh/stable" | tee -a /home/ec2-user/.bash_profile

helm search repo stable

echo "Completed setup of Helm"

echo "------------------------------------------------------"

curl -Lo ec2-instance-selector https://github.com/aws/amazon-ec2-instance-selector/releases/download/v1.3.0/ec2-instance-selector-`uname | tr '[:upper:]' '[:lower:]'`-amd64 && chmod +x ec2-instance-selector
sudo mv ec2-instance-selector /usr/local/bin/
ec2-instance-selector --version

echo "Installed EC2 instance selector"

echo "------------------------------------------------------"