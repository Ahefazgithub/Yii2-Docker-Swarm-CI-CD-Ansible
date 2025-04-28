#### 📘 DevOps Project - Yii2 Application Deployment with Docker Swarm, Ansible & GitHub Actions CI/CD
📋 Project Overview

####   This project demonstrates how to:

    Deploy a Yii2 PHP application inside a Docker container using Docker Swarm on an AWS EC2 instance (Amazon Linux 2, t2.medium).
    Run NGINX on host (not inside container) as a reverse proxy to the containerized application.
    Automate server setup using Ansible.

 ####   Implement CI/CD pipeline using GitHub Actions to:

        Build Docker image
        Push image to DockerHub
        SSH into EC2 server
        Pull the new image
        Update Docker Swarm service

### 🖥️ Server Environment

    AWS EC2 Instance: Amazon Linux 2 AMI
    Instance Type: t2.medium
    Security Groups: Allow SSH (22), HTTP (80)

### ⚙️ Technology Stack

    PHP 8.1 + Yii2
    Docker & Docker Swarm
    NGINX
    Ansible
    GitHub Actions (CI/CD)
    DockerHub (image repository)

#####    🚀 Full Setup Instructions



## Step 1: Launch EC2 Instance



    Launch an EC2 Instance using Amazon Linux 2 AMI (t2.medium).

    Configure security groups to allow ports 22 (SSH) and 80 (HTTP).

    
## Step 2: Connect to EC2 and Prepare Server



SSH into EC2 instance:

chmod 400 your-key.pem
ssh -i your-key.pem ec2-user@your-ec2-public-ip

## Update server and install basic packages:

sudo yum update -y

# Install Ansible
sudo amazon-linux-extras enable ansible2
sudo yum install ansible -y

# Install Git
sudo yum install git -y

##  Step 3: Project Structure

yii2-docker-project/
├── app/                     # Yii2 PHP Application
├── Dockerfile
├── docker-compose.yml
├── ansible/
│   ├── install.yml
│   ├── deploy.yml
│   ├── nginx.conf
├── .github/
│   └── workflows/
│       └── deploy.yml
├── inventory.ini
└── README.md

##  Step 4: Dockerfile

Create Dockerfile:

FROM php:8.1-fpm

RUN apt-get update && apt-get install -y \
    git unzip libzip-dev zip \
    && docker-php-ext-install zip pdo pdo_mysql

WORKDIR /var/www/html

COPY ./app /var/www/html/

RUN chown -R www-data:www-data /var/www/html

CMD ["php-fpm"]

###  Step 5: Docker Compose

## Create docker-compose.yml:                     (below is my docker-compose.yml file )

version: "3.7"

services:
  yii2-app:
    image: ahefaz/your-app:latest               (ahefaz = my dockerhub username)
    ports:
      - "9000:9000"
    deploy:
      replicas: 1
      restart_policy:
        condition: on-failure
    networks:
      - appnet

networks:
  appnet:
    driver: overlay

##  Step 6: Ansible Playbooks

## Create ansible/install.yml:                (below is my install.yml file for Ansible)

---
- hosts: all
  become: yes
  tasks:
    - name: Install Docker
      yum:
        name: docker
        state: present

    - name: Install Docker Compose
      get_url:
        url: https://github.com/docker/compose/releases/download/v2.17.2/docker-compose-linux-x86_64
        dest: /usr/local/bin/docker-compose
        mode: '0755'

    - name: Install NGINX
      yum:
        name: nginx
        state: present

    - name: Start and enable Docker
      service:
        name: docker
        state: started
        enabled: yes

    - name: Start and enable NGINX
      service:
        name: nginx
        state: started
        enabled: yes

    - name: Add ec2-user to docker group
      user:
        name: ec2-user
        groups: docker
        append: yes

###    Create ansible/deploy.yml:               (below is deploy.yml file for Ansible)

---
- hosts: all
  become: yes
  tasks:
    - name: Clone project repository
      git:
        repo: "git@github.com:Ahefazgithub/your-repo.git"             (this is my github repo link, you to change this according to yours)
        dest: /home/ec2-user/yii2-docker-project                       (provided path of application)
        force: yes

    - name: Copy NGINX configuration
      copy:
        src: nginx.conf
        dest: /etc/nginx/conf.d/default.conf

    - name: Reload NGINX
      service:
        name: nginx
        state: restarted

    - name: Initialize Docker Swarm
      shell: |
        docker swarm init || true

    - name: Deploy Docker Stack
      shell: |
        cd /home/ec2-user/yii2-docker-project
        docker stack deploy -c docker-compose.yml app

###  Create ansible/nginx.conf:               (nginx.conf file for Ansible)

server {
    listen 80;
    server_name 34.219.196.47            (put the public IP address of your ec2 instance)

    location / {
        proxy_pass http://127.0.0.1:9000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}

###   Step 7: GitHub Actions CI/CD Pipeline

Create .github/workflows/deploy.yml:

name: Deploy to EC2

on:
  push:
    branches:
      - main

jobs:
  deploy:
    name: Build and Deploy
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Build Docker image
        run: docker build -t your-dockerhub-username/your-app:latest .

      - name: Login to DockerHub
        run: echo "${{ secrets.DOCKERHUB_PASSWORD }}" | docker login -u "${{ secrets.DOCKERHUB_USERNAME }}" --password-stdin

      - name: Push Docker image
        run: docker push your-dockerhub-username/your-app:latest

      - name: Deploy via SSH
        uses: appleboy/ssh-action@v0.1.7
        with:
          host: ${{ secrets.EC2_PUBLIC_IP }}
          username: ec2-user
          key: ${{ secrets.EC2_SSH_PRIVATE_KEY }}
          script: |
            cd /home/ec2-user/your-project
            git pull origin main
            docker pull your-dockerhub-username/your-app:latest
            docker stack deploy -c docker-compose.yml app
            sudo systemctl restart nginx

####    Step 8: Setup GitHub Secrets

In your GitHub Repository → Settings → Secrets → Actions, add:
Secret Name	Value
DOCKERHUB_USERNAME	Your DockerHub username
DOCKERHUB_PASSWORD	Your DockerHub password
EC2_PUBLIC_IP	Your EC2 Public IP
EC2_SSH_PRIVATE_KEY	Your .pem file private key content



### Step 9: Run Ansible Playbooks

Create inventory.ini:

[servers]
34.219.196.47 ansible_user=ec2-user ansible_ssh_private_key_file=pem.pem          (replace IP to yours, also,  pem.pem to your .pem file)

Run playbooks:

ansible-playbook -i inventory.ini ansible/install.yml
ansible-playbook -i inventory.ini ansible/deploy.yml

###  Step 10: Push Code to GitHub

git init
git remote add origin git@github.com:Ahefazgithub/Yii2-Docker-Swarm-CI-CD-Ansible.git           ( modify according to your github username and github repository name)
git add .
git commit -m "Initial commit"
git push -u origin main






✅ How It Works

    You push code to GitHub.

    GitHub Actions:

        Builds Docker image
        Pushes it to DockerHub
        SSHs into EC2
        Pulls latest image
        Updates Swarm Service
        Reloads NGINX

### Your Yii2 app is deployed automatically!



🎯 Final Notes

    Ensure your EC2 public IP is used correctly in nginx.conf.

    Always keep secrets and credentials protected.

    Use proper Docker image tagging and versioning in real projects.
