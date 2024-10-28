# Passo 1: Instalar o Terraform e o Provedor libvirt
Instale o Terraform: Siga as instruções de instalação para o seu sistema operacional neste link.

Instale o Provedor libvirt:

Para usar o libvirt com o Terraform, você deve ter o libvirt instalado e configurado no Linux. Em um ambiente Ubuntu, por exemplo, você pode instalar com:
```bash

sudo apt-get update
sudo apt-get install -y libvirt-daemon-system libvirt-clients qemu-kvm 
```


Baixe o binário do libvirt-provider para o Terraform e coloque-o na pasta .terraform.d/plugins/ do seu diretório inicial.


# Passo 2: Arquivo de Configuração do Terraform (main.tf)
Aqui está um exemplo básico de código Terraform usando o provedor libvirt para criar uma VM Linux:
```

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
```

Esse código cria uma rede minha_rede com NAT, baixa uma imagem Ubuntu, configura uma máquina virtual (minha_vm) e usa o cloud-init para configurar um usuário SSH chamado terraform. Certifique-se de substituir AAA...SuaChaveSSH... pela sua chave SSH pública.

# Passo 3: Inicializar e Aplicar o Código Terraform
1)Inicialize o Terraform para baixar o provedor:

```
bash
terraform init

```
2)Verifique o plano de execução para conferir o que será criado:
```
bash

terraform plan
```
3)Aplique o plano para criar o ambiente:
```
bash

terraform apply
```
Digite yes para confirmar a criação dos recursos.

Passo 4: Conectar-se à VM
Após a criação, você pode conectar-se à VM usando SSH:
```
bash

ssh terraform@192.168.100.10 
```

# Explicação dos Componentes
libvirt_network: Cria uma rede NAT com o nome minha_rede, permitindo que a VM tenha um endereço IP interno.
libvirt_volume: Baixa uma imagem do Ubuntu e armazena como um volume.
libvirt_domain: Cria a VM com 1 GB de RAM e 1 vCPU, conectada à rede minha_rede.
cloudinit: Usa cloud-init para configurar o usuário SSH, facilitando o acesso à VM.

# Dicas para Uso Prático
Backups e Snapshots: Use snapshots para restaurar o estado de suas VMs rapidamente.
Rede Local: Para comunicação com a rede externa, verifique a configuração NAT ou bridge.
Automatização: Adicione mais VMs e redes, e ajuste as configurações para escalar seu ambiente conforme necessário.
Isso cria um ambiente Linux com rede local, tudo configurado via Terraform em sua infraestrutura própria.


# Próximos Passos
Agora que você revisou o plano e está satisfeito com as ações que o Terraform realizará, você pode aplicar as mudanças. Para isso, execute:
```
bash

terraform apply
```

O Terraform solicitará confirmação antes de proceder. Digite yes para confirmar.

Monitoramento e Verificação
Após a execução do comando terraform apply, você poderá monitorar o progresso e verificar se todas as instâncias foram criadas corretamente. Você pode usar comandos como virsh list --all para verificar o status das VMs criadas.

Problemas Potenciais
Erros de Rede: Se a rede não for configurada corretamente, a VM pode não conseguir obter um endereço IP via DHCP.
Acesso SSH: Certifique-se de que a chave SSH está configurada corretamente para acessar a VM.