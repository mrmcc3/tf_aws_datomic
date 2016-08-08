exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

export XMX=${xmx}
export JAVA_OPTS=${java_opts}
export DATOMIC_DEPLOY_BUCKET=${datomic_bucket}
export DATOMIC_VERSION=${datomic_version}

cd /datomic

cat <<EOF >aws.properties
host=`curl http://169.254.169.254/latest/meta-data/local-ipv4`
alt-host=`curl http://169.254.169.254/latest/meta-data/public-ipv4`
aws-cloudwatch-region=${aws_region}
aws-dynamodb-region=${aws_region}
aws-transactor-role=${transactor_role}
aws-peer-role=${peer_role}
protocol=ddb
memory-index-max=${memory_index_max}
aws-s3-log-bucket-id=${s3_log_bucket}
port=4334
memory-index-threshold=${memory_index_threshold}
aws-cloudwatch-dimension-value=${cloudwatch_dimension}
object-cache-max=${object_cache_max}
license-key=${license-key}
aws-dynamodb-table=${dynamo_table}
EOF
chmod 744 aws.properties

AWS_ACCESS_KEY_ID="$${DATOMIC_READ_DEPLOY_ACCESS_KEY_ID}" AWS_SECRET_ACCESS_KEY="$${DATOMIC_READ_DEPLOY_AWS_SECRET_KEY}" aws s3 cp "s3://$${DATOMIC_DEPLOY_BUCKET}/$${DATOMIC_VERSION}/startup.sh" startup.sh
chmod 500 startup.sh
./startup.sh
