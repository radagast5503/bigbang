variable "project_id" {
  type        = string
  description = "Project id, if empty it will be generated"
  default     = ""
}

variable "name" {
  type        = string
  description = "Project name"
  default     = "muebles-ra"
}

variable "random_project_id" {
  description = "Adds a suffix of 4 random characters to the `project_id`"
  type        = bool
  default     = true
}

variable "billing_account_id" {
  description = "Billing account id"
  type = string
}