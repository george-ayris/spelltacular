aws cloudformation package \
   --template-file template.yaml \
   --output-template-file deploy-template.yaml \
   --s3-bucket spelltacular-deployment
