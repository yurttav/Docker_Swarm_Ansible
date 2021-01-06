PATH="$PATH:/usr/local/bin"
CFN_KEYPAIR="dayilar-prj.key"
AWS_REGION="us-east-1"
APP_STACK_NAME="dayilar-prj"
CFN_TEMPLATE="~/prj_dayilar/dev-docker-swarm-infrastructure-cfn-template.yml"
export ANSIBLE_PRIVATE_KEY_FILE="~/.ssh/${CFN_KEYPAIR}"
export ANSIBLE_HOST_KEY_CHECKING="False"
GRAND_MASTER_PUBLIC_IP="35.175.129.45"

echo "Setup Docker Swarm"
echo "Update dynamic environment"
echo "Swarm Setup for all nodes (instances)"
ansible-playbook -i ./ansible/inventory/dev_stack_dynamic_inventory_aws_ec2.yaml -b ./ansible/playbooks/pb_setup_for_all_docker_swarm_instances.yaml
echo "Swarm Setup for Grand Master node"
ansible-playbook -i ./ansible/inventory/dev_stack_dynamic_inventory_aws_ec2.yaml -b ./ansible/playbooks/pb_initialize_docker_swarm.yaml
echo "Swarm Setup for Other Managers nodes"
ansible-playbook -i ./ansible/inventory/dev_stack_dynamic_inventory_aws_ec2.yaml -b ./ansible/playbooks/pb_join_docker_swarm_managers.yaml
echo "Swarm Setup for Workers nodes"
ansible-playbook -i ./ansible/inventory/dev_stack_dynamic_inventory_aws_ec2.yaml -b ./ansible/playbooks/pb_join_docker_swarm_workers.yaml
            
