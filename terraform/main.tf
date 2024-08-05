resource "proxmox_lxc" "proxmox_backup_server" {
  target_node        = var.proxmox_target_node
  hostname           = var.hostname
  password           = var.password #necessary for PBS login
  tags               = var.tags
  ostemplate         = var.ostemplate
  vmid               = var.vm_id
  cores              = var.cores
  memory             = var.memory
  swap               = var.swap
  arch               = var.arch
  ostype             = var.ostype
  unprivileged       = var.unprivileged
  ssh_public_keys    = var.ssh_public_keys
  start              = var.start
  nameserver         = var.nameserver

  rootfs {
    storage = var.rootfs_storage
    size    = var.rootfs_size
  }

  network {
    bridge = var.network_bridge
    name   = var.network_name
    ip     = var.ip_address
    gw     = var.gateway
  }

  features {
    nesting = var.features_nesting
  }
}

output "container_id" {
  value = proxmox_lxc.proxmox_backup_server.vmid
  description = "The VM ID of the Proxmox LXC container"
}

output "lxc_ip" {
  value = split("/", proxmox_lxc.proxmox_backup_server.network[0].ip)[0]
  description = "The IP address of the Proxmox LXC container"
}

