#!/bin/bash

user_id=$(id -u)

if [ "${user_id}" -ne 0 ]; then

    echo " please run with the sudo or admin previlages"
    exit 1
fi

scripts_path=$(pwd)
logs_folder="/var/log/roboshop"
logs_file="$logs_folder/cart.log"

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

validate() { 
    if [ $1 -ne 0 ]; then
        echo " [error] ${red} $2 failed ${nc}" &>> "${logs_file}"
        exit 1
    else
        echo " [info] ${green} $2 succeeded ${nc}" &>> "${logs_file}"
    fi
}




# install the mysql server

echo "installing the mysql server"

dnf install mysql-server -y  &>> ${logs_file}

validate $? "installing the mysql"



# enabling the systemctl  
systemctl enable mysqld

validate $? "mysql is enabled"

systemctl start mysqld  

validate $? "mysql is started"

# changing the root password

mysql_secure_installation --set-root-pass RoboShop@1

validate $? "the passoword update is completed"

