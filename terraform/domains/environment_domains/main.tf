# Used to create domains to be managed by front door.
module "domains" {
  for_each            = var.hosted_zone
  source              = "./vendor/modules/domains//domains/environment_domains"
  zone                = each.key
  front_door_name     = each.value.front_door_name
  resource_group_name = each.value.resource_group_name
  domains             = each.value.domains
  environment         = each.value.environment_short
  redirect_rules      = each.value.redirect_rules
}

module "statuscake" {
  source = "./vendor/modules/domains//monitoring/statuscake"

  uptime_urls    = ["https://professional-development-for-teachers-leaders.education.gov.uk/"]
  ssl_urls       = ["https://professional-development-for-teachers-leaders.education.gov.uk/"]
  contact_groups = [291418, 282453] # CPD and Infra
  confirmation   = 2
}
