#!/bin/bash

# this script is used to install the mongodb in the ec2 instance

#this script needs to be run by the sudo user

user_id=$(id -u)

if [ "$user_id" -ne 0 ]; then
    echo "This script must be run as root or with sudo privileges."
    exit 1
fi

scripts_path=$(pwd)

# copy the mongo repo to the /etc/yum.repos.d/mongo.repo in the ec2 instance

cp $scripts_path/mongo_repo.file /etc/yum.repos.d/mongo.repo

# cheeck the mongo repo is copied or not

if [ -f /etc/yum.repos.d/mongo.repo ]; then
    echo "Mongo repo copied successfully."
else
    echo "Failed to copy mongo repo."
    exit 1
fi

dnf install mongodb-org -y 

systemctl enable mongod 
systemctl start mongod 

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf

systemctl restart mongod



