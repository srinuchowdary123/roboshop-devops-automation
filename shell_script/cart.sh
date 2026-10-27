#!/bin/bash

# check the user is root or not

user_id=$(id -u)

if [ $"{user_id}" -ne 0 ]; then

    echo " please run with the sudo or admin previlages"
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

validate() { 
    if [ $1 -ne 0 ]; then
        echo " [error] ${red} $2 failed ${nc}" &>> "${logs_file}"
        exit 1
    else
        echo " [info] ${green} $2 succeeded ${nc}" &>> "${logs_file}"
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


# if user already exists then we can skip the user creation and if not we can create the user and group

id -u roboshop 

if [ $? -eq 0 ]; then
    echo -e " [info] ${green} the roboshop user already exists so skipping the user creation ${nc}" &>> "${logs_file}"
else
    echo -e " [info] ${yellow} the roboshop user is not there so creating the new one ${nc}" &>> "${logs_file}"
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop  &>> "${logs_file}"
fi
validate $? "roboshop user created successfully"


#We keep application in one standard location. This is a usual practice that runs in the organization.

# check the directory is there or not first

app_folder=app
if [ ! -d "/$app_folder" ]; then
    echo " [info]  ${green} creating the directory ${nc}"
    mkdir /$app_folder
    rm -rf /tmp/user.zip  
    curl -L -o /tmp/cart.zip https://roboshop-artifacts.s3.amazonaws.com/cart-v3.zip
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



cp "$scripts_path/cart_service.file" "/etc/systemd/system/cart.service"

#load the service

systemctl daemon-reload

validate $?  " re loading the daemon"

#start and enable the user 

systemctl enable cart 

validate $? "enabling the cart service"

systemctl start cart

validate $? "started the cart service"

