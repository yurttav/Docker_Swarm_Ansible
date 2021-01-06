PATH="$PATH:/usr/local/bin"
CFN_KEYPAIR="dayilar-prj.key"
AWS_REGION="us-east-1"
APP_STACK_NAME="dayilar-prj"
CFN_TEMPLATE="~/prj_dayilar/dev-docker-swarm-infrastructure-cfn-template.yml"
export ANSIBLE_PRIVATE_KEY_FILE="~/.ssh/${CFN_KEYPAIR}"
export ANSIBLE_HOST_KEY_CHECKING="False"
GRAND_MASTER_PUBLIC_IP="35.175.219.64"

while :
do
    echo "Could not connect to Docker Grand Master with SSH, I will try again in 10 seconds"
    sleep 10
    if ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i ~/prj_dayilar/${CFN_KEYPAIR} ec2-user@${GRAND_MASTER_PUBLIC_IP} hostname
    then
        echo "Docker Grand Master is reachable with SSH."
        break
    fi
done

echo "Setup Docker Swarm"
echo "Update dynamic environment"
sed -i 's/APP_STACK_NAME/${APP_STACK_NAME}/' ~/prj_dayilar/ansible/inventory/dev_stack_dynamic_inventory_aws_ec2.yaml
echo "Swarm Setup for all nodes (instances)"
ansible-playbook -i ./ansible/inventory/dev_stack_dynamic_inventory_aws_ec2.yaml -b ./ansible/playbooks/pb_setup_for_all_docker_swarm_instances.yaml
echo "Swarm Setup for Grand Master node"
ansible-playbook -i ./ansible/inventory/dev_stack_dynamic_inventory_aws_ec2.yaml -b ./ansible/playbooks/pb_initialize_docker_swarm.yaml
echo "Swarm Setup for Other Managers nodes"
ansible-playbook -i ./ansible/inventory/dev_stack_dynamic_inventory_aws_ec2.yaml -b ./ansible/playbooks/pb_join_docker_swarm_managers.yaml
echo "Swarm Setup for Workers nodes"
ansible-playbook -i ./ansible/inventory/dev_stack_dynamic_inventory_aws_ec2.yaml -b ./ansible/playbooks/pb_join_docker_swarm_workers.yaml
            
