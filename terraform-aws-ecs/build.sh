# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ecs_cluster

terraform version
if [ $? != "0" ]; then exit $?; fi

terraform fmt
terraform get
terraform graph 

import [options] ADDRESS ID
output
plan
push
refresh

remote

show

state


terraform workspace list 

export WKSPC=dev
echo "aws_access_key = \"$CCIE_AWS_ACCESS_KEY\"" >> terraform.tfvars
echo "aws_secret_key = \"$CCIE_AWS_SECRET_KEY\"" >> terraform.tfvars

terraform workspace select $WKSPC || terraform workspace new $WKSPC

mkdir -p plans

terraform plan -var-file=dev.tfvars -input=false -out=plans/tfm.plan

terraform apply "plans/tfm.plan"

aws sts decode-authorization-message --encoded-message \
MTHzWnYT0PrNrPWJwLz4Lubbpb0zWXrGy5X6rr9_GU7WNR17TjjCy3Rs6SYUBzf_kpELHr46ktmvH4c5iBXF_ANsZzoubuqb0EUooozYVRw42mm9bUhRscA5O3y9Kar4Rbn0De5QR2_SaqAHCaEsh8hJsi5556SFV-SoF18Ss4KIPfUku1q1AuoqZLECgY1EfWZSQz3xxd_nb81AaSYRmt4cBgSLHXPZE1dsOwRPHg_yELbLVmGHKXZRv1SjOWEoYeEfIneMpZAebGX1wtYBhmGKUUhLmI6X79GETwMoXJrkaWfBM0jpN3h11IQbGCDz4MZTQLPyvLeQ5ww4f04pAHmV9QFgSyq3R-aYpQEadT6JmYJUtrg3LA_y4wNHvDTVMj5OGBUqHxxRiPFYvsz88_ogy83XMl4iU2HdhcGvPnhWbbk4CiheEX9NguZMPoaVxZgLy4e7DomXd9VIUnOxRQYAbGDRmd7dMBSvLGhjsMApKSAzsbRG3h5MdqHXm5RuC3JRjKWe1YrptWfCMOxuaAay0ODw0kj55Hkvl4sAuRw80Y5EYFBnIpvhsTW8OvYWRQTCMu_KPYB9g16-Yrw_WOwIEnhNIyLKhdcqoI0mHpWW48W23j22OOyJvfDsyEypXFXrToLQCt7PvcBIKMvY4RKHIz1wmqc_0xMCI3Pai45LkunfRQ4Nrtys8ANco31YYDfJv8q4JS6FN8nMWy9BWrpE5VPYV9t84FeIJ1XzDBMhONPlLgQUP0OUUOPEXJMzARnCOqy-Ag7Mxieto05kMk7mqBrsn2Qak2JtJrxItZaAj0LXUPNfXzJa4r5Zfw1LOqHiBVjd5MhVdk3FPe5fIWk4e4a1M1hemqeBtW8aWhhVRfU0IXGHPw_iXXezYDwib-_CMiB1ApEaMFN_88hJj6WGmx7LVLtHufbxD60yIJeI8X1Tzn-KT9xNkwzHUGgZ

aws iam create-instance-profile --instance-profile-name DAMO-Cluster-instance-profile
aws iam delete-instance-profile --instance-profile-name DAMO-Cluster-instance-profile
aws iam list-instance-profiles-for-role --role-name DAMO-Cluster-instance-role

terraform destroy -var-file=dev.tfvars -input=false