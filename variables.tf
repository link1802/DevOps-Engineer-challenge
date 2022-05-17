provider "google-beta" {
  project     = "devops-engineer-challenge"
  region      = "us-central1"
  zone        = "us-central1-a"
}

provider "google" {
  project     = "devops-engineer-challenge"
  region      = "us-central1"
  zone        = "us-central1-a"
}

variable "machine_type" {
  description = "the type of machine on GCP"
  type        = string
  default     = "e2-micro"
}