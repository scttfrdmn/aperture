# Cognito Module with ORCID Federation

This module creates and manages AWS Cognito User Pool with ORCID authentication integration for the Aperture platform.

## Features

- **ORCID Integration**: Seamless federated authentication with ORCID iD
- **Password Policy**: Configurable strong password requirements
- **MFA Support**: Optional or required multi-factor authentication
- **RBAC Groups**: Pre-configured roles (admins, researchers, reviewers, users)
- **Advanced Security**: Compromised credentials detection and account takeover prevention
- **Email Integration**: SES support for custom email templates
- **Custom Domain**: Optional custom domain for hosted UI
- **API Client**: Machine-to-machine authentication support
- **CloudWatch Logging**: Comprehensive event logging
- **Risk Configuration**: Adaptive authentication based on risk assessment

## ORCID Integration

### What is ORCID?

[ORCID](https://orcid.org) (Open Researcher and Contributor ID) provides researchers with a unique, persistent identifier that distinguishes them from other researchers. It's widely adopted in academic publishing and research data management.

### ORCID Setup

1. **Register for ORCID API Credentials**:
   - Production: https://orcid.org/developer-tools
   - Sandbox (testing): https://sandbox.orcid.org/developer-tools

2. **Create an Application**:
   - Name: Aperture Research Platform
   - Description: AI-powered research media repository
   - Redirect URIs: `https://your-cognito-domain.auth.region.amazoncognito.com/oauth2/idpresponse`

3. **Configure Scopes**:
   - `openid`: Required for authentication
   - `email`: Access to user's email
   - `profile`: Access to user's name

### ORCID Environments

**Sandbox** (Development/Testing):
- ORCID Issuer: `https://sandbox.orcid.org`
- Use test ORCID iDs
- Data is reset periodically

**Production**:
- ORCID Issuer: `https://orcid.org`
- Real user accounts
- Production API credentials required

## Usage

### Basic Configuration with ORCID

```hcl
module "cognito" {
  source = "./modules/cognito"

  project_name = "aperture"
  environment  = "prod"

  # ORCID Configuration
  enable_orcid         = true
  orcid_client_id      = var.orcid_client_id
  orcid_client_secret  = var.orcid_client_secret
  orcid_environment    = "production" # or "sandbox"

  # OAuth Configuration
  callback_urls = [
    "https://aperture.university.edu/callback",
    "http://localhost:3000/callback"
  ]
  logout_urls = [
    "https://aperture.university.edu",
    "http://localhost:3000"
  ]

  # Email Configuration
  from_email_address = "no-reply@aperture.university.edu"
  support_email      = "support@aperture.university.edu"

  tags = {
    Project = "Aperture"
  }
}
```

### With Custom Domain

```hcl
module "cognito" {
  source = "./modules/cognito"

  project_name = "aperture"
  environment  = "prod"

  # Custom domain for hosted UI
  custom_domain   = "auth.aperture.university.edu"
  certificate_arn = aws_acm_certificate.auth.arn

  enable_orcid        = true
  orcid_client_id     = var.orcid_client_id
  orcid_client_secret = var.orcid_client_secret

  callback_urls = [
    "https://aperture.university.edu/callback"
  ]

  tags = {
    Project = "Aperture"
  }
}
```

### With SES Email Integration

```hcl
resource "aws_ses_email_identity" "cognito" {
  email = "no-reply@aperture.university.edu"
}

module "cognito" {
  source = "./modules/cognito"

  project_name = "aperture"
  environment  = "prod"

  # SES Configuration
  ses_email_identity     = aws_ses_email_identity.cognito.arn
  from_email_address     = "no-reply@aperture.university.edu"
  reply_to_email_address = "support@aperture.university.edu"

  enable_orcid        = true
  orcid_client_id     = var.orcid_client_id
  orcid_client_secret = var.orcid_client_secret

  callback_urls = ["https://aperture.university.edu/callback"]

  tags = {
    Project = "Aperture"
  }
}
```

### Development/Testing Configuration

```hcl
module "cognito" {
  source = "./modules/cognito"

  project_name = "aperture"
  environment  = "dev"

  # Use ORCID sandbox for testing
  enable_orcid        = true
  orcid_environment   = "sandbox"
  orcid_client_id     = var.orcid_sandbox_client_id
  orcid_client_secret = var.orcid_sandbox_client_secret

  # Relaxed security for development
  deletion_protection    = false
  advanced_security_mode = "AUDIT"
  mfa_configuration      = "OPTIONAL"

  callback_urls = [
    "http://localhost:3000/callback"
  ]
  logout_urls = [
    "http://localhost:3000"
  ]

  tags = {
    Environment = "Development"
  }
}
```

## User Groups

The module creates four pre-configured user groups:

### 1. Admins (precedence: 1)
- Full system access
- User management
- System configuration
- Budget and cost controls

### 2. Researchers (precedence: 10)
- Create and manage datasets
- Upload media files
- Mint DOIs
- Access all public and owned private data

### 3. Reviewers (precedence: 20)
- Access restricted datasets
- Review and approve submissions
- Read-only access to private data

### 4. Users (precedence: 30)
- Access public datasets
- Download and stream media
- Basic search and discovery

## Security Features

### Password Policy
- Minimum length: 12 characters (configurable)
- Requires: lowercase, uppercase, numbers, symbols
- Temporary passwords valid for 7 days

### MFA (Multi-Factor Authentication)
- Configurable: OFF, OPTIONAL, or ON
- Supports TOTP (Time-based One-Time Password)
- Software token MFA (Google Authenticator, Authy, etc.)

### Advanced Security
- **AUDIT**: Logs risky sign-ins without blocking
- **ENFORCED**: Blocks risky sign-ins automatically
- Detects:
  - Compromised credentials
  - Account takeover attempts
  - Unusual geographic locations
  - Device fingerprint changes

### Risk-Based Authentication
- Low risk: Normal sign-in
- Medium risk: MFA challenge (if configured)
- High risk: MFA required + email notification
- Compromised credentials: Automatic blocking

### Device Tracking
- Remembers trusted devices
- Challenges new devices
- User controls device trust

## OAuth 2.0 / OpenID Connect

### Endpoints

After deployment, the module provides these OAuth endpoints:

```
Authorization: https://{domain}.auth.{region}.amazoncognito.com/oauth2/authorize
Token:         https://{domain}.auth.{region}.amazoncognito.com/oauth2/token
UserInfo:      https://{domain}.auth.{region}.amazoncognito.com/oauth2/userInfo
JWKS:          https://cognito-idp.{region}.amazonaws.com/{pool-id}/.well-known/jwks.json
```

### Supported Flows
- **Authorization Code**: For web applications (recommended)
- **Implicit**: For single-page applications (legacy)
- **Client Credentials**: For machine-to-machine (API client)

### Tokens
- **ID Token**: 1 hour (configurable)
- **Access Token**: 1 hour (configurable)
- **Refresh Token**: 30 days (configurable)

## Integration Examples

### Frontend (React)

```javascript
import { CognitoAuth } from 'amazon-cognito-auth-js';

const auth = new CognitoAuth({
  ClientId: '<web_app_client_id>',
  AppWebDomain: '<user_pool_domain>',
  TokenScopesArray: ['openid', 'email', 'profile'],
  RedirectUriSignIn: 'https://aperture.university.edu/callback',
  RedirectUriSignOut: 'https://aperture.university.edu',
  IdentityProvider: 'ORCID', // Use ORCID for sign-in
  UserPoolId: '<user_pool_id>',
});

// Sign in with ORCID
auth.getSession();
```

### Backend (Python)

```python
import boto3

cognito = boto3.client('cognito-idp')

# Verify JWT token
response = cognito.get_user(
    AccessToken='user_access_token'
)

# Get user attributes
email = next(attr['Value'] for attr in response['UserAttributes'] if attr['Name'] == 'email')
orcid = next(attr['Value'] for attr in response['UserAttributes'] if attr['Name'] == 'custom:orcid')
```

### CLI Authentication

```bash
# Using AWS CLI with API client credentials
aws cognito-idp initiate-auth \
  --auth-flow CLIENT_CREDENTIALS \
  --client-id <api_client_id> \
  --auth-parameters CLIENT_SECRET=<api_client_secret>
```

## Custom Attributes

The module defines these custom attributes for research workflows:

- `custom:orcid` - ORCID iD (0000-0000-0000-0000)
- `custom:institution` - Research institution
- `custom:role` - Research role/position

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| project_name | Project name | string | - | yes |
| environment | Environment | string | - | yes |
| enable_orcid | Enable ORCID provider | bool | true | no |
| orcid_client_id | ORCID OAuth client ID | string | "" | conditional |
| orcid_client_secret | ORCID OAuth client secret | string | "" | conditional |
| orcid_environment | ORCID environment | string | "sandbox" | no |
| callback_urls | OAuth callback URLs | list(string) | [] | no |
| logout_urls | OAuth logout URLs | list(string) | [] | no |
| password_minimum_length | Min password length | number | 12 | no |
| mfa_configuration | MFA setting | string | "OPTIONAL" | no |
| advanced_security_mode | Security mode | string | "ENFORCED" | no |
| deletion_protection | Enable deletion protection | bool | true | no |
| custom_domain | Custom domain | string | null | no |
| certificate_arn | ACM certificate ARN | string | null | no |
| ses_email_identity | SES identity ARN | string | null | no |
| from_email_address | From email | string | null | no |
| create_api_client | Create API client | bool | true | no |
| enable_cloudwatch_logs | Enable CloudWatch logs | bool | true | no |
| enable_risk_configuration | Enable risk config | bool | true | no |
| tags | Additional tags | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| user_pool_id | Cognito user pool ID |
| user_pool_arn | Cognito user pool ARN |
| web_app_client_id | Web app client ID |
| api_client_id | API client ID (if created) |
| api_client_secret | API client secret (sensitive) |
| user_pool_domain | Cognito hosted UI domain |
| oauth_authorize_url | OAuth authorization endpoint |
| oauth_token_url | OAuth token endpoint |
| orcid_provider_name | ORCID provider name (if enabled) |

## Cost Estimate

**Cognito Pricing** (as of 2025):
- **Free Tier**: 50,000 MAUs (Monthly Active Users)
- **Beyond Free Tier**: $0.0055 per MAU
- **Advanced Security**: +$0.05 per MAU

**Example**:
- 1,000 active users/month: Free
- 100,000 active users/month: $275/month ($0.0055 × 50,000 beyond free tier)
- With advanced security: $5,275/month

**Email Costs**:
- Cognito default: Free (10,000 emails/month)
- SES: $0.10 per 1,000 emails

## Troubleshooting

### ORCID Connection Issues
1. Verify client ID and secret are correct
2. Check redirect URI matches exactly
3. Ensure ORCID environment (sandbox vs production) matches
4. Verify ORCID scopes are configured

### Custom Domain Not Working
1. Ensure ACM certificate is in us-east-1 region
2. Verify DNS CNAME record points to CloudFront
3. Allow 24-48 hours for DNS propagation

### MFA Not Working
1. Verify MFA is enabled in configuration
2. Check user has enrolled MFA device
3. Ensure time sync on authenticator app

## Roadmap

- [x] ORCID integration
- [ ] Globus Auth integration (see Issue #16)
- [ ] InCommon/Shibboleth federation
- [ ] GitHub OAuth integration
- [ ] Google Workspace integration

## Security Best Practices

1. **Always use ENFORCED advanced security in production**
2. **Enable deletion protection for production pools**
3. **Use custom domain with SSL certificate**
4. **Configure SES for professional emails**
5. **Enable CloudWatch logging for audit trails**
6. **Require MFA for admin users**
7. **Regularly rotate API client secrets**
8. **Monitor CloudWatch logs for suspicious activity**

## License

Copyright 2025 Scott Friedman

Licensed under the Apache License, Version 2.0.
