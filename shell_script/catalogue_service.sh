#!/bin/bash

# this script will create the catalogue micro service

# check the script is running with the sudo user or not
user_id=$(id -u)

if [ "$user_id" -ne 0 ]; then
    echo "This script must be run as root or with sudo privileges."
    exit 1
fi

scripts_path=$(pwd)
# Install NodeJS, By default NodeJS 16 is available, We would like to enable 20 version and install list.

dnf module disable nodejs -y

if [ $? -eq 0 ]; then
    echo "nodejs module disable suceessfully"
else
    echo "nodejs module disable failed"
    exit 1
fi

#enabling the nodejs 20 module

dnf module enable nodejs:20 -y

if [ $? -eq 0 ]; then
    echo "nodejs module enable suceessfully"
else
    echo "nodejs module enable failed"
    exit 1
fi

# installing the nodejs
dnf install nodejs -y

# check the nodejs is installed or not
if [ $? -eq 0 ]; then
    echo "nodejs installed suceessfully"
else
    echo "nodejs installation failed"
    exit 1
fi

# creating the catalogue user and group

useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop

#lets create the app directory and download the catalogue micro service code

mkdir -p /app

#Download the application code to created app directory.

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip 
cd /app 
unzip /tmp/catalogue.zip

cd /app 
npm install 


cp $scripts_path/catalogue.service /etc/systemd/system/catalogue.service

#do the systemctl daemon-reload
systemctl daemon-reload

#enable and start the catalogue service

systemctl enable catalogue 
systemctl start catalogue

#To load schema / master data we need to install mongodb client and then we can load it.

#To have mongo client installed we have to setup MongoDB repo and install mongodb-client. 
cp $scripts_path/mongo_repo.file /etc/yum.repos.d/mongo.repo

dnf install mongodb-mongosh -y



mongosh --host roboshop-mongodb.srinun.in </app/db/master-data.js

# check the data load is success or not

COUNT=$(mongosh catalogue --quiet --eval "db.products.countDocuments()")

if [ "$COUNT" -eq 0 ]; then
    echo "data not loaded properly please check one more time"
    exit 1
else 
    echo "the data loaded successfully and the count of the products is $COUNT"
fi
