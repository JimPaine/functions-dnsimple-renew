# Certificate creation and renewal with Azure PaaS and Terraform

So after lots of pain of having to create web jobs to run in my subscription to handle renewing of my certificates for my web apps and functions I finally came across the Terraform ACME provider, which is awesome. This allows me to register with an acme provider, like Let's Encrypt, create a new certificate and deploy it to Azure Key Vault, from there I can use it to add SSL to my apps which is great.

## Pre-Reqs

- An Azure Service Principal to run Terraform in your CI / CD pipeline [guide](/docs/service_principal_setup.md)
- A storage account to store Terraform remote state [guide](/docs/terraform_remote_state.md)
- Azure DevOps account
- Azure subscription
- An account with a supported DNS provider, for this walkthrough I will use [DNSimple](https://dnsimple.com)

## Step 1.

Fork / Clone / Copy this repository

## In GitHub

![clone](/docs/images/clone.png)

## In DevOps

![import](/docs/images/import.png)

## Step 2.

Next we will create a build pipeline which will be what runs Terraform against our environment.

- Click Pipelines
- Build
- New build pipeline

This should pick up our yaml build definition from our repository. 

- Save
- Edit

### Pipeline Variables

| Name                | Value                                       | Comment                                              |
| ------------------- |:-------------------------------------------:| ---------------------------------------------------- |
| subscription_id     | The Subscription guid                       |                                                      |
| dnsimple_auth_token | Auth token for DNSimple                     |                                                      |
| domain              | The domain to create records against        |                                                      |
| email               | Email address to register acme account with |                                                      |
| hostname            | Full record                                 | if domain was jim.cloud this could be test.jim.cloud |

Both the resource_name and the tf_state_key are set in the azure-pipeline.yml as they are not sensitive and I was happy for this to be public facing in GitHub, feel free to move these into Pipeline variables like the ones above.

- Save
- Queue

## Step 3.

Triggers
