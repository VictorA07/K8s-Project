#!/bin/bash
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
echo "${private-key}" >> /home/ubuntu/.ssh/id_rsa
sudo chmod 400 /home/ubuntu/.ssh/id_rsa
sudo chown ubuntu:ubuntu /home/ubuntu/.ssh/id_rsa
sudo hostnamectl set-hostname Bastion