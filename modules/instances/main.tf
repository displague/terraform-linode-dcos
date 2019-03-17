data "linode_instance_type" "type" {
  id = "${var.node_type}"
}

resource "linode_instance" "instance" {
  count      = "${var.node_count}"
  region     = "${var.region}"
  label      = "${var.label_prefix == "" ? "" : "${var.label_prefix}-"}${var.node_class}-${count.index + 1}"
  group      = "${var.linode_group}"
  type       = "${var.node_type}"
  private_ip = "${var.private_ip}"
  tags       = ["dcos", "${var.node_class}"]

  disk {
    label           = "boot"
    size            = "${data.linode_instance_type.type.disk}"
    authorized_keys = ["${chomp(file(var.ssh_public_key))}"]
    image           = "linode/containerlinux"
  }

  config {
    label = "${var.node_class}"

    kernel = "linode/direct-disk"

    devices {
      sda = {
        disk_label = "boot"
      }
    }
  }

  provisioner "file" {
    source      = "${path.module}/scripts/"
    destination = "/tmp"

    connection {
      user    = "core"
      timeout = "300s"
    }
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/setup.sh && sudo /tmp/setup.sh",
      "chmod +x /tmp/linode-network.sh && sudo /tmp/linode-network.sh ${self.private_ip_address} ${self.label}",
    ]

    connection {
      user    = "core"
      timeout = "300s"
    }
  }
}
