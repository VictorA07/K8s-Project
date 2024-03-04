#!/bin/bash

# Update instance and install ansible
sudo apt-get update -y
sudo apt-get install software-properties-common -y
sudo add-apt-repository --yes --update ppa:ansible/ansible
sudo apt-get install ansible python3-pip -y

# copy keypair from local machine to ansible server
echo "${keypair}" > /home/ubuntu/.ssh/id_rsa
sudo chmod 400 /home/ubuntu/.ssh/id_rsa
sudo chown ubuntu:ubuntu /home/ubuntu/.ssh/id_rsa

# Give right permissions to the ansible directory
sudo touch /etc/ansible/hosts
sudo chown ubuntu:ubuntu /etc/ansible/hosts
sudo chown -R ubuntu:ubuntu /etc/ansible && chmod +x /etc/ansible
sudo chown -R ubuntu:ubuntu /etc/ansible
sudo chmod 777 /etc/ansible/hosts

# create haproxy ips variable file for our playbook
sudo echo HAPROXY1: "${haproxy1}" > /home/ubuntu/ha-ip.yml
sudo echo HAPROXY2: "${haproxy2}" >> /home/ubuntu/ha-ip.yml

# Update the host inventory file with all our IPs
echo "[all:vars]" > /etc/ansible/hosts
echo "ansible_ssh_common_args='-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no'" >> /etc/ansible/hosts
sudo echo "[haproxy1]" > /etc/ansible/hosts
sudo echo "${haproxy1} ansible_ssh_private_key_file=/home/ubuntu/.ssh/id_rsa >> /etc/ansible/hosts
sudo echo "[haproxy2]" >> /etc/ansible/hosts
sudo echo "${haproxy2} ansible_ssh_private_key_file=/home/ubuntu/.ssh/id_rsa >> /etc/ansible/hosts
sudo echo "[main-master]" >> /etc/ansible/hosts
sudo echo "${main-master} ansible_ssh_private_key_file=/home/ubuntu/.ssh/id_rsa >> /etc/ansible/hosts
sudo echo "[member-master]" >> /etc/ansible/hosts
sudo echo "${member-master01} ansible_ssh_private_key_file=/home/ubuntu/.ssh/id_rsa >> /etc/ansible/hosts
sudo echo "${member-master02} ansible_ssh_private_key_file=/home/ubuntu/.ssh/id_rsa >> /etc/ansible/hosts
sudo echo "[worker]" >> /etc/ansible/hosts
sudo echo "${worker01} ansible_ssh_private_key_file=/home/ubuntu/.ssh/id_rsa >> /etc/ansible/hosts
sudo echo "${worker02} ansible_ssh_private_key_file=/home/ubuntu/.ssh/id_rsa >> /etc/ansible/hosts
sudo echo "${worker03} ansible_ssh_private_key_file=/home/ubuntu/.ssh/id_rsa >> /etc/ansible/hosts

# execute our playbooks
sudo su -c "ansible-playbook /home/ubuntu/playbooks/install.yml" ubuntu
sudo su -c "ansible-playbook /home/ubuntu/playbooks/ha-keepalived.yml" ubuntu
sudo su -c "ansible-playbook /home/ubuntu/playbooks/main-master.yml" ubuntu
sudo su -c "ansible-playbook /home/ubuntu/playbooks/member-master.yml" ubuntu
sudo su -c "ansible-playbook /home/ubuntu/playbooks/worker.yml" ubuntu
sudo su -c "ansible-playbook /home/ubuntu/playbooks/ha-kubectl.yml" ubuntu
sudo su -c "ansible-playbook /home/ubuntu/playbooks/stage.yml" ubuntu
sudo su -c "ansible-playbook /home/ubuntu/playbooks/prod.yml" ubuntu
sudo su -c "ansible-playbook /home/ubuntu/playbooks/monitoring.yml" ubuntu

sudo hostnamectl set-hostname ansible
