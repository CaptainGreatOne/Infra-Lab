variable "memory" {
  description = "RAM in MB for each VM"
  type        = number
  default     = 1024
}

variable "cpu_count" {
  description = "Number of CPU cores for each VM"
  type        = number
  default     = 1
}

# variable "disk_size" {
#   description = "Disk size in GB for each VM"
#   type        = number
#   default     = 20
# }

variable "network_name" {
  description = "Name of the network to attach VMs to"
  type        = string
  default     = "default"
}

variable "base_image_path" {
  description = "Path to the base image to use for the VMs"
  type        = string
  default     = "/var/lib/libvirt/images/Fedora-Server-Guest-Generic-43-1.6.x86_64.qcow2"
}

variable "web_node_name" {
    description = "Name of the web node VM"
    type        = string
    default     = "web-node"
}

variable "db_node_name" {
    description = "Name of the database node VM"
    type        = string
    default     = "db-node"
}

variable "monitor_node_name" {
  description = "Name of the monitor node VM"
  type        = string
  default     = "monitor-node"
}

variable "storage_pool" {
  description = "Name of the storage pool to use for VMs"
  type        = string
  default     = "default"
}

variable "disk_size" {
    description = "Size of the VM disk volume in bytes (e.g., 10 GB = 10737418240 bytes)"
    type        = number
    default     = 1024 * 1024 * 1024 * 10 # 10 GB in bytes
}
