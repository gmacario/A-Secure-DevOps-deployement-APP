variable "region" {
  type        = string
  description = "The region where the resources are gonna be deployed"
}

variable "company" {
  type        = string
  description = "Company name"
}

variable "availability_zones" {
  type        = set(string)
  description = "List of avalaibility zone"
}