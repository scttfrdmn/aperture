"""
Authentication Lambda Function
Handles user authentication and JWT token validation
"""

import json
import os
import boto3
import logging
from typing import Dict, Any

logger = logging.getLogger()
logger.setLevel(logging.INFO)

# AWS clients
cognito = boto3.client('cognito-idp')

# Environment variables
USER_POOL_ID = os.environ['USER_POOL_ID']
APP_CLIENT_ID = os.environ['APP_CLIENT_ID']


def lambda_handler(event, context):
    """
    Main Lambda handler for authentication

    Supported operations:
    - login: Authenticate user with username/password
    - refresh: Refresh access token
    - logout: Invalidate tokens
    - verify: Verify JWT token
    """
    try:
        # Parse request
        body = json.loads(event.get('body', '{}'))
        operation = body.get('operation', 'login')

        logger.info(f"Authentication operation: {operation}")

        if operation == 'login':
            return login(body)
        elif operation == 'refresh':
            return refresh_token(body)
        elif operation == 'logout':
            return logout(body)
        elif operation == 'verify':
            return verify_token(event)
        else:
            return error_response(400, f"Unknown operation: {operation}")

    except Exception as e:
        logger.error(f"Authentication error: {str(e)}")
        return error_response(500, str(e))


def login(body: Dict[str, Any]) -> Dict[str, Any]:
    """
    Authenticate user with username and password
    """
    username = body.get('username')
    password = body.get('password')

    if not username or not password:
        return error_response(400, "Username and password required")

    try:
        # Initiate auth with Cognito
        response = cognito.initiate_auth(
            ClientId=APP_CLIENT_ID,
            AuthFlow='USER_PASSWORD_AUTH',
            AuthParameters={
                'USERNAME': username,
                'PASSWORD': password
            }
        )

        # Extract tokens
        auth_result = response['AuthenticationResult']

        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'accessToken': auth_result['AccessToken'],
                'idToken': auth_result['IdToken'],
                'refreshToken': auth_result['RefreshToken'],
                'expiresIn': auth_result['ExpiresIn'],
                'tokenType': auth_result['TokenType']
            })
        }

    except cognito.exceptions.NotAuthorizedException:
        return error_response(401, "Invalid username or password")
    except cognito.exceptions.UserNotFoundException:
        return error_response(401, "Invalid username or password")
    except cognito.exceptions.UserNotConfirmedException:
        return error_response(403, "User account not confirmed")
    except Exception as e:
        logger.error(f"Login error: {str(e)}")
        return error_response(500, "Authentication failed")


def refresh_token(body: Dict[str, Any]) -> Dict[str, Any]:
    """
    Refresh access token using refresh token
    """
    refresh_token_value = body.get('refreshToken')

    if not refresh_token_value:
        return error_response(400, "Refresh token required")

    try:
        response = cognito.initiate_auth(
            ClientId=APP_CLIENT_ID,
            AuthFlow='REFRESH_TOKEN_AUTH',
            AuthParameters={
                'REFRESH_TOKEN': refresh_token_value
            }
        )

        auth_result = response['AuthenticationResult']

        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'accessToken': auth_result['AccessToken'],
                'idToken': auth_result['IdToken'],
                'expiresIn': auth_result['ExpiresIn'],
                'tokenType': auth_result['TokenType']
            })
        }

    except cognito.exceptions.NotAuthorizedException:
        return error_response(401, "Invalid or expired refresh token")
    except Exception as e:
        logger.error(f"Token refresh error: {str(e)}")
        return error_response(500, "Token refresh failed")


def logout(body: Dict[str, Any]) -> Dict[str, Any]:
    """
    Sign out user globally (invalidate all tokens)
    """
    access_token = body.get('accessToken')

    if not access_token:
        return error_response(400, "Access token required")

    try:
        cognito.global_sign_out(
            AccessToken=access_token
        )

        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'message': 'Successfully signed out'
            })
        }

    except cognito.exceptions.NotAuthorizedException:
        return error_response(401, "Invalid access token")
    except Exception as e:
        logger.error(f"Logout error: {str(e)}")
        return error_response(500, "Logout failed")


def verify_token(event: Dict[str, Any]) -> Dict[str, Any]:
    """
    Verify JWT token (used by API Gateway authorizer)
    """
    # Extract token from Authorization header
    auth_header = event.get('headers', {}).get('Authorization', '')

    if not auth_header.startswith('Bearer '):
        return error_response(401, "Invalid Authorization header")

    token = auth_header[7:]  # Remove "Bearer " prefix

    try:
        # Get user info from token
        response = cognito.get_user(
            AccessToken=token
        )

        # Extract user attributes
        user_attributes = {attr['Name']: attr['Value'] for attr in response['UserAttributes']}

        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'valid': True,
                'username': response['Username'],
                'email': user_attributes.get('email'),
                'sub': user_attributes.get('sub'),
                'email_verified': user_attributes.get('email_verified') == 'true'
            })
        }

    except cognito.exceptions.NotAuthorizedException:
        return error_response(401, "Invalid or expired token")
    except Exception as e:
        logger.error(f"Token verification error: {str(e)}")
        return error_response(500, "Token verification failed")


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
