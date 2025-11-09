# Cognito User Pool Module with ORCID Federation
# Copyright 2025 Scott Friedman
# Manages authentication and authorization for Aperture

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Cognito User Pool
resource "aws_cognito_user_pool" "main" {
  name = "${var.project_name}-users-${var.environment}"

  # Username configuration
  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]

  username_configuration {
    case_sensitive = false
  }

  # Password policy
  password_policy {
    minimum_length                   = var.password_minimum_length
    require_lowercase                = var.password_require_lowercase
    require_uppercase                = var.password_require_uppercase
    require_numbers                  = var.password_require_numbers
    require_symbols                  = var.password_require_symbols
    temporary_password_validity_days = var.temporary_password_validity_days
  }

  # Account recovery
  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  # Email configuration
  email_configuration {
    email_sending_account  = var.ses_email_identity != null ? "DEVELOPER" : "COGNITO_DEFAULT"
    source_arn             = var.ses_email_identity
    from_email_address     = var.from_email_address
    reply_to_email_address = var.reply_to_email_address
  }

  # MFA configuration
  mfa_configuration = var.mfa_configuration

  dynamic "software_token_mfa_configuration" {
    for_each = var.mfa_configuration != "OFF" ? [1] : []
    content {
      enabled = true
    }
  }

  # User attribute schema
  schema {
    name                     = "email"
    attribute_data_type      = "String"
    required                 = true
    mutable                  = true
    developer_only_attribute = false

    string_attribute_constraints {
      min_length = 1
      max_length = 256
    }
  }

  schema {
    name                     = "name"
    attribute_data_type      = "String"
    required                 = false
    mutable                  = true
    developer_only_attribute = false

    string_attribute_constraints {
      min_length = 1
      max_length = 256
    }
  }

  # Custom attributes for ORCID and research metadata
  schema {
    name                     = "orcid"
    attribute_data_type      = "String"
    required                 = false
    mutable                  = true
    developer_only_attribute = false

    string_attribute_constraints {
      min_length = 1
      max_length = 19 # ORCID format: 0000-0000-0000-0000
    }
  }

  schema {
    name                     = "institution"
    attribute_data_type      = "String"
    required                 = false
    mutable                  = true
    developer_only_attribute = false

    string_attribute_constraints {
      min_length = 1
      max_length = 256
    }
  }

  schema {
    name                     = "role"
    attribute_data_type      = "String"
    required                 = false
    mutable                  = true
    developer_only_attribute = false

    string_attribute_constraints {
      min_length = 1
      max_length = 50
    }
  }

  # Account takeover prevention
  user_pool_add_ons {
    advanced_security_mode = var.advanced_security_mode
  }

  # Device tracking
  device_configuration {
    challenge_required_on_new_device      = true
    device_only_remembered_on_user_prompt = true
  }

  # Deletion protection
  deletion_protection = var.deletion_protection ? "ACTIVE" : "INACTIVE"

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-user-pool-${var.environment}"
      Purpose     = "User authentication and authorization"
      Environment = var.environment
    }
  )
}

# User Pool Domain
resource "aws_cognito_user_pool_domain" "main" {
  domain       = "${var.project_name}-${var.environment}"
  user_pool_id = aws_cognito_user_pool.main.id
}

# Custom domain (optional)
resource "aws_cognito_user_pool_domain" "custom" {
  count = var.custom_domain != null ? 1 : 0

  domain          = var.custom_domain
  certificate_arn = var.certificate_arn
  user_pool_id    = aws_cognito_user_pool.main.id
}

# ORCID Identity Provider
resource "aws_cognito_identity_provider" "orcid" {
  count = var.enable_orcid ? 1 : 0

  user_pool_id  = aws_cognito_user_pool.main.id
  provider_name = "ORCID"
  provider_type = "OIDC"

  provider_details = {
    client_id                 = var.orcid_client_id
    client_secret             = var.orcid_client_secret
    authorize_scopes          = var.orcid_scopes
    attributes_request_method = "GET"
    oidc_issuer               = var.orcid_environment == "production" ? "https://orcid.org" : "https://sandbox.orcid.org"
    authorize_url             = var.orcid_environment == "production" ? "https://orcid.org/oauth/authorize" : "https://sandbox.orcid.org/oauth/authorize"
    token_url                 = var.orcid_environment == "production" ? "https://orcid.org/oauth/token" : "https://sandbox.orcid.org/oauth/token"
    attributes_url            = var.orcid_environment == "production" ? "https://pub.orcid.org/v3.0" : "https://pub.sandbox.orcid.org/v3.0"
    jwks_uri                  = var.orcid_environment == "production" ? "https://orcid.org/oauth/jwks" : "https://sandbox.orcid.org/oauth/jwks"
  }

  attribute_mapping = {
    email          = "email"
    name           = "name"
    username       = "sub"
    "custom:orcid" = "sub"
  }
}

# App Client for Web Application
resource "aws_cognito_user_pool_client" "web_app" {
  name         = "${var.project_name}-web-app-${var.environment}"
  user_pool_id = aws_cognito_user_pool.main.id

  # OAuth configuration
  generate_secret                      = false
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code", "implicit"]
  allowed_oauth_scopes                 = ["email", "openid", "profile", "aws.cognito.signin.user.admin"]
  callback_urls                        = var.callback_urls
  logout_urls                          = var.logout_urls
  default_redirect_uri                 = length(var.callback_urls) > 0 ? var.callback_urls[0] : null

  # Supported identity providers
  supported_identity_providers = concat(
    ["COGNITO"],
    var.enable_orcid ? ["ORCID"] : []
  )

  # Token validity
  id_token_validity      = var.id_token_validity
  access_token_validity  = var.access_token_validity
  refresh_token_validity = var.refresh_token_validity

  token_validity_units {
    id_token      = "hours"
    access_token  = "hours"
    refresh_token = "days"
  }

  # Read/write attributes
  read_attributes = [
    "email",
    "email_verified",
    "name",
    "custom:orcid",
    "custom:institution",
    "custom:role",
  ]

  write_attributes = [
    "email",
    "name",
    "custom:orcid",
    "custom:institution",
    "custom:role",
  ]

  # Prevent destruction of client
  prevent_user_existence_errors = "ENABLED"

  # Enable token revocation
  enable_token_revocation = true

  # Auth session validity
  auth_session_validity = 3
}

# App Client for API/CLI
resource "aws_cognito_user_pool_client" "api_client" {
  count = var.create_api_client ? 1 : 0

  name         = "${var.project_name}-api-client-${var.environment}"
  user_pool_id = aws_cognito_user_pool.main.id

  # OAuth configuration for machine-to-machine
  generate_secret                      = true
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["client_credentials"]
  allowed_oauth_scopes                 = var.api_client_scopes
  supported_identity_providers         = ["COGNITO"]

  # Token validity (shorter for API clients)
  access_token_validity = 1

  token_validity_units {
    access_token = "hours"
  }

  prevent_user_existence_errors = "ENABLED"
  enable_token_revocation       = true
}

# User Pool Groups for RBAC
resource "aws_cognito_user_group" "admins" {
  name         = "admins"
  user_pool_id = aws_cognito_user_pool.main.id
  description  = "Administrators with full access"
  precedence   = 1
}

resource "aws_cognito_user_group" "researchers" {
  name         = "researchers"
  user_pool_id = aws_cognito_user_pool.main.id
  description  = "Researchers who can create and manage datasets"
  precedence   = 10
}

resource "aws_cognito_user_group" "reviewers" {
  name         = "reviewers"
  user_pool_id = aws_cognito_user_pool.main.id
  description  = "Reviewers who can access restricted datasets"
  precedence   = 20
}

resource "aws_cognito_user_group" "users" {
  name         = "users"
  user_pool_id = aws_cognito_user_pool.main.id
  description  = "Authenticated users with read access"
  precedence   = 30
}

# CloudWatch Log Group for user pool events
resource "aws_cloudwatch_log_group" "cognito_logs" {
  count = var.enable_cloudwatch_logs ? 1 : 0

  name              = "/aws/cognito/${var.project_name}-${var.environment}"
  retention_in_days = var.log_retention_days

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-cognito-logs-${var.environment}"
      Environment = var.environment
    }
  )
}

# Risk configuration for compromised credentials detection
resource "aws_cognito_risk_configuration" "main" {
  count = var.enable_risk_configuration ? 1 : 0

  user_pool_id = aws_cognito_user_pool.main.id

  compromised_credentials_risk_configuration {
    event_filter = ["SIGN_IN", "PASSWORD_CHANGE", "SIGN_UP"]

    actions {
      event_action = var.compromised_credentials_action
    }
  }

  account_takeover_risk_configuration {
    actions {
      high_action {
        event_action = "MFA_IF_CONFIGURED"
        notify       = true
      }

      medium_action {
        event_action = "MFA_IF_CONFIGURED"
        notify       = true
      }

      low_action {
        event_action = "NO_ACTION"
        notify       = false
      }
    }

    notify_configuration {
      from       = var.from_email_address
      reply_to   = var.reply_to_email_address
      source_arn = var.ses_email_identity

      block_email {
        subject   = "Account Temporarily Blocked"
        html_body = "Your account has been temporarily blocked due to suspicious activity. Please contact support at ${var.support_email}."
        text_body = "Your account has been temporarily blocked due to suspicious activity. Please contact support at ${var.support_email}."
      }

      mfa_email {
        subject   = "MFA Required"
        html_body = "We detected unusual sign-in activity. For your security, please complete MFA."
        text_body = "We detected unusual sign-in activity. For your security, please complete MFA."
      }

      no_action_email {
        subject   = "New Sign-in Location Detected"
        html_body = "We detected a sign-in from a new location."
        text_body = "We detected a sign-in from a new location."
      }
    }
  }
}
