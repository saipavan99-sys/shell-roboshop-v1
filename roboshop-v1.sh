#!/bin/bash

ami_id="ami-0055977a6e828a4f4"
instance_type="t3.micro"
domain_name="saipavan.store"
hosted_zone_id="Z02885542LU4LAGB483WQ"

for instance in $@
do
    echo "creating instance: $instance"

    instance_id=$(aws ec2 run-instances \
          --image-id ami-0055977a6e828a4f4 \
          --instance-type t3.micro \
          --security-groups "roboshop-common" "roboshop-$instance" \
          --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=roboshop-$instance}]" \
          --query 'Instances[0].InstanceId' \
          --output text
    )

    echo "$instance instance id: $instance_id"

    if [ $instance != "fontend" ]; then
        IP=$( aws ec2 describe-instances \
               --instance-ids $instance_id \
               --query "Reservations[].Instances[].PublicIpAddress]" \
               --output text  
        )
        r53_record="$instance.$domain_name"   #avoid spaces for var
   else
     IP=$( aws ec2 describe-instances \
               --instance-ids $instance_id \
               --query "Reservations[].Instances[].PrivateIpAddress]" \
               --output text  
        ) 
        r53_record="$domain_name"    
   fi
   
   #update route_53 Record

     aws route53 change-resource-record-sets \
    --hosted-zone-id $hosted_zone_id \
    --change-batch '{
        "Changes": [
            {
                "Action": "UPSERT",
                "ResourceRecordSet": {
                    "Name": "'$r53_record'",
                    "Type": "A",
                    "TTL": 1,
                    "ResourceRecords": [{"Value": "'$IP'"}]
                }
            }
        ]
    }'
    
    echo "updated r53 record for $instance"
done