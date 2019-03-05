resource "tls_private_key" "private_key" {
  algorithm = "RSA"
}

resource "acme_registration" "demo" {
  account_key_pem = "${tls_private_key.private_key.private_key_pem}"
  email_address   = "${var.email}"
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