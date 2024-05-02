variable "cidr_block" {
  type        = string
  default     = "10.0.0.0/16"
  description = "The CIDR block for the VPC"
}

variable "name" {
  type        = string
  default     = "my-vpc"
  description = "The name of the VPC"
}

variable "availability_zones" {
  type = list(object({
    availability_zones = string
    public_subnet      = string
    private_subnet     = string
  }))
  default = [
    {
      availability_zones = "us-east-1a"
      public_subnet      = "10.0.1.0/24"
      private_subnet     = "10.0.2.0/24"
    },
    {
      availability_zones = "us-east-1b"
      public_subnet      = "10.0.3.0/24"
      private_subnet     = "10.0.4.0/24"
    }
  ]
  description = "A list of availability zones with public and private subnets"
}

variable "tags" {
  type        = map(string)
  default = {}
  
  description = "A map of tags to apply to the resources"
}