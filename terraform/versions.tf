terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    octopusdeploy = {
      source  = "OctopusDeploy/octopusdeploy"
      version = "~> 1.5"
    }
  }
}
