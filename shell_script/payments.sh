#!/bin/bash
set -u

# this script will create the catalogue micro service

# check the script is running with the sudo user or not
user_id=$(id -u)

if [ "$user_id" -ne 0 ]; then
    echo "This script must be run as root or with sudo privileges."
    exit 1
fi

scripts_path=$(pwd)
logs_folder="/var/log/roboshop"
logs_file="$logs_folder/payments.log"

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

dnf install python3 gcc python3-devel -y

validate $? "installing the python3"

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

 if [ -f "/tmp/payment.zip" ]; then
    echo "the payment.zip already exists so deleting the old one and downloading the new one"
    rm -f /tmp/payment.zip
 fi

curl -L -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip    &>> "${logs_file}"
cd /app    &>> "${logs_file}"
unzip -o /tmp/payment.zip   &>> "${logs_file}"

cd /app 

echo "installing the requirements.txt"
pip3 install -r requirements.txt   &>> ${logs_file}

validate $? "installing the requirements.txt"



cp "$scripts_path/payments_service.file" "/etc/systemd/system/payment.service"

systemctl daemon-reload

validate $?  " re loading the daemon"

#start and enable the user 

systemctl enable payment  

validate $? "enabling the payment "

systemctl start payment 

validate $? "started the payment "

