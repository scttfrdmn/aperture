"""
RAG Knowledge Base Lambda Handler
Implements Retrieval-Augmented Generation for querying research datasets
"""

import json
import os
import boto3
import base64
from typing import List, Dict, Any, Tuple
from decimal import Decimal
import math
from datetime import datetime

# AWS clients
bedrock_runtime = boto3.client('bedrock-runtime')
dynamodb = boto3.resource('dynamodb')
s3_client = boto3.client('s3')

# Environment variables
EMBEDDINGS_TABLE = os.environ.get('EMBEDDINGS_TABLE', 'aperture-knowledge-base-embeddings-dev')
EMBEDDING_MODEL = 'amazon.titan-embed-text-v1'
LLM_MODEL = 'anthropic.claude-3-sonnet-20240229-v1:0'


class DecimalEncoder(json.JSONEncoder):
    """JSON encoder for Decimal types"""
    def default(self, obj):
        if isinstance(obj, Decimal):
            return float(obj)
        return super(DecimalEncoder, self).default(obj)


def cosine_similarity(vec1: List[float], vec2: List[float]) -> float:
    """
    Calculate cosine similarity between two vectors
    """
    dot_product = sum(a * b for a, b in zip(vec1, vec2))
    magnitude1 = math.sqrt(sum(a * a for a in vec1))
    magnitude2 = math.sqrt(sum(b * b for b in vec2))

    if magnitude1 == 0 or magnitude2 == 0:
        return 0.0

    return dot_product / (magnitude1 * magnitude2)


def generate_embedding(text: str) -> List[float]:
    """
    Generate embedding for text using Titan model
    """
    try:
        body = json.dumps({
            "inputText": text
        })

        response = bedrock_runtime.invoke_model(
            modelId=EMBEDDING_MODEL,
            body=body,
            contentType='application/json',
            accept='application/json'
        )

        response_body = json.loads(response['body'].read())
        embedding = response_body.get('embedding', [])

        return embedding

    except Exception as e:
        print(f"Error generating embedding: {str(e)}")
        raise


def store_embedding(
    embedding_id: str,
    dataset_id: str,
    content_type: str,
    content: str,
    embedding: List[float],
    metadata: Dict[str, Any] = None
) -> Dict[str, Any]:
    """
    Store embedding in DynamoDB
    """
    try:
        table = dynamodb.Table(EMBEDDINGS_TABLE)

        item = {
            'embedding_id': embedding_id,
            'dataset_id': dataset_id,
            'content_type': content_type,
            'content': content,
            'embedding': embedding,
            'model': EMBEDDING_MODEL,
            'created_at': datetime.utcnow().isoformat(),
            'metadata': metadata or {}
        }

        table.put_item(Item=item)

        return {
            'success': True,
            'embedding_id': embedding_id
        }

    except Exception as e:
        print(f"Error storing embedding: {str(e)}")
        raise


def retrieve_embeddings(dataset_id: str = None, limit: int = 1000) -> List[Dict[str, Any]]:
    """
    Retrieve embeddings from DynamoDB
    """
    try:
        table = dynamodb.Table(EMBEDDINGS_TABLE)

        if dataset_id:
            # Query by dataset_id using GSI
            response = table.query(
                IndexName='DatasetIdIndex',
                KeyConditionExpression='dataset_id = :dataset_id',
                ExpressionAttributeValues={':dataset_id': dataset_id},
                Limit=limit
            )
        else:
            # Scan all embeddings (expensive, use with caution)
            response = table.scan(Limit=limit)

        items = response.get('Items', [])
        return items

    except Exception as e:
        print(f"Error retrieving embeddings: {str(e)}")
        raise


def semantic_search(
    query: str,
    top_k: int = 5,
    dataset_id: str = None,
    content_type: str = None
) -> List[Dict[str, Any]]:
    """
    Perform semantic search using cosine similarity
    """
    try:
        # Generate embedding for query
        query_embedding = generate_embedding(query)

        # Retrieve all embeddings
        all_embeddings = retrieve_embeddings(dataset_id=dataset_id)

        # Filter by content type if specified
        if content_type:
            all_embeddings = [
                item for item in all_embeddings
                if item.get('content_type') == content_type
            ]

        # Calculate similarity scores
        results = []
        for item in all_embeddings:
            stored_embedding = item.get('embedding', [])

            # Convert Decimal to float if necessary
            if stored_embedding and isinstance(stored_embedding[0], Decimal):
                stored_embedding = [float(x) for x in stored_embedding]

            similarity = cosine_similarity(query_embedding, stored_embedding)

            results.append({
                'embedding_id': item['embedding_id'],
                'dataset_id': item['dataset_id'],
                'content_type': item['content_type'],
                'content': item['content'],
                'metadata': item.get('metadata', {}),
                'similarity': similarity
            })

        # Sort by similarity (descending)
        results.sort(key=lambda x: x['similarity'], reverse=True)

        # Return top K results
        return results[:top_k]

    except Exception as e:
        print(f"Error in semantic search: {str(e)}")
        raise


def generate_answer(query: str, context: List[Dict[str, Any]]) -> str:
    """
    Generate answer using Claude with retrieved context
    """
    try:
        # Build context string from retrieved documents
        context_str = "\n\n".join([
            f"[Dataset: {item['dataset_id']}]\n{item['content']}"
            for item in context
        ])

        # Create prompt for Claude
        prompt = f"""You are an expert research assistant helping users find information in an academic media repository.

Based on the following research dataset information, please answer the user's question.

Context:
{context_str}

User Question: {query}

Please provide a comprehensive answer based on the context above. If the context doesn't contain enough information to fully answer the question, acknowledge this and provide what information is available. Include references to specific datasets when relevant."""

        # Call Claude
        body = json.dumps({
            "anthropic_version": "bedrock-2023-05-31",
            "max_tokens": 2000,
            "messages": [
                {
                    "role": "user",
                    "content": prompt
                }
            ],
            "temperature": 0.7
        })

        response = bedrock_runtime.invoke_model(
            modelId=LLM_MODEL,
            body=body,
            contentType='application/json',
            accept='application/json'
        )

        response_body = json.loads(response['body'].read())
        answer = response_body.get('content', [{}])[0].get('text', '')

        return answer

    except Exception as e:
        print(f"Error generating answer: {str(e)}")
        raise


def index_dataset(params: Dict[str, Any]) -> Dict[str, Any]:
    """
    Index a dataset by generating and storing embeddings
    """
    dataset_id = params.get('dataset_id')
    title = params.get('title', '')
    description = params.get('description', '')
    abstract = params.get('abstract', '')
    keywords = params.get('keywords', [])
    subjects = params.get('subjects', [])

    if not dataset_id:
        raise ValueError("dataset_id is required")

    results = []

    # Index title and description
    if title and description:
        combined_text = f"Title: {title}\n\nDescription: {description}"
        embedding = generate_embedding(combined_text)

        embedding_id = f"{dataset_id}#metadata"
        result = store_embedding(
            embedding_id=embedding_id,
            dataset_id=dataset_id,
            content_type='metadata',
            content=combined_text,
            embedding=embedding,
            metadata={'title': title, 'has_description': True}
        )
        results.append(result)

    # Index abstract separately
    if abstract:
        embedding = generate_embedding(abstract)

        embedding_id = f"{dataset_id}#abstract"
        result = store_embedding(
            embedding_id=embedding_id,
            dataset_id=dataset_id,
            content_type='abstract',
            content=abstract,
            embedding=embedding,
            metadata={'title': title}
        )
        results.append(result)

    # Index keywords and subjects
    if keywords or subjects:
        keywords_text = f"Keywords: {', '.join(keywords)}\nSubjects: {', '.join(subjects)}"
        embedding = generate_embedding(keywords_text)

        embedding_id = f"{dataset_id}#keywords"
        result = store_embedding(
            embedding_id=embedding_id,
            dataset_id=dataset_id,
            content_type='keywords',
            content=keywords_text,
            embedding=embedding,
            metadata={'title': title}
        )
        results.append(result)

    return {
        'success': True,
        'dataset_id': dataset_id,
        'embeddings_created': len(results),
        'results': results
    }


def query_knowledge_base(params: Dict[str, Any]) -> Dict[str, Any]:
    """
    Query the knowledge base using RAG
    """
    query = params.get('query')
    top_k = params.get('top_k', 5)
    dataset_id = params.get('dataset_id')
    content_type = params.get('content_type')
    include_answer = params.get('include_answer', True)

    if not query:
        raise ValueError("query is required")

    # Perform semantic search
    results = semantic_search(
        query=query,
        top_k=top_k,
        dataset_id=dataset_id,
        content_type=content_type
    )

    # Generate answer if requested
    answer = None
    if include_answer and results:
        answer = generate_answer(query, results)

    return {
        'query': query,
        'results': results,
        'answer': answer,
        'total_results': len(results)
    }


def delete_dataset_embeddings(params: Dict[str, Any]) -> Dict[str, Any]:
    """
    Delete all embeddings for a dataset
    """
    dataset_id = params.get('dataset_id')

    if not dataset_id:
        raise ValueError("dataset_id is required")

    try:
        embeddings = retrieve_embeddings(dataset_id=dataset_id)

        table = dynamodb.Table(EMBEDDINGS_TABLE)
        deleted_count = 0

        for item in embeddings:
            table.delete_item(
                Key={
                    'embedding_id': item['embedding_id'],
                    'created_at': item['created_at']
                }
            )
            deleted_count += 1

        return {
            'success': True,
            'dataset_id': dataset_id,
            'deleted_count': deleted_count
        }

    except Exception as e:
        print(f"Error deleting embeddings: {str(e)}")
        raise


def lambda_handler(event, context):
    """
    Main Lambda handler for RAG knowledge base operations
    """
    print(f"Received event: {json.dumps(event)}")

    try:
        # Parse request
        if isinstance(event.get('body'), str):
            body = json.loads(event['body'])
        else:
            body = event.get('body', event)

        operation = body.get('operation')
        parameters = body.get('parameters', {})

        # Route to appropriate handler
        if operation == 'index_dataset':
            result = index_dataset(parameters)
        elif operation == 'query':
            result = query_knowledge_base(parameters)
        elif operation == 'delete_dataset':
            result = delete_dataset_embeddings(parameters)
        elif operation == 'semantic_search':
            # Direct semantic search without answer generation
            query = parameters.get('query')
            top_k = parameters.get('top_k', 10)
            dataset_id = parameters.get('dataset_id')

            results = semantic_search(query, top_k, dataset_id)
            result = {'results': results, 'total_results': len(results)}
        else:
            raise ValueError(f"Unknown operation: {operation}")

        # Return success response
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps(result, cls=DecimalEncoder)
        }

    except ValueError as e:
        print(f"Validation error: {str(e)}")
        return {
            'statusCode': 400,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'error': 'Validation error',
                'message': str(e)
            })
        }

    except Exception as e:
        print(f"Error: {str(e)}")
        import traceback
        traceback.print_exc()

        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'error': 'Internal server error',
                'message': str(e)
            })
        }
