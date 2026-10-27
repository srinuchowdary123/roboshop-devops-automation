

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


# disable the dnf module
echo "disabled the dnf module"
dnf module disable nodejs -y   &>> "$logs_file"

validate $? "diasbled the dnf module"

echo "enaling the dnf module"
dnf module enable nodejs:20 -y   &>> "$logs_file"

validate $? "enable the dnf module"

#installing nodejs
echo "installing node js"

dnf install nodejs -y   &>> "$logs_file"

validate $? "installing the nodejs"

# add the application user

useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop

validate $? "creating theapp user"

#We keep application in one standard location. This is a usual practice that runs in the organization.

# check the directory is there or not first

app_folder=app
if [ ! -d "/$app_folder" ]; then
    echo " [info]  ${green} creating the directory ${nc}"
    mkdir /$app_folder
    rm -rf /tmp/user.zip  
    curl -L -o /tmp/user.zip https://roboshop-artifacts.s3.amazonaws.com/user-v3.zip 
    cd /$app_folder 
    unzip /tmp/user.zip
else
    echo " [info]  ${yellow} directory already exists skipping the creation ${nc}"
fi

validate $? "creating directory and downloading the code "


# download the dependencies

cd /$app_folder

npm install 

validate $? " installing the dependencies of application"


cp "$scripts_path/user_service.file" "/etc/systemd/system/user.service"

#load the service

systemctl daemon-reload

validate $?  " re loading the daemon"

#start and enable the user 

systemctl enable user 

validate $? "enabling the user"

systemctl start user

validate $? "started the user"

