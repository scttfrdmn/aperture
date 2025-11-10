"""
Presigned URLs Lambda Function
Generates temporary signed URLs for S3 object access
"""

import json
import os
import boto3
import logging
from typing import Dict, Any, List
from datetime import datetime, timedelta

logger = logging.getLogger()
logger.setLevel(logging.INFO)

# AWS clients
s3 = boto3.client('s3')
dynamodb = boto3.resource('dynamodb')

# Environment variables
PUBLIC_MEDIA_BUCKET = os.environ['PUBLIC_MEDIA_BUCKET']
PRIVATE_MEDIA_BUCKET = os.environ['PRIVATE_MEDIA_BUCKET']
RESTRICTED_MEDIA_BUCKET = os.environ['RESTRICTED_MEDIA_BUCKET']
EMBARGOED_MEDIA_BUCKET = os.environ['EMBARGOED_MEDIA_BUCKET']
ACCESS_LOGS_TABLE = os.environ['ACCESS_LOGS_TABLE']
DOI_REGISTRY_TABLE = os.environ['DOI_REGISTRY_TABLE']

# URL expiration times (seconds)
DEFAULT_EXPIRATION = 3600  # 1 hour
MAX_EXPIRATION = 86400  # 24 hours


def lambda_handler(event, context):
    """
    Main Lambda handler for presigned URL generation

    Expected event structure:
    {
        "operation": "generate" | "batch",
        "bucket": "public" | "private" | "restricted" | "embargoed",
        "key": "path/to/object",
        "keys": ["path/to/object1", "path/to/object2"],  # For batch
        "expiration": 3600,  # Optional, seconds
        "user": {
            "sub": "user-id",
            "email": "user@example.com",
            "groups": ["researchers"]
        }
    }
    """
    try:
        # Parse request
        body = json.loads(event.get('body', '{}'))
        operation = body.get('operation', 'generate')
        user = body.get('user', {})

        logger.info(f"Presigned URL operation: {operation} for user: {user.get('email')}")

        if operation == 'generate':
            return generate_url(body, user)
        elif operation == 'batch':
            return generate_batch_urls(body, user)
        else:
            return error_response(400, f"Unknown operation: {operation}")

    except Exception as e:
        logger.error(f"Presigned URL error: {str(e)}")
        return error_response(500, str(e))


def generate_url(body: Dict[str, Any], user: Dict[str, Any]) -> Dict[str, Any]:
    """
    Generate a single presigned URL
    """
    bucket_name = body.get('bucket')
    key = body.get('key')
    expiration = min(body.get('expiration', DEFAULT_EXPIRATION), MAX_EXPIRATION)

    if not bucket_name or not key:
        return error_response(400, "Bucket and key are required")

    # Map bucket identifier to actual bucket name
    actual_bucket = get_bucket_name(bucket_name)
    if not actual_bucket:
        return error_response(400, f"Invalid bucket: {bucket_name}")

    # Check access permissions
    if not check_access(bucket_name, key, user):
        log_access_denial(bucket_name, key, user)
        return error_response(403, "Access denied")

    try:
        # Generate presigned URL
        url = s3.generate_presigned_url(
            'get_object',
            Params={
                'Bucket': actual_bucket,
                'Key': key
            },
            ExpiresIn=expiration
        )

        # Log successful access
        log_access(bucket_name, key, user, 'presigned_url_generated')

        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'url': url,
                'expiresIn': expiration,
                'bucket': bucket_name,
                'key': key,
                'expiresAt': (datetime.utcnow() + timedelta(seconds=expiration)).isoformat()
            })
        }

    except s3.exceptions.NoSuchKey:
        return error_response(404, "Object not found")
    except Exception as e:
        logger.error(f"Error generating presigned URL: {str(e)}")
        return error_response(500, "Failed to generate presigned URL")


def generate_batch_urls(body: Dict[str, Any], user: Dict[str, Any]) -> Dict[str, Any]:
    """
    Generate multiple presigned URLs in batch
    """
    bucket_name = body.get('bucket')
    keys = body.get('keys', [])
    expiration = min(body.get('expiration', DEFAULT_EXPIRATION), MAX_EXPIRATION)

    if not bucket_name or not keys:
        return error_response(400, "Bucket and keys are required")

    if len(keys) > 100:
        return error_response(400, "Maximum 100 objects per batch request")

    actual_bucket = get_bucket_name(bucket_name)
    if not actual_bucket:
        return error_response(400, f"Invalid bucket: {bucket_name}")

    urls = []
    errors = []

    for key in keys:
        # Check access for each object
        if not check_access(bucket_name, key, user):
            errors.append({
                'key': key,
                'error': 'Access denied'
            })
            continue

        try:
            # Generate presigned URL
            url = s3.generate_presigned_url(
                'get_object',
                Params={
                    'Bucket': actual_bucket,
                    'Key': key
                },
                ExpiresIn=expiration
            )

            urls.append({
                'key': key,
                'url': url,
                'expiresIn': expiration
            })

            # Log access
            log_access(bucket_name, key, user, 'presigned_url_generated_batch')

        except s3.exceptions.NoSuchKey:
            errors.append({
                'key': key,
                'error': 'Object not found'
            })
        except Exception as e:
            logger.error(f"Error generating URL for {key}: {str(e)}")
            errors.append({
                'key': key,
                'error': str(e)
            })

    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps({
            'urls': urls,
            'errors': errors,
            'total': len(keys),
            'successful': len(urls),
            'failed': len(errors),
            'expiresAt': (datetime.utcnow() + timedelta(seconds=expiration)).isoformat()
        })
    }


def get_bucket_name(bucket_identifier: str) -> str:
    """
    Map bucket identifier to actual bucket name
    """
    bucket_map = {
        'public': PUBLIC_MEDIA_BUCKET,
        'private': PRIVATE_MEDIA_BUCKET,
        'restricted': RESTRICTED_MEDIA_BUCKET,
        'embargoed': EMBARGOED_MEDIA_BUCKET
    }
    return bucket_map.get(bucket_identifier)


def check_access(bucket: str, key: str, user: Dict[str, Any]) -> bool:
    """
    Check if user has access to the requested object
    """
    user_groups = user.get('groups', [])

    # Public bucket - anyone can access
    if bucket == 'public':
        return True

    # User must be authenticated for other buckets
    if not user.get('sub'):
        return False

    # Admins have access to everything
    if 'admins' in user_groups:
        return True

    # Private bucket - researchers and above
    if bucket == 'private':
        return any(group in user_groups for group in ['researchers', 'reviewers', 'admins'])

    # Restricted and embargoed - need specific checks
    if bucket in ['restricted', 'embargoed']:
        # Check dataset-specific permissions in DynamoDB
        return check_dataset_permission(key, user)

    return False


def check_dataset_permission(key: str, user: Dict[str, Any]) -> bool:
    """
    Check dataset-specific permissions for restricted/embargoed data
    """
    try:
        # Extract dataset ID from key (e.g., datasets/dataset-123/file.mp4)
        parts = key.split('/')
        if len(parts) < 2 or parts[0] != 'datasets':
            return False

        dataset_id = parts[1]

        # Query DOI registry for dataset metadata
        table = dynamodb.Table(DOI_REGISTRY_TABLE)
        response = table.query(
            IndexName='dataset_id-index',
            KeyConditionExpression='dataset_id = :did',
            ExpressionAttributeValues={':did': dataset_id}
        )

        if not response['Items']:
            return False

        dataset = response['Items'][0]
        metadata = json.loads(dataset.get('metadata_json', '{}'))

        # Check if user is in allowed_users list
        allowed_users = metadata.get('access_control', {}).get('allowed_users', [])
        if user.get('sub') in allowed_users or user.get('email') in allowed_users:
            return True

        # Check embargo date
        if dataset.get('status') == 'embargoed':
            embargo_date = metadata.get('embargo', {}).get('end_date')
            if embargo_date:
                if datetime.fromisoformat(embargo_date) <= datetime.utcnow():
                    return True

        return False

    except Exception as e:
        logger.error(f"Error checking dataset permission: {str(e)}")
        return False


def log_access(bucket: str, key: str, user: Dict[str, Any], action: str):
    """
    Log access to DynamoDB access logs table
    """
    try:
        table = dynamodb.Table(ACCESS_LOGS_TABLE)
        table.put_item(
            Item={
                'user_id': user.get('sub', 'anonymous'),
                'timestamp': datetime.utcnow().isoformat(),
                'action': action,
                'bucket': bucket,
                'key': key,
                'email': user.get('email', ''),
                'ip': user.get('ip', ''),
                'user_agent': user.get('user_agent', '')
            }
        )
    except Exception as e:
        logger.error(f"Error logging access: {str(e)}")
        # Don't fail the request if logging fails


def log_access_denial(bucket: str, key: str, user: Dict[str, Any]):
    """
    Log access denial
    """
    log_access(bucket, key, user, 'access_denied')


def error_response(status_code: int, message: str) -> Dict[str, Any]:
    """
    Generate error response
    """
    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps({
            'error': message
        })
    }
