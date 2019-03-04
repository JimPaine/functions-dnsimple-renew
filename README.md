# Certificate creation and renewal with Azure PaaS and Terraform

So after lots of pain of having to create web jobs to run in my subscription to handle renewing of my certificates for my web apps and functions I finally came across the Terraform ACME provider, which is awesome. This allows me to register with an acme provider, like Let's Encrypt, create a new certificate and deploy it to Azure Key Vault, from there I can use it to add SSL to my apps which is great.

Write up coming soon!
