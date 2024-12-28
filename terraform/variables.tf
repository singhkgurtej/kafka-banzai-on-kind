variable "github_token" {
  description = "GitHub token"
  sensitive   = true
  type        = string
  default     = "<gitlab-token>"
}

variable "github_org" {
  description = "GitHub organization"
  type        = string
  default     = "singhkgurtej"
}

variable "github_repository" {
  description = "GitHub repository"
  type        = string
  default     = "terraform-flux-kafka"
}