# fullstack-fargate-api
Example of creating and deploying an API with Docker and Terraform on AWS

## Prerequisites

* Install [Terraform](https://www.terraform.io/downloads.html)
* Install the [AWS CLI](https://aws.amazon.com/cli/)
* Log into your `dev` account (with [`aws sso login`](https://awscli.amazonaws.com/v2/documentation/api/latest/reference/sso/login.html))
* Ensure your account has a [Terraform State S3 Backend](https://github.com/byu-oit/terraform-aws-backend-s3) deployed
* If you're outside the [`byu-oit` GitHub organization](https://github.com/byu-oit), obtain a DivvyCloud username and password from the Cloud Office at cloudoffice@byu.edu

## Setup
* Add yourself (or your team) as a [Dependabot reviewer](https://docs.github.com/en/code-security/supply-chain-security/keeping-your-dependencies-updated-automatically/configuration-options-for-dependency-updates#reviewers) in [`dependabot.yml`](.github/dependabot.yml)
* Commit/push your changes
```
git commit -am "update template with repo specific details" 
git push
```

## Run Locally
There are few ways to run locally:
### docker-compose
This is a good way to run the app server along with any database or other system the app requires.
```shell
# ./
docker-compose up --build
```

This is the most comprehensive way to run locally, but it takes the longest because it needs to build the docker image and compile the typescript code etc.

### npm run dev
This is a good way to quickly make sure the app runs well without docker and without compiling 
```shell
# ./app/
npm ci # or npm install
npm run dev
```

This does not allow you to attach a debugger however

### app-local-debug Run Configuration 
In order to debug locally you will need to run the node application with specific arguments.
You can use the provided run configuration `app-local-debug` in debug mode.

** NOTE ** this run configuration is tracked by git, so don't include any sensitive environment variables in the configuration.

## Deployment

### Deploy the "one time setup" resources

```
cd iac/dev/setup/
terraform init
terraform apply
```

In the AWS Console, see if you can find the resources from `setup.tf` (ECR, SSM Param).

### Enable GitHub Actions on your repo

* Use this [order form](https://it.byu.edu/it?id=sc_cat_item&sys_id=d20809201b2d141069fbbaecdc4bcb84) to give your repo access to the secrets that will let it deploy into your AWS accounts. Fill out the form twice to give access to both your `dev` and `prd` accounts.
* In GitHub, go to the `Actions` tab for your repo (e.g. https://github.com/byu-oit/my-repo/actions)
* Click the `Enable Actions on this repo` button

If you look at [`.github/workflows/deploy.yml`](.github/workflows/deploy.yml), you'll see that it is set up to run on pushes to the `dev` branch. Because you have already pushed to the `dev` branch, this workflow should be running now.

* In GitHub, click on the workflow run (it has the same name as the last commit message you pushed)
* Click on the `Build and Deploy` job
* Expand any of the steps to see what they are doing

### View the deployed application

Anytime after the `Terraform Apply` step succeeds:
```
cd ../app/
terraform init
terraform output
```

This will output a DNS Name. Enter this in a browser. It will probably return `503 Service Unavailable`. It takes some time for the ECS Tasks to spin up and for the ALB to recognize that they are healthy.

In the AWS Console, see if you can find the ECS Service and see the state of its ECS Tasks. Also see if you can find the ALB Target Group, and notice when Tasks are added to it.

> Note:
> 
> While Terraform creates the ECS Service, it doesn't actually spin up any ECS Tasks. This isn't Terraform's job. The ECS Service is responsible for ensuring that ECS Tasks are running.
> 
> Because of this, if the ECS Tasks fail to launch (due to bugs in the code causing the docker container to crash, for example), Terraform won't know anything about that. From Terraform's perspective, the deployment was successful.
> 
> These type of issues can often be tracked down by finding the Stopped ECS Tasks in the ECS Console, and looking at their logs or their container status.

Once the Tasks are running, you should be able to hit the app's URL and get a JSON response. Between `index.js` and `main.tf`, can you find what pieces are necessary to make this data available to the app?

In the AWS Console, see if you can find the other resources from `main.tf`.

### Push a change to your application

Make a small change to `index.ts` (try adding a `console.log`, a simple key/value pair to the JSON response, or a new path). Commit and push this change to the `dev` branch.

```
git commit -am "try deploying a change"
git push
```

In GitHub Actions, watch the deploy steps run (you have a new push, so you'll have to go back and select the new workflow run instance and the job again). Once it gets to the CodeDeploy step, you can watch the deploy happen in the CodeDeploy console in AWS. Once CodeDeploy says that production traffic has been switched over, hit your application in the browser and see if your change worked. If the service is broken, look at the stopped ECS Tasks in the ECS Console to see if you can figure out why.

> Note: 
>
> It's always best to test your changes locally before pushing to GitHub and AWS.
> Testing locally will significantly increase your productivity as you won't be constantly waiting for GitHub Actions and CodeDeploy to deploy, just to discover bugs.
> See the [Run Locally](#run-locally) section.

## Learn what was built

By digging through the `.tf` files, you'll see what resources are being created. You should spend some time searching through the AWS Console for each of these resources. The goal is to start making connections between the Terraform syntax and the actual AWS resources that are created.

Several OIT created Terraform modules are used. You can look these modules up in our GitHub Organization. There you can see what resources each of these modules creates. You can look those up in the AWS Console too.

## Deployment details

There are a lot of moving parts in the CI/CD pipeline for this project. This diagram shows the interaction between various services during a deployment.

![CI/CD Sequence Diagram](doc/Fargate%20API%20CI%20CD.png)


## Implement Database
<!-- TODO would this info make more sense to live in the fullstack-developer-handbook? -->
This template does _not_ include code nor terraform configuration for any database.
You will need to include some terraform infrastructure as well as some code dependencies in order to take advantage of a database.

### Setup Relational Database - RDS
See the [RDS Setup instructions in the full stack handbook](https://improved-barnacle-1bd884d5.pages.github.io/reference/general/database-rds.html#setup)

### Setup No-SQL Database - DynamoDB
See the [DynamoDB Setup instructions in the full stack handbook](https://improved-barnacle-1bd884d5.pages.github.io/reference/general/database-dynamo.html#setup)
