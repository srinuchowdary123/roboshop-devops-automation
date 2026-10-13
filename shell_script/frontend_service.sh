#!/bin/bash

# now we are going to deploy the frontend micro service in the ec2 instance

# check the script is running with the sudo user or not

user_id=$(id -u)

scripts_path=$(pwd)
if [ "$user_id" -ne 0 ]; then
    echo "this script must run with the sudo  user or root user"
    exit 1
fi

# writing a function to validate the status of commands insted of duplicating the same if condition for each #command executed

validate () {
    if [ $1 -eq 0 ]; then 
    echo " the $2 is got suceded"
else
    echo "$2 is got failed"
    exit 1
fi
}

#list the nginx modules first and then we can disable the default module and enable the new module

dnf module list nginx

validate $? "list the nginx module properly"


dnf module disable nginx -y

validate $? "disable the nginx module properly"

dnf module enable nginx:1.24 -y

validate $? "enabled  the nginx module properly"

dnf install nginx -y

validate $? "nginx installed sucesfully"

#Start & Enable Nginx service

systemctl enable nginx 

validate $? "nginx enabled sucesfully"


systemctl start nginx 

validate $? "nginx started sucesfully"

# remove the defalt html page of the nginx which is present in this path rm -rf /usr/share/nginx/html/* 

rm -rf /usr/share/nginx/html/* 

validate $? "delete the default nginx content"

#Download the frontend content

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip
validate $? "downloaded the frotntend content"

cd /usr/share/nginx/html 
unzip /tmp/frontend.zip

validate $? "unzipped the frontend content"


# copy the service file to the nginx configuration directory 


cp $scripts_path/nginx_service.file /etc/nginx/nginx.conf

validate $? "copied the nginx service file to the nginx configuration directory"

# lets restart the nginx  service to reflect the changes

systemctl restart nginx 

validate $? "nginx restarted sucesfully"






