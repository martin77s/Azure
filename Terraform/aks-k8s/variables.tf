variable "agent_count" {
    default = 2
}

variable "ssh_public_key" {
    default = "./.ssh/id_rsa.pub"
}

variable "dns_prefix" {
    default = "aksdemo"
}

variable cluster_name {
    default = "aksdemo"
}

variable resource_group_name {
    default = "aksdemo-rg"
}

variable location {
    default = "West Europe"
}

variable log_analytics_workspace_name {
    default = "aksdemolaw777"
}

# refer https://azure.microsoft.com/global-infrastructure/services/?products=monitor for log analytics available regions
variable log_analytics_workspace_location {
    default = "westeurope"
}

# refer https://azure.microsoft.com/pricing/details/monitor/ for log analytics pricing
variable log_analytics_workspace_sku {
    default = "PerGB2018"
}