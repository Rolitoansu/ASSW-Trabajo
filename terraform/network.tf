resource "openstack_networking_network_v2" "private_net" {
  name           = "app-private-net"
  admin_state_up = "true"
}

resource "openstack_networking_subnet_v2" "private_subnet" {
  name       = "app-private-subnet"
  network_id = openstack_networking_network_v2.private_net.id
  cidr       = "10.0.10.0/24"
  ip_version = 4
}

data "openstack_networking_network_v2" "ext_net" {
  name = "public"
}

resource "openstack_networking_router_v2" "app_router" {
  name                = "app-router"
  external_network_id = data.openstack_networking_network_v2.ext_net.id
}

resource "openstack_networking_router_interface_v2" "router_interface" {
  router_id = openstack_networking_router_v2.app_router.id
  subnet_id = openstack_networking_subnet_v2.private_subnet.id
}

resource "openstack_compute_secgroup_v2" "sg_waf" {
  name        = "waf-secgroup"
  description = "Permitir HTTP, HTTPS y SSH desde exterior"

  rule {
    from_port   = 22
    to_port     = 22
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }
  rule {
    from_port   = 80
    to_port     = 80
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }
  rule {
    from_port   = 443
    to_port     = 443
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }
}

resource "openstack_compute_secgroup_v2" "sg_internal" {
  name        = "internal-secgroup"
  description = "Permitir trafico solo desde la red privada"

  rule {
    from_port   = 1
    to_port     = 65535
    ip_protocol = "tcp"
    cidr        = "10.0.10.0/24"
  }
}
