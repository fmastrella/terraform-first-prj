terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

# Set the variable value in *.tfvars file
# or using -var="do_token=..." CLI option
# variable "do_token" {}

# Configure the DigitalOcean Provider
provider "digitalocean" {
  token = var.do_token
}

# Create a new Web Droplet in the nyc2 region
resource "digitalocean_droplet" "jenkins" {
  image    = "ubuntu-22-04-x64"
  name     = "jnks-vm"
  region   = var.region
  size     = "s-2vcpu-2gb"
  ssh_keys = [data.digitalocean_ssh_key.MacBookPro.id]
}

data "digitalocean_ssh_key" "MacBookPro" {
  name = var.ssh_key_name
}

resource "digitalocean_kubernetes_cluster" "k8s" {
  name   = "k8s"
  region = var.region
  # Grab the latest version slug from `doctl kubernetes options versions`
  version = "1.24.8-do.0"

  node_pool {
    name       = "default-node"
    size       = "s-2vcpu-2gb"
    node_count = 2

    # taint {
    #   key    = "workloadKind"
    #   value  = "database"
    #   effect = "NoSchedule"
    # }
  }
}

variable "do_token" {
  default = ""
}

variable "ssh_key_name" {
  default = ""
}

variable "region" {
  default = ""
} 

output "jkns_ip" {
  value = digitalocean_droplet.jenkins.ipv4_address
}

resource "local_file" "kube_config" {
  content = digitalocean_kubernetes_cluster.k8s.kube_config.0.raw_config
  filename = "kube_config.yaml"
}