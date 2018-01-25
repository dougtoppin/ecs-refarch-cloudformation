#!/bin/sh
# start.sh
# utility script to create an ECS cluster, deploy applications and an RDS database to the VPC

# typical usage of this:
#     start.sh test-ecs-1 stack       - create base stack
#       manual step - add NAT Gateway IPs to the ALB SG
#     start.sh test-ecs-1 rds         - create an RDS instance in the VPC
#       manual step - add ECS host SG to the RDS security group
#     start.sh test-ecs-1 springboot1 - deploy a springboot app
#     start.sh test-ecs-1 springboot2 - deploy a springboot app

# to delete the stacks
#    manual step - remove the ECS host SG from the RDS SG
#    manual step - remove NAT Gateway IPs from the ALB SG
#    delete the base stack with aws cloudformation delete-stack --stack-name STACKNAME
# 

# base stack name
STACK1=$1

# stack name for simple springboot application 1
STACK2="$STACK1"-springboot1

# stack name for simple springboot application 2
STACK3="$STACK1"-springboot2

# stack name for RDS database
STACK4="$STACK1"-rds

# location of master (base stack) template
URL=https://s3.amazonaws.com/dougtoppin-cloudformation/ecs-refarch-cloudformation/master.yaml

# aws cli profile to use
PROFILE=dtoppin-01


usage() {
    echo "Usage: $0 stackname stack|boot1|boot2|rds|test|check"
}

if test $# -ne 2
then
    usage
    exit 1
fi

setNames() {
    # the following are all based on the base stack having been completely created

    # get the PhysicalResourceId for the ALB, note that stack-name and the associated PhysicalResourceId are interchangeable
    ALBSTACKNAME=`aws --profile $PROFILE cloudformation describe-stack-resource --stack-name $STACK1 --logical-resource-id ALB --query StackResourceDetail.PhysicalResourceId --output text`

    # get the Listener from the ALB stack outputs
    ALBLISTENER=`aws --profile $PROFILE cloudformation describe-stacks --stack-name $ALBSTACKNAME --query 'Stacks[].Outputs[?OutputKey==\`Listener\`].OutputValue' --output text`

    # get the SecurityGroups PhysicalResourceId
    SGSTACKNAME=`aws --profile $PROFILE cloudformation describe-stack-resource --stack-name $STACK1 --logical-resource-id SecurityGroups --query StackResourceDetail.PhysicalResourceId --output text`

    # ecs hosts security group
    ECSSG=`aws --profile $PROFILE cloudformation describe-stacks --stack-name $SGSTACKNAME --query 'Stacks[].Outputs[?OutputKey==\`ECSHostSecurityGroup\`].OutputValue' --output text`

    # get the name of the VPC stack
    VPCSTACKNAME=`aws --profile $PROFILE cloudformation describe-stack-resource --stack-name $STACK1 --logical-resource-id VPC --query StackResourceDetail.PhysicalResourceId --output text`

    # get the vpcid from the VPC stack outputs
    VPCID=`aws --profile $PROFILE cloudformation describe-stacks --stack-name $VPCSTACKNAME --query 'Stacks[].Outputs[?OutputKey==\`VPC\`].OutputValue' --output text`

    # get the PrivateSubnets list from the VPC stack outputs
    SUBNETS=`aws --profile $PROFILE cloudformation describe-stacks --stack-name $VPCSTACKNAME --query 'Stacks[].Outputs[?OutputKey==\`PrivateSubnets\`].OutputValue' --output text`
}

case $2 in
    stack)
        echo "creating stack $STACK1"
        # create base stack
        aws --profile $PROFILE cloudformation create-stack --stack-name $STACK1  --template-url $URL --capabilities CAPABILITY_NAMED_IAM
        ;;
    boot1)
        echo "deploying springboot1"
        setNames

       # create springboot stack
       aws --profile $PROFILE cloudformation create-stack --stack-name $STACK2 --template-url https://s3.amazonaws.com/dougtoppin-cloudformation/ecs-refarch-cloudformation/services/springboot-service1/service.yaml --parameters ParameterKey=DesiredCount,ParameterValue=2 ParameterKey=VPC,ParameterValue=$VPCID ParameterKey=Path,ParameterValue=/springboot1 ParameterKey=Listener,ParameterValue=$ALBLISTENER ParameterKey=Cluster,ParameterValue=$STACK1 --capabilities CAPABILITY_NAMED_IAM
        ;;
    boot2)
        echo "deploying springboot2"
        setNames

       # create springboot stack
       aws --profile $PROFILE cloudformation create-stack --stack-name $STACK3 --template-url https://s3.amazonaws.com/dougtoppin-cloudformation/ecs-refarch-cloudformation/services/springboot-service2/service.yaml --parameters ParameterKey=DesiredCount,ParameterValue=2 ParameterKey=VPC,ParameterValue=$VPCID ParameterKey=Path,ParameterValue=/springboot2 ParameterKey=Listener,ParameterValue=$ALBLISTENER ParameterKey=Cluster,ParameterValue=$STACK1 --capabilities CAPABILITY_NAMED_IAM
        ;;
    rds)
        echo "deploying RDS"

        setNames

       aws --profile $PROFILE cloudformation create-stack --stack-name $STACK4 --template-url https://s3.amazonaws.com/dougtoppin-cloudformation/ecs-refarch-cloudformation/infrastructure/rds.json --parameters ParameterKey=Subnets,ParameterValue=\"$SUBNETS\" ParameterKey=VpcId,ParameterValue=$VPCID
        ;;
    check)
        echo "error checking templates"
        docker run -it --rm -v $(pwd):/opt/src ruby  bash -c "gem install cfn-nag; cfn_nag_scan --input-path /opt/src/"
        ;;

    test)
        setNames

        echo "STACK1=$STACK1"
        echo "STACK2=$STACK2"
        echo "STACK3=$STACK3"
        echo "STACK4=$STACK4"
        echo "ALBSTACKNAME=$ALBSTACKNAME"
        echo "ALBLISTENER=$ALBLISTENER"
        echo "SGSTACKNAME=$SGSTACKNAME"
        echo "ECSSG=$ECSSG"
        echo "VPCSTACKNAME=$VPCSTACKNAME"
        echo "VPC=$VPCID"
        echo "SUBNETS=$SUBNETS"
        ;;
    *)
      usage
      exit 1
esac

