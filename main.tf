terraform {
  required_providers {
    proxmox = {
      source = "bpg/proxmox"
      version = "0.96.0"
    }
  }
}

resource "proxmox_virtual_environment_container" "this" {
  description = "Managed by Terraform"

  node_name     = var.node_name
  vm_id         = var.vm_id
  tags          = var.tags

  unprivileged  = var.unprivileged
  protection    = var.protection
  start_on_boot = var.start_on_boot

  environment_variables = var.env_vars

  features {
    nesting = var.features.nesting
    keyctl  = var.features.keyctl
    fuse    = var.features.fuse
  }

  initialization {
    hostname = var.init.hostname

    ip_config {
      ipv4 {
        address = var.init.ipv4_address
        gateway = var.init.ipv4_gateway
      }
    }

    user_account {
      password = var.init.password
    }
  }

  memory {
    dedicated = var.resources.memory_ram
  }

  cpu {
    cores = var.resources.cpu_cores
  }

  network_interface {
    name   = var.network.name
    bridge = var.network.bridge
  }

  disk {
    mount_options = var.disk.options
    datastore_id  = var.disk.datastore
    size          = var.disk.size
  }

  operating_system {
    template_file_id = var.os.template_id
    type             = var.os.type
  }

  dynamic "mount_point" {
    # ------------------------
    # bind mount, *requires* root@pam authentication
    # volume = "/mnt/bindmounts/shared"
    # ------------------------
    # a new volume will be created by PVE
    # volume = "local-lvm"
    # ------------------------
    # volume mount, an existing volume will be mounted
    # volume = "local-lvm:subvol-108-disk-101"
    # ------------------------
    # to reference a mount point volume from another resource, use path_in_datastore:
    # volume = other_container.mount_point[0].path_in_datastore
    # ------------------------
    # size   = "10G"
    # ------------------------
    # location visible in this
    # path   = "/mnt/volume"
    # ------------------------
    for_each = var.mount

    content {
      volume = mount_point.value.volume
      path   = mount_point.value.path
      size   = try(mount_point.value.size, null)
    }
  }

  startup {
    order      = "3"
    up_delay   = "60"
    down_delay = "60"
  }
}

resource "null_resource" "ssh_credentials" {
  count       = var.ssh.enable && var.ssh.username != null && var.ssh.password != null ? 1 : 0
  depends_on  = [proxmox_virtual_environment_container.this]

  provisioner "local-exec" {
    command = <<EOT
      sshpass -p "${var.pve.password}" ssh -o StrictHostKeyChecking=no root@${var.pve.host} "
        sleep 10;
        pct exec ${proxmox_virtual_environment_container.this.vm_id} -- bash -c '
          id -u ${var.ssh.username} >/dev/null 2>&1 || useradd -m -s /bin/bash ${var.ssh.username};
          usermod --password \$(openssl passwd -6 \"${var.ssh.password}\") ${var.ssh.username};
          usermod -aG sudo ${var.ssh.username};
          mkdir -p /home/${var.ssh.username}/.ssh;
          chown -R ${var.ssh.username}:${var.ssh.username} /home/${var.ssh.username}/.ssh;
          systemctl restart ssh;
        '
      "
    EOT
  }
}

resource "null_resource" "dev_net_tun" {
  count       = var.tun && var.pve.host != null && var.pve.password != null ? 1 : 0
  depends_on  = [proxmox_virtual_environment_container.this]

  provisioner "local-exec" {
  command = <<EOT
    sshpass -p "${var.pve.password}" ssh -o StrictHostKeyChecking=no root@${var.pve.host} \
    "
      echo 'lxc.cgroup2.devices.allow = c 10:200 rwm' >> /etc/pve/lxc/${proxmox_virtual_environment_container.this.vm_id}.conf;
      echo 'lxc.mount.entry = /dev/net/tun dev/net/tun none bind,create=file' >> /etc/pve/lxc/${proxmox_virtual_environment_container.this.vm_id}.conf;
    "
    EOT
  }
}
