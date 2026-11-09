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

#Installing python
dnf install python3.14 python3.14-pip -y &>> $log_file
validate $? "Installing python 3.14"

#Create system user/app user
id roboshop &>> $log_file  #checking syatem user
if [ $? -ne 0 ]; then
   useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>> $log_file
   validate $? "creating system user"
else
   echo -e "$(timestamp) [INFO] System user already exists....${Y}SKIPPING${N}"
fi

#create app directory (-p if exists not create )
rm -rf /app
validate $? "Removing old code"

mkdir -p /app
validate $? "Creating app directory"

#Download application
curl -L -o /tmp/payment.zip https://raw.githubusercontent.com/daws-92s/roboshop-documentation/refs/heads/main/artifacts/payment-v4.zip &>> $log_file
validate $? "Downloading payment"

cd /app
unzip /tmp/payment.zip &>> $log_file
validate $? "Unzip payment"

#Installing dependencies
python3.14 -m venv /app/.venv &>> $log_file
validate $? "Creating virtual environment"


/app/.venv/bin/pip install -r requirements.txt &>> $log_file
validate $? "Installing dependencies"

#updating payment.servicce file
sed -i "s/DOMAIN_NAME/$domain_name/g" "$scripts_dir/payment.service"
cp "$scripts_dir/shipping.service" /etc/systemd/system/payment.service


systemctl daemon-reload &>> $log_file
systemctl enable payment &>> $log_file
systemctl start payment &>> $log_file
validate $? "Enable and start payment"

###### End_Time #########
echo  "$(timestamp) [INFO] Script completed in $SECONDS seconds"
echo  "$(timestamp) [INFO] ===== script completed execution =====" | tee -a $log_file
