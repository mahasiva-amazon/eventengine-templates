echo "Start Installation and Configuration of Cloud9"

export LOG_FILE="/tmp/cloud9-configurescript-log.txt"
sudo yum -y update

sudo yum -y install jq gettext bash-completion

export AWS_DEFAULT_REGION=$(curl -s 169.254.169.254/latest/dynamic/instance-identity/document | jq -r '.region')
export ACCOUNT_ID=$(aws sts get-caller-identity --output text --query Account)
export AWS_REGION=$AWS_DEFAULT_REGION
echo "export ACCOUNT_ID=${ACCOUNT_ID}" | tee -a /home/ec2-user/.bash_profile
echo "export AWS_REGION=${AWS_REGION}" | tee -a /home/ec2-user/.bash_profile
echo "export export AWS_DEFAULT_REGION=${AWS_REGION}" | tee -a /home/ec2-user/.bash_profile
aws configure set default.region ${AWS_REGION}
aws configure get default.region

function log {
   echo "$1 -> $2" >> $LOG_FILE
}