# Automated Proxmox Backup Server Installation
> This repository contains a shell script that automatically installs Proxmox Backup Server (PBS) on a LXC in Proxmox using Terraform and Ansible.

This script does the following:

1. Terraform creates the LXC
2. Ansible configures idmap on the PVE host and within the LXC configuration file, and then installs PBS on the Debian LXC.
3. The shell script automates the process and handoff between Terraform and Ansible.

## Prerequisites
- Resilient storage (i.e. raid-backed ZFS pool) available locally or via NFS. This script assumes storage is on an external NAS and bind-mounted to the PVE host.
- [Debian 12 LXC](https://wiki.debian.org/LXC) template is already downloaded and available within Proxmox per the [official documentation](https://pve.proxmox.com/wiki/Linux_Container). This script assumes the template is located on shared storage ("NFS_shared:vztmpl/debian-12-standard_12.0-1_amd64.tar.zst"), but can be customized in 'terraform.tfvars'.
  - Alternatively, the latest debian image can be downloaded from within the PVE shell (replace 'NFS_shared' with your desired storage location)
  ```sh
  pveam update
  pveam download NFS_shared debian-12-standard_12.2-1_amd64.tar.zst
  ```


## Installation & Usage
1. Cone this repository:

```sh
git clone https://github.com/Robert-litts/Automated_Proxmox-Backup-Server_Installation.git
```

### Ansible
1. Update Ansible inventory
```sh
inventory.yml
```
2. Update role-specific variables
```sh
ansible/roles/pbs_install/vars/main.yml
ansible/roles/proxmox_lxc_pbs/vars/main.yml
```
### Terraform

3. Rename tfvars.example and edit variables
```sh
cp terraform/tfvars.example terraform/terraform.tfvars
```
4. Make the shell script executable and run

```sh
chmod +x PBS_install.sh
./PBS_install.sh
```

## How This Script Works
> Detailed writeup can be found [on my website](https://litts.me/projects/2024/third/)

1. Enable mapping UID/GID 34 on the host to the LXC

    **Edit */etc/subuid* on PVE host**
    ```bash                                                                                                                    
    root:100000:65536
    root:34:1
    ```

    **Edit */etc/subgid* on PVE host**
    ```bash
    root:100000:65536
    root:34:1
    ```

    The /etc/subuid file is used to define the user ID (UID) ranges that can be used for user namespace mappings in unprivileged containers. The entries in this file specify which UIDs on the host system can be mapped to UIDs within the container.
    - \<username>\:<start_uid>\:\<count>

        - **username** is the user for whom the UID range is being defined.
        - **start_uid** is the starting UID on the host.
        - **count** is the number of UIDs that can be mapped starting from <start_uid>.
     
2. Resilient Storage: The Proxmox node where you are creating the LXC must either have resilient storage itself (i.e. raid-backed ZFS pool), or be connected to resilient storage. In my scenario, my node has a CIFS share from TrueNAS mounted to "/mnt/proxmox_backup/server". The LXC will need this mountpoint passed through to the container so that VMs can be stored externally on the NAS.

    **Edit the fstab to ensure that your storage is mounted on the PVE host.** 
    Below, I created a SMB share on TrueNAS and mounted it to /mnt/proxmox_backup_server on the PVE host. This will be the storage location for PBS.

    ***/etc/fstab***
    ```bash
    //192.168.5.202/proxmox_backup_server /mnt/proxmox_backup_server cifs _netdev,x-systemd.automount,noatime,uid=34,gid=34,dir_mode=0770,file_mode=0770,user=proxmox,pass=secret_password 0 0
    ```

    Mount options for the above explained: 

    - **_netdev**: Indicates that the mount requires network access. This option is useful for network filesystems as it ensures that the filesystem is mounted only after the network is up.
    - **x-systemd.automount**: This option tells systemd to automatically mount the share when it is first accessed. It helps to manage mounting through systemd rather than at boot time.
    - **noatime**: Disables the updating of file access times. This can improve performance by reducing the number of writes to the filesystem.
    - **uid=34**: Sets the user ID (UID) that will own the files in the mounted share. In this case, UID 34 is used.
    - **gid=34**: Sets the group ID (GID) that will own the files in the mounted share. Here, GID 34 is used.
    - **dir_mode=0770**: Sets the permissions for directories within the mounted share. 0770 means read, write, and execute permissions for the owner and group, and no permissions for others.
    - **file_mode=0770**: Sets the permissions for files within the mounted share. Similarly, 0770 means read, write, and execute permissions for the owner and group, and no permissions for others.
    - **user=proxmox**: Specifies the username for authentication with the CIFS share. Here, the username is proxmox.
    - **pass=secret_password**: Specifies the password for authentication with the CIFS share. Replace secret_password with the actual password.
  
3. Create the LXC -- this script uses Terraform.
```terraform
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
```
3.a Alternatively, this can step can also be done manually from the commandline:
```sh
pct create 400 truenas_proxmox_shared:vztmpl/debian-12-standard_12.0-1_amd64.tar.zst \
    --arch amd64 \
    --ostype debian \
    --hostname proxmox-backup-server \
    --cores 2 \
    --memory 4096 \
    --swap 512 \
    --ssh-public-keys /root/.ssh/ansible_user.pub \
    --password super-secret-password \
    --features nesting=1 \
    --mp0 /mnt/proxmox_backup_server,mp=/mnt/proxmox_backup_server \
    --unprivileged 1 \
    --rootfs local-zfs:10 \
    --net0 name=eth0,bridge=vmbr0,gw=192.168.5.1,ip=192.168.5.100/24,type=veth
```
4. Updates the LXC Configuration file to utilize the correct UID/GID mappings for PBS
```sh
lxc.idmap: u 0 100000 34
lxc.idmap: u 34 34 1
lxc.idmap: u 35 100035 65501
lxc.idmap: g 0 100000 34
lxc.idmap: g 34 34 1
lxc.idmap: g 35 100035 65501
```
- UID/GID must be mapped from host to LXC to ensure PBS has the correct permissions to conduct backups. UID 34 corresponds to the 'backup' user on Proxmox. Summary of UID/GID Mappings:
  - UIDs and GIDs 0-33: Mapped to 100000-100033 on the host.
  - UID and GID 34: Directly mapped to 34 on the host.
  - UIDs and GIDs 35-65535: Mapped to 100035-165535 on the host.
 
5. Configures PBS within the newly created LXC
- Download and install GPG Key for PBS:
```bash
wget https://enterprise.proxmox.com/debian/proxmox-release-bookworm.gpg -O /etc/apt/trusted.gpg.d/proxmox-release-bookworm.gpg
```
- Update /etc/apt/sources.list:
```bash
tee -a /etc/apt/sources.list <<EOF
deb http://deb.debian.org/debian bookworm main contrib
deb http://deb.debian.org/debian bookworm-updates main contrib
deb http://security.debian.org bookworm-security main contrib
deb http://download.proxmox.com/debian/pbs-client bookworm main
deb http://download.proxmox.com/debian/pbs bookworm pbs-no-subscription
EOF
```

- Update and install PBS:
```bash
apt update && apt upgrade -y && apt install -y proxmox-backup-server

```

6. PBS is now running on https://your.server.ip.addr:8007
- Login with username: root and the password you configured when creating the LXC earlier.

