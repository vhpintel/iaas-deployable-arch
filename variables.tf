variable "ibmcloud_api_key" {
  description = "IBM Cloud API Key"
  type        = string
  default     = ""
}
variable "ibmcloud_region" {
  description = "IBM Cloud Region"
  type        = string
  default     = "us-east"
}
variable "vpc_name" {
  description = "VPC name"
  type        = string
  default     = "test-vpc"
}

