# bootstrap peer

export VERSION=${datomic_version}
export DYNAMO_TABLE=${dynamo_table}
export AWS_REGION=${aws_region}
export WGET_USER=${wget_user}
export WGET_PASS=${wget_pass}
echo $DYNAMO_TABLE $VERSION $AWS_REGION
mkdir peer
cd  peer
wget --http-user=$WGET_USER --http-password=$WGET_PASS https://my.datomic.com/repo/com/datomic/datomic-pro/$VERSION/datomic-pro-$VERSION.zip -O datomic-pro-$VERSION.zip
unzip datomic-pro-$VERSION.zip
cd datomic-pro-$VERSION
./bin/rest -p 8080 dev "datomic:ddb://$AWS_REGION/$DYNAMO_TABLE"