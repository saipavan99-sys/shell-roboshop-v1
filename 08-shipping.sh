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


#install Java And Maven
dnf module enable maven:3.9 -y &>> $log_file
dnf install maven java-25-openjdk-devel -y &>> $log_file
validate $? "Installing Java And Maven"

#Setuping Java25 Version
alternatives --set java "/usr/lib/jvm/java-25-openjdk/bin/java"
validate $? "Setting Java25 as default version"

#Setting JAVA_HOME for maven
echo "export JAVA_HOME=$(dirname $(dirname $(readlink -f /usr/bin/java)))" > /etc/profile.d/java.sh
source /etc/profile.d/java.sh
echo $JAVA_HOME
validate $? "Setting JAVA_HOME for maven"

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
curl -L -o /tmp/shipping.zip https://raw.githubusercontent.com/daws-92s/roboshop-documentation/refs/heads/main/artifacts/shipping-v4.zip &>> $log_file
validate $? "Downloading shipping"

cd /app
unzip /tmp/shipping.zip &>> $log_file
validate $? "Unzip shipping"

#Installing dependencies
cd /app
mvn clean package &>> $log_file
validate $? "Installing dependencies"

#Moving shipping.jar file
mv target/shipping.jar shipping.jar
validate $? "Moving shipping.jar file"

#updating shipping.servicce file
sed -i "s/DOMAIN_NAME/$domain_name/g" "$scripts_dir/shipping.service"
cp "$scripts_dir/shipping.service" /etc/systemd/system/shipping.service

#installing mysql client
dnf install mysql -y &>> $log_file
validate $? "Installing mysql client"

#loading master data
count=$(mysql -h "mysql.$domain_name" -u root -pRoboShop@1 -N -B -e "SELECT COUNT(*) FROM cities.cities;" 2>> $logs_file )
if [ -z "$count" ] || [ "$count" -eq 0 ]; then
    mysql -h "mysql.$domain_name" -uroot -pRoboShop@1 < /app/db/master-data.sql
    validate $? "Loading shipping data"
else
    echo -e "$(timestamp) [INFO] Master data already loaded...${Y}SKIPPING${N}"
fi

#Creating APP user
mysql -h "mysql.$domain_name" -uroot -pRoboShop@1 < /app/db/app-user.sql &>> $log_file
validate $? "Creating APP user"

#Restarting/Starting shipping
systemctl daemon-reload &>> $logs_file
systemctl enable shipping &>> $logs_file
systemctl restart shipping &>> $log_file
validate $? "Restarting/Starting shipping"


###### End_Time #########
echo  "$(timestamp) [INFO] Script completed in $SECONDS seconds"
echo  "$(timestamp) [INFO] ===== script completed execution =====" | tee -a $log_file
