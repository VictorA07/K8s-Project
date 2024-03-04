# Project Name - Kubernetes Project with Multi-Jenkins CICD
## Introduction
This project involve creating a highly available, highly scalable microservice application using multi-master kubernetes and master-slave jenkins with a failover strategy.

This is a kubernetes project using Kubeadm and using Terraform as IAC (Infastructure as Code) to build the infastructure. This repository includes all terrraform code. The README file will gives step by step guide on how to deploy this project.

## Tech Stack
Infastructure as code (IAC) - Terraform
Cloud infrastructure - AWS Cloud Services
Version Control System - Github
Configuration Management - Ansible
Endpoint to cluster and Jenkins master-master lb- Haproxy
CICD Tool: Jenkins
Containerization: Docker, Kubernetes
Scripting: Bash/Shell Scripting
Monitoring Tools: grafana, prometheus
Operating Systems: Red Hat Linux, Ubuntu

## Prerequisites
Before you begin, make sure you have the following prerequisites:

An AWS account - You'll need an active AWS account to deploy resources using this Terraform code.
AWS CLI - Install the AWS Command Line Interface (CLI) on your local machine and configure it with your AWS credentials.
Terraform - Install Terraform on your local machine.
Git - Install Git on your local machine to clone this repository.
Create a AWS hosted zone on your AWS account and configure the dns with your domain name

## Application Breakdown
This project aims at satisfying client requirement in creating a highly avaialable, scalable micro service application.
The infastructure was built using Terraform blocks Blocks in Terraform Provider Block, Data Block, Resource Block, Module Block, Variable Block, Output Block, Locals Block.
We only provision all servers related to Jenkins on our local machine and the code is been pushed to the github repo.

## Continous Intergration and Continous Delivery (CICD) process
Jenkins was used in provisioning our application infastructure to enhance continuous integration with a webhook triger connected to our infastructure github repository for continuous dilevery of any enhancement.
### Jenkins architecture
We create two master jenkins with same configuration. One as main-master and the other as master-backup  to serve as failover for the Jenkins master. We mount an Elastic File System (EFS) on both sever pointing to same direcctory. We used Haproxy with port binding 80 to direct traffic to the backup serverif the main master is dowm.
For frequent update of jobs run on the main master, we use the code below whose functiion is to reloadand update the backup server.
`curl -s -XPOST 'http://localhost:8080/reload' -u admin:11b93da95c141b9395b7da9412b977a879 -H "$(curl -s 'http://localhost:8080/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,":",//crumb)' -u admin:admin)"`
We generate an API token from the backup sever, then use `$(curl -s 'http://localhost:8080/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,":",//crumb)' -u admin:admin)` to generate jenkins crumb id from the backup sever. The admin:admin signify the username and passowrd while `admin:11b93da95c141b9395b7da9412b977a879` signify the username and api token respectively.
Also as part of resource managemnt, we created a docker server for the purpose of creating jenkins-slaves to run jenkins jobs. each container is killed once a job is completed.

# Code Deployment
To deploythis code successfully, kindly follow the below instructions.

# Section 1: Jenkins Deployment
## Step 1: Git repository cloning
You can clone the repositoryusing the commmans below.
`git clone https://github.com/VictorA07/K8s-Project.git` and navigate to the project directory

## Step 2: Settings your credentials
Create and update this **variable.tfvars** below.
`
region =  "eu-west-2"
profile = " "
project-name =  " "
availability-zones = ["eu-west-2a", "eu-west-2b", "eu-west-2c"]
public-subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
private-subnets = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
instance-type = ""
iam-policy-arn = "arn:aws:iam::aws:policy/AdministratorAccess"
ami-ec2 = " "
ami-ubuntu = " "
efs-port = 2049
ssh-port = 22
jenkins-port = 8080
`
# Step 3: Initialize Terraform and Deploying resources
Run the command to initialize Terraform and deploy our jenkins resources.
### To initialize
`terraform init -var-file=variable.tfvars -lock=false`

### To plan the deployment
`terraform plan -var-file=variable.tfvars -lock=false`

### To deploy
`terraform apply -var-file=variable.tfvars -lock=false -auto-approve`

### To destroy
`terraform destroy -var-file=variable.tfvars -lock=false -auto-approve`

Some of the resources out needed in our application infrastructure main.tf will be populated. This is performedby a null resource block added to the jenkins infrastructure main.tf file.

`
resource "null_resource" "credentials" {
  depends_on = [aws_instance.jenkins-server-active]
  provisioner "local-exec" {
    command = <<-EOT
      ids_output=$(terraform output)
      printf '%s\n' "$ids_output" | awk '{print "  " $0}' | sed '3r /dev/stdin' ../main.tf > tmpfile && mv tmpfile ../main.tf
    EOT 
  }
}
`

# Section 2: Infastructure and Application deployment using Jenkins.

## Step 1: Jenkins setup
SSH in to your Jenkins server and set upthe following on both master and backup sever.
Required plugins - Terraform, AWS Credentials
Required credentials - AWS credentials (by adding our aws access key and id) and git credentials using username and password(git token)
Tools - Under Terraform - name- teraform, check Instal automatically, Type -linux amd64 
Under Admin - Configuration, Create an API token.
Use the token to create a webhook on your Github. paste the api token to the secret box below.
![alt text](<Screenshot 2024-03-04 at 14.04.45.png>)

## Pipeline setup
Create new item  or job
Select choice parameter
name= action
Choices = apply, destroy

choose github trigger
Add your github repository link
In your build, You can perform a terraform apply by chosing apply and terraform destroy by chosing destroy.
 You can use your domain name with specifiedprefix to access your application.


 Kinly reach out for more information and feedback.
 Thank you.