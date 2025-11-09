# CloudFront Module Outputs

#############################################
# Public Media Distribution
#############################################

output "public_media_distribution_id" {
  description = "ID of the public media CloudFront distribution"
  value       = aws_cloudfront_distribution.public_media.id
}

output "public_media_distribution_arn" {
  description = "ARN of the public media CloudFront distribution"
  value       = aws_cloudfront_distribution.public_media.arn
}

output "public_media_distribution_domain_name" {
  description = "Domain name of the public media CloudFront distribution"
  value       = aws_cloudfront_distribution.public_media.domain_name
}

output "public_media_distribution_hosted_zone_id" {
  description = "CloudFront Route 53 zone ID for public media distribution"
  value       = aws_cloudfront_distribution.public_media.hosted_zone_id
}

output "public_media_distribution_status" {
  description = "Status of the public media CloudFront distribution"
  value       = aws_cloudfront_distribution.public_media.status
}

output "public_media_distribution_etag" {
  description = "ETag of the public media distribution (for updates)"
  value       = aws_cloudfront_distribution.public_media.etag
}

#############################################
# Frontend Distribution
#############################################

output "frontend_distribution_id" {
  description = "ID of the frontend CloudFront distribution"
  value       = aws_cloudfront_distribution.frontend.id
}

output "frontend_distribution_arn" {
  description = "ARN of the frontend CloudFront distribution"
  value       = aws_cloudfront_distribution.frontend.arn
}

output "frontend_distribution_domain_name" {
  description = "Domain name of the frontend CloudFront distribution"
  value       = aws_cloudfront_distribution.frontend.domain_name
}

output "frontend_distribution_hosted_zone_id" {
  description = "CloudFront Route 53 zone ID for frontend distribution"
  value       = aws_cloudfront_distribution.frontend.hosted_zone_id
}

output "frontend_distribution_status" {
  description = "Status of the frontend CloudFront distribution"
  value       = aws_cloudfront_distribution.frontend.status
}

output "frontend_distribution_etag" {
  description = "ETag of the frontend distribution (for updates)"
  value       = aws_cloudfront_distribution.frontend.etag
}

#############################################
# Origin Access Control
#############################################

output "public_media_oac_id" {
  description = "ID of the public media Origin Access Control"
  value       = aws_cloudfront_origin_access_control.public_media.id
}

output "frontend_oac_id" {
  description = "ID of the frontend Origin Access Control"
  value       = aws_cloudfront_origin_access_control.frontend.id
}

#############################################
# Consolidated Outputs
#############################################

output "all_distribution_ids" {
  description = "List of all CloudFront distribution IDs"
  value = [
    aws_cloudfront_distribution.public_media.id,
    aws_cloudfront_distribution.frontend.id,
  ]
}

output "all_distribution_arns" {
  description = "List of all CloudFront distribution ARNs"
  value = [
    aws_cloudfront_distribution.public_media.arn,
    aws_cloudfront_distribution.frontend.arn,
  ]
}

output "all_distribution_domain_names" {
  description = "List of all CloudFront distribution domain names"
  value = [
    aws_cloudfront_distribution.public_media.domain_name,
    aws_cloudfront_distribution.frontend.domain_name,
  ]
}

#############################################
# URLs for Access
#############################################

output "public_media_url" {
  description = "URL for accessing public media (custom domain or CloudFront)"
  value       = var.media_domain_name != "" ? "https://${var.media_domain_name}" : "https://${aws_cloudfront_distribution.public_media.domain_name}"
}

output "frontend_url" {
  description = "URL for accessing frontend application (custom domain or CloudFront)"
  value       = var.frontend_domain_name != "" ? "https://${var.frontend_domain_name}" : "https://${aws_cloudfront_distribution.frontend.domain_name}"
}
