#!/bin/bash

# this script will create the catalogue micro service

# check the script is running with the sudo user or not
user_id=$(id -u)

if [ "$user_id" -ne 0 ]; then
    echo "This script must be run as root or with sudo privileges."
    exit 1
fi

scripts_path=$(pwd)
logs_folder="/var/log/roboshop"
logs_file="$logs_folder/catalogue.log"

green="\e[32m"
red="\e[31m"
yellow="\e[33m"
nc="\e[0m"

if [ ! -d "$logs_folder" ]; then
    echo -e " [info] ${red} directory not exists so creating the new one and creating the logsfile too ${nc}"
    mkdir -p "${logs_folder}"
    touch "${logs_file}"
else
    echo -e " [info] ${green} directory exists and there should be possible no logs file creating here too ${nc}"
    touch "${logs_file}"
fi
    

# Install NodeJS, By default NodeJS 16 is available, We would like to enable 20 version and install list.

dnf module disable nodejs -y  &>> "${logs_file}"

if [ $? -eq 0 ]; then
    echo "nodejs module disable suceessfully"
else
    echo "nodejs module disable failed"
    exit 1
fi

#enabling the nodejs 20 module

dnf module enable nodejs:20 -y &>> "${logs_file}"

if [ $? -eq 0 ]; then
    echo "nodejs module enable suceessfully"  &>> "${logs_file}"
else
    echo "nodejs module enable failed"     &>> "${logs_file}"
    exit 1
fi



# installing the nodejs
dnf install nodejs -y

# check the nodejs is installed or not
if [ $? -eq 0 ]; then
    echo "nodejs installed suceessfully"   &>> "${logs_file}"
else
    echo "nodejs installation failed"     &>> "${logs_file}"
    exit 1
fi

# creating the catalogue user and group

useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop  &>> "${logs_file}"

#lets create the app directory and download the catalogue micro service code

mkdir -p /app                         &>> "${logs_file}"

#Download the application code to created app directory.
 # check the application code already exists means we can delete and re-download the new one.

 if [ -f "/app/catalogue.zip" ]; then
    echo "the catalogue.zip already exists so deleting the old one and downloading the new one"
    rm -f /app/catalogue.zip
 fi

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip   &>> "${logs_file}"
cd /app    &>> "${logs_file}"
unzip /tmp/catalogue.zip   &>> "${logs_file}"

# just check the instalation is success or not by listing the files in the /app directory

 if [ -f "/app/catalogue.zip" ]; then
    echo -e " [info] ${green} the catalgue.zip now means the new file donwloaded sucessfully ${nc}"
else
    echo -e " [error] ${red} the catalgue.zip not downloaded properly please check the network connectivity and try again ${nc}"
    exit 1
 fi


cd /app 
npm install 


cp $scripts_path/catalogue.service /etc/systemd/system/catalogue.service

if [ $? -eq 0 ]; then
    echo " service file copied suceessfully"   &>> "${logs_file}"
else
    echo " service file copy is failed"     &>> "${logs_file}"
    exit 1
fi

#do the systemctl daemon-reload
systemctl daemon-reload

#enable and start the catalogue service

systemctl enable catalogue 
systemctl start catalogue

systemctl is-active catalogue &>> "${logs_file}"

if [ $? -eq 0 ]; then
    echo -e " [info] ${green} the catalogue service is up and running ${nc}"
else
    echo -e " [error] ${red} the catalogue service is not running please check the logs ${nc}"
    exit 1
fi

#To load schema / master data we need to install mongodb client and then we can load it.

#To have mongo client installed we have to setup MongoDB repo and install mongodb-client. 
cp $scripts_path/mongo_repo.file /etc/yum.repos.d/mongo.repo

if [ $? -eq 0 ]; then
    echo " mongo repo file copied suceessfully"   &>> "${logs_file}"
else
    echo " mongo repo file copy is failed"     &>> "${logs_file}"
    exit 1
fi

dnf install mongodb-mongosh -y

if [ $? -eq 0 ]; then
    echo " mongodb client installed suceessfully"   &>> "${logs_file}"
else
    echo " mongodb client installation failed"     &>> "${logs_file}"
    exit 1
fi

mongosh --host roboshop-mongodb.srinun.in </app/db/master-data.js

# check the data load is success or not

COUNT=$(mongosh catalogue --quiet --eval "db.products.countDocuments()")

if [ "$COUNT" -eq 0 ]; then
    echo "data not loaded properly please check one more time"
    exit 1
else 
    echo "the data loaded successfully and the count of the products is $COUNT"
fi
