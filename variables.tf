variable "disk" {
  description = "Root filesystem configuration."
  type = object({
    datastore     = optional(string)
    options       = optional(list(string))
    size          = optional(number)
  })
  default = {
    datastore = "local-lvm"
  }
}

variable "env_vars" {
  description = "Environment variables passed to the container."
  type        = map(string)
  default     = {}
}

variable "features" {
  description = "LXC feature flags."
  type = object({
    nesting = optional(bool)
    keyctl  = optional(bool)
    fuse    = optional(bool)
  })
  default = {}
}

variable "init" {
  description = "Initial container setup."
  type = object({
    hostname     = string
    keys         = optional(string, null)
    password     = string
    ipv4_address = string
    ipv4_gateway = string
  })
}

variable "mount" {
  description = "Optional bind mount configuration."
  type = list(object({
    volume = optional(string)
    size   = optional(string)
    path   = optional(string)
  }))
  default = []
}

variable "network" {
  description = "Network interface configuration."
  type = object({
    name   = string
    bridge = string
  })
  default = {
    name   = "eth0"
    bridge = "vmbr0"
  }
}

variable "node_name" {
  description = "Proxmox node where the container will be created."
  type        = string
  default     = "pve"
}

variable "os" {
  description = "Operating system template and type."
  type = object({
    template_id = string
    type        = string
  })
}

variable "protection" {
  description = "Protection to prevent accidental deletion or overwrite of the LXC container."
  type        = bool
  default     = false
}

variable "pve" {
  description = "Proxmox API connection details."
  type = object({
    host     = optional(string)
    password = optional(string)
  })
  default = {}

  validation {
    condition = !(var.tun || var.ssh.enable) || (var.pve.host != null && var.pve.password != null)
    error_message = <<EOT
      [ ${var.init.hostname} ] The following block is required when TUN or SSH is enabled:

      pve = {
        host     = PROXMOX_HOST
        password = PROXMOX_PASSWORD
      }
    EOT
  }
}

variable "resources" {
  description = "Hardware resources allocated to the container."
  type = object({
    cpu_cores     = optional(number)
    memory_ram    = optional(number)
  })
  default = {}
}

variable "ssh" {
  description = "SSH access configuration."
  type = object({
    enable   = bool
    username = optional(string)
    password = optional(string)
  })
  default = {
    enable = false
  }
}

variable "start_on_boot" {
  description = "Automatically start the container on node boot."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags assigned to the container."
  type        = list(string)
  default     = []
}

variable "tun" {
  description = "Enable TUN (dev/net/tun) support inside the container."
  type        = bool
  default     = false
}

variable "unprivileged" {
  description = "Whether the container runs unprivileged."
  type        = bool
  default     = true
}

variable "vm_id" {
  description = "Unique container ID in the Proxmox cluster."
  type        = number
}
