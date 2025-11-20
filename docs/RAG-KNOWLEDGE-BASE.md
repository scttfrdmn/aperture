# RAG Knowledge Base Integration

## Overview

The RAG (Retrieval-Augmented Generation) Knowledge Base enables semantic search and natural language querying across research datasets. It combines vector embeddings for similarity search with Claude AI for answer generation, providing researchers with powerful tools to discover and understand their data.

**Key Features:**
- **Natural Language Q&A**: Ask questions in plain language and get AI-generated answers
- **Semantic Search**: Find content by meaning, not just keywords
- **Dataset Indexing**: Automatically generate embeddings for searchable content
- **Cross-Dataset Search**: Search across multiple datasets simultaneously
- **Source Attribution**: See which datasets contributed to each answer

**Last Updated**: November 10, 2024
**Status**: Production Ready

---

## Table of Contents

1. [Architecture](#architecture)
2. [Components](#components)
3. [API Endpoints](#api-endpoints)
4. [Lambda Function](#lambda-function)
5. [Frontend Integration](#frontend-integration)
6. [Usage Examples](#usage-examples)
7. [Data Model](#data-model)
8. [Performance & Optimization](#performance--optimization)
9. [Cost Analysis](#cost-analysis)
10. [Limitations](#limitations)
11. [Troubleshooting](#troubleshooting)
12. [Future Enhancements](#future-enhancements)

---

## Architecture

### System Overview

```
┌─────────────┐     ┌──────────────┐     ┌─────────────────┐
│   Frontend  │────→│  API Gateway │────→│   RAG Lambda    │
│   (React)   │     │   (HTTP API) │     │   (Python 3.11) │
└─────────────┘     └──────────────┘     └─────────────────┘
                                                   │
                                                   ↓
                          ┌────────────────────────┼────────────────────┐
                          │                        │                    │
                          ↓                        ↓                    ↓
                   ┌──────────────┐      ┌───────────────┐    ┌──────────────┐
                   │   DynamoDB   │      │  Bedrock API  │    │ Bedrock API  │
                   │  (Embeddings)│      │  (Titan Embed)│    │   (Claude)   │
                   └──────────────┘      └───────────────┘    └──────────────┘
```

### Data Flow

#### 1. Indexing Flow
```
Dataset Metadata → RAG Lambda → Titan Embed Text → Vector Embeddings → DynamoDB
```

#### 2. Query Flow (Q&A)
```
User Question → RAG Lambda → Generate Query Embedding → DynamoDB (Cosine Similarity)
                    ↓
            Retrieve Top K Results
                    ↓
            Build Context from Sources
                    ↓
            Claude 3 Sonnet (Answer Generation)
                    ↓
            Return Answer + Sources
```

#### 3. Search Flow
```
Search Query → RAG Lambda → Generate Query Embedding → DynamoDB (Cosine Similarity)
                    ↓
            Return Ranked Results (No Answer Generation)
```

---

## Components

### 1. RAG Lambda Function

**Location**: `lambda/rag-knowledge-base/handler.py`

**Runtime**: Python 3.11
**Timeout**: 180 seconds
**Memory**: 1024 MB

**Operations**:
- `index_dataset`: Generate and store embeddings for dataset metadata
- `query`: Semantic search with Claude-generated answers (RAG)
- `semantic_search`: Vector similarity search without answer generation
- `delete_dataset`: Remove all embeddings for a dataset

**Dependencies**:
```python
boto3>=1.28.0  # AWS SDK for Bedrock and DynamoDB
```

### 2. DynamoDB Embeddings Table

**Table Name**: `{project_name}-knowledge-base-embeddings-{environment}`

**Schema**:
```
Primary Key:
  - embedding_id (String, Hash Key): Unique identifier for each embedding
  - created_at (String, Sort Key): ISO 8601 timestamp

Attributes:
  - dataset_id (String): Dataset identifier
  - content (String): Original text content (metadata, abstract, keywords, etc.)
  - content_type (String): Type of content (metadata, abstract, keywords, etc.)
  - embedding (List<Number>): 1536-dimensional vector from Titan Embed Text
  - metadata (Map): Additional metadata about the embedding

Global Secondary Indexes:
  - DatasetIdIndex: dataset_id (Hash) + created_at (Sort)
  - ContentTypeIndex: content_type (Hash) + created_at (Sort)
```

### 3. API Gateway Routes

**Base URL**: `https://{api-id}.execute-api.{region}.amazonaws.com/{environment}`

**Routes** (All protected with JWT):
- `POST /rag/index` - Index dataset embeddings
- `POST /rag/query` - Query with answer generation
- `POST /rag/search` - Semantic search only
- `DELETE /rag/{dataset_id}` - Delete dataset embeddings

---

## API Endpoints

### 1. Index Dataset

**Endpoint**: `POST /rag/index`

**Description**: Generate and store embeddings for dataset metadata, enabling semantic search.

**Request**:
```json
{
  "dataset_id": "dataset-12345",
  "metadata": {
    "title": "Bronze Age Pottery Collection",
    "description": "Ceramic vessels from archaeological excavations...",
    "keywords": ["pottery", "bronze age", "ceramics"],
    "abstract": "This dataset contains 3D scans and photographs..."
  }
}
```

**Response**:
```json
{
  "status": "success",
  "dataset_id": "dataset-12345",
  "embeddings_created": 4,
  "content_types": ["metadata", "abstract", "keywords"]
}
```

**Status Codes**:
- `200`: Success
- `400`: Invalid request
- `401`: Unauthorized
- `500`: Server error

---

### 2. Query Knowledge Base

**Endpoint**: `POST /rag/query`

**Description**: Ask a question and receive an AI-generated answer based on relevant dataset content.

**Request**:
```json
{
  "query": "What pottery artifacts were found in Bronze Age settlements?",
  "dataset_id": "dataset-12345",  // Optional: filter to specific dataset
  "top_k": 5,                      // Optional: number of sources (default: 5)
  "filters": {                     // Optional: additional filters
    "content_type": "abstract"
  }
}
```

**Response**:
```json
{
  "answer": "Based on the available research data, several pottery artifacts were discovered in Bronze Age settlements, including ceramic vessels, storage jars, and decorative bowls. The pottery shows evidence of advanced firing techniques and decorative patterns typical of the period...",
  "confidence": 0.89,
  "sources": [
    {
      "dataset_id": "dataset-12345",
      "content": "Ceramic vessels from archaeological excavations...",
      "content_type": "abstract",
      "similarity": 0.92,
      "metadata": {}
    },
    {
      "dataset_id": "dataset-67890",
      "content": "Bronze Age pottery collection featuring storage vessels...",
      "content_type": "metadata",
      "similarity": 0.87,
      "metadata": {}
    }
  ],
  "query_embedding_generated": true
}
```

**Status Codes**:
- `200`: Success
- `400`: Invalid request or missing query
- `401`: Unauthorized
- `404`: No relevant content found
- `500`: Server error

---

### 3. Semantic Search

**Endpoint**: `POST /rag/search`

**Description**: Find semantically similar content without generating an answer. Faster than query endpoint.

**Request**:
```json
{
  "query": "ceramic vessels ancient civilizations",
  "dataset_id": "dataset-12345",  // Optional
  "top_k": 10,                     // Optional: default 10
  "filters": {}                    // Optional
}
```

**Response**:
```json
{
  "results": [
    {
      "dataset_id": "dataset-12345",
      "content": "Bronze Age pottery collection...",
      "content_type": "metadata",
      "similarity": 0.94,
      "metadata": {},
      "created_at": "2024-11-10T15:30:00Z"
    },
    {
      "dataset_id": "dataset-67890",
      "content": "Ceramic analysis from excavation site...",
      "content_type": "abstract",
      "similarity": 0.89,
      "metadata": {},
      "created_at": "2024-11-09T10:15:00Z"
    }
  ],
  "total_results": 2,
  "query_embedding_generated": true
}
```

**Status Codes**:
- `200`: Success
- `400`: Invalid request
- `401`: Unauthorized
- `500`: Server error

---

### 4. Delete Dataset Embeddings

**Endpoint**: `DELETE /rag/{dataset_id}`

**Description**: Remove all embeddings associated with a dataset.

**Request**: No body required

**Response**:
```json
{
  "status": "success",
  "dataset_id": "dataset-12345",
  "embeddings_deleted": 15
}
```

**Status Codes**:
- `200`: Success
- `400`: Invalid dataset ID
- `401`: Unauthorized
- `404`: Dataset not found
- `500`: Server error

---

## Lambda Function

### Core Functions

#### 1. `index_dataset(dataset_id, metadata)`

**Purpose**: Generate embeddings for dataset metadata and store in DynamoDB.

**Process**:
1. Extract text content from metadata (title, description, abstract, keywords)
2. Generate embedding for each content type using Titan Embed Text
3. Store embeddings in DynamoDB with dataset ID and content type
4. Return count of embeddings created

**Example Usage**:
```python
result = index_dataset(
    dataset_id="dataset-12345",
    metadata={
        "title": "Bronze Age Pottery",
        "description": "Archaeological artifacts...",
        "keywords": ["pottery", "bronze age"]
    }
)
```

---

#### 2. `query_knowledge_base(query, dataset_id=None, top_k=5, filters=None)`

**Purpose**: Perform RAG query with answer generation.

**Process**:
1. Generate embedding for user query using Titan Embed Text
2. Retrieve all embeddings from DynamoDB (filtered by dataset_id if provided)
3. Calculate cosine similarity between query embedding and stored embeddings
4. Select top K most similar results
5. Build context from retrieved content
6. Generate answer using Claude 3 Sonnet
7. Return answer with source attribution

**Example Usage**:
```python
result = query_knowledge_base(
    query="What pottery was found?",
    dataset_id="dataset-12345",
    top_k=5
)
```

---

#### 3. `semantic_search(query, dataset_id=None, top_k=10, filters=None)`

**Purpose**: Perform semantic search without answer generation (faster).

**Process**:
1. Generate embedding for search query
2. Retrieve embeddings from DynamoDB
3. Calculate cosine similarity
4. Return top K results sorted by similarity

**Example Usage**:
```python
results = semantic_search(
    query="ceramic vessels",
    top_k=10
)
```

---

#### 4. `delete_dataset_embeddings(dataset_id)`

**Purpose**: Remove all embeddings for a dataset.

**Process**:
1. Query DynamoDB using DatasetIdIndex
2. Batch delete all matching embeddings
3. Return count of deleted items

**Example Usage**:
```python
result = delete_dataset_embeddings(dataset_id="dataset-12345")
```

---

### Vector Similarity

**Algorithm**: Cosine Similarity

**Implementation**:
```python
def cosine_similarity(vec1: List[float], vec2: List[float]) -> float:
    dot_product = sum(a * b for a, b in zip(vec1, vec2))
    magnitude1 = math.sqrt(sum(a * a for a in vec1))
    magnitude2 = math.sqrt(sum(b * b for b in vec2))
    return dot_product / (magnitude1 * magnitude2) if magnitude1 and magnitude2 else 0.0
```

**Range**: 0.0 to 1.0 (higher is more similar)

**Thresholds**:
- `>0.8`: Highly relevant
- `0.6-0.8`: Relevant
- `<0.6`: Marginally relevant

---

## Frontend Integration

### 1. Knowledge Base Page

**Location**: `frontend/src/pages/KnowledgeBase.tsx`

**Route**: `/knowledge-base`

**Features**:
- Three-tab interface (Ask Questions, Semantic Search, Manage & About)
- Dataset filtering by ID
- Configurable result count
- Real-time loading states
- Error handling with dismissible alerts
- Expandable source content display
- Similarity score badges

---

### 2. API Service Methods

**Location**: `frontend/src/services/api.ts`

**Methods**:
```typescript
// Index dataset
api.indexDataset(datasetId: string, metadata?: any): Promise<any>

// Query with answer generation
api.queryKnowledgeBase(
  query: string,
  datasetId?: string,
  topK?: number,
  filters?: any
): Promise<any>

// Semantic search
api.semanticSearch(
  query: string,
  datasetId?: string,
  topK?: number,
  filters?: any
): Promise<any>

// Delete embeddings
api.deleteDatasetEmbeddings(datasetId: string): Promise<any>
```

---

### 3. Navigation

**Section**: "AI & Search"

**Items**:
- AI Analysis
- Knowledge Base ← New

---

## Usage Examples

### Example 1: Index a New Dataset

```bash
curl -X POST https://api.example.com/dev/rag/index \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "dataset_id": "excavation-2024-site-a",
    "metadata": {
      "title": "Site A Excavation 2024",
      "description": "Archaeological excavation of Bronze Age settlement",
      "keywords": ["bronze age", "settlement", "pottery", "tools"],
      "abstract": "This dataset contains comprehensive documentation..."
    }
  }'
```

---

### Example 2: Ask a Question

```bash
curl -X POST https://api.example.com/dev/rag/query \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "What types of pottery were most common in Bronze Age settlements?",
    "top_k": 5
  }'
```

**Response**:
```json
{
  "answer": "Based on the research data, the most common pottery types in Bronze Age settlements included storage jars, cooking vessels, and decorative bowls. Storage jars were particularly prevalent, used for grain and liquid storage...",
  "confidence": 0.91,
  "sources": [...]
}
```

---

### Example 3: Semantic Search

```bash
curl -X POST https://api.example.com/dev/rag/search \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "ceramic analysis archaeological sites",
    "top_k": 10,
    "dataset_id": "excavation-2024-site-a"
  }'
```

---

### Example 4: Delete Dataset Embeddings

```bash
curl -X DELETE https://api.example.com/dev/rag/excavation-2024-site-a \
  -H "Authorization: Bearer $TOKEN"
```

---

## Data Model

### Embedding Record Structure

```json
{
  "embedding_id": "emb-abc123",
  "dataset_id": "dataset-12345",
  "created_at": "2024-11-10T15:30:00.000Z",
  "content": "Bronze Age pottery collection featuring ceramic vessels from archaeological excavations conducted in 2023-2024...",
  "content_type": "abstract",
  "embedding": [0.023, -0.041, 0.089, ...],  // 1536 dimensions
  "metadata": {
    "source": "dataset_metadata",
    "version": "1.0"
  }
}
```

### Content Types

- **metadata**: Dataset title and description
- **abstract**: Academic abstract or summary
- **keywords**: Research keywords and tags
- **description**: Detailed description text
- **notes**: Additional notes or annotations

---

## Performance & Optimization

### Embedding Generation

**Model**: Amazon Titan Embed Text v1
**Dimensions**: 1536
**Latency**: ~200-500ms per embedding
**Cost**: $0.0001 per 1,000 tokens

**Optimization Tips**:
- Batch index multiple datasets during off-peak hours
- Cache embeddings for frequently queried content
- Use content-type filtering to reduce search space

---

### Similarity Search

**Complexity**: O(n) where n = number of embeddings
**Performance**:
- 1,000 embeddings: ~100-200ms
- 10,000 embeddings: ~500ms-1s
- 100,000 embeddings: ~5-10s

**Optimization Strategies**:
1. **Dataset Filtering**: Use dataset_id to limit search scope
2. **Content Type Filtering**: Filter by content_type GSI
3. **Result Limiting**: Use appropriate top_k values (5-10 for Q&A, 10-20 for search)
4. **Parallel Processing**: Consider parallel similarity calculations for large datasets

---

### Answer Generation

**Model**: Claude 3 Sonnet
**Context Window**: Up to 200K tokens
**Typical Latency**: 1-3 seconds
**Cost**: $3 per million input tokens, $15 per million output tokens

**Best Practices**:
- Limit context to top 5-10 most relevant sources
- Use semantic search (without answer generation) when answer not needed
- Implement response caching for common queries

---

## Cost Analysis

### Monthly Cost Estimates

**Assumptions**:
- 1,000 datasets indexed per month
- 10,000 queries per month
- Average 500 tokens per query
- Average 300 tokens per answer

**Breakdown**:

| Component | Usage | Unit Cost | Monthly Cost |
|-----------|-------|-----------|--------------|
| Titan Embed Text (Indexing) | 1,000 datasets × 4 embeddings × 200 tokens | $0.0001 per 1K tokens | $0.08 |
| Titan Embed Text (Queries) | 10,000 queries × 50 tokens | $0.0001 per 1K tokens | $0.05 |
| Claude 3 Sonnet (Input) | 10,000 queries × 500 tokens | $3 per 1M tokens | $15.00 |
| Claude 3 Sonnet (Output) | 10,000 queries × 300 tokens | $15 per 1M tokens | $45.00 |
| DynamoDB Storage | 1,000 datasets × 4 embeddings × 10KB | $0.25 per GB | $0.10 |
| DynamoDB Reads | 10,000 queries × 5 reads | $0.25 per 1M reads | $0.01 |
| DynamoDB Writes | 1,000 datasets × 4 writes | $1.25 per 1M writes | $0.01 |
| Lambda Execution | 10,000 invocations × 10s avg × 1024MB | See Lambda pricing | $2.00 |
| **Total** | | | **~$62.25/month** |

**Scaling**:
- Light usage (1,000 queries/mo): ~$8/month
- Medium usage (10,000 queries/mo): ~$62/month
- Heavy usage (100,000 queries/mo): ~$600/month

---

## Limitations

### Technical Limitations

1. **Search Performance**: O(n) complexity means search time increases linearly with embeddings count
   - **Impact**: 100K+ embeddings may have 5-10s latency
   - **Mitigation**: Use dataset filtering, consider vector database for scale

2. **Context Window**: Claude has 200K token limit
   - **Impact**: Very long documents may be truncated
   - **Mitigation**: Chunk long documents during indexing

3. **Embedding Dimensions**: 1536 dimensions (fixed by Titan model)
   - **Impact**: Cannot change embedding size
   - **Mitigation**: None needed, but aware for storage calculations

4. **Decimal Precision**: DynamoDB stores numbers as Decimals
   - **Impact**: Need conversion to/from float
   - **Mitigation**: Handled in Lambda code

---

### Business Limitations

1. **No Versioning**: Embeddings are not versioned
   - **Impact**: Re-indexing overwrites previous embeddings
   - **Mitigation**: Implement versioning in metadata if needed

2. **No Ranking ML**: Uses simple cosine similarity
   - **Impact**: May not learn from user feedback
   - **Mitigation**: Consider ML ranking model in future

3. **English-Centric**: Titan Embed Text optimized for English
   - **Impact**: Other languages may have reduced quality
   - **Mitigation**: Test multilingual use cases, consider language-specific models

---

## Troubleshooting

### Common Issues

#### 1. No Results Returned

**Symptoms**:
```json
{
  "results": [],
  "total_results": 0
}
```

**Causes**:
- Dataset not indexed
- Query too specific
- Low similarity threshold

**Solutions**:
```bash
# 1. Check if dataset is indexed
aws dynamodb query \
  --table-name aperture-knowledge-base-embeddings-dev \
  --index-name DatasetIdIndex \
  --key-condition-expression "dataset_id = :did" \
  --expression-attribute-values '{":did":{"S":"dataset-12345"}}'

# 2. Try broader query
# Instead of: "Bronze Age ceramic vessels with geometric patterns"
# Try: "Bronze Age pottery"

# 3. Check CloudWatch logs
aws logs tail /aws/lambda/aperture-dev-rag-knowledge-base --follow
```

---

#### 2. Slow Query Performance

**Symptoms**: Queries taking >10 seconds

**Causes**:
- Large number of embeddings (100K+)
- Not using dataset filtering
- Network latency

**Solutions**:
```python
# Use dataset filtering
api.queryKnowledgeBase(
    query="...",
    dataset_id="specific-dataset",  # Add this!
    top_k=5
)

# Or use content type filtering
filters = {"content_type": "abstract"}

# Monitor performance
import time
start = time.time()
result = api.queryKnowledgeBase(...)
print(f"Query took {time.time() - start:.2f} seconds")
```

---

#### 3. Poor Answer Quality

**Symptoms**: Answers don't match question or are too generic

**Causes**:
- Low similarity scores in sources
- Insufficient context
- Ambiguous question

**Solutions**:
```python
# 1. Check similarity scores
response = api.queryKnowledgeBase(...)
for source in response['sources']:
    print(f"Similarity: {source['similarity']}")
    # Should be >0.6 for good results

# 2. Increase top_k for more context
api.queryKnowledgeBase(..., top_k=10)

# 3. Rephrase question with more specificity
# Instead of: "Tell me about pottery"
# Try: "What are the characteristics of Bronze Age pottery found in settlement sites?"
```

---

#### 4. Indexing Failures

**Symptoms**: 500 error when indexing dataset

**Causes**:
- Metadata too large
- Invalid JSON
- Bedrock throttling

**Solutions**:
```python
# 1. Validate metadata size
import json
metadata_json = json.dumps(metadata)
print(f"Metadata size: {len(metadata_json)} bytes")
# Should be <400KB per embedding

# 2. Check CloudWatch logs
aws logs tail /aws/lambda/aperture-dev-rag-knowledge-base --follow

# 3. Implement retry logic
from botocore.exceptions import ClientError
import time

def index_with_retry(dataset_id, metadata, max_retries=3):
    for attempt in range(max_retries):
        try:
            return api.indexDataset(dataset_id, metadata)
        except ClientError as e:
            if e.response['Error']['Code'] == 'ThrottlingException':
                time.sleep(2 ** attempt)  # Exponential backoff
            else:
                raise
```

---

#### 5. DynamoDB Decimal Conversion Errors

**Symptoms**: TypeError about Decimal objects

**Causes**: DynamoDB returns Decimals, Python expects floats

**Solutions**:
```python
# Already handled in Lambda, but if extending:
from decimal import Decimal

def convert_decimal_to_float(obj):
    if isinstance(obj, list):
        return [convert_decimal_to_float(i) for i in obj]
    elif isinstance(obj, dict):
        return {k: convert_decimal_to_float(v) for k, v in obj.items()}
    elif isinstance(obj, Decimal):
        return float(obj)
    return obj
```

---

## Future Enhancements

### Short-term (Next 3-6 months)

1. **Query History & Analytics**
   - Track popular queries
   - Analyze search patterns
   - Measure answer quality

2. **Batch Indexing**
   - Index multiple datasets in single operation
   - Progress tracking
   - Error reporting

3. **Advanced Filtering**
   - Date range filters
   - Metadata field filters
   - Boolean query operators

4. **Caching Layer**
   - Cache common queries
   - Redis integration
   - TTL-based invalidation

---

### Medium-term (6-12 months)

1. **Vector Database Migration**
   - Replace DynamoDB with purpose-built vector DB (e.g., Pinecone, Weaviate)
   - Improved search performance (sub-100ms for 1M+ embeddings)
   - Advanced filtering capabilities

2. **Multi-modal Search**
   - Image embeddings (already supported via Bedrock)
   - Search across text and images
   - Cross-modal retrieval

3. **Feedback Loop**
   - Thumbs up/down on answers
   - Relevance feedback
   - ML ranking model

4. **Query Expansion**
   - Automatic synonym expansion
   - Related terms suggestion
   - Spell correction

---

### Long-term (12+ months)

1. **Personalized Search**
   - User-specific ranking
   - Search history integration
   - Collaborative filtering

2. **Knowledge Graph Integration**
   - Entity extraction
   - Relationship mapping
   - Graph-based reasoning

3. **Multi-language Support**
   - Language detection
   - Translation integration
   - Language-specific models

4. **Real-time Indexing**
   - Auto-index on dataset upload
   - Streaming updates
   - Incremental indexing

---

## Additional Resources

### AWS Documentation

- [Amazon Bedrock](https://docs.aws.amazon.com/bedrock/)
- [Titan Embed Text](https://docs.aws.amazon.com/bedrock/latest/userguide/titan-embedding-models.html)
- [Claude Models](https://docs.aws.amazon.com/bedrock/latest/userguide/model-parameters-claude.html)
- [DynamoDB](https://docs.aws.amazon.com/dynamodb/)

### Academic Papers

- "Retrieval-Augmented Generation for Knowledge-Intensive NLP Tasks" (Lewis et al., 2020)
- "Dense Passage Retrieval for Open-Domain Question Answering" (Karpukhin et al., 2020)
- "REALM: Retrieval-Augmented Language Model Pre-Training" (Guu et al., 2020)

### Related Aperture Documentation

- [AWS Bedrock Integration](./AWS-BEDROCK-INTEGRATION.md)
- [API Gateway Module](../infrastructure/terraform/modules/api-gateway/README.md)
- [Lambda Functions Module](../infrastructure/terraform/modules/lambda/README.md)
- [DynamoDB Module](../infrastructure/terraform/modules/dynamodb/README.md)

---

## Support

**Issues**: https://github.com/scttfrdmn/aperture/issues
**Discussions**: https://github.com/scttfrdmn/aperture/discussions
**Security**: security@aperture-platform.org

---

**Document Version**: 1.0
**Last Updated**: November 10, 2024
**Maintainer**: Aperture Development Team
