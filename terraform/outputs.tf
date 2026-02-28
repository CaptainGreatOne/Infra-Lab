output "web_node_ip" {
  value = libvirt_domain.web_node.description
} 

output "db_node_ip" {
  value = libvirt_domain.db_node.description
}

output "monitor_node_ip" {
  value = libvirt_domain.monitor_node.description
}