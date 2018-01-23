#!/bin/sh
# create related stuff

STACK1=$1
STACK2="$STACK1"-springboot1
STACK3="$STACK1"-springboot2
STACK4="$STACK1"-rds
REPO=~/Desktop/Projects/Github/ecs-refarch-cloudformation
URL=https://s3.amazonaws.com/dougtoppin-cloudformation/ecs-refarch-cloudformation/master.yaml

PROFILE=dtoppin-01


usage() {
    echo "Usage: $0 stackname stack|boot1|boot2|rds"
}

if test $# -ne 2
then
    usage
    exit 1
fi

setNames() {
    # the following are all based on the base stack having been completely created
    ALBSTACKNAME=`aws --profile $PROFILE cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --query "StackSummaries[?starts_with(StackName,\\\`"$STACK1"-ALB\\\`)].StackName" --output text`
    ALBLISTENER=`aws --profile $PROFILE cloudformation describe-stacks --stack-name $ALBSTACKNAME --query 'Stacks[].Outputs[?OutputKey==\`Listener\`].OutputValue' --output text`
    SGSTACKNAME=`aws --profile $PROFILE cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --query "StackSummaries[?starts_with(StackName,\\\`"$STACK1"-SecurityGroups\\\`)].StackName" --output text`
    ECSSG=`aws --profile $PROFILE cloudformation describe-stacks --stack-name $SGSTACKNAME --query 'Stacks[].Outputs[?OutputKey==\`ECSHostSecurityGroup\`].OutputValue' --output text`
    VPCSTACKNAME=`aws --profile $PROFILE cloudformation list-stacks --stack-status-filter CREATE_COMPLETE --query "StackSummaries[?starts_with(StackName,\\\`"$STACK1"-VPC\\\`)].StackName" --output text`
    VPC=`aws --profile $PROFILE cloudformation describe-stacks --stack-name $VPCSTACKNAME --query 'Stacks[].Outputs[?OutputKey==\`VPC\`].OutputValue' --output text`
    SUBNETS=`aws --profile $PROFILE cloudformation describe-stacks --stack-name $VPCSTACKNAME --query 'Stacks[].Outputs[?OutputKey==\`PrivateSubnets\`].OutputValue' --output text`
}

case $2 in
    stack)
        # create base stack
        aws --profile $PROFILE cloudformation create-stack --stack-name $STACK1  --template-url $URL --capabilities CAPABILITY_NAMED_IAM
        ;;
    boot1)
        setNames

       # create springboot stack
       aws --profile $PROFILE cloudformation create-stack --stack-name $STACK2 --template-url https://s3.amazonaws.com/dougtoppin-cloudformation/ecs-refarch-cloudformation/services/springboot-service1/service.yaml --parameters ParameterKey=DesiredCount,ParameterValue=2 ParameterKey=VPC,ParameterValue=$VPC ParameterKey=Path,ParameterValue=/springboot1 ParameterKey=Listener,ParameterValue=$ALBLISTENER ParameterKey=Cluster,ParameterValue=$STACK1 --capabilities CAPABILITY_NAMED_IAM
        ;;
    boot2)
        setNames

       # create springboot stack
       aws --profile $PROFILE cloudformation create-stack --stack-name $STACK3 --template-url https://s3.amazonaws.com/dougtoppin-cloudformation/ecs-refarch-cloudformation/services/springboot-service2/service.yaml --parameters ParameterKey=DesiredCount,ParameterValue=2 ParameterKey=VPC,ParameterValue=$VPC ParameterKey=Path,ParameterValue=/springboot2 ParameterKey=Listener,ParameterValue=$ALBLISTENER ParameterKey=Cluster,ParameterValue=$STACK1 --capabilities CAPABILITY_NAMED_IAM
        ;;
    rds)
        setNames

       aws --profile $PROFILE cloudformation create-stack --stack-name $STACK4 --template-url https://s3.amazonaws.com/dougtoppin-cloudformation/ecs-refarch-cloudformation/infrastructure/rds.json --parameters ParameterKey=Subnets,ParameterValue=\"$SUBNETS\" ParameterKey=VpcId,ParameterValue=$VPC
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
        echo "VPC=$VPC"
        echo "SUBNETS=$SUBNETS"
        ;;
    *)
      usage
      exit 1
esac

