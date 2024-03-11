variable "hosted_zone" {
  type    = map(any)
  default = {}
}

variable "azure_resource_prefix" {
  description = "Standard resource prefix. Usually s189t01 (test) or s189p01 (production)"
}
variable "config_short" {
  description = "Short name of the environment configuration, e.g. dv, st, pd..."
}
variable "service_short" {
  description = "Short name to identify the service. Up to 6 charcters."
}
