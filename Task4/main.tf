terraform {
  required_providers {
    yandex = {
        source = "yandex-cloud/yandex"
    }
    ansible = {
        source = "ansible/ansible"
    }
  }
}

variable "public_key_path" {
  default = "~/.ssh/rsa_terraform.pub"
}

variable "yandex_cloud_token" {
    type = string
    description = "Please enter your 0Auth token"
}

provider "yandex" {
  token = var.yandex_cloud_token
  cloud_id = "b1g9buch9n733l8f1n53"
  folder_id = "b1g2pn3mjr53ojse3crm"
  zone = "ru-central1-b"
}

resource "yandex_compute_instance" "vm" {
  count = 2

  name = "balanetvm${count.index}"
  boot_disk {
    initialize_params {
        image_id = "fd8epq5qp2v73a23oir4"
        size = 10
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet1.id
    nat = true
  }

  resources {
    core_fraction = 5
    cores = 2
    memory = 2
  }

  metadata = { 
    ssh-keys = var.public_key_path
    user-data = "${file("metadata.yml")}"
  }
}

resource "yandex_vpc_network" "network1" {
  name = "network1"
}

resource "yandex_vpc_subnet" "subnet1" {
  name = "subnet1"
  network_id = yandex_vpc_network.network1.id
  v4_cidr_blocks = [ "172.24.20.0/24" ]
}

resource "yandex_lb_target_group" "group1" {
  name = "group1"

  dynamic "target" {
    for_each = yandex_compute_instance.vm
    content {
        subnet_id = yandex_vpc_subnet.subnet1.id
        address = target.value.network_interface.0.ip_address
    }
  }
}

resource "yandex_lb_network_load_balancer" "balancer1" {
    name = "balancer1"
    deletion_protection = "false"
    listener {
        name = "listener1"
        port = 80
        external_address_spec {
            ip_version = "ipv4"
        }
    }

    attached_target_group {
        target_group_id = yandex_lb_target_group.group1.id
        healthcheck {
            name = "http"
            http_options {
                port = 80
                path = "/"
            }
        }
    }
}

resource "ansible_host" "vm" {
    count = length(yandex_compute_instance.vm)

    name = "vm${count.index}"
    groups = ["nginx"]
    variables = {
        ansible_host = yandex_compute_instance.vm[count.index].network_interface.0.nat_ip_address
    } 
}
