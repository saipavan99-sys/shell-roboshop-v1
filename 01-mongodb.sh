#!/bin/bash

log_folder="/var/log/roboshop"
log_file="${log_folder}/${0}.log"
R="\e[31m"  #adding colours to specific words
G="\e[32m"
Y="\e[33m"
N="\e[0m"   

user_id=$(id -u)

if [ $user_id -ne 0 ]; then
  echo "please run this script with sudo access"
  exit 1
fi

mkdir -p $log_folder                                                  #creating log_folder if not

echo "script started execution at: $(date +"%F %T")" &>> $log_file    #redirection to logs into file

#function

validate(){
     if [ $1 -ne 0 ]; then
        echo -e "$2 is ${R}FAILED....${N}" | tee -a $log_file         #to print status on screen use tee cmd
        exit 1                                                        #exit status
    else 
        echo -e "$2 is ${G}SUCCESS....${N}" | tee -a $log_file        # "-e" is to execute colours
    fi
}

cp mongo.repo /etc/yum.repos.d/mongo.repo
validate $? "Adding mongo repo"

# installing MongoDB
dnf install mongodb-org -y &>> $log_file
validate $? "install MongoDB"

# start and enable MongoDb
systemctl enable mongod &>> $log_file
systemctl start mongod &>> $log_file
validate $? "enable and start MongoDB"

#updating remort connections
sde -i 's/127.0.0.1/0.0.0.0' /etc/mongod.conf
validate $? "updating remort connection to MongoDB"

#restaring mongod
systemctl restart mongod
validate $? "restarting MongoDB"


