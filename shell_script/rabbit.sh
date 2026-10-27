#!/bin/bash
set -u

# check the script is running with the sudo user or not
user_id=$(id -u)

if [ "$user_id" -ne 0 ]; then
    echo "This script must be run as root or with sudo privileges."
    exit 1
fi

scripts_path=$(pwd)
logs_folder="/var/log/roboshop"
logs_file="$logs_folder/rabbitmq.log"

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



cp "$scripts_path/rabbit_mq_service.file" "/etc/yum.repos.d/rabbitmq.repo"

validate $? "copy got sucessful"


#installing the rabbit mq
echo "installing the rabbitmq"
dnf install rabbitmq-server -y  &>> ${logs_file}

# enabling the rabbit mq

systemctl enable rabbitmq-server

validate $? "enabling the rabbit mq"

systemctl start rabbitmq-server

validate $? "starting the rabbitma"


rabbitmqctl list_users | grep -q "^roboshop"

if [ $? -eq 0 ]; then
    echo -e " [info] ${green} the roboshop user already exists so skipping the user creation ${nc}" &>> "${logs_file}"
else
    echo -e " [info] ${yellow} the roboshop user is not there so creating the new one ${nc}" &>> "${logs_file}"
    rabbitmqctl add_user roboshop roboshop123
    validate $? "creating the user"
fi

rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*"

validate $? "setting the permissions"


