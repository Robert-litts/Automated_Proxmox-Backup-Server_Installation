terraform {
  required_providers {
    proxmox = {
      source = "telmate/proxmox"
      version = "3.0.1-rc1"
    }
  }
}

provider "proxmox" {
  pm_api_url            = var.pm_api_url
  pm_api_token_id       = var.pm_api_token_id
  pm_api_token_secret   = var.pm_api_token_secret
  pm_tls_insecure       = var.pm_tls_insecure
  pm_timeout            = var.pm_timeout
  pm_parallel           = var.pm_parallel
}