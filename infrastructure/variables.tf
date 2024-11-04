# AWS access key
variable "AWS_ACCESS_KEY" {
  description = "AWS access key for API access"
  type        = string
}

# AWS secret access key
variable "AWS_SECRET_ACCESS_KEY" {
  description = "AWS secret access key for API access"
  type        = string
}

# AWS session token
variable "AWS_SESSION_TOKEN" {
  description = "AWS session token for temporary API access"
  type        = string
}

# Path to the SSH private key
variable "private_key_path" {
  description = "Path to the SSH private key"
  type        = string
  default     = "../infrastructure/my_terraform_key"
}

# Key pair name for SSH access
variable "key_pair_name" {
  description = "The name of the key pair for SSH access"
  type        = string
  default     = "my_terraform_key"
}
