#!/bin/bash

log_folder="/var/log/roboshop"
log_file="${log_folder}/${0}.log"
domain_name="saipavan.store"
script_dir=$(dirname "$(realpath "$0")")
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

###### Starting_Time #######
echo  "$(timestamp) [INFO] ===== script started Execution =====" | tee -a $log_file

#Installing nginx
dnf module disable nginx -y &>> $log_file
dnf module enable nginx:1.26 -y &>> $log_file
dnf install nginx -y &>> $log_file
validate $? "Installing nginx"

#Start and enable nginx
systemctl enable nginx &>> $log_file
systemctl start nginx &>> $log_file
validate $? "Start and enable nginx"

#Removing default content
rm -rf /usr/share/nginx/html/* &>> $log_file
validate $? "Removing default content in html"

#downloading and unziping front end code
curl -L -o /tmp/frontend.zip https://raw.githubusercontent.com/daws-92s/roboshop-documentation/refs/heads/main/artifacts/frontend-v4.zip &>> $log_file
cd /usr/share/nginx/html &>> $log_file
unzip /tmp/frontend.zip &>> $log_file
validate $? "Downloding and unziping frontend code"

#updating roboshop.cong file
sed -i "s/DOMAIN_NAME/$domain_name/g" "$script_dir/roboshop.conf" &>> $log_file
cp "$script_dir/roboshop.conf" /etc/nginx/default.d/roboshop.conf &>> $log_file
validate $? "Copied roboshop.config"

#nginx config
nginx -t &>> $log_file
validate $? "nginx configuration"

#Restart nginx
systemctl restart nginx &>> $log_file
validate $? "Restartig Nginx"


###### End_Time #########
echo  "$(timestamp) [INFO] Script completed in $SECONDS seconds"
echo  "$(timestamp) [INFO] ===== script completed execution =====" | tee -a $log_file
