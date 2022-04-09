BRANCH=causal
COMMIT=$(BRANCH)-$(shell git rev-parse HEAD)
DATE=$(shell date +%Y-%m-%d-%H-%M)
NEO_ECR_REPO=476985428237.dkr.ecr.ap-southeast-1.amazonaws.com/neo
NEO_AWS_REGION=ap-southeast-1
.PHONY:
build:
	@ echo "Building image..."
	@ docker build -t neo .

# Use param NEO_ECR_REPO, e.g. NEO_ECR_REPO=xxxxxxxxxxxx.dkr.ecr.us-east-1.amazonaws.com/neo to specify ECR repository
# Use param NEO_AWS_REGION, e.g. NEO_AWS_REGION=us-east-1
.PHONY:
push_image: build
	@ echo "Pushing image based on last commit $(COMMIT)"
	@ export AWS_ACCESS_KEY_ID=$(dev.AWS_ACCESS_KEY_ID)
	@ export AWS_SECRET_ACCESS_KEY=$(dev.AWS_SECRET_ACCESS_KEY)
	@ aws ecr get-login-password --region ap-southeast-1 | docker login --username AWS --password-stdin $(NEO_ECR_REPO)
	@ docker tag neo:latest $(NEO_ECR_REPO):$(COMMIT)
	@ docker tag neo:latest $(NEO_ECR_REPO):$(BRANCH)
	@ docker push $(NEO_ECR_REPO):$(COMMIT)
	@ docker push $(NEO_ECR_REPO):$(BRANCH)
	@ echo "Pushed image $(NEO_ECR_REPO):$(COMMIT)"