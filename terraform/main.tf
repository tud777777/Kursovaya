terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}

provider "yandex" {
  zone = ""
}

resource "yandex_vpc_network" "network-1" {
  name = var.network-1
}

resource "yandex_vpc_subnet" "subnet-public" {
  network_id     = yandex_vpc_network.network-1.id
  name           = "subnet-public"
  v4_cidr_blocks = var.subnet_v4-1
  zone = var.zone-a
}

resource "yandex_vpc_subnet" "subnet-private-a" {
  network_id     = yandex_vpc_network.network-1.id
  name           = "subnet-private-a"
  v4_cidr_blocks = var.subnet_v4-2
  zone = var.zone-a
}

resource "yandex_vpc_subnet" "subnet-private-b" {
  network_id     = yandex_vpc_network.network-1.id
  name           = "subnet-private-b"
  v4_cidr_blocks = var.subnet_v4-3
  zone = var.zone-b
}

resource "yandex_compute_instance" "bastion" {
  name = "bastion"
  platform_id = "standard-v3"
  zone = var.zone-a
  boot_disk {
    initialize_params {
      image_id = "fd8j0uq7qcvtb65fbffl"
      size = "10"
      type = "network-hdd"
    }
  }
  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-private-a.id
    nat = true
    security_group_ids  = [yandex_vpc_security_group.bastion_sg.id]
  }
  resources {
    cores = 2
    core_fraction = 20
    memory = 2
  }
  metadata = {
    serial-port-enable = "true"
    user-data = "${file("cloud_config.yaml")}"
  }
}

resource "yandex_compute_instance" "web-1" {
  name = "web-1"
  platform_id = "standard-v3"
  zone = var.zone-a
  boot_disk {
    initialize_params {
      image_id = "fd8j0uq7qcvtb65fbffl"
      size = "10"
      type = "network-hdd"
    }
  }
  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-private-a.id
    security_group_ids  = [yandex_vpc_security_group.web_sg.id]
  }
  resources {
    cores = 2
    core_fraction = 20
    memory = 2
  }
  metadata = {
    serial-port-enable = "true"
    user-data = "${file("cloud_config.yaml")}"
  }
}

resource "yandex_compute_instance" "web-2" {
  name = "web-2"
  platform_id = "standard-v3"
  zone = var.zone-b
  boot_disk {
    initialize_params {
      image_id = "fd8j0uq7qcvtb65fbffl"
      size = "10"
      type = "network-hdd"
    }
  }
  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-private-b.id
    security_group_ids  = [yandex_vpc_security_group.web_sg.id]
  }
  resources {
    cores = 2
    core_fraction = 20
    memory = 2
  }
  metadata = {
    serial-port-enable = "true"
    user-data = "${file("cloud_config.yaml")}"
  }
}

resource "yandex_compute_instance" "prometheus" {
  name = "prometheus"
  platform_id = "standard-v3"
  zone = var.zone-a
  boot_disk {
    initialize_params {
      image_id = "fd8j0uq7qcvtb65fbffl"
      size = "10"
      type = "network-hdd"
    }
  }
  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-private-a.id
    security_group_ids  = [yandex_vpc_security_group.prometheus_sg.id]
  }
  resources {
    cores = 2
    core_fraction = 20
    memory = 2
  }
  metadata = {
    serial-port-enable = "true"
    user-data = "${file("cloud_config.yaml")}"
  }
}

resource "yandex_compute_instance" "grafana" {
  name = "grafana"
  platform_id = "standard-v3"
  zone = var.zone-a
  boot_disk {
    initialize_params {
      image_id = "fd8j0uq7qcvtb65fbffl"
      size = "12"
      type = "network-hdd"
    }
  }
  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-public.id
    nat = true
    security_group_ids  = [yandex_vpc_security_group.grafana_sg.id]
  }
  resources {
    cores = 2
    core_fraction = 20
    memory = 3
  }
  metadata = {
    serial-port-enable = "true"
    user-data = "${file("cloud_config.yaml")}"
  }
}

resource "yandex_compute_instance" "elasticsearch" {
  name = "elasticsearch"
  platform_id = "standard-v3"
  zone = var.zone-a
  boot_disk {
    initialize_params {
      image_id = "fd8j0uq7qcvtb65fbffl"
      size = "10"
      type = "network-hdd"
    }
  }
  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-private-a.id
    security_group_ids  = [yandex_vpc_security_group.elasticsearch_sg.id]
  }
  resources {
    cores = 2
    core_fraction = 20
    memory = 2
  }
  metadata = {
    serial-port-enable = "true"
    user-data = "${file("cloud_config.yaml")}"
  }
}

resource "yandex_compute_instance" "kibana" {
  name = "kibana"
  platform_id = "standard-v3"
  zone = var.zone-a
  boot_disk {
    initialize_params {
      image_id = "fd8j0uq7qcvtb65fbffl"
      size = "10"
      type = "network-hdd"
    }
  }
  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-public.id
    nat = true
    security_group_ids  = [yandex_vpc_security_group.kibana_sg.id]
  }
  resources {
    cores = 2
    core_fraction = 20
    memory = 2
  }
  metadata = {
    serial-port-enable = "true"
    user-data = "${file("cloud_config.yaml")}"
  }
}


resource "yandex_alb_target_group" "web_group" {
  name = "web-group1"

  target {
    subnet_id = "${yandex_vpc_subnet.subnet-private-a.id}"
    ip_address   = "${yandex_compute_instance.web-1.network_interface.0.ip_address}"
  }

  target {
    subnet_id = "${yandex_vpc_subnet.subnet-private-b.id}"
    ip_address   = "${yandex_compute_instance.web-2.network_interface.0.ip_address}"
  }
}

resource "yandex_alb_backend_group" "backend-group" {
  name      = "backend-group"

  http_backend {
    name = "http-backend"
    port = 80
    target_group_ids = ["${yandex_alb_target_group.web_group.id}"] 
    healthcheck {
      timeout = "1s"
      interval = "1s"
      healthcheck_port = 80
      http_healthcheck {
        path  = "/"
      }
    }
  }
}

resource "yandex_alb_http_router" "http-router" {
  name      = "http-router"
}

resource "yandex_alb_virtual_host" "canary-vh-production" {
  name           = "canary-vh-production"
  http_router_id = "${yandex_alb_http_router.http-router.id}"

  route {
    name = "canary-route-production"
    http_route {
      http_route_action {
        backend_group_id = "${yandex_alb_backend_group.backend-group.id}"
      }
    }
  }  
}

resource "yandex_alb_load_balancer" "load-balancer" {
  name        = "load-balancer"

  network_id  = yandex_vpc_network.network-1.id
  
  allocation_policy {
    location {
      zone_id   = "ru-central1-a"
      subnet_id = "${yandex_vpc_subnet.subnet-private-a.id}" 
    }
    location {
      zone_id   = "ru-central1-b"
      subnet_id = "${yandex_vpc_subnet.subnet-private-b.id}"
    }
  }
  
  listener {
    name = "listener"
    endpoint {
      address {
        external_ipv4_address {
          
        }
      }
      ports = [ 80 ]
    }    
    http {
      handler {
        http_router_id = "${yandex_alb_http_router.http-router.id}"
      }
    }
  }
}

resource "yandex_vpc_security_group" "bastion_sg" {
  name        = "bastion-sg"
  network_id  = yandex_vpc_network.network-1.id

  ingress {
    description = "Allow SSH"
    protocol    = "TCP"
    port        = 22
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all egress"
    protocol    = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_vpc_security_group" "web_sg" {
  name        = "web-sg"
  network_id  = yandex_vpc_network.network-1.id

  ingress {
    description = "Allow HTTP"
    protocol    = "TCP"
    port        = 80
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all egress"
    protocol    = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_vpc_security_group" "prometheus_sg" {
  name        = "prometheus-sg"
  network_id  = yandex_vpc_network.network-1.id

  ingress {
    description = "Allow Prometheus"
    protocol    = "TCP"
    port        = 9090
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all egress"
    protocol    = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_vpc_security_group" "grafana_sg" {
  name        = "grafana-sg"
  network_id  = yandex_vpc_network.network-1.id

  ingress {
    description = "Allow Grafana"
    protocol    = "TCP"
    port        = 3000
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all egress"
    protocol    = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_vpc_security_group" "kibana_sg" {
  name        = "kibana-sg"
  network_id  = yandex_vpc_network.network-1.id

  ingress {
    description = "Allow Kibana"
    protocol    = "TCP"
    port        = 5601
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all egress"
    protocol    = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_vpc_security_group" "elasticsearch_sg" {
  name        = "elasticsearch-sg"
  network_id  = yandex_vpc_network.network-1.id

  ingress {
    description = "Allow Elasticsearch"
    protocol    = "TCP"
    port        = 9200
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all egress"
    protocol    = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}


output "ip_web-1" {
  value = yandex_compute_instance.web-1.network_interface.0.nat_ip_address 
}
output "ip_web-2" {
  value = yandex_compute_instance.web-2.network_interface.0.nat_ip_address 
}
output "ip_prometheus" {
  value = yandex_compute_instance.prometheus.network_interface.0.nat_ip_address 
}
output "ip_grafana" {
  value = yandex_compute_instance.grafana.network_interface.0.nat_ip_address 
}
output "ip_elasticsearch" {
  value = yandex_compute_instance.elasticsearch.network_interface.0.nat_ip_address 
}
output "ip_kibana" {
  value = yandex_compute_instance.kibana.network_interface.0.nat_ip_address 
}
