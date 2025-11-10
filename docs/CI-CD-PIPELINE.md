# CI/CD Pipeline Documentation

Complete guide to the Aperture CI/CD pipeline using GitHub Actions.

## Overview

The Aperture project uses GitHub Actions for continuous integration and deployment with three main workflows:

1. **CI Workflow** (`ci.yml`) - Automated testing and validation on every push/PR
2. **Terraform PR Workflow** (`terraform-pr.yml`) - Terraform plan preview in PR comments
3. **Deploy Workflow** (`deploy.yml`) - Manual infrastructure deployment

## Workflow Details

### 1. CI Workflow (`.github/workflows/ci.yml`)

**Triggers**: Push to `main` or `develop`, Pull Requests

**Jobs**:

#### terraform-validate
Validates all Terraform modules:
- Format check (`terraform fmt`)
- Initialization (`terraform init`)
- Validation (`terraform validate`)

**Modules validated**:
- DynamoDB
- S3
- Cognito
- CloudFront
- EventBridge
- Lambda
- API Gateway

#### lambda-tests
Tests Python Lambda functions:
- Python 3.11 setup
- Dependency installation
- Syntax checking (`py_compile`)
- Linting (`pylint`)

#### terraform-docs
Documentation checks:
- Verifies README.md exists in all modules
- Checks CHANGELOG.md updated in PRs

#### security
Security scanning:
- Checkov (Terraform security scanner)
- Soft fail mode (warns but doesn't block)

### 2. Terraform PR Workflow (`.github/workflows/terraform-pr.yml`)

**Triggers**: Pull Requests modifying `.tf` or `.tfvars` files

**Features**:
- Runs Terraform plan on PR
- Posts plan results as PR comment
- Shows format, init, validate, and plan results
- Helps reviewers understand infrastructure changes

**Output**:
```
#### Terraform Format and Style 🖌 success
#### Terraform Initialization ⚙️ success
#### Terraform Validation 🤖 success
#### Terraform Plan 📖 success

<details><summary>Show Plan</summary>
... (terraform plan output)
</details>
```

### 3. Deploy Workflow (`.github/workflows/deploy.yml`)

**Trigger**: Manual (`workflow_dispatch`)

**Inputs**:
- `environment`: dev / staging / prod
- `terraform_action`: plan / apply / destroy

**Features**:
- Manual approval required for destroy operations
- AWS OIDC authentication
- Environment-specific deployments
- Terraform state management
- Output artifacts (plan files, outputs)

**Workflow**:
1. Checkout code
2. Setup Terraform
3. Configure AWS credentials (OIDC)
4. Terraform init
5. Run selected action (plan/apply/destroy)
6. Upload artifacts
7. Notify status

## Setup Instructions

### 1. AWS Configuration

#### Option A: OIDC (Recommended)

Configure AWS IAM Identity Provider for GitHub:

```bash
# Create OIDC provider
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1

# Create IAM role with trust policy
aws iam create-role --role-name GitHubActionsDeployRole \
  --assume-role-policy-document file://trust-policy.json
```

**trust-policy.json**:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:scttfrdmn/aperture:*"
        }
      }
    }
  ]
}
```

Attach administrator policy (or custom policy):
```bash
aws iam attach-role-policy \
  --role-name GitHubActionsDeployRole \
  --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
```

#### Option B: Access Keys (Not Recommended)

If OIDC is not available, use access keys:
- Create IAM user for GitHub Actions
- Generate access key
- Store in GitHub secrets

### 2. GitHub Secrets

Configure secrets in **Settings → Secrets and variables → Actions**:

**Required**:
- `AWS_ROLE_ARN` - ARN of GitHub Actions IAM role
  - Example: `arn:aws:iam::123456789012:role/GitHubActionsDeployRole`
- `AWS_REGION` - AWS region (default: us-east-1)
- `DATACITE_USERNAME` - DataCite API username
- `DATACITE_PASSWORD` - DataCite API password
- `ORCID_CLIENT_ID` - ORCID OAuth client ID
- `ORCID_CLIENT_SECRET` - ORCID OAuth client secret

**Optional**:
- `AWS_ACCESS_KEY_ID` - If using access keys
- `AWS_SECRET_ACCESS_KEY` - If using access keys

### 3. GitHub Environments

Create environments in **Settings → Environments**:

#### dev
- No protection rules
- Secrets: environment-specific values

#### staging
- Optional: Required reviewers
- Secrets: environment-specific values

#### prod
- **Required**: Required reviewers (1+ approvals)
- **Required**: Wait timer (5+ minutes)
- Secrets: production values

### 4. Environment Configuration Files

Create environment-specific tfvars:

```bash
# Copy templates
cp environments/dev.tfvars.example environments/dev.tfvars
cp environments/staging.tfvars.example environments/staging.tfvars
cp environments/prod.tfvars.example environments/prod.tfvars

# Edit each file with your values
# DO NOT commit these files (they're in .gitignore)
```

**Note**: Sensitive values should be stored in GitHub secrets, not tfvars files.

### 5. Terraform Backend

Configure S3 backend in `main.tf`:

```hcl
terraform {
  backend "s3" {
    bucket = "your-terraform-state-bucket"
    key    = "aperture/terraform.tfstate"
    region = "us-east-1"

    # Optional: Enable state locking
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}
```

Create backend resources:

```bash
# Create S3 bucket for state
aws s3 mb s3://your-terraform-state-bucket --region us-east-1

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket your-terraform-state-bucket \
  --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket your-terraform-state-bucket \
  --server-side-encryption-configuration \
  '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'

# Create DynamoDB table for locking (optional)
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST
```

## Usage

### Running CI on Pull Requests

CI runs automatically on all PRs:

```bash
# Create PR
git checkout -b feature/my-feature
git commit -am "Add feature"
git push -u origin feature/my-feature
gh pr create

# CI runs automatically:
# ✓ Terraform validation
# ✓ Lambda tests
# ✓ Documentation checks
# ✓ Security scanning
# ✓ Terraform plan (with PR comment)
```

### Deploying to Development

```bash
# Navigate to Actions → Deploy Infrastructure
# Or use GitHub CLI:
gh workflow run deploy.yml \
  -f environment=dev \
  -f terraform_action=plan

# Review plan, then apply:
gh workflow run deploy.yml \
  -f environment=dev \
  -f terraform_action=apply
```

### Deploying to Production

```bash
# 1. Plan
gh workflow run deploy.yml \
  -f environment=prod \
  -f terraform_action=plan

# 2. Review plan output in Actions

# 3. Apply (requires approval in GitHub)
gh workflow run deploy.yml \
  -f environment=prod \
  -f terraform_action=apply

# 4. Approve deployment in GitHub UI
```

### Destroying Infrastructure

**⚠️ DANGER: This will destroy all infrastructure**

```bash
# Requires manual approval
gh workflow run deploy.yml \
  -f environment=dev \
  -f terraform_action=destroy

# Approve in GitHub issue that gets created
```

## Workflow Artifacts

Workflows generate artifacts:

### Terraform Plan
- **Name**: `tfplan-{environment}`
- **Retention**: 5 days
- **Contents**: Binary Terraform plan file

### Terraform Outputs
- **Name**: `terraform-outputs-{environment}`
- **Retention**: 30 days
- **Contents**: JSON file with all Terraform outputs

Download artifacts:

```bash
# List artifacts
gh run list --workflow=deploy.yml --limit 1

# Download specific artifact
gh run download <run-id> -n tfplan-prod
```

## Security Best Practices

### 1. Secrets Management
- ✅ Use GitHub secrets for credentials
- ✅ Use environment-specific secrets
- ✅ Rotate credentials regularly
- ❌ Never commit credentials to repository
- ❌ Never log secrets in workflow outputs

### 2. Access Control
- ✅ Require approvals for production deployments
- ✅ Limit who can approve production changes
- ✅ Use branch protection rules
- ✅ Enable audit logging

### 3. Terraform State
- ✅ Use S3 backend with encryption
- ✅ Enable versioning on state bucket
- ✅ Use DynamoDB for state locking
- ✅ Restrict access to state bucket
- ❌ Never commit state files

### 4. OIDC Authentication
- ✅ Use OIDC instead of access keys
- ✅ Limit OIDC trust to specific repository
- ✅ Use least-privilege IAM policies
- ✅ Audit IAM role usage

## Troubleshooting

### Workflow Fails with "Error: Configuring Terraform AWS Provider"

**Cause**: AWS credentials not configured or invalid

**Solution**:
1. Verify `AWS_ROLE_ARN` secret is set
2. Check IAM role exists and has correct trust policy
3. Verify repository name in trust policy matches

### Terraform Plan Shows Many Changes Unexpectedly

**Cause**: Terraform state out of sync

**Solution**:
1. Check if resources were modified outside Terraform
2. Review state file in S3 bucket
3. Consider importing resources or refreshing state

### Security Scan Failing

**Cause**: Checkov found security issues

**Solution**:
1. Review Checkov output in workflow logs
2. Fix security issues or add exceptions
3. Security scan is soft-fail by default (won't block)

### Deploy Workflow Times Out

**Cause**: Large infrastructure changes or resource creation delays

**Solution**:
1. Check AWS console for resources stuck creating
2. Review workflow timeout settings
3. Consider breaking deployment into smaller chunks

### Lambda Tests Failing

**Cause**: Syntax errors or import issues in Lambda code

**Solution**:
1. Test Lambda functions locally
2. Check all dependencies are in requirements.txt
3. Verify Python version matches (3.11)

## Monitoring

### GitHub Actions Logs

View logs:
```bash
# Recent workflow runs
gh run list

# View specific run
gh run view <run-id>

# View logs
gh run view <run-id> --log
```

### Workflow Status Badges

Add to README.md:

```markdown
![CI](https://github.com/scttfrdmn/aperture/workflows/CI/badge.svg)
![Deploy](https://github.com/scttfrdmn/aperture/workflows/Deploy%20Infrastructure/badge.svg)
```

## Cost Optimization

GitHub Actions pricing:
- **Public repos**: Free unlimited minutes
- **Private repos**: 2,000 free minutes/month, then $0.008/minute

Typical usage:
- CI workflow: ~5 minutes per run
- Deploy workflow: ~10-15 minutes per run
- Estimated monthly cost (private repo, 100 runs): ~$8-12

Tips:
- Use caching for dependencies
- Run workflows only on relevant file changes
- Use smaller runners when possible

## Future Enhancements

Planned improvements:
- [ ] Add integration tests with localstack
- [ ] Implement automated rollback on failures
- [ ] Add Slack/email notifications
- [ ] Implement blue-green deployments
- [ ] Add cost estimation in PR comments
- [ ] Implement drift detection
- [ ] Add compliance scanning (NIST 800-171)

## References

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Terraform GitHub Actions](https://github.com/hashicorp/setup-terraform)
- [AWS OIDC with GitHub Actions](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)
- [Checkov Security Scanner](https://www.checkov.io/)

## Support

For issues or questions:
- Open an issue on GitHub
- Check workflow logs for errors
- Review Terraform state in S3
- Consult AWS CloudWatch logs for Lambda/API Gateway issues
