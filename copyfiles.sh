PROFILE=
LOC=s3://dougtoppin-cloudformation/ecs-refarch-cloudformation
LIST="master.yaml infrastructure/ecs-cluster.yaml infrastructure/security-groups.yaml infrastructure/load-balancers.yaml infrastructure/vpc.yaml services/product-service/service.yaml services/website-service/service.yaml services/springboot-service/service.yaml services/springboot-service1/service.yaml services/springboot-service2/service.yaml infrastructure/rds.json"

for i in $LIST
do
    if test ! -f $i
    then
        echo "error: not found $i"
        exit 1
    fi
    echo $i
    aws --profile $PROFILE s3 cp $i $LOC/$i
done

