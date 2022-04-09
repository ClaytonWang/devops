terraform init
terraform plan -var-file=dev.tfvars -input=false -out=tfm.plan
terraform apply "tfm.plan"