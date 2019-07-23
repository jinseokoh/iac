resource "digitalocean_droplet" "jenkins" {
  image              = "ubuntu-18-04-x64"
  name               = "jenkins"
  region             = "sgp1"
  size               = "s-1vcpu-1gb"
  private_networking = true
  monitoring         = true
  user_data          = "${file("config/jenkins-userdata.sh")}"

  ssh_keys = [
    "${var.ssh_fingerprint}",
  ]

  connection {
    user        = "root"
    type        = "ssh"
    private_key = "${file(var.pvt_key)}"
    timeout     = "2m"
  }
}
