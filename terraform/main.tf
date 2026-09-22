locals {
  config  = jsondecode(file("${path.module}/config.json"))
  waf_fip = local.config.waf_floating_ip
}

data "openstack_images_image_v2" "ubuntu" {
  name        = "Ubuntu-26.04"
  most_recent = true
}

data "openstack_compute_flavor_v2" "small" {
  name = "ephym_small_2"
}

variable "ssh_public_key_path" {
  type = string
}

variable "ssh_user" {
  type    = string
  default = "ubuntu"
}

variable "public_network_name" {
  type        = string
  description = "Nombre de la red externa o pool de IPs flotantes"
  default     = "public"
}

resource "openstack_compute_keypair_v2" "app_key" {
  name       = "infra-segura-key"
  public_key = file(var.ssh_public_key_path)
}

# --- DEFINICIÓN DE MÁQUINAS ---

variable "vms_batch_1" {
  description = "Primer lote de despliegue (2 MVs)"
  type = map(object({
    name           = string
    security_group = string
  }))
  default = {
    waf = {
      name           = "waf-perimetral"
      security_group = "waf"
    }
    front = {
      name           = "frontend"
      security_group = "internal"
    }
  }
}

variable "vms_batch_2" {
  description = "Segundo lote de despliegue (3 MVs)"
  type = map(object({
    name           = string
    security_group = string
  }))
  default = {
    proxy1 = {
      name           = "proxy-interno-1"
      security_group = "internal"
    }
    back = {
      name           = "backend"
      security_group = "internal"
    }
    proxy2 = {
      name           = "proxy-interno-2"
      security_group = "internal"
    }
  }
}

# --- LOTE 1 (2 máquinas) ---

resource "openstack_compute_instance_v2" "app_batch_1" {
  for_each = var.vms_batch_1

  name      = each.value.name
  image_id  = data.openstack_images_image_v2.ubuntu.id
  flavor_id = data.openstack_compute_flavor_v2.small.id
  key_pair  = openstack_compute_keypair_v2.app_key.name
  user_data = local.common_user_data

  security_groups = [
    each.value.security_group == "waf"
    ? openstack_compute_secgroup_v2.sg_waf.name
    : openstack_compute_secgroup_v2.sg_internal.name
  ]

  network {
    uuid = openstack_networking_network_v2.private_net.id
  }

  depends_on = [
    openstack_networking_subnet_v2.private_subnet
  ]
}

# --- LOTE 2 (3 máquinas) ---

resource "openstack_compute_instance_v2" "app_batch_2" {
  for_each = var.vms_batch_2

  name      = each.value.name
  image_id  = data.openstack_images_image_v2.ubuntu.id
  flavor_id = data.openstack_compute_flavor_v2.small.id
  key_pair  = openstack_compute_keypair_v2.app_key.name
  user_data = local.common_user_data

  security_groups = [
    each.value.security_group == "waf"
    ? openstack_compute_secgroup_v2.sg_waf.name
    : openstack_compute_secgroup_v2.sg_internal.name
  ]

  network {
    uuid = openstack_networking_network_v2.private_net.id
  }

  depends_on = [
    openstack_networking_subnet_v2.private_subnet,
    openstack_compute_instance_v2.app_batch_1
  ]
}

# --- ASOCIACIÓN DE IP FLOTANTE ---

resource "openstack_compute_floatingip_associate_v2" "fip_waf_assoc" {
  floating_ip = local.waf_fip
  instance_id = openstack_compute_instance_v2.app_batch_1["waf"].id
}

# --- INVENTARIO DE ANSIBLE ---

resource "local_file" "inventory" {
  content = templatefile("${path.module}/templates/inventory.tpl", {
    waf_fip   = local.waf_fip
    ip_front  = openstack_compute_instance_v2.app_batch_1["front"].network[0].fixed_ip_v4
    ip_proxy1 = openstack_compute_instance_v2.app_batch_2["proxy1"].network[0].fixed_ip_v4
    ip_back   = openstack_compute_instance_v2.app_batch_2["back"].network[0].fixed_ip_v4
    ip_proxy2 = openstack_compute_instance_v2.app_batch_2["proxy2"].network[0].fixed_ip_v4
    ssh_user  = var.ssh_user
  })
  filename = "${path.module}/../ansible/inventory.ini"
}