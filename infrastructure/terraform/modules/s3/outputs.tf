# S3 Module Outputs

#############################################
# Public Media Bucket
#############################################

output "public_media_bucket_id" {
  description = "ID of the public media bucket"
  value       = aws_s3_bucket.public_media.id
}

output "public_media_bucket_arn" {
  description = "ARN of the public media bucket"
  value       = aws_s3_bucket.public_media.arn
}

output "public_media_bucket_domain_name" {
  description = "Domain name of the public media bucket"
  value       = aws_s3_bucket.public_media.bucket_domain_name
}

output "public_media_bucket_regional_domain_name" {
  description = "Regional domain name of the public media bucket"
  value       = aws_s3_bucket.public_media.bucket_regional_domain_name
}

#############################################
# Private Media Bucket
#############################################

output "private_media_bucket_id" {
  description = "ID of the private media bucket"
  value       = aws_s3_bucket.private_media.id
}

output "private_media_bucket_arn" {
  description = "ARN of the private media bucket"
  value       = aws_s3_bucket.private_media.arn
}

output "private_media_bucket_domain_name" {
  description = "Domain name of the private media bucket"
  value       = aws_s3_bucket.private_media.bucket_domain_name
}

output "private_media_bucket_regional_domain_name" {
  description = "Regional domain name of the private media bucket"
  value       = aws_s3_bucket.private_media.bucket_regional_domain_name
}

#############################################
# Restricted Media Bucket
#############################################

output "restricted_media_bucket_id" {
  description = "ID of the restricted media bucket"
  value       = aws_s3_bucket.restricted_media.id
}

output "restricted_media_bucket_arn" {
  description = "ARN of the restricted media bucket"
  value       = aws_s3_bucket.restricted_media.arn
}

output "restricted_media_bucket_domain_name" {
  description = "Domain name of the restricted media bucket"
  value       = aws_s3_bucket.restricted_media.bucket_domain_name
}

output "restricted_media_bucket_regional_domain_name" {
  description = "Regional domain name of the restricted media bucket"
  value       = aws_s3_bucket.restricted_media.bucket_regional_domain_name
}

#############################################
# Embargoed Media Bucket
#############################################

output "embargoed_media_bucket_id" {
  description = "ID of the embargoed media bucket"
  value       = aws_s3_bucket.embargoed_media.id
}

output "embargoed_media_bucket_arn" {
  description = "ARN of the embargoed media bucket"
  value       = aws_s3_bucket.embargoed_media.arn
}

output "embargoed_media_bucket_domain_name" {
  description = "Domain name of the embargoed media bucket"
  value       = aws_s3_bucket.embargoed_media.bucket_domain_name
}

output "embargoed_media_bucket_regional_domain_name" {
  description = "Regional domain name of the embargoed media bucket"
  value       = aws_s3_bucket.embargoed_media.bucket_regional_domain_name
}

#############################################
# Processing Bucket
#############################################

output "processing_bucket_id" {
  description = "ID of the processing bucket"
  value       = aws_s3_bucket.processing.id
}

output "processing_bucket_arn" {
  description = "ARN of the processing bucket"
  value       = aws_s3_bucket.processing.arn
}

output "processing_bucket_domain_name" {
  description = "Domain name of the processing bucket"
  value       = aws_s3_bucket.processing.bucket_domain_name
}

output "processing_bucket_regional_domain_name" {
  description = "Regional domain name of the processing bucket"
  value       = aws_s3_bucket.processing.bucket_regional_domain_name
}

#############################################
# Logs Bucket
#############################################

output "logs_bucket_id" {
  description = "ID of the logs bucket"
  value       = aws_s3_bucket.logs.id
}

output "logs_bucket_arn" {
  description = "ARN of the logs bucket"
  value       = aws_s3_bucket.logs.arn
}

output "logs_bucket_domain_name" {
  description = "Domain name of the logs bucket"
  value       = aws_s3_bucket.logs.bucket_domain_name
}

output "logs_bucket_regional_domain_name" {
  description = "Regional domain name of the logs bucket"
  value       = aws_s3_bucket.logs.bucket_regional_domain_name
}

#############################################
# Frontend Bucket
#############################################

output "frontend_bucket_id" {
  description = "ID of the frontend bucket"
  value       = aws_s3_bucket.frontend.id
}

output "frontend_bucket_arn" {
  description = "ARN of the frontend bucket"
  value       = aws_s3_bucket.frontend.arn
}

output "frontend_bucket_domain_name" {
  description = "Domain name of the frontend bucket"
  value       = aws_s3_bucket.frontend.bucket_domain_name
}

output "frontend_bucket_regional_domain_name" {
  description = "Regional domain name of the frontend bucket"
  value       = aws_s3_bucket.frontend.bucket_regional_domain_name
}

output "frontend_bucket_website_endpoint" {
  description = "Website endpoint of the frontend bucket (if static website hosting is enabled)"
  value       = try(aws_s3_bucket_website_configuration.frontend[0].website_endpoint, null)
}

output "frontend_bucket_website_domain" {
  description = "Website domain of the frontend bucket (if static website hosting is enabled)"
  value       = try(aws_s3_bucket_website_configuration.frontend[0].website_domain, null)
}

#############################################
# Consolidated Outputs
#############################################

output "all_bucket_ids" {
  description = "List of all bucket IDs"
  value = [
    aws_s3_bucket.public_media.id,
    aws_s3_bucket.private_media.id,
    aws_s3_bucket.restricted_media.id,
    aws_s3_bucket.embargoed_media.id,
    aws_s3_bucket.processing.id,
    aws_s3_bucket.logs.id,
    aws_s3_bucket.frontend.id,
  ]
}

output "all_bucket_arns" {
  description = "List of all bucket ARNs"
  value = [
    aws_s3_bucket.public_media.arn,
    aws_s3_bucket.private_media.arn,
    aws_s3_bucket.restricted_media.arn,
    aws_s3_bucket.embargoed_media.arn,
    aws_s3_bucket.processing.arn,
    aws_s3_bucket.logs.arn,
    aws_s3_bucket.frontend.arn,
  ]
}

output "media_bucket_ids" {
  description = "List of media bucket IDs (public, private, restricted, embargoed)"
  value = [
    aws_s3_bucket.public_media.id,
    aws_s3_bucket.private_media.id,
    aws_s3_bucket.restricted_media.id,
    aws_s3_bucket.embargoed_media.id,
  ]
}

output "media_bucket_arns" {
  description = "List of media bucket ARNs (public, private, restricted, embargoed)"
  value = [
    aws_s3_bucket.public_media.arn,
    aws_s3_bucket.private_media.arn,
    aws_s3_bucket.restricted_media.arn,
    aws_s3_bucket.embargoed_media.arn,
  ]
}
