# terraform/envs/prod/terraform.tfvars
# Production environment — GRS storage, Premium Firewall, full address space

environment    = "prod"
location       = "uksouth"
location_short = "uks"
cost_centre    = "CC-MIGRATION-PROD"
owner          = "migration-team@contoso.com"
migration_wave = "Platform"

hub_address_space      = "10.100.0.0/16"
firewall_subnet_prefix = "10.100.0.0/26"
gateway_subnet_prefix  = "10.100.0.64/27"
bastion_subnet_prefix  = "10.100.0.96/26"

custom_dns_servers = ["10.100.0.132", "10.100.0.133"]

spokes = {
  "workload-app" = {
    resource_group_name = "rg-workload-app-prod"
    address_space       = "10.100.16.0/22"
    tags = {
      WorkloadName  = "app-tier"
      MigrationWave = "Wave-1"
    }
  }
  "workload-data" = {
    resource_group_name = "rg-workload-data-prod"
    address_space       = "10.100.20.0/22"
    tags = {
      WorkloadName  = "data-tier"
      MigrationWave = "Wave-2"
    }
  }
  "workload-dmz" = {
    resource_group_name = "rg-workload-dmz-prod"
    address_space       = "10.100.24.0/24"
    tags = {
      WorkloadName  = "dmz-tier"
      MigrationWave = "Wave-1"
    }
  }
}
