variable "location" {
  type = string
  default = "eastus"
}
variable "prefix" {
  type = string
  default = "climatemldev"
}
variable "enable_app" {
  type = bool
  default = false
}
variable "container_image" {
  type = string
  default = ""
}
variable "tags" {
  type = map(string)
  default = {
    project = "climate-ml-demo"
    environment = "dev"
  }
}
