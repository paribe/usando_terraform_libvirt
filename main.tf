# main.tf

# Define o provedor libvirt
terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.6.12"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

# Defina a rede
resource "libvirt_network" "network1" {
  name   = "minha_rede"
  mode   = "nat"           # Rede NAT (ou "bridge" se precisar de comunicação externa direta)
  domain = "minha_rede.local"

  addresses = ["192.168.100.0/24"]
}

# Baixe uma imagem base do Ubuntu
resource "libvirt_volume" "ubuntu_image" {
  name = "ubuntu20.04"
  pool = "default"
  source = "https://cloud-images.ubuntu.com/releases/20.04/release/ubuntu-20.04-server-cloudimg-amd64.img"
  format = "qcow2"
}

# Crie a máquina virtual
resource "libvirt_domain" "vm1" {
  name   = "minha_vm"
  memory = "1024"
  vcpu   = 1

  network_interface {
    network_name = libvirt_network.network1.name
    addresses    = ["192.168.100.10"]
  }

  disk {
    volume_id = libvirt_volume.ubuntu_image.id
  }

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  # Configuração da inicialização em nuvem (cloud-init)
  cloudinit = libvirt_cloudinit_disk.common.id
}

resource "libvirt_cloudinit_disk" "common" {
  name           = "commoninit.iso"
  user_data      = data.template_cloudinit_config.config.rendered
  network_config = <<EOF
version: 2
ethernets:
  eth0:
    dhcp4: true
EOF
}

# Defina as configurações do Cloud-init (usuário e senha)
data "template_cloudinit_config" "config" {
  gzip          = false
  base64_encode = false

  part {
    content_type = "text/cloud-config"
    content = <<EOF
#cloud-config
users:
  - name: terraform
    sudo: ["ALL=(ALL) NOPASSWD:ALL"]
    shell: /bin/bash
    ssh_authorized_keys:
      - ssh-rsa AAA...SuaChaveSSH...
EOF
  }
}