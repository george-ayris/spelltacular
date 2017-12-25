aws cloudformation deploy \
   --template-file deploy-template.yaml \
   --stack-name spelltacular-api \
   --capabilities CAPABILITY_IAM \
   --parameter-overrides PostgresConnectionString="$(cat ../database/aws_postgres_connection_string.txt)"
   
