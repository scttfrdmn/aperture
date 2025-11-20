# AWS Bedrock Integration Guide

## Overview

Aperture integrates AWS Bedrock to provide AI-powered analysis capabilities for academic media, with a focus on archaeological research artifacts. This integration leverages foundation models from Anthropic (Claude 3 Sonnet) and Amazon (Titan) to enable automated metadata extraction, artifact classification, description generation, and visual similarity search.

## Table of Contents

- [Features](#features)
- [Architecture](#architecture)
- [API Endpoints](#api-endpoints)
- [Lambda Function](#lambda-function)
- [Frontend Integration](#frontend-integration)
- [Best Practices](#best-practices)
- [Limitations](#limitations)
- [Cost Considerations](#cost-considerations)

## Features

### 1. Image Analysis

Analyze artifacts with detailed visual descriptions, including:
- Physical characteristics (size, shape, color, texture)
- Condition assessment
- Notable features
- Research-relevant observations

**Use Case:** Initial cataloging of newly excavated artifacts

### 2. Metadata Extraction

Automatically extract structured metadata following archaeological standards:
- CIDOC-CRM compliant schemas
- Customizable field extraction
- Support for both artifact and dataset metadata types

**Use Case:** Bulk metadata generation for large collections

### 3. Artifact Classification

Identify and classify artifacts with confidence scores:
- Artifact type (pottery, tool, sculpture, etc.)
- Historical period (Neolithic, Bronze Age, etc.)
- Cultural origin
- Material composition

**Use Case:** Preliminary identification before expert verification

### 4. Description Generation

Generate publication-ready descriptions in multiple styles:
- **Academic**: Formal, technical descriptions for papers
- **Catalog**: Museum catalog-style entries
- **Public**: Accessible descriptions for general audiences

**Use Case:** Creating descriptions for exhibitions or publications

### 5. Text Extraction (OCR)

Extract text from images for:
- Inscriptions and engravings
- Field notes and labels
- Annotations and markings

**Use Case:** Digitizing handwritten field notes

### 6. Embedding Generation

Create vector embeddings for:
- Visual similarity search
- Clustering similar artifacts
- Cross-collection comparisons

**Use Case:** Finding stylistically similar artifacts across collections

### 7. Batch Processing

Process multiple images in a single operation:
- Up to 10 images per batch
- Consistent analysis parameters
- Parallel processing for efficiency

**Use Case:** Processing all images from a single excavation site

## Architecture

```
┌─────────────┐     ┌──────────────┐     ┌─────────────┐     ┌──────────┐
│  Frontend   │────▶│ API Gateway  │────▶│   Lambda    │────▶│ Bedrock  │
│   React     │     │   HTTP API   │     │   Python    │     │  Models  │
└─────────────┘     └──────────────┘     └─────────────┘     └──────────┘
                                                │
                                                ▼
                                          ┌──────────┐
                                          │    S3    │
                                          │  Buckets │
                                          └──────────┘
```

### Components

1. **Frontend (React + Cloudscape)**
   - AI Analysis page (`/ai-analysis`)
   - API service methods
   - Results visualization

2. **API Gateway**
   - 7 protected routes under `/ai/*`
   - JWT authorization via Cognito
   - Request/response logging

3. **Lambda Function**
   - Handler: `lambda/bedrock-analysis/handler.py`
   - Runtime: Python 3.11
   - Memory: 1024 MB
   - Timeout: 120 seconds

4. **Bedrock Models**
   - `anthropic.claude-3-sonnet-20240229-v1:0` - Vision and text analysis
   - `amazon.titan-embed-image-v1` - Image embeddings
   - `amazon.titan-image-generator-v1` - Future image generation (placeholder)

5. **S3 Storage**
   - All 4 buckets accessible (public, private, restricted, embargoed)
   - Read-only access for analysis
   - Pre-signed URLs for secure access

## API Endpoints

All endpoints require JWT authentication via Cognito.

### POST /ai/analyze-image

Analyze an image with custom or default prompts.

**Request:**
```json
{
  "bucket": "aperture-public-media",
  "key": "datasets/artifact-001/photo.jpg",
  "prompt": "Describe this ceramic artifact in detail, including style and possible origin."
}
```

**Response:**
```json
{
  "analysis": "This appears to be a ceramic vessel fragment from the Bronze Age period...",
  "model": "anthropic.claude-3-sonnet-20240229-v1:0",
  "timestamp": "2024-11-10T20:00:00Z"
}
```

### POST /ai/extract-metadata

Extract structured metadata from an image.

**Request:**
```json
{
  "bucket": "aperture-public-media",
  "key": "datasets/artifact-001/photo.jpg",
  "schema_type": "artifact"
}
```

**Response:**
```json
{
  "metadata": {
    "artifact_type": "Pottery",
    "period": "Bronze Age",
    "material": "Ceramic",
    "dimensions": {
      "height": "15cm",
      "diameter": "10cm"
    },
    "condition": "Fragmentary",
    "decoration": "Geometric patterns"
  },
  "timestamp": "2024-11-10T20:00:00Z"
}
```

### POST /ai/classify-artifact

Classify an artifact with confidence scores.

**Request:**
```json
{
  "bucket": "aperture-public-media",
  "key": "datasets/artifact-001/photo.jpg"
}
```

**Response:**
```json
{
  "classification": {
    "artifact_type": "Ceramic Vessel",
    "period": "Bronze Age (2000-1500 BCE)",
    "culture": "Minoan",
    "material": "Red clay with slip decoration",
    "confidence": 0.85
  },
  "timestamp": "2024-11-10T20:00:00Z"
}
```

### POST /ai/generate-description

Generate a description in a specific style.

**Request:**
```json
{
  "bucket": "aperture-public-media",
  "key": "datasets/artifact-001/photo.jpg",
  "style": "academic"
}
```

**Response:**
```json
{
  "description": "Fragment of a ceramic vessel, likely a storage jar, dating to the Middle Bronze Age...",
  "style": "academic",
  "word_count": 234,
  "timestamp": "2024-11-10T20:00:00Z"
}
```

### POST /ai/generate-embeddings

Generate vector embeddings for similarity search.

**Request:**
```json
{
  "bucket": "aperture-public-media",
  "key": "datasets/artifact-001/photo.jpg"
}
```

**Response:**
```json
{
  "embeddings": [0.123, -0.456, 0.789, ...],
  "dimensions": 1024,
  "model": "amazon.titan-embed-image-v1",
  "timestamp": "2024-11-10T20:00:00Z"
}
```

### POST /ai/extract-text

Extract text from images (OCR).

**Request:**
```json
{
  "bucket": "aperture-public-media",
  "key": "datasets/field-notes/page-001.jpg"
}
```

**Response:**
```json
{
  "text": "Excavation Site A, Grid 12-B, Depth: 2.3m, Date: June 15, 2024...",
  "confidence": 0.92,
  "timestamp": "2024-11-10T20:00:00Z"
}
```

### POST /ai/analyze-batch

Analyze multiple images in a batch.

**Request:**
```json
{
  "images": [
    {
      "bucket": "aperture-public-media",
      "key": "datasets/artifact-001/photo1.jpg"
    },
    {
      "bucket": "aperture-public-media",
      "key": "datasets/artifact-001/photo2.jpg"
    }
  ],
  "operation": "classify_artifact"
}
```

**Response:**
```json
{
  "results": [
    {
      "key": "datasets/artifact-001/photo1.jpg",
      "classification": { ... },
      "success": true
    },
    {
      "key": "datasets/artifact-001/photo2.jpg",
      "classification": { ... },
      "success": true
    }
  ],
  "total": 2,
  "successful": 2,
  "failed": 0,
  "timestamp": "2024-11-10T20:00:00Z"
}
```

## Lambda Function

### Function Configuration

- **Name**: `aperture-{environment}-bedrock-analysis`
- **Runtime**: Python 3.11
- **Memory**: 1024 MB
- **Timeout**: 120 seconds
- **Handler**: `handler.lambda_handler`

### Environment Variables

```bash
PUBLIC_MEDIA_BUCKET=aperture-dev-public-media
PRIVATE_MEDIA_BUCKET=aperture-dev-private-media
RESTRICTED_MEDIA_BUCKET=aperture-dev-restricted-media
EMBARGOED_MEDIA_BUCKET=aperture-dev-embargoed-media
AWS_REGION=us-east-1
ENVIRONMENT=dev
```

### IAM Permissions

The Lambda function requires the following permissions:

**Bedrock Model Access:**
```json
{
  "Effect": "Allow",
  "Action": [
    "bedrock:InvokeModel",
    "bedrock:InvokeModelWithResponseStream"
  ],
  "Resource": [
    "arn:aws:bedrock:*::foundation-model/anthropic.claude-3-sonnet-20240229-v1:0",
    "arn:aws:bedrock:*::foundation-model/amazon.titan-embed-image-v1",
    "arn:aws:bedrock:*::foundation-model/amazon.titan-image-generator-v1"
  ]
}
```

**S3 Read Access:**
```json
{
  "Effect": "Allow",
  "Action": [
    "s3:GetObject"
  ],
  "Resource": [
    "arn:aws:s3:::aperture-*-media/*"
  ]
}
```

**CloudWatch Logs:**
```json
{
  "Effect": "Allow",
  "Action": [
    "logs:CreateLogGroup",
    "logs:CreateLogStream",
    "logs:PutLogEvents"
  ],
  "Resource": [
    "arn:aws:logs:*:*:log-group:/aws/lambda/aperture-*-bedrock-analysis:*"
  ]
}
```

### Function Structure

```python
def lambda_handler(event, context):
    """
    Main Lambda handler that routes requests to appropriate operations.

    Expected event structure:
    {
        "operation": "analyze_image | extract_metadata | classify_artifact | ...",
        "parameters": { ... }
    }
    """
    # Extract operation and parameters
    # Route to appropriate handler function
    # Return formatted response
```

### Supported Operations

1. `analyze_image` - General image analysis
2. `extract_metadata` - Structured metadata extraction
3. `classify_artifact` - Artifact classification
4. `generate_description` - Description generation
5. `generate_embeddings` - Embedding generation
6. `extract_text` - Text extraction (OCR)
7. `analyze_batch` - Batch processing

## Frontend Integration

### React Component

The AI Analysis page is located at `/ai-analysis` and provides:

- Bucket selection (public, private, restricted, embargoed)
- Object key input
- Operation selection dropdown
- Custom prompt input (for analyze_image)
- Results visualization with expandable sections
- Tabs for analysis and documentation

### API Service Methods

```typescript
// Analyze an image
await api.analyzeImage(bucket, key, prompt);

// Extract metadata
await api.extractMetadata(bucket, key, schemaType);

// Classify artifact
await api.classifyArtifact(bucket, key);

// Generate description
await api.generateDescription(bucket, key, style);

// Generate embeddings
await api.generateEmbeddings(bucket, key);

// Extract text
await api.extractText(bucket, key);

// Batch analysis
await api.analyzeBatch(images, operation);
```

### Navigation

AI Analysis is accessible via:
- Main navigation sidebar under "AI Analysis"
- Home page quick actions card
- Direct URL: `/ai-analysis`

## Best Practices

### Image Quality

- Use high-resolution images (at least 1024x1024 pixels)
- Ensure good lighting and focus
- Include scale markers when relevant
- Photograph from multiple angles for batch analysis

### Prompt Engineering

For `analyze_image`, provide context:

**Good:**
```
"Analyze this Bronze Age ceramic fragment found in Crete.
Focus on decorative patterns, firing technique, and possible function."
```

**Bad:**
```
"Describe this."
```

### Metadata Extraction

- Use `artifact` schema type for individual objects
- Use `dataset` schema type for collections or field records
- Validate extracted metadata with domain experts
- Supplement with manual metadata entry

### Classification Confidence

- Scores > 0.9: High confidence, minimal verification needed
- Scores 0.7-0.9: Good confidence, expert verification recommended
- Scores < 0.7: Low confidence, requires expert review

### Embedding Storage

Store embeddings in a vector database (future enhancement) for:
- Similarity search across collections
- Visual clustering
- Style analysis
- Duplicate detection

### Batch Processing

- Process similar artifacts together
- Use consistent image formats
- Maximum 10 images per batch
- Monitor processing time (typically 30-60 seconds)

## Limitations

### Current Limitations

1. **Model Capabilities**
   - Classification accuracy depends on training data
   - May not recognize very rare or unique artifact types
   - Limited to visual analysis (no chemical/material analysis)

2. **Image Requirements**
   - Maximum image size: 5 MB
   - Supported formats: JPEG, PNG, GIF, WebP
   - Cannot analyze 3D models or video

3. **Processing Time**
   - Single image: 5-15 seconds
   - Batch (10 images): 30-60 seconds
   - Large images may timeout (120s limit)

4. **Language Support**
   - Primary language: English
   - Text extraction supports multiple languages
   - Metadata extraction optimized for English

5. **Context Limitations**
   - Claude 3 Sonnet: 200K token context window
   - Cannot analyze relationships between artifacts without batch processing
   - No temporal analysis (change over time)

### Future Enhancements

- Vector database integration for similarity search
- 3D model analysis support
- Multi-modal analysis (text + image)
- Custom model fine-tuning
- Real-time streaming responses
- Collaborative annotation features

## Cost Considerations

### Bedrock Pricing

**Claude 3 Sonnet (per 1K tokens):**
- Input: $0.003
- Output: $0.015

**Titan Embed Image (per image):**
- $0.00006 per image

### Typical Costs

**Single Image Analysis:**
- Analyze image: ~$0.01
- Extract metadata: ~$0.01
- Classify artifact: ~$0.008
- Generate description: ~$0.012
- Generate embeddings: ~$0.00006
- Extract text: ~$0.008

**Batch Processing (10 images):**
- Classify batch: ~$0.08
- Total with embeddings: ~$0.0806

### Cost Optimization

1. **Cache Results**
   - Store analysis results in DynamoDB
   - Avoid re-analyzing same images
   - Implement TTL for cached results

2. **Batch Processing**
   - More efficient than individual requests
   - Shared context reduces token usage
   - Single API call overhead

3. **Model Selection**
   - Use Claude Haiku for simple tasks (future)
   - Use Claude Sonnet for complex analysis
   - Use Claude Opus only when necessary (future)

4. **Prompt Optimization**
   - Clear, concise prompts reduce token usage
   - Avoid repetitive context
   - Use system prompts effectively

### Monthly Estimates

**Small Research Lab (100 artifacts/month):**
- Analysis: $1.00
- Classification: $0.80
- Embeddings: $0.006
- **Total: ~$2.00/month**

**Medium Museum (1,000 artifacts/month):**
- Analysis: $10.00
- Classification: $8.00
- Embeddings: $0.06
- **Total: ~$18.00/month**

**Large Archive (10,000 artifacts/month):**
- Analysis: $100.00
- Classification: $80.00
- Embeddings: $0.60
- **Total: ~$180.00/month**

## Support and Resources

### Documentation

- [AWS Bedrock Documentation](https://docs.aws.amazon.com/bedrock/)
- [Claude 3 Model Card](https://www.anthropic.com/claude)
- [Titan Models Documentation](https://docs.aws.amazon.com/bedrock/latest/userguide/titan-models.html)

### Monitoring

- CloudWatch Logs: `/aws/lambda/aperture-{env}-bedrock-analysis`
- API Gateway Logs: `/aws/apigateway/aperture-{env}`
- Cost Explorer: Monitor Bedrock usage

### Troubleshooting

**Error: "Model not found"**
- Ensure Bedrock models are enabled in your region
- Check model ARNs in Lambda IAM policy

**Error: "Image too large"**
- Compress images before analysis
- Maximum size: 5 MB

**Error: "Timeout"**
- Increase Lambda timeout (max 15 minutes)
- Use batch processing for multiple images
- Optimize image sizes

**Error: "Access denied"**
- Verify IAM permissions
- Check S3 bucket policies
- Ensure Lambda execution role has necessary permissions

### Contact

For issues or questions:
- GitHub Issues: [aperture/issues](https://github.com/your-org/aperture/issues)
- Slack: #aperture-support
- Email: aperture-support@example.edu

---

**Last Updated:** November 10, 2024
**Version:** 1.0.0
**Author:** Aperture Development Team
