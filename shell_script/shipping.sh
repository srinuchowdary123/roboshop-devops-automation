#!/bin/bash

# check the user is root or not

user_id=$(id -u)

if [ "$user_id" -ne 0 ]; then

    echo "please run with the sudo previlages or root permissions"
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

    echo " the directory not exists creating the directory and also the logs file"
    mkdir "${logs_folder}"
    touch "${logs_file}"
else

    echo " the directory exists so oly creating the logs file"
    touch "${logs_file}"
fi

#writing the function to check the previous command is sucessful or not"

validate() { 
    if [ $1 -ne 0 ]; then
        echo " [error] ${red} $2 failed${nc}" &>> "${logs_file}"
        exit 1
    else
        echo " [info] ${green} $2   succeded ${nc}" &>> "${logs_file}"
    fi
}


#installing maven

echo "installing the maven"

dnf install maven -y  &>> "${logs_file}"

validate $? "installing the maven"

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

 if [ -f "/tmp/shipping.zip" ]; then
    echo "the shipping.zip already exists so deleting the old one and downloading the new one"
    rm -f /tmp/shipping.zip
 fi

curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip   &>> "${logs_file}"
cd /app    &>> "${logs_file}"
unzip -o /tmp/shipping.zip   &>> "${logs_file}"


cd /app 

#packing the applciation

echo "running the mvn package command"

mvn clean package   &>> "${logs_file}"

validate $? "running the clean package"

mv target/shipping-1.0.jar shipping.jar 

validate $? "jar file "

cp "$scripts_path/user_service.file" "/etc/systemd/system/shipping.service"

#load the service

systemctl daemon-reload

validate $?  " re loading the daemon"

#start and enable the user 

systemctl enable shipping  

validate $? "enabling the shipping "

systemctl start shipping 

validate $? "started the shipping "

# to load the data we need to install the mysql client here 

dnf install mysql -y   &>> ${logs_file}

validate $? "installing the mysql client"

# load the schema 
mysql -h roboshop-mysql.srinun.in -uroot -pRoboShop@1 < /app/db/schema.sql


# create the user for mysql

mysql -h roboshop-mysql.srinun.in -uroot -pRoboShop@1 < /app/db/app-user.sql 


# restarting the shipping svc

systemctl restart shipping

validate $? "re starting the shipping svc"

