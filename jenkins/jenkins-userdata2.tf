locals {
  jenkins-userdata2 = <<-EOF
#!/bin/bash
sudo yum update -y
sudo yum install git -y
sudo yum install wget -y
sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
sudo yum upgrade -y
sudo yum install java-17-openjdk -y
sudo yum install jenkins -y
sudo systemctl daemon-reload
sudo systemctl enable jenkins
sudo systemctl start jenkins
sudo usermod -aG jenkins ec2-user
sudo hostnamectl set-hostname Jenkins

#Instaling EFS for active jenkins
#sudo reboot

# Installing EFS
sudo yum -y install git rpm-build make
git clone https://github.com/aws/efs-utils
cd efs-utils
make rpm
sudo yum -y install build/amazon-efs-utils*rpm
sudo su -c "echo '${aws_efs_file_system.jenkins-efs.id}:/ /var/lib/jenkins/jobs efs _netdev,tls 0 0' >> /etc/fstab"
sudo systemctl stop jenkins

## mounting EFS
sudo mount /var/lib/jenkins/jobs
sudo chown -R jenkins:jenkins /var/lib/jenkins/jobs
sudo systemctl start jenkins

# add the section to jenkins passive node for concurrrent job updates
sudo su -c "echo 'crumb_id=$(curl -s 'http://localhost:8080/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,":",//crumb)' -u admin:admin) \
curl -s -XPOST 'http://localhost:8080/reload' -u admin:admin -H "$crumb_id"' >> /opt/jenkins_reload.sh" 
sudo chmod +x /opt/jenkins_reload.sh
sudo su -c "echo '*/1 * * * * root /bin/bash /opt/jenkins_reload.sh' >> /etc/cron.d/jenkins_reload"
EOF  
}