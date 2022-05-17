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
/////////////////////////////////////////////////////
variable "proyect_region" {
  description = "the regon of proyect"
  type        = string
  default     = "us-central1"
}
///////////////variables of VM///////////////////////
variable "machine_type" {
  description = "the type of machine on GCP"
  type        = string
  default     = "e2-micro"
}
variable "vm_base_name" {
  description = "name of vm"
  type        = string
  default     = "vm-base"
}
variable "vm_base_os" {
  description = "the os of the vm"
  type        = string
  default     = "debian-cloud/debian-11"
}
variable "vm_image" {
  description = "the image of the VM"
  type        = string
  default     = "debian-cloud/debian-11"
}
///////////variables of Networking/////////////////////
variable "ip_range_lan" {
  description = "range of lan"
  type        = string
  default     = "10.1.2.0/24"
}
variable "ip_range_proxy" {
  description = "range of proxy"
  type        = string
  default     = "10.129.0.0/26"
}
/////////////////////////////////////////////////////
variable "instance_group_size" {
  description = "size of instance group"
  type        = number
  default     = 2
}