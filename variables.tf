
variable "gitops_config" {
  type        = object({
    boostrap = object({
      argocd-config = object({
        project = string
        repo = string
        url = string
        path = string
      })
    })
    infrastructure = object({
      argocd-config = object({
        project = string
        repo = string
        url = string
        path = string
      })
      payload = object({
        repo = string
        url = string
        path = string
      })
    })
    services = object({
      argocd-config = object({
        project = string
        repo = string
        url = string
        path = string
      })
      payload = object({
        repo = string
        url = string
        path = string
      })
    })
    applications = object({
      argocd-config = object({
        project = string
        repo = string
        url = string
        path = string
      })
      payload = object({
        repo = string
        url = string
        path = string
      })
    })
  })
  description = "Config information regarding the gitops repo structure"
}

variable "git_credentials" {
  type = list(object({
    repo = string
    url = string
    username = string
    token = string
  }))
  description = "The credentials for the gitops repo(s)"
  sensitive   = true
}

variable "kubeseal_cert" {
  type        = string
  description = "The certificate/public key used to encrypt the sealed secrets"
  default     = ""
}

variable "server_name" {
  type        = string
  description = "The name of the server"
  default     = "default"
}

variable "resource_group_id" {
  type        = string
  description = "The id of the resource group where the portworx instance will be provisioned"
}

variable "ibmcloud_api_key" {
  type        = string
  description = "The api key for the IBM Cloud account"
  sensitive = true
}

variable "region" {
  type        = string
  description = "The region where the Portworx service should be deployed. This region used doesn't really impact anything because the service runs in the cluster"
  default     = "us-east"
}

variable "encryption_key" {
  type        = string
  description = "The crn for the encryption key that should be used to encrypt the volume. If not provided the volume will be encrypted with an IBM-managed key"
  default     = ""
}

variable "capacity" {
  type        = string
  description = "The capacity of the portworx volume"
  default     = "200"
}

variable "iops" {
  type        = string
  description = "The transfer speed of the portworx volume. This value is only used if the profile is set to 'custom'"
  default     = ""
}

variable "profile" {
  type        = string
  description = "The profile of the portworx volumes"
  default     = "10iops-tier"
}

variable "default_rwx_storage_class" {
  type        = "string"
  description = "The default storage class that should be used for RWX volumes"
  default     = "portworx-rwx-gp3-sc"
}

variable "default_rwo_storage_class" {
  type        = "string"
  description = "The default storage class that should be used for RWO volumes"
  default     = "portworx-gp3-sc"
}

variable "default_file_storage_class" {
  type        = "string"
  description = "The default storage class that should be used for file volumes"
  default     = "portworx-gp3-sc"
}

variable "default_block_storage_class" {
  type        = "string"
  description = "The default storage class that should be used for block volumes"
  default     = "ibmc-vpc-block-10iops-tier"
}