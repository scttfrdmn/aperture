"""
DOI Minting Lambda Function
Integrates with DataCite API to mint DOIs for datasets
"""

import json
import os
import boto3
import requests
from datetime import datetime
from typing import Dict, Any
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

# AWS clients
s3 = boto3.client('s3')
dynamodb = boto3.resource('dynamodb')

# Environment variables
DATACITE_API_URL = os.environ.get('DATACITE_API_URL', 'https://api.datacite.org/dois')
DATACITE_USERNAME = os.environ['DATACITE_USERNAME']
DATACITE_PASSWORD = os.environ['DATACITE_PASSWORD']
DOI_PREFIX = os.environ['DOI_PREFIX']  # e.g., "10.5555"
DOI_REGISTRY_TABLE = os.environ['DOI_REGISTRY_TABLE']
PUBLIC_MEDIA_BUCKET = os.environ['PUBLIC_MEDIA_BUCKET']
REPO_BASE_URL = os.environ['REPO_BASE_URL']  # e.g., "https://repo.university.edu"


def lambda_handler(event, context):
    """
    Main Lambda handler for DOI minting
    
    Expected event structure:
    {
        "dataset_id": "ecology-2024-001",
        "metadata": {...},  # Full JSON-LD metadata
        "action": "mint" | "update" | "delete"
    }
    """
    try:
        dataset_id = event['dataset_id']
        metadata = event['metadata']
        action = event.get('action', 'mint')
        
        logger.info(f"Processing DOI {action} for dataset: {dataset_id}")
        
        if action == 'mint':
            return mint_doi(dataset_id, metadata)
        elif action == 'update':
            return update_doi(dataset_id, metadata)
        elif action == 'delete':
            return delete_doi(dataset_id)
        else:
            raise ValueError(f"Unknown action: {action}")
            
    except Exception as e:
        logger.error(f"Error processing DOI request: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': str(e)
            })
        }


def mint_doi(dataset_id: str, metadata: Dict[str, Any]) -> Dict[str, Any]:
    """
    Mint a new DOI via DataCite API
    """
    # Validate metadata completeness
    validation_errors = validate_metadata(metadata)
    if validation_errors:
        return {
            'statusCode': 400,
            'body': json.dumps({
                'error': 'Metadata validation failed',
                'details': validation_errors
            })
        }
    
    # Generate DOI suffix (use timestamp + dataset_id for uniqueness)
    timestamp = datetime.utcnow().strftime('%Y%m%d%H%M%S')
    doi_suffix = f"{dataset_id}-{timestamp}"
    doi = f"{DOI_PREFIX}/{doi_suffix}"
    
    # Convert metadata to DataCite schema
    datacite_metadata = convert_to_datacite(metadata, doi, dataset_id)
    
    # Submit to DataCite API
    response = requests.post(
        DATACITE_API_URL,
        json=datacite_metadata,
        auth=(DATACITE_USERNAME, DATACITE_PASSWORD),
        headers={'Content-Type': 'application/vnd.api+json'}
    )
    
    if response.status_code not in [200, 201]:
        logger.error(f"DataCite API error: {response.text}")
        return {
            'statusCode': response.status_code,
            'body': json.dumps({
                'error': 'DataCite API error',
                'details': response.text
            })
        }
    
    # Store DOI in DynamoDB
    table = dynamodb.Table(DOI_REGISTRY_TABLE)
    table.put_item(
        Item={
            'doi': doi,
            'dataset_id': dataset_id,
            's3_location': f"s3://{PUBLIC_MEDIA_BUCKET}/datasets/doi-{doi.replace('/', '-')}/",
            'metadata_json': json.dumps(metadata),
            'minted_at': datetime.utcnow().isoformat(),
            'status': 'published',
            'datacite_response': response.json()
        }
    )
    
    # Update dataset manifest with DOI
    update_manifest_with_doi(dataset_id, doi)
    
    # Generate landing page HTML
    generate_landing_page(dataset_id, doi, metadata)
    
    logger.info(f"Successfully minted DOI: {doi}")
    
    return {
        'statusCode': 201,
        'body': json.dumps({
            'doi': doi,
            'url': f"https://doi.org/{doi}",
            'landing_page': f"{REPO_BASE_URL}/datasets/doi-{doi.replace('/', '-')}",
            'status': 'published'
        })
    }


def validate_metadata(metadata: Dict[str, Any]) -> list:
    """
    Validate that required metadata fields are present
    """
    errors = []
    datacite = metadata.get('datacite', {})
    
    # Required fields per DataCite schema
    required_fields = {
        'creators': 'At least one creator is required',
        'title': 'Title is required',
        'publisher': 'Publisher is required',
        'publicationYear': 'Publication year is required',
        'resourceType': 'Resource type is required'
    }
    
    for field, error_msg in required_fields.items():
        if not datacite.get(field):
            errors.append(error_msg)
    
    # Validate creators have required fields
    if datacite.get('creators'):
        for i, creator in enumerate(datacite['creators']):
            if not creator.get('name'):
                errors.append(f"Creator {i+1} missing name")
    
    # Validate files exist
    if not metadata.get('files') or len(metadata['files']) == 0:
        errors.append('At least one file is required')
    
    return errors


def convert_to_datacite(metadata: Dict[str, Any], doi: str, dataset_id: str) -> Dict[str, Any]:
    """
    Convert our JSON-LD metadata to DataCite JSON format
    """
    datacite = metadata['datacite']
    
    # DataCite API expects this structure
    return {
        "data": {
            "type": "dois",
            "attributes": {
                "doi": doi,
                "prefix": DOI_PREFIX,
                "suffix": doi.split('/')[-1],
                "url": f"{REPO_BASE_URL}/datasets/doi-{doi.replace('/', '-')}",
                "creators": [
                    {
                        "name": creator.get('name'),
                        "nameType": "Personal" if '@type' in creator and creator['@type'] == 'Person' else "Organizational",
                        "givenName": creator.get('givenName'),
                        "familyName": creator.get('familyName'),
                        "nameIdentifiers": [
                            {
                                "nameIdentifier": creator.get('@id', '').replace('https://orcid.org/', ''),
                                "nameIdentifierScheme": "ORCID",
                                "schemeUri": "https://orcid.org"
                            }
                        ] if creator.get('@id') else [],
                        "affiliation": [
                            {
                                "name": creator['affiliation']['name'],
                                "affiliationIdentifier": creator['affiliation'].get('@id', ''),
                                "affiliationIdentifierScheme": "ROR"
                            }
                        ] if creator.get('affiliation') else []
                    }
                    for creator in datacite.get('creators', [])
                ],
                "titles": [
                    {
                        "title": datacite['title']
                    }
                ],
                "publisher": datacite['publisher'],
                "publicationYear": int(datacite['publicationYear']),
                "types": {
                    "resourceTypeGeneral": datacite['resourceType']['resourceTypeGeneral'],
                    "resourceType": datacite['resourceType']['resourceType']
                },
                "subjects": [
                    {
                        "subject": subject.get('subject'),
                        "subjectScheme": subject.get('subjectScheme')
                    }
                    for subject in datacite.get('subjects', [])
                ],
                "contributors": [
                    {
                        "name": contrib.get('name'),
                        "contributorType": contrib.get('contributorType', 'Other'),
                        "nameIdentifiers": [
                            {
                                "nameIdentifier": contrib.get('@id', '').replace('https://orcid.org/', ''),
                                "nameIdentifierScheme": "ORCID"
                            }
                        ] if contrib.get('@id') else []
                    }
                    for contrib in datacite.get('contributors', [])
                ],
                "dates": [
                    {
                        "date": date['date'],
                        "dateType": date['dateType']
                    }
                    for date in datacite.get('dates', [])
                ],
                "language": datacite.get('language'),
                "descriptions": [
                    {
                        "description": desc['description'],
                        "descriptionType": desc['descriptionType']
                    }
                    for desc in datacite.get('descriptions', [])
                ],
                "geoLocations": datacite.get('geoLocations', []),
                "fundingReferences": [
                    {
                        "funderName": ref.get('funderName'),
                        "funderIdentifier": ref.get('funderIdentifier'),
                        "awardNumber": ref.get('awardNumber'),
                        "awardTitle": ref.get('awardTitle')
                    }
                    for ref in datacite.get('fundingReferences', [])
                ],
                "relatedIdentifiers": [
                    {
                        "relatedIdentifier": rel.get('relatedIdentifier'),
                        "relatedIdentifierType": rel.get('relatedIdentifierType'),
                        "relationType": rel.get('relationType')
                    }
                    for rel in datacite.get('relatedIdentifiers', [])
                ],
                "rightsList": [
                    {
                        "rights": right.get('name'),
                        "rightsUri": right.get('license'),
                        "rightsIdentifier": right.get('identifier')
                    }
                    for right in datacite.get('rights', [])
                ],
                "version": datacite.get('version'),
                "schemaVersion": "http://datacite.org/schema/kernel-4"
            }
        }
    }


def update_manifest_with_doi(dataset_id: str, doi: str):
    """
    Update the dataset manifest.json with the minted DOI
    """
    # Assuming manifest is at datasets/{dataset_id}/manifest.json
    manifest_key = f"datasets/{dataset_id}/manifest.json"
    
    try:
        # Download manifest
        response = s3.get_object(Bucket=PUBLIC_MEDIA_BUCKET, Key=manifest_key)
        manifest = json.loads(response['Body'].read())
        
        # Update with DOI
        manifest['identifier'] = {
            '@type': 'PropertyValue',
            'propertyID': 'DOI',
            'value': doi
        }
        manifest['@id'] = f"https://doi.org/{doi}"
        
        # Upload updated manifest
        s3.put_object(
            Bucket=PUBLIC_MEDIA_BUCKET,
            Key=manifest_key,
            Body=json.dumps(manifest, indent=2),
            ContentType='application/json'
        )
        
        logger.info(f"Updated manifest with DOI: {doi}")
        
    except Exception as e:
        logger.error(f"Error updating manifest: {str(e)}")
        # Don't fail the DOI minting if manifest update fails
        pass


def generate_landing_page(dataset_id: str, doi: str, metadata: Dict[str, Any]):
    """
    Generate HTML landing page for the DOI
    Includes schema.org markup for Google Dataset Search
    """
    datacite = metadata['datacite']
    
    # Create citation string
    creators_str = "; ".join([c.get('name', '') for c in datacite.get('creators', [])])
    citation = f"{creators_str} ({datacite['publicationYear']}). {datacite['title']}. {datacite['publisher']}. https://doi.org/{doi}"
    
    # Generate HTML
    html = f"""<!DOCTYPE html>
<html lang="en" vocab="https://schema.org/" typeof="Dataset">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{datacite['title']}</title>
    
    <!-- Dublin Core metadata -->
    <meta name="DC.title" content="{datacite['title']}">
    <meta name="DC.creator" content="{creators_str}">
    <meta name="DC.date" content="{datacite['publicationYear']}">
    <meta name="DC.identifier" content="https://doi.org/{doi}">
    
    <!-- Citation metadata -->
    <meta name="citation_title" content="{datacite['title']}">
    <meta name="citation_author" content="{creators_str}">
    <meta name="citation_publication_date" content="{datacite['publicationYear']}">
    <meta name="citation_doi" content="{doi}">
    
    <!-- Schema.org JSON-LD -->
    <script type="application/ld+json">
    {json.dumps(metadata, indent=2)}
    </script>
    
    <style>
        body {{ font-family: Arial, sans-serif; max-width: 1200px; margin: 0 auto; padding: 20px; }}
        .header {{ background: #003366; color: white; padding: 20px; margin-bottom: 30px; }}
        .metadata {{ background: #f5f5f5; padding: 20px; margin-bottom: 20px; border-radius: 5px; }}
        .citation {{ background: #ffffcc; padding: 15px; border-left: 4px solid #003366; }}
        .file-list {{ list-style: none; padding: 0; }}
        .file-item {{ padding: 10px; border-bottom: 1px solid #ddd; }}
        .download-btn {{ background: #003366; color: white; padding: 10px 20px; text-decoration: none; border-radius: 3px; }}
    </style>
</head>
<body>
    <div class="header">
        <h1>{datacite['title']}</h1>
        <p>DOI: <a href="https://doi.org/{doi}" style="color: white;">{doi}</a></p>
    </div>
    
    <div class="metadata">
        <h2>Dataset Information</h2>
        <p><strong>Creators:</strong> {creators_str}</p>
        <p><strong>Publication Year:</strong> {datacite['publicationYear']}</p>
        <p><strong>Publisher:</strong> {datacite['publisher']}</p>
        <p><strong>Resource Type:</strong> {datacite['resourceType']['resourceType']}</p>
        <p><strong>License:</strong> {datacite.get('rights', [{}])[0].get('name', 'Not specified')}</p>
        
        <h3>Description</h3>
        <p>{datacite.get('descriptions', [{}])[0].get('description', '')}</p>
    </div>
    
    <div class="citation">
        <h3>Cite this dataset:</h3>
        <p>{citation}</p>
    </div>
    
    <div class="files">
        <h2>Files</h2>
        <ul class="file-list">
            {"".join([f'<li class="file-item">{f["name"]} ({f.get("contentSize", "unknown")} bytes)</li>' for f in metadata.get('files', [])])}
        </ul>
        <a href="{REPO_BASE_URL}/api/datasets/{dataset_id}/download" class="download-btn">Download Dataset</a>
    </div>
</body>
</html>"""
    
    # Upload landing page
    landing_page_key = f"datasets/doi-{doi.replace('/', '-')}/index.html"
    s3.put_object(
        Bucket=PUBLIC_MEDIA_BUCKET,
        Key=landing_page_key,
        Body=html,
        ContentType='text/html'
    )
    
    logger.info(f"Generated landing page: {landing_page_key}")


def update_doi(dataset_id: str, metadata: Dict[str, Any]) -> Dict[str, Any]:
    """
    Update an existing DOI's metadata
    """
    # Get existing DOI from DynamoDB
    table = dynamodb.Table(DOI_REGISTRY_TABLE)
    response = table.query(
        IndexName='dataset_id-index',
        KeyConditionExpression='dataset_id = :did',
        ExpressionAttributeValues={':did': dataset_id}
    )
    
    if not response['Items']:
        return {
            'statusCode': 404,
            'body': json.dumps({'error': 'DOI not found for this dataset'})
        }
    
    doi = response['Items'][0]['doi']
    
    # Convert metadata to DataCite format
    datacite_metadata = convert_to_datacite(metadata, doi, dataset_id)
    
    # Update via DataCite API
    update_response = requests.put(
        f"{DATACITE_API_URL}/{doi}",
        json=datacite_metadata,
        auth=(DATACITE_USERNAME, DATACITE_PASSWORD),
        headers={'Content-Type': 'application/vnd.api+json'}
    )
    
    if update_response.status_code not in [200, 201]:
        return {
            'statusCode': update_response.status_code,
            'body': json.dumps({
                'error': 'DataCite API error',
                'details': update_response.text
            })
        }
    
    # Update DynamoDB
    table.update_item(
        Key={'doi': doi},
        UpdateExpression='SET metadata_json = :meta, updated_at = :updated',
        ExpressionAttributeValues={
            ':meta': json.dumps(metadata),
            ':updated': datetime.utcnow().isoformat()
        }
    )
    
    # Regenerate landing page
    generate_landing_page(dataset_id, doi, metadata)
    
    return {
        'statusCode': 200,
        'body': json.dumps({
            'doi': doi,
            'status': 'updated'
        })
    }


def delete_doi(dataset_id: str) -> Dict[str, Any]:
    """
    Mark a DOI as deleted (tombstone)
    Note: DataCite doesn't allow true deletion, only marking as unavailable
    """
    # Implementation left as exercise
    pass
