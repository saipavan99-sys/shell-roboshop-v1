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

#Adding time stamp
timestamp(){
    date "+%F %T"
}

#function

validate(){
     if [ $1 -ne 0 ]; then
        echo -e "$(timestamp) [ERROR] $2 is ${R}FAILED....${N}" | tee -a $log_file         #to print status on screen use tee cmd
        exit 1                                                                             #exit status
    else 
        echo -e "$(timestamp) [INFO] $2 is ${G}SUCCESS....${N}" | tee -a $log_file        # "-e" is to execute colours
    fi
}

#Starting Time
echo  "$(timestamp) [INFO] ===== script started Execution =====" | tee -a $log_file

#Installing mysql server
dnf module enable mysql:8.4 -y &>> log_file
dnf install mysql-server -y &>> log_file
validate $? "Installing mysql server"

#Start and enable
systemctl enable mysqld &>> log_file
systemctl start mysqld
validate $? "start and enable mysql"

#Setup root password
mysql_secure_installation --set-root-pass RoboShop@1 &>> log_file
validate $? "Setup MySql root password"

#End Time
echo  "$(timestamp) [INFO] Script completed in $SECONDS seconds"
echo  "$(timestamp) [INFO] ===== script completed execution =====" | tee -a $log_file
