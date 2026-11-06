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

#Starting Time
echo  "$(timestamp) [INFO] ===== script started Execution =====" | tee -a $log_file

#Installing nodejs 24
dnf module disable nodejs -y &>> $log_file
dnf module enable nodejs:24 -y &>> $log_file
dnf install nodejs -y &>> $log_file
validate $? "Installing nodejs 24"

#Create system user
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
curl -L -o /tmp/catalogue.zip https://raw.githubusercontent.com/daws-92s/roboshop-documentation/refs/heads/main/artifacts/catalogue-v4.zip
validate $? "Downloading catalogue"

cd /app
unzip /tmp/catalogue.zip
validate $? "Unzip catalogue"

#Install Dependences
npm install
validate $? "Install dependencies"

#updating catalogue.service
sed -i "s/DOMAIN_NAME/$domain_name/g" "$script_dir/catalogue.service"
cp "$script_dir/catalogue.service" /etc/systemd/system/catalogue.service


systemctl daemon-reload &>> $log_file
systemctl enable catalogue &>> $log_file
systemctl start catalogue &>> $log_file
validate $? "Start and enable catalogue"

#installing MongoDB client
dnf install mongodb-mongosh -y &>> $log_file
validate $? "Installing MongoDB Client"

product_count=$(mongosh --host mongodb.$domain_name --quiet --eval 'db.getSiblingDB("catalogue").products.countDocuments()' 2>> $log_file)
validate $? "Connecting to MongoDB"
if [ $product_count -eq 0 ]; then          #0 means No data or products
    mongosh --host "mongodb.$domain_name" </app/db/master-data.js &>> $log_file
    validate $? "Loading products"
else
   echo "$(timestamp) [INFO] Products already loaded....${Y}SKIPPING${N}"
fi

systemctl restart catalogue
validate $? "restarting catalogue"

#Health checking
systemctl status catalogue
journalctl -u catalogue -f
curl http://localhost:8080/health
curl http://localhost:8080/products

#End Time
echo  "$(timestamp) [INFO] Script completed in $SECONDS seconds"
echo  "$(timestamp) [INFO] ===== script completed execution =====" | tee -a $log_file
