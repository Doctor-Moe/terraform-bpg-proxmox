## LXC Variables
variable "node" {
  description = "Name of Proxmox node to provision LXC on, e.g. `pve`."
  type        = string
}

variable "lxc_id" {
  description = "ID number for new LXC."
  type        = number
}

variable "lxc_name" {
  description = "LXC name, must be alphanumeric (may contain dash: `-`). Defaults to using PVE naming, e.g. 'CT<LXC_ID>'."
  type        = string
  default     = null
}

variable "description" {
  description = "LXC description."
  type        = string
  default     = null
}

variable "tags" {
  description = "Proxmox tags for the LXC."
  type        = list(string)
  default     = null
}

variable "unprivileged" {
  description = "Set container to unprivileged."
  type        = bool
  default     = true
}

variable "os_template" {
  description = "Template for LXC."
  type        = string
}

variable "os_type" {
  description = "Container OS specific setup, uses setup scripts in `/usr/share/lxc/config/<ostype>.common.conf`."
  type        = string
  default     = "unmanaged"
  validation {
    condition     = contains(["alpine", "archlinux", "centos", "debian", "devuan", "fedora", "gentoo", "kali", "nixos", "opensuse", "ubuntu", "unmanaged"], var.os_type)
    error_message = "Invalid OS type setting: ${var.os_type}."
  }
}

variable "vcpu" {
  description = "Number of CPU cores."
  type        = number
  default     = 1
}

variable "memory" {
  description = "Memory size in `MiB`."
  type        = number
  default     = 512
}

variable "memory_swap" {
  description = "Memory swap size in `MiB`."
  type        = number
  default     = 512
}

### Startup Variables
variable "start_on_boot" {
  description = "Start container on PVE boot."
  type        = bool
  default     = false
}

variable "start_order" {
  description = "Start order, e.g. `1`."
  type        = number
  default     = 1
}

variable "start_delay" {
  description = "Startup delay in seconds, e.g. `30`."
  type        = number
  default     = null
}

variable "shutdown_delay" {
  description = "Shutdown delay in seconds, e.g. `30`."
  type        = number
  default     = null
}

variable "start_on_create" {
  description = "Start container after creation."
  type        = bool
  default     = true
}

### Disk Variables
variable "disk_storage" {
  description = "Disk storage location."
  type        = string
  default     = "local-lvm"
}

variable "disk_size" {
  type    = number
  default = 8
}

variable "mountpoint" {
  type = list(object({
    mp_volume    = optional(string, null)
    mp_size      = optional(number, null)
    mp_path      = optional(string, null)
    mp_backup    = optional(bool, false)
    mp_read_only = optional(bool, false)
    }
  ))
  default = null
}

### Network Variables
variable "vnic_name" {
  description = "Networking adapter name."
  type        = string
  default     = "eth0"
}

variable "vnic_bridge" {
  description = "Networking adapter bridge, e.g. `vmbr0`."
  type        = string
  default     = "vmbr0"
}

variable "vlan_tag" {
  description = "Networking adapter VLAN tag."
  type        = number
  default     = null
}

variable "macaddr" {
  description = "Network interface MAC address"
  type        = string 
  default     = null
  validation {
    condition   = (
      var.macaddr == null ? true : (
      can(regex("^(?:[0-9A-Fa-f]{2}[:-]){5}(?:[0-9A-Fa-f]{2})$", var.macaddr))
      ) 
    )
    error_message = "Error: incorrect MAC address format."
  }
}

variable "ipv4" {
  type = list(object({
    ipv4_address = optional(string, null)
    ipv4_gateway = optional(string, null)
    }
  ))
  default = [{
    ipv4_address = "dhcp"
    ipv4_gateway = null
  }]
  validation {
    condition = alltrue(
      [for a in var.ipv4 :
        ( ( (a.ipv4_address == null || a.ipv4_address == "dhcp") && a.ipv4_gateway == null )  ) ? true :
          can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}(\\/([0-9]|[1-2][0-9]|3[0-2]))$", a.ipv4_address)) &&
          can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}(\\/([0-9]|[1-2][0-9]|3[0-2]))?$", a.ipv4_gateway))
      ]
                                    
    )
    error_message = <<-EOT
      Error: Incorrect IP address or gatewway format, or improper IP configuration.

             Do not specify any gateway whenever ip_address is "dhcp".
             Use 'CIDR' format for ip_address (xx.xxx.xx.x/xx - do NOT omit netmask).
      EOT
                                                
  }
}


variable "ipv6" {
  type = list(object({
    ipv6_address = optional(string, null)
    ipv6_gateway = optional(string, null)
    }
  ))
  default = [{
    ipv6_address = "auto"
    ipv6_gateway = null
  }]
  validation {
    condition = alltrue(
      [for a in var.ipv6 :
      ( ( (a.ipv6_address == null || a.ipv6_address == "dhcp" || a.ipv6_address == "auto") && a.ipv6_gateway == null) ) ? true :
        can(regex("^(([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]))(\\/((1(1[0-9]|2[0-8]))|([0-9][0-9])|([0-9])))$", a.ipv6_address)) &&
        can(regex("^(([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]))(\\/((1(1[0-9]|2[0-8]))|([0-9][0-9])|([0-9])))?$", a.ipv6_gateway))
      ]
    )
    error_message = <<-EOT
      Error: Incorrect IP address or gatewway format, or improper IP configuration.

             Do not specify any gateway whenever ip_address is "dhcp" or "auto".
             Use 'CIDR' format for ip_address (xx.xxx.xx.x/xx - do NOT omit netmask).
      EOT
  }
}

## Default User Variables
variable "user_ssh_key_public" {
  description = "Public SSH Key for LXC user"
  default     = null
  type        = string
  sensitive   = true
  validation {
    condition     = can(regex("(?i)PRIVATE", var.user_ssh_key_public)) == false
    error_message = "Error: Private SSH Key."
  }
}

variable "user_password" {
  description = "Password for LXC user"
  type        = string
  sensitive   = true
  default     = null
}
