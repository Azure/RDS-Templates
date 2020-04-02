/*** Default Tags ***/

variable "tagBUC" {
  description = "The Business Unit Code associated with the group responsible for the deployed asset."
  default     = ""
}

variable "tagSupportGroup" {
  description = "The name of the group responsible for the deployed asset."
  default     = ""
}

variable "tagAppGroupEmail" {
  description = "The email address for the operations team responsible for the deployed asset."
  default     = ""
}

variable "tagEnvironmentType" {
  description = "The tier of environment for the application -- this is separate from the service level defined at the subscription level."
  default     = ""
}

variable "tagCustomerCRMID" {
  description = "The end customer of the system and the CRM ID of the end customer of the system."
  default     = ""
}

variable "tagDescription" {
  description = "A description of the machine(s) to be created"
  default     = "WVD Servers"
}

/*** Resource Specific Tags ***/

variable "tagExpirationDate" {
  description = "The date that the asset is no longer required."
  default     = ""
}

variable "tagSLA" {
  description = "The contracted Service Level Agreement for system uptime."
  default     = ""
}

variable "tagNPI" {
  description = "An indicator of whether NPI is being stored on the asset."
  default     = ""
}

variable "tagWebhook" {
  description = "A webhook to send notifications of events within the Resource Group to."
  default     = ""
}

variable "tagSolutionCentralID" {
  description = "The Asset ID related to the entry in Solution Central for the product to be deployed on the given asset."
  default     = "10001887"
}

variable "tagTier" {
  description = "The tier of system in the application deployment model."
  default     = "Service"
}
