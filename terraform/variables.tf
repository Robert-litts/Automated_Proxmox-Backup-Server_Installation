# Proxmox Provider variables

variable "pm_api_url" {
  description = "The API URL for the Proxmox host."
  type        = string
}

variable "pm_api_token_id" {
  description = "The API token ID for Proxmox in the form <username>@pam!<tokenId>"
  type        = string
}

variable "pm_api_token_secret" {
  description = "The API token secret for Proxmox."
  type        = string
  sensitive   = true # Mark this as sensitive to avoid accidental exposure
}

variable "pm_tls_insecure" {
  description = "Whether to ignore TLS/SSL verification."
  type        = bool
  default     = true
}

variable "pm_timeout" {
  description = "The timeout for Proxmox API requests."
  type        = number
  default     = 1000
}

variable "pm_parallel" {
  description = "The number of parallel API requests to make."
  type        = number
  default     = 2
}


# Resource definition variables

variable "proxmox_target_node" {
  description = "The target Proxmox node for the LXC container."
  type        = string
}

variable "hostname" {
  description = "The hostname of the LXC container."
  type        = string
  default     = "proxmox-backup-server"
}

variable "password" {
  description = "The password of the root user on the LXC."
  type        = string
}

variable "tags" {
  description = "Tags for the LXC container."
  type        = string
  default     = "PBS"
}

variable "ostemplate" {
  description = "The template used for the LXC container."
  type        = string
}

variable "vm_id" {
  description = "The VM ID for the LXC container."
  type        = number
  default     = 900
}

variable "cores" {
  description = "The number of CPU cores for the LXC container."
  type        = number
  default     = 2
}

variable "memory" {
  description = "The amount of memory (in MB) for the LXC container."
  type        = number
  default     = 4096
}

variable "swap" {
  description = "The amount of swap memory (in MB) for the LXC container."
  type        = number
  default     = 512
}

variable "arch" {
  description = "The architecture of the LXC container."
  type        = string
  default     = "amd64"
}

variable "ostype" {
  description = "The OS type for the LXC container."
  type        = string
  default     = "debian"
}

variable "unprivileged" {
  description = "Whether the LXC container is unprivileged."
  type        = bool
  default     = true
}

variable "ssh_public_keys" {
  description = "The SSH public keys to be added to the LXC container."
  type        = string
}

variable "start" {
  description = "Whether to start the LXC container on creation."
  type        = bool
  default     = false
}

variable "nameserver" {
  description = "The nameserver IP address for the LXC container."
  type        = string
}

variable "rootfs_storage" {
  description = "The storage for the root filesystem of the LXC container."
  type        = string
}

variable "rootfs_size" {
  description = "The size of the root filesystem for the LXC container."
  type        = string
  default     = "10G"
}

variable "network_bridge" {
  description = "The network bridge for the LXC container."
  type        = string
  default     = "vmbr0"
}

variable "network_name" {
  description = "The network interface name for the LXC container."
  type        = string
  default     = "eth0"
}

variable "ip_address" {
  description = "The IP address for the LXC container."
  type        = string
}

variable "gateway" {
  description = "The gateway IP address for the LXC container."
  type        = string
}

variable "features_nesting" {
  description = "Whether nesting is enabled for the LXC container."
  type        = bool
  default     = true
}
