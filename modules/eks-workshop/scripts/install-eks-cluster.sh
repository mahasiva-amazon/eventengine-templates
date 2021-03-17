rm -vf ${HOME}/.aws/credentials

aws sts get-caller-identity

eksctl version

eksctl delete cluster  --name=@name@

aws eks update-kubeconfig --name @name@