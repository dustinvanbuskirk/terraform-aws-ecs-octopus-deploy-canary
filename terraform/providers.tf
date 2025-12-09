# Configure AWS Provider
provider "aws" {
  region = var.aws_region
}

# Configure Octopus Deploy Provider
provider "octopusdeploy" {
  address = var.octopus_server_url
  api_key = var.octopus_api_key
}