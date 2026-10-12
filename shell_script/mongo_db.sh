#!/bin/bash

# this script is used to install the mongodb in the ec2 instance

# this script needs to be run by the sudo user

user_id=$(id -u)

if [ "$user_id" -ne 0 ]; then
    echo "This script must be run as root or with sudo privileges."
    exit 1
fi

scripts_path=$(pwd)
logs_folder="/var/log/roboshop"
logs_file="$logs_folder/mongo.log"
package_name="mongodb-org"

nc="\e[0m"
green="\e[32m"
red="\e[31m"
yellow="\e[33m"

# check the directory exists and if not create it

if [ ! -d "$logs_folder" ]; then
    echo -e " [info] ${yellow}directory not exists so creating the new one${nc}" 
    mkdir -p "$logs_folder"
    touch "$logs_file"
else
    echo -e " [info] ${green}directory exists${nc}" &>> "$logs_file"
fi

# copy the mongo repo to /etc/yum.repos.d/mongo.repo in the ec2 instance

cp "$scripts_path/mongo_repo.file" "/etc/yum.repos.d/mongo.repo"

# check the cp is suceded or not
if [ $? -ne 0 ]; then
    echo -e " [error] ${red}the copy of the repos file is failed ${nc}" &>> "$logs_file"
    echo -e " [error] ${red}the copy of the repos file is failed ${nc}" 

    exit 1
fi

# check the mongo repo is copied or not

if [ -f "/etc/yum.repos.d/mongo.repo" ]; then
    echo "Mongo repo copied successfully." &>> "$logs_file"
else
    echo "Failed to copy mongo repo." &>> "$logs_file"
    exit 1
fi

# check the package is there or not already

dnf list installed "$package_name" &>> "$logs_file"

if [ $? -eq 0 ]; then
    echo -e " [info] ${yellow}the ${package_name}  is already installed; skipping installation ${nc}" &>> "$logs_file"
else
    echo -e " [info] ${green}installing the ${package_name} ${nc}"
    dnf install "$package_name" -y &>> "$logs_file"
fi

if [ $? -eq 0 ]; then

    echo -e "[info] ${green} the ${package_name} installed succesfully ${nc}"
else

    echo -e "[error] ${red} the ${package_name} instalation is failed ${package_name} ${nc}"
    exit 1
fi

systemctl enable mongod &>> "$logs_file"
systemctl start mongod &>> "$logs_file"

sed -i 's/127.0.0.1/0.0.0.0/g' "/etc/mongod.conf"

systemctl restart mongod &>> "$logs_file"

systemctl is-active "mongod"

if [ $? -ne 0 ]; then

    echo -e "[error] ${red} the ${package_name} not installed properly please check the instalation steps again ${nc}"

    exit 1

else

    echo -e "[info] ${green} the ${package_name} is running successfully ${nc}"
fi

