### Automated Proxmox Backup Server Installation with Terraform and Ansible
This repository contains a shell script that automatically installs Proxmox Backup Server (PBS) on a LXC in Proxmox. This script does the following:

1. Terraform creates the LXC
2. Ansible configures idmap on the PVE host and within the LXC configuration file, and then installs PBS on the Debian LXC.
3. The shell script automates the process and handoff between Terraform and Ansible.

Customize the following variables to fit your environment:

### Ansible
1. Update inventory.yml
2. Update 'roles/pbs_install/vars/main.yml' and 'roles/proxmox_lxc_pbs/vars/main.yml'

### Terraform

3. Rename tfvars.example and edit values
```bash
cp terraform/tfvars.example terraform/terraform.tfvars
```
4. Make the shell script executable and run

```bash
chmod +x PBS_install.sh
./PBS_install.sh
```