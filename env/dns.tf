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