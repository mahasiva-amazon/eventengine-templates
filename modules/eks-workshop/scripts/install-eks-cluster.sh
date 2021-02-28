rm -vf ${HOME}/.aws/credentials

aws sts get-caller-identity

eksctl version

eksctl create cluster --version=@@version@@ --name=@@name@@ --node-private-networking  --managed --nodes=@@nodes@@ --alb-ingress-access --region=${AWS_REGION} --node-labels=@@node_labels@@ --asg-access

aws eks update-kubeconfig --name @@name@@

kubectl get nodes

NODE_GROUP_NAME=$(eksctl get nodegroup --cluster @@name@@ -o json | jq -r '.[].Name')
ROLE_NAME=$(aws eks describe-nodegroup --cluster-name @@name@@ --nodegroup-name $NODE_GROUP_NAME | jq -r '.nodegroup["nodeRole"]' | cut -f2 -d/)
echo "export ROLE_NAME=${ROLE_NAME}" >> /home/ec2-user/.bash_profile

echo "Setup eks cluster"

echo "------------------------------------------------------"

echo "aws eks update-kubeconfig --name eksworkshop-eksctl" | tee -a /home/ec2-user/.bash_profile

echo "export LAB_CLUSTER_ID=@@name@@" | tee -a /home/ec2-user/.bash_profile

echo "Update kubeconfig"

echo "------------------------------------------------------"