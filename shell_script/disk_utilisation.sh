#!/bin/bash
set -u

# this script will create the catalogue micro service

# check the script is running with the sudo user or not
user_id=$(id -u)

if [ "$user_id" -ne 0 ]; then
    echo "This script must be run as root or with sudo privileges."
    exit 1
fi

green="\e[32m"
red="\e[31m"
yellow="\e[33m"
nc="\e[0m"

disk_utilisation=$(df -h / | awk '{print $5}' | sed '1d; s/%//')

#!/bin/bash
set -u

user_id=$(id -u)

if [ "$user_id" -ne 0 ]; then
    echo "This script must be run as root or with sudo privileges."
    exit 1
fi

green="\e[32m"
red="\e[31m"
yellow="\e[33m"
nc="\e[0m"

disk_utilisation=$(df -h / | awk '{print $5}' | sed '1d; s/%//')

if [ "${disk_utilisation}" -ge 80 ]; then
    echo -e "${red}[ ALERT ] disk utilisation crossed 80 percent. Urgent action required.${nc}"
    echo "Disk is above 80 percent on the frontend machine." | mail -s "disk utilisation alert" -r srinunuthi555@gmail.com srinunuthi555@gmail.com
elif [ "${disk_utilisation}" -ge 70 ]; then
    echo -e "${yellow}[ warning ] disk utilisation crossed 70 percent.${nc}"
    echo "Disk is above 70 percent on the frontend machine." | mail -s "disk utilisation alert" -r srinunuthi555@gmail.com srinunuthi555@gmail.com
else
    echo -e "${green}[ ok ] disk utilisation is under 70 percent.${nc}"
    echo "Disk is below 70 percent on the frontend machine." | mail -s "disk utilisation alert" -r srinunuthi555@gmail.com srinunuthi555@gmail.com
fi




