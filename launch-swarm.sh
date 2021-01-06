PATH="$PATH:/usr/local/bin"
CFN_KEYPAIR="dayilar-prj.key"
AWS_REGION="us-east-1"
APP_STACK_NAME="dayilar-prj"
CFN_TEMPLATE="~/prj_dayilar/dev-docker-swarm-infrastructure-cfn-template.yml"
export ANSIBLE_PRIVATE_KEY_FILE="~/.ssh/${CFN_KEYPAIR}"
export ANSIBLE_HOST_KEY_CHECKING="False"

aws ec2 create-key-pair --region ${AWS_REGION} --key-name ${CFN_KEYPAIR} --query KeyMaterial --output text > ${CFN_KEYPAIR}
sudo chmod 400 ${CFN_KEYPAIR}
mkdir -p ~/.ssh
mv ${CFN_KEYPAIR} ~/.ssh/${CFN_KEYPAIR}

echo "Creating QA Automation Infrastructure for Dev Environment with Cloudfomation"
aws cloudformation create-stack --region ${AWS_REGION} --stack-name ${APP_STACK_NAME} --capabilities CAPABILITY_IAM --template-body file://${CFN_TEMPLATE} --parameters ParameterKey=KeyPairName,ParameterValue=${CFN_KEYPAIR}
while :
do
    echo "Docker Grand Master is not UP and running yet. Will try to reach again after 10 seconds..."
    sleep 10
    ip=$(aws ec2 describe-instances --region ${AWS_REGION} --filters Name=tag-value,Values=grand-master Name=tag-value,Values=${APP_STACK_NAME} --query Reservations[*].Instances[*].[PublicIpAddress] --output text)
    echo $ip
    if [ ${#ip} -ge 7 ]
    then
        echo "Docker Grand Master Public Ip Address Found: $ip"
        export GRAND_MASTER_PUBLIC_IP="$ip"
        break
    fi
done
while :
do
    echo "Could not connect to Docker Grand Master with SSH, I will try again in 10 seconds"
    sleep 10
    if ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i ~/.ssh/${CFN_KEYPAIR} ec2-user@${GRAND_MASTER_PUBLIC_IP} hostname
    then
        echo "Docker Grand Master is reachable with SSH."
        break
    fi
done

echo "Setup Docker Swarm"
echo "Update dynamic environment"
# sed -i 's/APP_STACK_NAME/${APP_STACK_NAME}/' ~/prj_dayilar/ansible/inventory/dev_stack_dynamic_inventory_aws_ec2.yaml
echo "Swarm Setup for all nodes (instances)"
ansible-playbook -i ./ansible/inventory/dev_stack_dynamic_inventory_aws_ec2.yaml -b ./ansible/playbooks/pb_setup_for_all_docker_swarm_instances.yaml
echo "Swarm Setup for Grand Master node"
ansible-playbook -i ./ansible/inventory/dev_stack_dynamic_inventory_aws_ec2.yaml -b ./ansible/playbooks/pb_initialize_docker_swarm.yaml
echo "Swarm Setup for Other Managers nodes"
ansible-playbook -i ./ansible/inventory/dev_stack_dynamic_inventory_aws_ec2.yaml -b ./ansible/playbooks/pb_join_docker_swarm_managers.yaml
echo "Swarm Setup for Workers nodes"
ansible-playbook -i ./ansible/inventory/dev_stack_dynamic_inventory_aws_ec2.yaml -b ./ansible/playbooks/pb_join_docker_swarm_workers.yaml
            
