variable "location" {
  type        = string
  description = "The Azure Region in which all resources should be created"
  default     = "WestEurope"
}

variable "prefix" {
  type        = string
  description = "The prefix string to use for all resources"
  default     = "tfdemo"
}

variable "vm_username" {
  type        = string
  description = "The VM's admin username to use"
  default     = "vmadmin"
}

variable "vm_password" {
  type        = string
  sensitive   = true
  description = "The VM's admin password"
}
