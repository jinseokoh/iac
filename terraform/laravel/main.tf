variable "do_api_token" {}
variable "fingerprint1" {}
variable "fingerprint2" {}
variable "fingerprint3" {}

## cloud privider
provider "digitalocean" {
  token = "${var.do_api_token}"
}

## firewall
resource "digitalocean_firewall" "api" {
  name = "api"

  droplet_ids = [
    "${digitalocean_droplet.api.id}",
  ]

  inbound_rule = [
    {
      protocol   = "tcp"
      port_range = "22"
    },
    {
      protocol   = "tcp"
      port_range = "80"
    },
    {
      protocol   = "tcp"
      port_range = "443"
    },
  ]
}

## instance
resource "digitalocean_tag" "api" {
  name = "api"
}

resource "digitalocean_droplet" "api" {
  name               = "api01"
  image              = "ubuntu-18-04-x64"
  region             = "sgp1"
  size               = "s-1vcpu-1gb"
  private_networking = true
  monitoring         = true

  tags = [
    "${digitalocean_tag.api.name}",
  ]

  ssh_keys = [
    "${var.fingerprint1}",
    "${var.fingerprint2}",
    "${var.fingerprint3}",
  ]
}

## dns
# resource "digitalocean_domain" "default" {
#   name = "hanlingo.com"
# }

resource "digitalocean_record" "hanlingo" {
  name   = "api"
  type   = "A"
  domain = "hanlingo.com"
  value  = "${digitalocean_droplet.api.ipv4_address}"
}
