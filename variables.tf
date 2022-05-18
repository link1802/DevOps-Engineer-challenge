provider "google-beta" {
  project     = var.proyect_id
  region      = var.proyect_region
  zone        = "us-central1-a"
}

provider "google" {
  project     = var.proyect_id
  region      = var.proyect_region
  zone        = "us-central1-a"
}
////////Proyect settings//////////////////////////////
variable "proyect_id" {
  description = "the name of proyect"
  type        = string
  default     = "devops-engineer-challenge-10"
}
variable "proyect_region" {
  description = "the region of proyect"
  type        = string
  default     = "us-central1"
}
variable "proyect_billing_id" {
  description = "the id of billing account"
  type        = string
  default     = "000000-000000-000000"
}
///////////////variables of VM///////////////////////
variable "machine_type" {
  description = "the type of machine on GCP"
  type        = string
  default     = "e2-micro"
}
variable "vm_base_name" {
  description = "name of vm with nginx"
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
  default     = "vm-clean-os"
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
////////////instance settings////////////////////////
variable "instance_group_size" {
  description = "size of instance group"
  type        = number
  default     = 2
}
variable "instance_autocaler_max" {
  description = "maximun size of instance autocaler"
  type        = number
  default     = 2
}
variable "instance_autocaler_min" {
  description = "minimun size of instance autoscaler"
  type        = number
  default     = 1
}