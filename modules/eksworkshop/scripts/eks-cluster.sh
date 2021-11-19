rm -vf ${HOME}/.aws/credentials

aws sts get-caller-identity

eksctl version

export AZS=($(aws ec2 describe-availability-zones --query 'AvailabilityZones[].ZoneName' --output text --region $AWS_REGION))
export MASTER_ARN=$(aws kms describe-key --key-id alias/eksworkshop --query KeyMetadata.Arn --output text)

echo "creating eks cluster in region ${AWS_REGION} with key ${MASTER_ARN} in AZs ${AZS[0]} ${AZS[1]} ${AZS[2]}"

cat << EOF > eksworkshop.yaml
---
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig

metadata:
  name: @Eks_Name@
  region: ${AWS_REGION}
  version: "@Eks_Version@"

availabilityZones: ["${AZS[0]}", "${AZS[1]}", "${AZS[2]}"]

managedNodeGroups:
- name: @Eks_NG1_Name@
  minSize: @Eks_MinSize@
  maxSize: @Eks_MaxSize@
  desiredCapacity: @Eks_DersiredCapacity@
  instanceType: @Eks_InstanceType@
  volumeSize: @Eks_VolumeSize@
  ssh:
    enableSsm: true
  labels: {role: workshop}
  tags:
    nodegroup-role: workshop

# To enable all of the control plane logs, uncomment below:
# cloudWatch:
#  clusterLogging:
#    enableTypes: ["*"]

secretsEncryption:
  keyARN: ${MASTER_ARN}
EOF

eksctl create cluster -f eksworkshop.yaml

aws eks --region $AWS_REGION update-kubeconfig --name eksworkshop-eksctl

kubectl get nodes

STACK_NAME=$(eksctl get nodegroup --cluster eksworkshop-eksctl -o json | jq -r '.[].StackName')
ROLE_NAME=$(aws cloudformation describe-stack-resources --stack-name $STACK_NAME | jq -r '.StackResources[] | select(.ResourceType=="AWS::IAM::Role") | .PhysicalResourceId')
echo "export ROLE_NAME=${ROLE_NAME}" | tee -a /home/ec2-user/.bash_profile

echo "Setup eks cluster"

echo "------------------------------------------------------"

rolearn=$(aws iam get-role --role-name TeamRole --query Role.Arn --output text)

eksctl create iamidentitymapping --cluster eksworkshop-eksctl --arn ${rolearn} --group system:masters --username admin

echo "Added console credentials for console access"

echo "------------------------------------------------------"
echo "aws eks update-kubeconfig --name eksworkshop-eksctl --region ${AWS_REGION}" | tee -a /home/ec2-user/.bash_profile
echo "export LAB_CLUSTER_ID=eksworkshop-eksctl" | tee -a /home/ec2-user/.bash_profile

echo "Completed cluster setup"

echo "------------------------------------------------------"
