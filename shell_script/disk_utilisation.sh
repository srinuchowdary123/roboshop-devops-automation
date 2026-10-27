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

hostname=$(hostname -f)
email="srinunuthi555@gmail.com"

if [ "$disk_utilisation" -ge 80 ]; then
    echo -e "${red}[ ALERT ] Disk utilization is ${disk_utilisation}%. Urgent action required.${nc}"
    echo "ALERT: Disk utilization is ${disk_utilisation}% on ${hostname} (/) ." |
        mail -s "CRITICAL: Disk utilization alert" -r "$email" "$email"

elif [ "$disk_utilisation" -ge 70 ]; then
    echo -e "${yellow}[ WARNING ] Disk utilization is ${disk_utilisation}%.${nc}"
    echo "WARNING: Disk utilization is ${disk_utilisation}% on ${hostname} (/)." |
        mail -s "WARNING: Disk utilization alert" -r "$email" "$email"

else
    echo -e "${green}[ OK ] Disk utilization is ${disk_utilisation}%.${nc}"
fi




