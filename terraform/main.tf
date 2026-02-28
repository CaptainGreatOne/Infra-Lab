# resource "libvirt_network" "lab_network" {
#   name      = var.network_name
#   autostart = true
#   forward = {
#     mode = "nat"

#   }

#   bridge = {
#     name = "virbr1"
#     stp = "on"
#     delay = "0"
#   }

#   domain = {
#     name = "nat-network.local"
#   }

#   ips = [ 
#     {
#     dhcp = {
#     enabled = true
#     address = "192.168.100.1"
#     netmask = "255.255.255.0"
#     mac = "52:54:00:6b:3c:40"
#     range = {
#       start = "192.168.100.10"
#       end   = "192.168.100.250"
#       hosts = [
#         {
#           mac = "52:54:00:6b:3c:58"
#           name = var.web_node_name
#           ip = "192.168.100.5"
#         },
#         {
#           mac = "52:54:00:6b:3c:59"
#           name = var.db_node_name
#           ip = "192.168.100.6"
#         } ,
#         {
#           mac = "52:54:00:6b:3c:5a"
#           name = var.monitor_node_name
#           ip = "192.168.100.7"
#         }   
#       ]
#     } 
#   }
# }
# ] 
# } 

# resource "libvirt_network" "lab_network" {
#   name      = var.network_name
#   autostart = true
#   bridge = {
#     name = var.network_name
#   }
#   forward = {
#     mode = "nat"
#   } 
#   ips = [ {
#     address = "192.168.100.1"
#     netmask = "255.255.255.0"
    
#   } ]
# }

# this network is the bane of my very existance. :(

# resource "libvirt_volume" "base_image" {
#   name   = basename(var.base_image_path)
#   pool   = var.storage_pool
#   capacity = var.disk_size # 10 GB
#   target = {
#       format = {
#         type = "qcow2"
#       }
#     }
#   create = {
#     content = {
#       url = var.base_image_path
#     }
#   }
# }

resource "libvirt_volume" "web_node_volume" {
  name           = var.web_node_name
  pool           = var.storage_pool
  capacity = var.disk_size # 10 GB
  target = {
    format = {
      type = "qcow2"
    }
  }
  create = {
    content = {
      url = var.base_image_path
    }
  }
}

resource "libvirt_volume" "db_node_volume" {
  name           = var.db_node_name
  pool           = var.storage_pool
  capacity = var.disk_size # 10 GB
  target = {
    format = {
      type = "qcow2"
    }
  }
  create = {
    content = {
      url = var.base_image_path
    }
  }
}

resource "libvirt_volume" "monitor_node_volume" {
  name           = var.monitor_node_name
  pool           = var.storage_pool
  capacity = var.disk_size # 10 GB
  target = {
    format = {
      type = "qcow2"
    }
  }
  create = {
      content = {
        url = var.base_image_path
      }
    }
  }

resource "libvirt_cloudinit_disk" "cloud_init" {
  name = "cloud-init"
  user_data = file("cloud_init.yml")
    meta_data = yamlencode({
    instance-id    = "vm-01"
    local-hostname = "webserver"
  })
}

# resource "libvirt_volume" "cloudinit" {
#   name   = "vm-cloudinit"
#   pool   = "default"

#   create = {
#     content = {
#       url = libvirt_cloudinit_disk.cloud_init.id
#     }
#   }
# }

resource "libvirt_domain" "web_node" {
  name   = var.web_node_name
  memory = var.memory
  memory_unit   = "MiB"
  vcpu   = var.cpu_count
  type   = "kvm"

  os = {
    type         = "hvm"
    type_arch    = "x86_64"
    type_machine = "q35"
  }

  devices = {
    disks = [
      {
        source = {
          file = {
            file = libvirt_volume.web_node_volume.path
          }
        }
        target = {
          dev = "vda"
          bus = "virtio"
        }
      }
    ]
    interfaces = [
      {
        model = {
          type = "virtio"
        }
        source = {
          network = {
            network = "default"
            wait_for_lease = true
          }
        }
      }
    ]
  }
}

resource "libvirt_domain" "db_node" {
  name   = var.db_node_name
  memory = var.memory
  memory_unit   = "MiB"
  vcpu   = var.cpu_count
  type   = "kvm"

  os = {
      type         = "hvm"
      type_arch    = "x86_64"
      type_machine = "q35"
    }


  devices = {
    disks = [
      {
        source = {
          file = {
            file = libvirt_volume.db_node_volume.path
          }
        }
        target = {
          dev = "vda"
          bus = "virtio"
        }
      }
    ]
    interfaces = [
      {
        model = {
          type = "virtio"
        }
        source = {
          network = {
            network = "default"
            wait_for_lease = true
          }
        }
      }
    ]
  }
}

resource "libvirt_domain" "monitor_node" {
  name   = var.monitor_node_name
  memory = var.memory
  memory_unit   = "MiB"
  vcpu   = var.cpu_count
  type   = "kvm"

  os = {
  type         = "hvm"
  type_arch    = "x86_64"
  type_machine = "q35"
}


  devices = {
    disks = [
      {
        source = {
          file = {
            file = libvirt_volume.monitor_node_volume.path
          }
        }
        target = {
          dev = "vda"
          bus = "virtio"
        }
      }
    ]
    interfaces = [
      {
        model = {
          type = "virtio"
        }
        source = {
          network = {
            network = "default"
            wait_for_lease = true
          }
        }
      }
    ]
  }
}