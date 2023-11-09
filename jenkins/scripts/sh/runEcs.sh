#!/bin/bash -e

SECURITY_GROUP_ID="i-0366c73da3f6a488d"


function main {
	# fetch VPC ID for security group	
	aws ec2 describe-instances --instance-ids "$SECURITY_GROUP_ID" --region us-east-1
}


main