# Setting up a Service Principal

Creating a Service Principal for use with Terraform and Azure DevOps Pipelines

## Step 1. Create Application in Azure AD

## Step 2. (Optional) Add required permissions to create service prinicpals

In scenarios like when creating AKS clusters you will need your Terraform client to be able to create and add service prinicpals in your tenant. 

## Variable Group - Terraform Service Principal

Create a new variable group with the below:

| Name                        | Value          | Comment       |
| --------------------------- |:--------------:| ------------- |
| client_id                   | Variable Group |  |
| client_secret |
| tenant_id |