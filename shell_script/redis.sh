#!/bin/bash

#installing the redis service in the ec2 machine

#run the script with the sudo user




if [ "$(id -u)" -eq 0 ]; then
    echo "This script must be run as root or with sudo privileges."
    exit 1
fi


# adding the logs folder and logs file to store the logs of the script executed

logs_folder="/var/log/roboshop"
logs_file="$logs_folder/redis.log"

# adding the color to the logs to make it more readable and understandable

red="\e[31m"
green="\e[32m"
nc="\e[0m"
yellow="\e[33m"


if [ -d "$logs_folder" ]; then
    echo " [info] ${green} directory exists and there should be possible no logs file creating here too ${nc}"
    touch "${logs_file}"
else
    echo " [info] ${red} directory not exists so creating the new one and creating the logsfile too ${nc}"
    mkdir -p "${logs_folder}"
    touch "${logs_file}"
fi




#validate fucntion just to check the previous command is sucess or not with the valid comments

validate () {

    if [ $1 -ne 0 ]; then
        echo " [error] ${red} $2 failed ${nc}" &>> "${logs_file}"
        exit 1
    else
        echo " [info] ${green} $2 succeeded ${nc}" &>> "${logs_file}"
    fi
}

# disable the reds module and enable the redis module to install the latest version of redis

echo -e " [info] ${yellow} disabling the redis module and enabling the redis module to install the latest version of redis ${nc}"

dnf module disable redis -y  &>> "${logs_file}"

validate $? "redis module disabled"

echo -e " [info] ${yellow} enabling the redis module to install the latest version of redis ${nc}"

dnf module enable redis:7 -y  &>> "${logs_file}"

validate $? "redis module enabled"


#install the redis service in the ec2 machine

echo -e " [info] ${yellow} installing the redis service in the ec2 machine ${nc}"

dnf install redis -y &>> "${logs_file}"

validate $? "redis service installed"


#Update listen address from 127.0.0.1 to 0.0.0.0 in /etc/redis/redis.conf

echo -e " [info] ${yellow} updating listen address in redis.conf ${nc}"
sed -i 's/127.0.0.1/0.0.0.0/g' /etc/redis/redis.conf

validate $? "listen address updated in redis.conf"

#Update protected-mode from yes to no in /etc/redis/redis.conf

echo -e " [info] ${yellow} updating protected-mode in redis.conf ${nc}" 
sed -i 's/protected-mode yes/protected-mode no/g' /etc/redis/redis.conf

validate $? "protected-mode updated in redis.conf"

#Start & Enable Redis Service

echo -e " [info] ${yellow} starting and enabling redis service ${nc}"
systemctl enable redis 

validate $? "redis service enabled"

systemctl start redis 

validate $? "redis service started"

systemctl is-active redis &>> "${logs_file}"

validate $? "redis service is-active"