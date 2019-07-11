variable "rg" {
  description = "Name of the Resource Group to deploy."
  default     = "TF-RG"
}

variable "location" {
  description = "Location to deploy the solution into"
  default     = "Australia East"
}

variable "name" {
  description = "name of vm"
  default     = "TF"
}


variable "rootuser" {
  default = "ubuntu"
}

variable "rootpassword" {
  description = "Root Password for the VM"
  default     = "myV3ry53cur3dP@55w0rd!"
}

variable "vmsize" {
  description = "VM size"
  default     = "Standard_D2s_v3"
}
