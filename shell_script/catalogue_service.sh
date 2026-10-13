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
    

# writing the validate function to validate the status of the command executed instated of writing the if condition for each command executed
# it should take two argumets first is the $? and second is the name/comment we provided 

validate() { 
    if [ $1 -ne 0 ]; then
        echo " [error] ${red} $2 failed ${nc}" &>> "${logs_file}"
        exit 1
    else
        echo " [info] ${green} $2 succeeded ${nc}" &>> "${logs_file}"
    fi
}
# Install NodeJS, By default NodeJS 16 is available, We would like to enable 20 version and install list.

dnf module disable nodejs -y  &>> "${logs_file}"

validate $? "nodejs module disabled"

dnf module enable nodejs:20 -y &>> "${logs_file}"

validate $? "nodejs module enable"




# check the nodejs installed or not already
dnf list installed nodejs &>> "${logs_file}"

if [ $? -gt 0 ]; then
    echo -e " [info] ${yellow} the nodejs is not installed so installing the nodejs now ${nc}" &>> "${logs_file}"
     echo -e " [info] ${green} installing the nodejs ${nc}" &>> "${logs_file }"
    dnf install nodejs -y
else
    echo -e " [info] ${green} the nodejs is already installed so skipping the installation ${nc}" &>> "${logs_file}"
fi




# if user already exists then we can skip the user creation and if not we can create the user and group

id -u roboshop 

if [ $? -eq 0 ]; then
    echo -e " [info] ${green} the roboshop user already exists so skipping the user creation ${nc}" &>> "${logs_file}"
else
    echo -e " [info] ${yellow} the roboshop user is not there so creating the new one ${nc}" &>> "${logs_file}"
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop  &>> "${logs_file}"
fi
validate $? "roboshop user created successfully"

#lets create the app directory and download the catalogue micro service code

mkdir -p /app                         &>> "${logs_file}"

#Download the application code to created app directory.
 # check the application code already exists means we can delete and re-download the new one.

 if [ -f "/tmp/catalogue.zip" ]; then
    echo "the catalogue.zip already exists so deleting the old one and downloading the new one"
    rm -f /tmp/catalogue.zip
 fi

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip   &>> "${logs_file}"
cd /app    &>> "${logs_file}"
unzip -o /tmp/catalogue.zip   &>> "${logs_file}"

# just check the instalation is success or not by listing the files in the /app directory

 if [ -f "/app/server.js" ]; then
    echo -e " [info] ${green} the server.js now means the new file donwloaded sucessfully ${nc}"
else
    echo -e " [error] ${red} the code not downloaded properly please check the network connectivity and try again ${nc}"
    exit 1
 fi


cd /app 
npm install 


cp $scripts_path/catalogue.service /etc/systemd/system/catalogue.service

validate $? "service file copied sucessfully"

#do the systemctl daemon-reload
systemctl daemon-reload

validate $? "daemon reload done sucessfully"
#enable and start the catalogue service

systemctl enable catalogue 
validate $? "catalogue service enabled sucessfully"
systemctl start catalogue
validate $? "catalogue service started sucessfully"

systemctl is-active catalogue &>> "${logs_file}"

validate $? "catalogue service is up and running"



#To load schema / master data we need to install mongodb client and then we can load it.

#To have mongo client installed we have to setup MongoDB repo and install mongodb-client. 
cp $scripts_path/mongo_repo.file /etc/yum.repos.d/mongo.repo

validate $? "mongo repo copied sucessfully"

mongosh --version

if [ $? -ne 0 ]; then
    echo -e " [info] ${yellow} the mongodb client is not installed so installing the mongodb client ${nc}"
    dnf install mongodb-mongosh -y

else
    echo -e " [info] ${green} the mongodb client is already installed so skipping the installation ${nc}"
fi


validate $? "mongodb client installed sucessfully"



mongosh --host roboshop-mongodb.srinun.in </app/db/master-data.js

# check the data load is success or not

COUNT=$(mongosh --host roboshop-mongodb.srinun.in catalogue --quiet --eval "db.products.countDocuments()")

if [ "$COUNT" -eq 0 ]; then
    echo "data not loaded properly please check one more time"
    exit 1
else 
    echo "the data loaded successfully and the count of the products is $COUNT"
fi
