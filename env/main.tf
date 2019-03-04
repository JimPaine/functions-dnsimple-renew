resource "tls_private_key" "private_key" {
  algorithm = "RSA"
}

resource "acme_registration" "demo" {
  account_key_pem = "${tls_private_key.private_key.private_key_pem}"
  email_address   = "${var.email}"
}


resource "dnsimple_record" "demo" {
  domain = "${var.domain}"
  name   = "cert"
  value  = "${azurerm_function_app.demo.default_hostname}"
  type   = "CNAME"
  ttl    = 3600

  provisioner "local-exec" {
    command = "sleep 30s"
  }
}

resource "acme_certificate" "demo" {
  account_key_pem           = "${acme_registration.demo.account_key_pem}"
  common_name               = "${dnsimple_record.demo.hostname}"

  dns_challenge {
    provider = "dnsimple"

    config {
        DNSIMPLE_OAUTH_TOKEN = "${var.dnsimple_auth_token}"
    }    
  }
}

resource "azurerm_resource_group" "demo" {
  name     = "${var.resource_name}"
  location = "westeurope"
}

resource "random_id" "demo" {
  keepers = {
    # Generate a new ID only when a new resource group is defined
    resource_group = "${azurerm_resource_group.demo.name}"
  }

  byte_length = 2
}


resource "azurerm_storage_account" "demo" {
  name                     = "${var.resource_name}${random_id.demo.dec}store"
  resource_group_name      = "${azurerm_resource_group.demo.name}"
  location                 = "${azurerm_resource_group.demo.location}"
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_app_service_plan" "demo" {
  name                = "${var.resource_name}${random_id.demo.dec}plan"
  location            = "${azurerm_resource_group.demo.location}"
  resource_group_name = "${azurerm_resource_group.demo.name}"
  kind                = "FunctionApp"

  sku {
    tier = "Dynamic"
    size = "Y1"
  }
}

resource "azurerm_function_app" "demo" {
  name                      = "${var.resource_name}${random_id.demo.dec}"
  location                  = "${azurerm_resource_group.demo.location}"
  resource_group_name       = "${azurerm_resource_group.demo.name}"
  app_service_plan_id       = "${azurerm_app_service_plan.demo.id}"
  storage_connection_string = "${azurerm_storage_account.demo.primary_connection_string}"

  https_only = true

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_app_service_custom_hostname_binding" "demo" {
  hostname            = "${var.hostname}"
  app_service_name    = "${azurerm_function_app.demo.name}"
  resource_group_name = "${azurerm_resource_group.demo.name}"
}

data "azurerm_client_config" "demo" {}

resource "azurerm_key_vault" "demo" {
  name                = "${var.resource_name}${random_id.demo.dec}vault"
  location            = "${azurerm_resource_group.demo.location}"
  resource_group_name = "${azurerm_resource_group.demo.name}"
  tenant_id           = "${data.azurerm_client_config.demo.tenant_id}"
  
  enabled_for_template_deployment = true

  sku {
    name = "standard"
  }
}

resource "azurerm_key_vault_access_policy" "terraformclient" {
  vault_name          = "${azurerm_key_vault.demo.name}"
  resource_group_name = "${azurerm_key_vault.demo.resource_group_name}"

  tenant_id = "${data.azurerm_client_config.demo.tenant_id}"
  object_id = "${data.azurerm_client_config.demo.service_principal_object_id}"

  key_permissions = []

  secret_permissions = [
      "list",
      "set",
      "get",
    ]
}

data "azuread_service_principal" "arm" {
  application_id = "abfa0a7c-a6b6-4736-8310-5855508787cd"
}

resource "azurerm_key_vault_access_policy" "app" {
  vault_name          = "${azurerm_key_vault.demo.name}"
  resource_group_name = "${azurerm_key_vault.demo.resource_group_name}"

  tenant_id = "${data.azurerm_client_config.demo.tenant_id}"
  object_id = "${data.azuread_service_principal.arm.id}"

  key_permissions = []

  secret_permissions = [
      "list",
      "get",
    ]
}

resource "azurerm_key_vault_secret" "cert" {
  name      = "cert"
  value     = "${acme_certificate.demo.certificate_p12}=="
  key_vault_id = "${azurerm_key_vault.demo.id}"
  content_type = "application/x-pkcs12"
}

resource "azurerm_template_deployment" "demo" {
  name                = "${var.resource_name}${random_id.demo.dec}cert"
  resource_group_name = "${azurerm_resource_group.demo.name}"

  template_body = <<DEPLOY
    {
        "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
        "contentVersion": "1.0.0.0",
        "parameters" : {
            "certificateName" : {
                "type": "string"
            },
            "existingAppLocation" : {
                "type": "string"
            },
            "existingKeyVaultId" : {
                "type": "string"
            },
            "existingKeyVaultSecretName" : {
                "type": "string"
            },
            "existingServerFarmId" : {
                "type": "string"
            },
            "existingWebAppName" : {
                "type": "string"
            },
            "hostname" : {
                "type": "string"
            }            
        },
        "resources": [
        {
            "type": "Microsoft.Web/certificates",
            "name": "[parameters('certificateName')]",
            "apiVersion": "2016-03-01",
            "location": "[parameters('existingAppLocation')]",
            "properties": {
                "keyVaultId": "[parameters('existingKeyVaultId')]",
                "keyVaultSecretName": "[parameters('existingKeyVaultSecretName')]",
                "serverFarmId": "[parameters('existingServerFarmId')]"
            }
        },
        {
            "type": "Microsoft.Web/sites",
            "name": "[parameters('existingWebAppName')]",
            "apiVersion": "2016-03-01",
            "location": "[parameters('existingAppLocation')]",
            "dependsOn": [
                "[resourceId('Microsoft.Web/certificates', parameters('certificateName'))]"
            ],
            "properties": {
                "name": "[parameters('existingWebAppName')]",
                "hostNameSslStates": [
                {
                    "name": "[parameters('hostname')]",
                    "sslState": "SniEnabled",
                    "thumbprint": "[reference(resourceId('Microsoft.Web/certificates', parameters('certificateName'))).Thumbprint]",
                    "toUpdate": true
                }
                ]
            }
        }
    ]
}
DEPLOY

  parameters {
      "certificateName" = "${var.hostname}"
      "existingAppLocation" = "${azurerm_resource_group.demo.location}"
      "existingKeyVaultId" = "${azurerm_key_vault.demo.id}"
      "existingKeyVaultSecretName" = "${azurerm_key_vault_secret.cert.name}"
      "existingServerFarmId" = "${azurerm_app_service_plan.demo.id}"
      "existingWebAppName" = "${azurerm_function_app.demo.name}"
      "hostname" = "${azurerm_app_service_custom_hostname_binding.demo.hostname}"
  }

  deployment_mode = "Incremental"
}
