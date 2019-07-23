#!/bin/bash

export DEBIAN_FRONTEND=noninteractive
export PATH=$PATH:/user/bin
export LANG=en_US.UTF-8
export LANGUAGE=en_US:en
export LC_ALL=en_US.UTF-8

# create ssh key to communicate b/w jenkins and repository
ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa

# add sudoable jenkins user
adduser jenkins
usermod -aG sudo jenkins
rsync --archive --chown=jenkins:jenkins ~/.ssh /home/jenkins

# add additional apt repositories
wget -q -O - https://pkg.jenkins.io/debian/jenkins.io.key | sudo apt-key add -
sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ | sudo tee -a /etc/apt/sources.list.d/jenkins.list'
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
add-apt-repository -y "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable"
add-apt-repository -y ppa:certbot/certbot

# pull the packages for installing jenkins
apt update && apt -y upgrade

# add 2gb swap memory
fallocate -l 2G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
echo 'vm.swappiness=10' | sudo tee -a /etc/sysctl.conf
echo 'vm.vfs_cache_pressure=50' | sudo tee -a /etc/sysctl.conf

# setting up a basic firewall
ufw allow 22
ufw allow 80
ufw allow 443
ufw allow 8080
ufw --force enable

# install general tools
apt install -y apt-transport-https ca-certificates
apt install -y software-properties-common python-software-properties build-essential
apt install -y vim git curl htop

# install java and jenkins
apt install -y openjdk-8-jdk
apt install -y jenkins

# install docker and docker-compose
apt install -y docker-ce
apt install -y docker-compose

# install nginx and certbot
apt install -y nginx
apt install -y certbot python-certbot-nginx

# install s3cmd (for easy dot-env file management)
apt install -y s3cmd

# remove packages no longer needed
apt remove -y --purge software-properties-common
apt -y autoremove

# add jenkins to docker group
sudo usermod -aG docker jenkins

# download nginx config
wget https://gist.githubusercontent.com/jinseokoh/cf21d257fda1d858e298c7322e8b2c5b/raw/60d98dde66133c3cadea53ee4205f740f8438238/nginx.conf -O /etc/nginx/sites-available/default

# let certbot to update nginx config
certbot --nginx --non-interactive --redirect --agree-tos -m "admin@hanlingo.com" -d jenkins.hanlingo.com

# restart services
systemctl start jenkins
systemctl reload nginx

# print out initial password
cat /var/lib/jenkins/secrets/initialAdminPassword
