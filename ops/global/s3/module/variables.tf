
#~~~~~~~~~~
# Generic
#~~~~~~~~~~
variable "tags" {
  description = "A map of tags to apply to all resources"
  type        = map(string)
  default     = {}
}

#~~~~~~~~~
# Bucket
#~~~~~~~~~

variable "name" {
  description = "Name of the resource. Conflicts with name_prefix"
  default     = ""
}


#~~~~~~~~~~~~
# SSE Block
#~~~~~~~~~~~~
variable "sse_key_id" {
  description = "Configures server side encryption for the bucket.  The sse_key should either be set to S3 or a KMS Key ID"
  type        = any
  default = []
}

#~~~~~~~~~~~~~
# Versioning
#~~~~~~~~~~~~~
variable "versioning_config" {
  description = "Configure versioning on bucket object.  Once you version-enable a bucket, it can never return to an unversioned state. You can, however, suspend versioning on that bucket"
  type        = list(map(string))
  default     = []
}


variable "cors_rules" {
  description = "A data structure that configures CORS rules"
  type        = list(object({
    allowed_headers = list(string)
    allowed_methods = list(string)
    allowed_origins = list(string)
    expose_headers  = list(string)
    max_age_seconds = number
  }))
  default = []
}

#~~~~~~~~~~~~~~~~~~
# Lifecycle Rules
#~~~~~~~~~~~~~~~~~~
variable "lifecycle_rules" {
  description = "A data structure to create lifcycle rules"
  type        = list(object({
    id                                     = string
    prefix                                 = string
    tags                                   = map(string)
    enabled                                = bool
    abort_incomplete_multipart_upload_days = number
    expiration_config = list(object({
      days = number
      expired_object_delete_marker = bool
    }))
    noncurrent_version_expiration_config = list(object({
      days = number
    }))
    transitions_config = list(object({
      days          = number
      storage_class = string
    }))
    noncurrent_version_transitions_config = list(object({
      days          = number
      storage_class = string
    }))
  }))
  default = []
}

#~~~~~~~~~~~~~~~~~~~~~~
# Public Access Block
#~~~~~~~~~~~~~~~~~~~~~~
variable "remove_public_access_block" {
  description = "When set to true, will disable all public access block attributes"
  type        = bool
  default     = false
}

variable "block_public_acls" {
  description = "Whether Amazon S3 should block public ACLs for this bucket"
  type        = bool
  default     = true
}

variable "block_public_policy" {
  description = "Whether Amazon S3 should block public bucket policies for this bucket"
  type        = bool
  default     = true
}

variable "ignore_public_acls" {
  description = "Whether Amazon S3 should ignore public ACLs for this bucket"
  type        = bool
  default     = true
}

variable "restrict_public_buckets" {
  description = "Whether Amazon S3 should restrict public bucket policies for this bucket"
  type        = bool
  default     = true
}