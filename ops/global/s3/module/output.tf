output "id" {
  description = "Name of the bucket"
  value       = concat(aws_s3_bucket.this.*.id, [""])[0]
}

output "arn" {
  description = "ARN of the bucket"
  value       = concat(aws_s3_bucket.this.*.arn, [""])[0]
}

output "bucket_domain_name" {
  description = "The bucket domain name. Will be of format bucketname.s3.amazonaws.com"
  value       = concat(aws_s3_bucket.this.*.bucket_domain_name, [""])[0]
}

output "bucket_regional_domain_name" {
  description = "The bucket region-specific domain name"
  value       = concat(aws_s3_bucket.this.*.bucket_regional_domain_name, [""])[0]
}

output "hosted_zone_id" {
  description = "The Route 53 Hosted Zone ID for this bucket's region"
  value       = concat(aws_s3_bucket.this.*.hosted_zone_id, [""])[0]
}

output "region" {
  description = "The AWS region this bucket resides in"
  value       = concat(aws_s3_bucket.this.*.region, [""])[0]
}