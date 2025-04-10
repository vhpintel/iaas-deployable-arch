locals {
    BASENAME = "iaas-spr-2"
    ZONE     = "us-east-2"
}

resource "ibm_is_vpc" "vpc" {
    name = "${local.BASENAME}-vpc-${random_string.suffix.result}"
}

resource "random_string" "suffix" {
  length  = 3
  special = false
  upper   = false
}
resource "ibm_is_security_group" "sg1" {
    name = "${local.BASENAME}-sg1"
    vpc  = ibm_is_vpc.vpc.id
}

# allow all incoming network traffic on port 22
resource "ibm_is_security_group_rule" "ingress_ssh_all" {
    group     = ibm_is_security_group.sg1.id
    direction = "inbound"
    remote    = "0.0.0.0/0"

    tcp {
      port_min = 22
      port_max = 22
    }
}

# Allow all outbound traffic
resource "ibm_is_security_group_rule" "egress_all" {
  group     = ibm_is_security_group.sg1.id
  direction = "outbound"
  remote    = "0.0.0.0/0"

  tcp {
    port_min = 1
    port_max = 65535
  }
}

# Allow DNS resolution (UDP 53)
resource "ibm_is_security_group_rule" "egress_dns" {
  group     = ibm_is_security_group.sg1.id
  direction = "outbound"
  remote    = "0.0.0.0/0"

  udp {
    port_min = 53
    port_max = 53
  }
}


# Create a Public Gateway for the VPC
resource "ibm_is_public_gateway" "pgw" {
  name = "${local.BASENAME}-public-gateway"
  vpc  = ibm_is_vpc.vpc.id
  zone = local.ZONE
}

resource "ibm_is_subnet" "subnet1" {
    name                     = "${local.BASENAME}-subnet1"
    vpc                      = ibm_is_vpc.vpc.id
    zone                     = local.ZONE
    total_ipv4_address_count = 256
    public_gateway           = ibm_is_public_gateway.pgw.id
}

data "ibm_is_image" "ubuntu" {
    name = "ibm-ubuntu-22-04-5-minimal-amd64-1"
}

resource "ibm_is_instance" "vsi3" {
    name    = "${local.BASENAME}-vsi3"
    vpc     = ibm_is_vpc.vpc.id
    zone    = local.ZONE
    keys    = ["r014-00f00457-2576-424f-afc3-78ad167503e3"]
    image   = data.ibm_is_image.ubuntu.id
    profile = "cx2d-32x64"

    primary_network_interface {
        subnet          = ibm_is_subnet.subnet1.id
        security_groups = [ibm_is_security_group.sg1.id]
    }
}
resource "ibm_is_floating_ip" "fip3" {
    name   = "${local.BASENAME}-fip3"
    target = ibm_is_instance.vsi3.primary_network_interface[0].id
}

output "floating_ip" {
  value = ibm_is_floating_ip.fip3.address
}

output "reserved_ip" {
  value = ibm_is_instance.vsi3.primary_network_interface[0].primary_ipv4_address
}
