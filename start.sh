LISTENER=
VPC=
STACK1=test-ecs-15
STACK2=test-ecs-15-springboot1
STACK3=test-ecs-15-springboot2
REPO=~/Desktop/Projects/Github/ecs-refarch-cloudformation
URL=https://s3.amazonaws.com/dougtoppin-cloudformation/ecs-refarch-cloudformation/master.yaml
SUBNETS=""
BODY=

PROFILE=

if test $# -ne 1
then
    echo "Usage: $0 resource"
    exit 1
fi

case $1 in
    stack)
        # create base stack
        aws --profile $PROFILE cloudformation create-stack --stack-name $STACK1  --template-url $URL --capabilities CAPABILITY_NAMED_IAM
        ;;
    boot1)
       # create springboot stack
       aws cloudformation create-stack --stack-name $STACK2 --template-url https://s3.amazonaws.com/dougtoppin-cloudformation/ecs-refarch-cloudformation/services/springboot-service1/service.yaml --parameters ParameterKey=DesiredCount,ParameterValue=2 ParameterKey=VPC,ParameterValue=$VPC ParameterKey=Path,ParameterValue=/springboot1 ParameterKey=Listener,ParameterValue=$LISTENER ParameterKey=Cluster,ParameterValue=$STACK1 --capabilities CAPABILITY_NAMED_IAM
        ;;
    boot2)
       # create springboot stack
       aws cloudformation create-stack --stack-name $STACK3 --template-url https://s3.amazonaws.com/dougtoppin-cloudformation/ecs-refarch-cloudformation/services/springboot-service2/service.yaml --parameters ParameterKey=DesiredCount,ParameterValue=2 ParameterKey=VPC,ParameterValue=$VPC ParameterKey=Path,ParameterValue=/springboot2 ParameterKey=Listener,ParameterValue=$LISTENER ParameterKey=Cluster,ParameterValue=$STACK1 --capabilities CAPABILITY_NAMED_IAM
        ;;
    rds)
       aws cloudformation create-stack --stack-name "$STACK1"-rds --template-url https://s3.amazonaws.com/dougtoppin-cloudformation/ecs-refarch-cloudformation/infrastructure/rds.json --parameters ParameterKey=Subnets,ParameterValue=\"$SUBNETS\" ParameterKey=VpcId,ParameterValue=$VPC
        ;;
    *)
      echo "Usage: $0 resource"
      exit 1
esac

