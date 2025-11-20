"""
AWS Bedrock Integration Lambda
Provides AI-powered analysis for research datasets using Claude and Titan models
"""

import json
import boto3
import base64
from typing import Dict, Any, List
from datetime import datetime

# AWS clients
bedrock_runtime = boto3.client('bedrock-runtime', region_name='us-east-1')
s3_client = boto3.client('s3')

# Model IDs
CLAUDE_MODEL = 'anthropic.claude-3-sonnet-20240229-v1:0'
TITAN_EMBED_MODEL = 'amazon.titan-embed-image-v1'
TITAN_IMAGE_MODEL = 'amazon.titan-image-generator-v1'


def lambda_handler(event, context):
    """Main Lambda handler for Bedrock AI operations"""
    try:
        body = json.loads(event.get('body', '{}'))
        operation = body.get('operation', 'analyze_image')

        handlers = {
            'analyze_image': analyze_image,
            'extract_metadata': extract_metadata,
            'classify_artifact': classify_artifact,
            'generate_description': generate_description,
            'similarity_search': generate_embeddings,
            'extract_text': extract_text_from_image,
            'analyze_batch': analyze_batch_images
        }

        if operation not in handlers:
            return error_response(400, f'Unknown operation: {operation}')

        return handlers[operation](body)

    except Exception as e:
        print(f'Error: {str(e)}')
        return error_response(500, str(e))


def analyze_image(params: Dict[str, Any]) -> Dict[str, Any]:
    """
    Analyze an image using Claude vision capabilities
    Identifies objects, provides descriptions, suggests metadata
    """
    try:
        bucket = params.get('bucket')
        key = params.get('key')
        prompt = params.get('prompt', 'Analyze this image and describe what you see in detail.')

        if not bucket or not key:
            return error_response(400, 'Bucket and key are required')

        # Get image from S3
        response = s3_client.get_object(Bucket=bucket, Key=key)
        image_data = response['Body'].read()
        image_base64 = base64.b64encode(image_data).decode('utf-8')

        # Determine media type
        content_type = response.get('ContentType', 'image/jpeg')

        # Invoke Claude with vision
        request_body = {
            "anthropic_version": "bedrock-2023-05-31",
            "max_tokens": 2048,
            "messages": [
                {
                    "role": "user",
                    "content": [
                        {
                            "type": "image",
                            "source": {
                                "type": "base64",
                                "media_type": content_type,
                                "data": image_base64
                            }
                        },
                        {
                            "type": "text",
                            "text": prompt
                        }
                    ]
                }
            ]
        }

        response = bedrock_runtime.invoke_model(
            modelId=CLAUDE_MODEL,
            body=json.dumps(request_body)
        )

        result = json.loads(response['body'].read())
        analysis = result['content'][0]['text']

        return success_response({
            'analysis': analysis,
            'bucket': bucket,
            'key': key,
            'model': CLAUDE_MODEL,
            'timestamp': datetime.utcnow().isoformat()
        })

    except Exception as e:
        return error_response(500, f'Image analysis failed: {str(e)}')


def extract_metadata(params: Dict[str, Any]) -> Dict[str, Any]:
    """
    Extract structured metadata from image or document
    Returns fields like: title, date, location, materials, dimensions, etc.
    """
    try:
        bucket = params.get('bucket')
        key = params.get('key')
        schema_type = params.get('schema_type', 'artifact')

        if not bucket or not key:
            return error_response(400, 'Bucket and key are required')

        # Get image from S3
        response = s3_client.get_object(Bucket=bucket, Key=key)
        image_data = response['Body'].read()
        image_base64 = base64.b64encode(image_data).decode('utf-8')
        content_type = response.get('ContentType', 'image/jpeg')

        # Schema-specific prompts
        prompts = {
            'artifact': '''Analyze this archaeological artifact image and extract structured metadata in JSON format:
{
  "object_type": "ceramic vessel, stone tool, etc.",
  "period": "Bronze Age, Roman, Medieval, etc.",
  "material": "ceramic, stone, metal, etc.",
  "condition": "excellent, good, fair, poor",
  "dimensions": "approximate size if visible",
  "decoration": "describe any decorative elements",
  "inscriptions": "any visible text or markings",
  "context": "any contextual clues visible",
  "keywords": ["keyword1", "keyword2"],
  "suggested_title": "descriptive title"
}
Only return valid JSON.''',

            'dataset': '''Analyze this research data image and extract metadata in JSON format:
{
  "data_type": "photograph, diagram, map, scan, etc.",
  "subject": "what is depicted",
  "date_estimate": "if any date indicators visible",
  "location": "if location identifiable",
  "scale": "if scale bar present",
  "quality": "resolution and clarity assessment",
  "keywords": ["keyword1", "keyword2"],
  "suggested_title": "descriptive title",
  "notes": "any additional observations"
}
Only return valid JSON.'''
        }

        prompt = prompts.get(schema_type, prompts['artifact'])

        # Invoke Claude with vision
        request_body = {
            "anthropic_version": "bedrock-2023-05-31",
            "max_tokens": 1024,
            "messages": [
                {
                    "role": "user",
                    "content": [
                        {
                            "type": "image",
                            "source": {
                                "type": "base64",
                                "media_type": content_type,
                                "data": image_base64
                            }
                        },
                        {
                            "type": "text",
                            "text": prompt
                        }
                    ]
                }
            ]
        }

        response = bedrock_runtime.invoke_model(
            modelId=CLAUDE_MODEL,
            body=json.dumps(request_body)
        )

        result = json.loads(response['body'].read())
        metadata_text = result['content'][0]['text']

        # Try to parse as JSON
        try:
            # Extract JSON from response (may have markdown code blocks)
            if '```json' in metadata_text:
                metadata_text = metadata_text.split('```json')[1].split('```')[0]
            elif '```' in metadata_text:
                metadata_text = metadata_text.split('```')[1].split('```')[0]

            metadata = json.loads(metadata_text.strip())
        except:
            # If JSON parsing fails, return raw text
            metadata = {'raw_analysis': metadata_text}

        return success_response({
            'metadata': metadata,
            'bucket': bucket,
            'key': key,
            'schema_type': schema_type,
            'timestamp': datetime.utcnow().isoformat()
        })

    except Exception as e:
        return error_response(500, f'Metadata extraction failed: {str(e)}')


def classify_artifact(params: Dict[str, Any]) -> Dict[str, Any]:
    """
    Classify artifact type, period, and material
    Useful for archaeology and museum collections
    """
    try:
        bucket = params.get('bucket')
        key = params.get('key')

        if not bucket or not key:
            return error_response(400, 'Bucket and key are required')

        # Get image from S3
        response = s3_client.get_object(Bucket=bucket, Key=key)
        image_data = response['Body'].read()
        image_base64 = base64.b64encode(image_data).decode('utf-8')
        content_type = response.get('ContentType', 'image/jpeg')

        prompt = '''Classify this artifact. Provide your analysis in JSON format:
{
  "artifact_type": "pottery, tool, weapon, jewelry, architectural, other",
  "specific_classification": "vessel type, tool type, etc.",
  "period": "Paleolithic, Neolithic, Bronze Age, Iron Age, Classical, Medieval, etc.",
  "culture": "if identifiable",
  "material": "primary material (ceramic, stone, metal, bone, glass, etc.)",
  "technique": "manufacturing technique if visible",
  "function": "likely use or purpose",
  "typology": "typological classification if applicable",
  "parallels": "similar known artifacts or types",
  "confidence": "high, medium, low",
  "reasoning": "brief explanation of classification"
}
Only return valid JSON.'''

        request_body = {
            "anthropic_version": "bedrock-2023-05-31",
            "max_tokens": 1024,
            "messages": [
                {
                    "role": "user",
                    "content": [
                        {
                            "type": "image",
                            "source": {
                                "type": "base64",
                                "media_type": content_type,
                                "data": image_base64
                            }
                        },
                        {
                            "type": "text",
                            "text": prompt
                        }
                    ]
                }
            ]
        }

        response = bedrock_runtime.invoke_model(
            modelId=CLAUDE_MODEL,
            body=json.dumps(request_body)
        )

        result = json.loads(response['body'].read())
        classification_text = result['content'][0]['text']

        # Parse JSON
        try:
            if '```json' in classification_text:
                classification_text = classification_text.split('```json')[1].split('```')[0]
            elif '```' in classification_text:
                classification_text = classification_text.split('```')[1].split('```')[0]

            classification = json.loads(classification_text.strip())
        except:
            classification = {'raw_analysis': classification_text}

        return success_response({
            'classification': classification,
            'bucket': bucket,
            'key': key,
            'timestamp': datetime.utcnow().isoformat()
        })

    except Exception as e:
        return error_response(500, f'Classification failed: {str(e)}')


def generate_description(params: Dict[str, Any]) -> Dict[str, Any]:
    """
    Generate a comprehensive description for dataset or artifact
    Useful for auto-generating catalog entries
    """
    try:
        bucket = params.get('bucket')
        key = params.get('key')
        style = params.get('style', 'academic')  # academic, catalog, public

        if not bucket or not key:
            return error_response(400, 'Bucket and key are required')

        # Get image from S3
        response = s3_client.get_object(Bucket=bucket, Key=key)
        image_data = response['Body'].read()
        image_base64 = base64.b64encode(image_data).decode('utf-8')
        content_type = response.get('ContentType', 'image/jpeg')

        style_prompts = {
            'academic': 'Write a detailed academic description of this artifact suitable for a research publication. Include observations about form, decoration, material, condition, and significance.',
            'catalog': 'Write a concise museum catalog entry for this artifact. Include type, period, material, dimensions (if visible), and brief description.',
            'public': 'Write an engaging description for a general public audience. Explain what this artifact is, when it was made, and why it matters.'
        }

        prompt = style_prompts.get(style, style_prompts['academic'])

        request_body = {
            "anthropic_version": "bedrock-2023-05-31",
            "max_tokens": 1024,
            "messages": [
                {
                    "role": "user",
                    "content": [
                        {
                            "type": "image",
                            "source": {
                                "type": "base64",
                                "media_type": content_type,
                                "data": image_base64
                            }
                        },
                        {
                            "type": "text",
                            "text": prompt
                        }
                    ]
                }
            ]
        }

        response = bedrock_runtime.invoke_model(
            modelId=CLAUDE_MODEL,
            body=json.dumps(request_body)
        )

        result = json.loads(response['body'].read())
        description = result['content'][0]['text']

        return success_response({
            'description': description,
            'style': style,
            'bucket': bucket,
            'key': key,
            'timestamp': datetime.utcnow().isoformat()
        })

    except Exception as e:
        return error_response(500, f'Description generation failed: {str(e)}')


def generate_embeddings(params: Dict[str, Any]) -> Dict[str, Any]:
    """
    Generate embeddings for image using Titan
    Used for similarity search
    """
    try:
        bucket = params.get('bucket')
        key = params.get('key')

        if not bucket or not key:
            return error_response(400, 'Bucket and key are required')

        # Get image from S3
        response = s3_client.get_object(Bucket=bucket, Key=key)
        image_data = response['Body'].read()
        image_base64 = base64.b64encode(image_data).decode('utf-8')

        request_body = {
            "inputImage": image_base64
        }

        response = bedrock_runtime.invoke_model(
            modelId=TITAN_EMBED_MODEL,
            body=json.dumps(request_body)
        )

        result = json.loads(response['body'].read())
        embeddings = result.get('embedding', [])

        return success_response({
            'embeddings': embeddings,
            'dimension': len(embeddings),
            'bucket': bucket,
            'key': key,
            'timestamp': datetime.utcnow().isoformat()
        })

    except Exception as e:
        return error_response(500, f'Embedding generation failed: {str(e)}')


def extract_text_from_image(params: Dict[str, Any]) -> Dict[str, Any]:
    """
    Extract text from images (OCR)
    Useful for inscriptions, field notes, labels, etc.
    """
    try:
        bucket = params.get('bucket')
        key = params.get('key')
        language = params.get('language', 'auto')

        if not bucket or not key:
            return error_response(400, 'Bucket and key are required')

        # Get image from S3
        response = s3_client.get_object(Bucket=bucket, Key=key)
        image_data = response['Body'].read()
        image_base64 = base64.b64encode(image_data).decode('utf-8')
        content_type = response.get('ContentType', 'image/jpeg')

        prompt = f'''Extract all text visible in this image. If the language is {language}, transcribe it exactly. Include:
1. All readable text (inscriptions, labels, notes, etc.)
2. Location of text in image (if relevant)
3. Confidence level for each text segment
4. Language identification

Return in JSON format:
{{
  "texts": [
    {{"content": "text here", "location": "description", "confidence": "high/medium/low", "language": "detected"}}
  ],
  "summary": "brief summary of all text found"
}}
Only return valid JSON.'''

        request_body = {
            "anthropic_version": "bedrock-2023-05-31",
            "max_tokens": 2048,
            "messages": [
                {
                    "role": "user",
                    "content": [
                        {
                            "type": "image",
                            "source": {
                                "type": "base64",
                                "media_type": content_type,
                                "data": image_base64
                            }
                        },
                        {
                            "type": "text",
                            "text": prompt
                        }
                    ]
                }
            ]
        }

        response = bedrock_runtime.invoke_model(
            modelId=CLAUDE_MODEL,
            body=json.dumps(request_body)
        )

        result = json.loads(response['body'].read())
        text_result = result['content'][0]['text']

        # Parse JSON
        try:
            if '```json' in text_result:
                text_result = text_result.split('```json')[1].split('```')[0]
            elif '```' in text_result:
                text_result = text_result.split('```')[1].split('```')[0]

            extracted_text = json.loads(text_result.strip())
        except:
            extracted_text = {'raw_text': text_result}

        return success_response({
            'extracted_text': extracted_text,
            'bucket': bucket,
            'key': key,
            'timestamp': datetime.utcnow().isoformat()
        })

    except Exception as e:
        return error_response(500, f'Text extraction failed: {str(e)}')


def analyze_batch_images(params: Dict[str, Any]) -> Dict[str, Any]:
    """
    Analyze multiple images in batch
    Maximum 10 images per request
    """
    try:
        images = params.get('images', [])
        operation = params.get('batch_operation', 'analyze_image')

        if not images:
            return error_response(400, 'Images array is required')

        if len(images) > 10:
            return error_response(400, 'Maximum 10 images per batch')

        results = []
        errors = []

        for img in images:
            try:
                # Call individual operation for each image
                if operation == 'classify_artifact':
                    result = classify_artifact(img)
                elif operation == 'extract_metadata':
                    result = extract_metadata(img)
                else:
                    result = analyze_image(img)

                if result.get('statusCode') == 200:
                    body = json.loads(result.get('body', '{}'))
                    results.append({
                        'bucket': img.get('bucket'),
                        'key': img.get('key'),
                        'result': body
                    })
                else:
                    errors.append({
                        'bucket': img.get('bucket'),
                        'key': img.get('key'),
                        'error': result.get('body')
                    })
            except Exception as e:
                errors.append({
                    'bucket': img.get('bucket'),
                    'key': img.get('key'),
                    'error': str(e)
                })

        return success_response({
            'total': len(images),
            'successful': len(results),
            'failed': len(errors),
            'results': results,
            'errors': errors if errors else None,
            'timestamp': datetime.utcnow().isoformat()
        })

    except Exception as e:
        return error_response(500, f'Batch analysis failed: {str(e)}')


def success_response(data: Dict[str, Any]) -> Dict[str, Any]:
    """Return successful response"""
    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps(data)
    }


def error_response(status_code: int, message: str) -> Dict[str, Any]:
    """Return error response"""
    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps({'error': message})
    }
