# terraform/envs/dev/terraform.tfvars
# Development environment — lower cost SKUs, smaller address spaces

environment    = "dev"
location       = "uksouth"
location_short = "uks"
cost_centre    = "CC-MIGRATION-DEV"
owner          = "migration-team@contoso.com"
migration_wave = "Platform"

hub_address_space      = "10.0.0.0/20"
firewall_subnet_prefix = "10.0.0.0/26"
gateway_subnet_prefix  = "10.0.0.64/27"
bastion_subnet_prefix  = "10.0.0.96/26"

custom_dns_servers = ["10.0.0.132", "10.0.0.133"]

spokes = {
  "workload-app" = {
    resource_group_name = "rg-workload-app-dev"
    address_space       = "10.0.16.0/24"
    tags = {
      WorkloadName = "app-tier"
      MigrationWave = "Wave-1"
    }
  }
  "workload-data" = {
    resource_group_name = "rg-workload-data-dev"
    address_space       = "10.0.17.0/24"
    tags = {
      WorkloadName = "data-tier"
      MigrationWave = "Wave-2"
    }
  }
}
