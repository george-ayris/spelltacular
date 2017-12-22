./copy_app_files.sh
sam local start-api -t dist/template.yaml --env-vars env_vars.json
