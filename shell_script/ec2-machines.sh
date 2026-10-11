#!/bin/bash

# Usage: bash ec2-machines.sh <create|delete> <name1> <name2> ...

state_of_machine=$1
shift

red='\e[1;31m'
green='\e[1;32m'
yellow='\e[1;33m'
nc='\e[0m'

if [ $# -lt 1 ]; then
    echo -e "${red}Usage: $0 <create|delete> <name1> [name2 ...]${nc}"
    exit 1
fi

if [ "$state_of_machine" != "create" ] && [ "$state_of_machine" != "delete" ]; then
    echo "Invalid operation. Use create or delete."
    exit 1
fi

if [ "$state_of_machine" == "create" ]; then
    common_sg_id=$(aws ec2 describe-security-groups --filters "Name=vpc-id,Values=vpc-0bf3a8f73da50ede9" --query "SecurityGroups[?GroupName=='common-sg'].GroupId" --output text)


    if [ -z "$common_sg_id" ] || [ "$common_sg_id" == "None" ]; then
        echo "the common-sg not there so creating the new one"
        common_sg_id=$(aws ec2 create-security-group --group-name common-sg --description "Common Security Group" --vpc-id vpc-0bf3a8f73da50ede9 --query 'GroupId' --output text)
    else
        echo "the common-sg is already there with id $common_sg_id"
    fi
fi

for name_of_machine in "$@"; do
    instance_name="roboshop-$name_of_machine"



    if [ "$state_of_machine" == "create" ]; then
            app_sg_id=$(aws ec2 describe-security-groups --filters "Name=vpc-id,Values=vpc-0bf3a8f73da50ede9" --query "SecurityGroups[?GroupName=='$instance_name'].GroupId" --output text)


            if  [ -z "$app_sg_id" ] || [ "$app_sg_id" == "None" ]; then
                echo "the $instance_name not there so creating the new one"
                app_sg_id=$(aws ec2 create-security-group --group-name $instance_name --description "app Security Group" --vpc-id vpc-0bf3a8f73da50ede9 --query 'GroupId' --output text)
                
            else
                echo "the $instance_name instance is already there with id $app_sg_id"
            fi
        instance_id=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=$instance_name" "Name=instance-state-name,Values=running" --query 'Reservations[].Instances[].InstanceId' --output text)

        if [ -n "$instance_id" ] && [ "$instance_id" != "None" ]; then
            echo "$instance_name already exists. Skipping creation."
        else
            echo "Creating $instance_name..."
            aws ec2 run-instances --image-id ami-0220d79f3f480ecf5 --instance-type t3.micro --security-group-ids "$common_sg_id" "$app_sg_id" --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance_name}]"

            if [ $? -eq 0 ]; then
                echo -e "${green}Successfully launched $instance_name${nc}"
            else
                echo -e "${red}Failed to launch $instance_name${nc}"
            fi
        fi

    elif [ "$state_of_machine" == "delete" ]; then
        instance_id=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=$instance_name" "Name=instance-state-name,Values=pending,running,stopping,stopped" --query 'Reservations[].Instances[].InstanceId' --output text)

        if [ -z "$instance_id" ] || [ "$instance_id" == "None" ]; then
            echo "$instance_name does not exist or is already terminated."
        else
            echo "Terminating $instance_name ($instance_id)..."
            aws ec2 terminate-instances --instance-ids $instance_id

            if [ $? -eq 0 ]; then
                echo -e "${green}Termination requested for $instance_name${nc}"
            else
                echo -e "${red}Failed to terminate $instance_name${nc}"
            fi
        fi
    fi
done