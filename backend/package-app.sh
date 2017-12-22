rm -rf dist
mkdir dist
cp -r app/* dist 
rsync --exclude='pip*' --exclude='setuptools*' --exclude='easy_install.py' --exclude='psycopg2*' -r env/lib/python3.6/site-packages/* dist
cp -r lambda-compiled-libs/ dist
aws cloudformation package \
   --template-file dist/template.yaml \
   --output-template-file deploy-template.yaml \
   --s3-bucket spelltacular-deployment
