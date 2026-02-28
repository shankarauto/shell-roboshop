#!/bin/bash

SG_ID="sg-048193ac291fc884d"
AMI_ID="ami-0220d79f3f480ecf5"
INSTANCE_TYPE="t2.micro"
ZONE_ID="Z0203342ANSR45M2EYDS"
DOMAIN_NAME="vtk88s.online"


for instance in $@
do
    INSTANCE_ID=$(aws ec2 run-instances \
    --image-id "$AMI_ID" \
    --instance-type "$INSTANCE_TYPE" \
    --security-group-ids "$SG_ID" \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" \
    --query 'Instances[0].InstanceId' \
    --output text)

    if [ "$instance" = "frontend" ]; then
        IP=$(aws ec2 describe-instances \
            --instance-ids $INSTANCE_ID \
            --query 'Reservations[0].Instances[0].PublicIpAddress' \
            --output text)
    else
        IP=$(aws ec2 describe-instances \
            --instance-ids $INSTANCE_ID \
            --query 'Reservations[0].Instances[0].PrivateIpAddress' \
            --output text
            )
            RECORD_NAME="$Instance.$DOMAIN_NAME" #mongodb.vtk88s.online
    fi

    echo "IP Address:" $IP

    aws route53 change-resource-record-sets \
    --hosted-zone-id $ZONE_ID \
    --change-batch '
    {
    "Comment": "Updating record",
    "Changes": [
        {
        "Action": "UPSERT", 
        "ResourceRecordSet": {
            "Name": "'$RECORD_NAME'",
            "Type": "A",
            "TTL": 1,
            "ResourceRecords": [
            {
                "Value": "'$IP'"
            }
            ]
        }
        }
    ]
    }

    '
    echo "record updated for $instance"

    
done