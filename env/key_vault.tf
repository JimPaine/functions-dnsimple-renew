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

# The Websites Resource Provider doesn't have access to Azure Key Vault
# even when you enabled AKV for template deployment, this adds it.
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
  value     = "${acme_certificate.demo.certificate_p12}"
  key_vault_id = "${azurerm_key_vault.demo.id}"
  content_type = "application/x-pkcs12"
}