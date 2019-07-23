resource "digitalocean_record" "jenkins" {
  domain = "hanlingo.com"
  type   = "A"
  name   = "jenkins"
  value  = "${digitalocean_droplet.jenkins.ipv4_address}"
}
