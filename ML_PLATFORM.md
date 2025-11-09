# ML Research Platform - Advanced AI Capabilities
## Bring Your Own Model, Training, Fine-tuning, and RAG

## Overview

Transform your media repository into a complete **ML research platform** where researchers can:

1. **Bring Your Own Models (BYOM)** - Use custom models via Bedrock
2. **Train/Fine-tune Models** - On repository data
3. **Model Distillation** - Create smaller, efficient models
4. **RAG (Retrieval Augmented Generation)** - Build knowledge bases from your data
5. **Share Models** - Collaborate with model marketplace

## 🚀 Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    Researcher Workspace                          │
│  ┌────────────┐  ┌──────────────┐  ┌────────────────┐         │
│  │  Data      │  │  Model       │  │  Compute       │         │
│  │  Selection │→ │  Training    │→ │  Resources     │         │
│  └────────────┘  └──────────────┘  └────────────────┘         │
└──────────────────────────┬──────────────────────────────────────┘
                           │
         ┌─────────────────┴─────────────────┐
         │                                   │
    ┌────▼─────┐                    ┌───────▼────────┐
    │  Amazon  │                    │  Amazon        │
    │  Bedrock │                    │  SageMaker     │
    │          │                    │                │
    │ • BYOM   │                    │ • Training     │
    │ • Custom │                    │ • Fine-tuning  │
    │ • RAG    │                    │ • Distillation │
    └────┬─────┘                    └───────┬────────┘
         │                                   │
         └─────────────────┬─────────────────┘
                           │
         ┌─────────────────▼─────────────────┐
         │     Model Registry (S3 + DynamoDB) │
         │  • Private models                  │
         │  • Shared models                   │
         │  • Model metadata                  │
         │  • Version control                 │
         └────────────────────────────────────┘
```

## 1. 🎯 Bring Your Own Model (BYOM)

### Supported Methods

#### A. Bedrock Custom Model Import
Import your own foundation model into Bedrock:

```python
def import_custom_model(researcher_id, model_config):
    """
    Import custom model into Bedrock
    """
    # Model config
    {
        "modelName": "species-classifier-v2",
        "description": "Fine-tuned CLIP for species identification",
        "modelType": "vision",  # or "text", "multimodal"
        "sourceLocation": "s3://models/species-classifier.tar.gz",
        "framework": "pytorch",
        "inferenceConfig": {
            "instanceType": "ml.g5.xlarge",
            "minInstances": 0,  # Serverless
            "maxInstances": 3
        },
        "visibility": "private",  # or "team", "public"
        "tags": ["ecology", "species-identification", "computer-vision"]
    }
    
    # Import to Bedrock
    response = bedrock.create_custom_model(
        modelName=model_config['modelName'],
        jobName=f"import-{model_config['modelName']}-{timestamp}",
        customizationType="FINE_TUNING",  # or "CONTINUED_PRETRAINING"
        baseModelIdentifier="anthropic.claude-3-sonnet",  # Base model
        trainingDataConfig={
            "s3Uri": model_config['sourceLocation']
        },
        outputDataConfig={
            "s3Uri": f"s3://models/{researcher_id}/outputs/"
        },
        roleArn=get_bedrock_role_arn()
    )
    
    # Register in model registry
    register_model(
        model_id=response['modelArn'],
        owner=researcher_id,
        metadata=model_config
    )
    
    return {
        "model_id": response['modelArn'],
        "status": "importing",
        "endpoint": f"/api/models/{response['modelArn']}/invoke"
    }
```

#### B. SageMaker Endpoint Integration
Deploy any model as a SageMaker endpoint:

```python
def deploy_custom_model_sagemaker(researcher_id, model_artifact):
    """
    Deploy custom model to SageMaker endpoint
    """
    # Create model
    model = sagemaker.create_model(
        ModelName=f"{researcher_id}-custom-model",
        PrimaryContainer={
            'Image': get_container_image(model_artifact['framework']),
            'ModelDataUrl': model_artifact['s3_path'],
            'Environment': model_artifact.get('env_vars', {})
        },
        ExecutionRoleArn=get_sagemaker_role_arn()
    )
    
    # Create endpoint config (serverless)
    endpoint_config = sagemaker.create_endpoint_config(
        EndpointConfigName=f"{researcher_id}-config",
        ProductionVariants=[{
            'VariantName': 'primary',
            'ModelName': model['ModelName'],
            'ServerlessConfig': {
                'MemorySizeInMB': 4096,
                'MaxConcurrency': 20
            }
        }]
    )
    
    # Create endpoint
    endpoint = sagemaker.create_endpoint(
        EndpointName=f"{researcher_id}-endpoint",
        EndpointConfigName=endpoint_config['EndpointConfigName']
    )
    
    return {
        "endpoint_name": endpoint['EndpointName'],
        "endpoint_url": f"/api/models/custom/{endpoint['EndpointName']}/invoke"
    }
```

### Use Cases for BYOM

1. **Domain-Specific Models**
   - Medical imaging classifiers (trained on private patient data)
   - Species identification (trained on institution's biodiversity data)
   - Geological sample analysis
   - Protein structure prediction

2. **Specialized Tasks**
   - Custom OCR for historical documents
   - Acoustic models for rare dialects
   - Material science image analysis
   - Custom segmentation models

3. **Compliance Requirements**
   - Air-gapped models for sensitive data
   - On-premises model hosting
   - Export-controlled research

### Example: Deploy a Custom Species Classifier

```python
# Researcher uploads their PyTorch model
model_artifact = upload_model(
    path="./species_classifier.pth",
    framework="pytorch",
    python_version="3.10"
)

# Deploy to Bedrock or SageMaker
endpoint = deploy_custom_model_sagemaker(
    researcher_id="dr-jane-smith",
    model_artifact=model_artifact
)

# Use it on repository data
results = []
for image in dataset.get_images():
    prediction = invoke_custom_model(
        endpoint=endpoint['endpoint_name'],
        input=image.to_bytes()
    )
    results.append({
        "image_id": image.id,
        "species": prediction['species'],
        "confidence": prediction['confidence']
    })

# Store predictions in dataset metadata
update_dataset_metadata(dataset.id, {"predictions": results})
```

## 2. 🎓 Model Training & Fine-tuning

### A. Fine-tune Foundation Models (Bedrock)

```python
def fine_tune_claude_on_dataset(dataset_id, task_type):
    """
    Fine-tune Claude on domain-specific data
    """
    # Prepare training data from dataset
    training_data = prepare_training_data(
        dataset_id=dataset_id,
        task_type=task_type,  # "classification", "qa", "summarization"
        format="jsonl"
    )
    
    # Upload to S3
    training_s3_path = upload_training_data(training_data)
    
    # Start fine-tuning job
    job = bedrock.create_model_customization_job(
        jobName=f"finetune-{dataset_id}-{timestamp}",
        customModelName=f"claude-{task_type}-{dataset_id}",
        roleArn=get_bedrock_role_arn(),
        baseModelIdentifier="anthropic.claude-3-sonnet-20240229-v1:0",
        trainingDataConfig={
            "s3Uri": training_s3_path
        },
        validationDataConfig={
            "validators": [{
                "s3Uri": f"{training_s3_path}/validation"
            }]
        },
        hyperParameters={
            "epochCount": "3",
            "batchSize": "4",
            "learningRate": "0.00001"
        },
        outputDataConfig={
            "s3Uri": f"s3://models/{dataset_id}/fine-tuned-output/"
        }
    )
    
    # Track job status
    monitor_training_job(job['jobArn'])
    
    return {
        "job_id": job['jobArn'],
        "status": "training",
        "estimated_completion": calculate_eta(training_data.size)
    }
```

### B. Train Custom Computer Vision Models (SageMaker)

```python
def train_image_classifier(dataset_id, classes):
    """
    Train custom image classifier on dataset
    """
    from sagemaker.pytorch import PyTorch
    
    # Prepare dataset
    training_images = extract_dataset_images(
        dataset_id=dataset_id,
        classes=classes,
        split=0.8  # 80% train, 20% validation
    )
    
    # Upload to S3
    training_input = upload_for_training(training_images)
    
    # Define training script
    training_script = """
    import torch
    import torch.nn as nn
    from torchvision import models, transforms
    
    def train(args):
        # Load pretrained ResNet
        model = models.resnet50(pretrained=True)
        model.fc = nn.Linear(model.fc.in_features, args.num_classes)
        
        # Training loop
        for epoch in range(args.epochs):
            train_epoch(model, train_loader, optimizer, criterion)
            validate(model, val_loader)
        
        # Save model
        torch.save(model.state_dict(), args.model_dir + '/model.pth')
    """
    
    # Create SageMaker estimator
    estimator = PyTorch(
        entry_point='train.py',
        source_dir='./training_scripts',
        role=get_sagemaker_role_arn(),
        instance_type='ml.g5.2xlarge',
        instance_count=1,
        framework_version='2.0',
        py_version='py310',
        hyperparameters={
            'epochs': 10,
            'batch-size': 32,
            'learning-rate': 0.001,
            'num-classes': len(classes)
        },
        use_spot_instances=True,  # Save 70% on compute
        max_wait=7200
    )
    
    # Start training
    estimator.fit({'training': training_input})
    
    # Deploy model
    predictor = estimator.deploy(
        initial_instance_count=1,
        instance_type='ml.g5.xlarge',
        serverless_inference_config={
            'MemorySizeInMB': 4096,
            'MaxConcurrency': 10
        }
    )
    
    return {
        "model_name": estimator.model_data,
        "endpoint_name": predictor.endpoint_name,
        "accuracy": get_validation_metrics(estimator)
    }
```

### C. Audio Model Training

```python
def train_audio_classifier(dataset_id, task="speech_recognition"):
    """
    Train custom audio model (speech recognition, speaker ID, etc.)
    """
    # Extract audio dataset
    audio_data = extract_dataset_audio(
        dataset_id=dataset_id,
        include_transcripts=True
    )
    
    # Use Hugging Face Transformers with SageMaker
    from sagemaker.huggingface import HuggingFace
    
    estimator = HuggingFace(
        entry_point='train_whisper.py',
        source_dir='./audio_training',
        instance_type='ml.g5.4xlarge',
        instance_count=1,
        transformers_version='4.26',
        pytorch_version='2.0',
        py_version='py310',
        role=get_sagemaker_role_arn(),
        hyperparameters={
            'model_name_or_path': 'openai/whisper-base',
            'dataset_name': dataset_id,
            'language': 'en',
            'epochs': 5,
            'learning_rate': 1e-5
        }
    )
    
    estimator.fit({'train': audio_data['train'], 'test': audio_data['test']})
    
    return {
        "model_artifact": estimator.model_data,
        "metrics": {
            "wer": get_word_error_rate(estimator),  # Word Error Rate
            "training_time": estimator.training_time
        }
    }
```

## 3. 🔬 Model Distillation

Create smaller, faster models from larger ones:

```python
def distill_model(teacher_model_id, dataset_id):
    """
    Distill large model into smaller, faster version
    """
    # Use dataset for distillation
    distillation_data = extract_dataset(dataset_id)
    
    # Generate teacher predictions
    teacher_predictions = []
    for sample in distillation_data:
        prediction = invoke_model(teacher_model_id, sample)
        teacher_predictions.append({
            "input": sample,
            "teacher_output": prediction,
            "teacher_logits": prediction.get('logits')
        })
    
    # Train student model
    from transformers import DistilBertForSequenceClassification
    
    student_model = train_distilled_model(
        teacher_predictions=teacher_predictions,
        student_architecture="distilbert-base",
        temperature=2.0,  # Distillation temperature
        alpha=0.5  # Balance between hard and soft labels
    )
    
    # Compare performance
    comparison = {
        "teacher": {
            "accuracy": evaluate_model(teacher_model_id),
            "latency": measure_latency(teacher_model_id),
            "size": get_model_size(teacher_model_id)
        },
        "student": {
            "accuracy": evaluate_model(student_model),
            "latency": measure_latency(student_model),
            "size": get_model_size(student_model)
        }
    }
    
    # Typical results: 95% accuracy, 10x faster, 90% smaller
    return {
        "distilled_model": student_model,
        "comparison": comparison,
        "recommendation": "Deploy student for real-time inference"
    }
```

## 4. 📚 RAG (Retrieval Augmented Generation)

Build knowledge bases from repository data:

### A. Create Knowledge Base (Bedrock Knowledge Bases)

```python
def create_knowledge_base_from_dataset(dataset_id, kb_config):
    """
    Create RAG knowledge base from dataset transcripts and metadata
    """
    # Extract all text content from dataset
    text_corpus = []
    
    # Audio transcripts
    for audio in get_dataset_audio(dataset_id):
        transcript = get_transcript(audio.id)
        text_corpus.append({
            "content": transcript['text'],
            "metadata": {
                "source": audio.filename,
                "type": "audio_transcript",
                "speakers": transcript.get('speakers', []),
                "duration": audio.duration,
                "url": audio.url
            }
        })
    
    # Video transcripts
    for video in get_dataset_videos(dataset_id):
        transcript = get_transcript(video.id)
        text_corpus.append({
            "content": transcript['text'],
            "metadata": {
                "source": video.filename,
                "type": "video_transcript",
                "duration": video.duration,
                "url": video.url
            }
        })
    
    # Image descriptions
    for image in get_dataset_images(dataset_id):
        description = get_ai_analysis(image.id)['description']
        text_corpus.append({
            "content": description,
            "metadata": {
                "source": image.filename,
                "type": "image_description",
                "url": image.url
            }
        })
    
    # Dataset documentation
    readme = get_dataset_readme(dataset_id)
    if readme:
        text_corpus.append({
            "content": readme,
            "metadata": {
                "source": "README.md",
                "type": "documentation"
            }
        })
    
    # Create vector embeddings
    embeddings_s3_path = create_embeddings(
        corpus=text_corpus,
        model="amazon.titan-embed-text-v1"
    )
    
    # Create Bedrock Knowledge Base
    kb = bedrock_agent.create_knowledge_base(
        name=f"kb-{dataset_id}",
        description=f"Knowledge base for dataset {dataset_id}",
        roleArn=get_bedrock_kb_role_arn(),
        knowledgeBaseConfiguration={
            'type': 'VECTOR',
            'vectorKnowledgeBaseConfiguration': {
                'embeddingModelArn': 'arn:aws:bedrock:us-east-1::foundation-model/amazon.titan-embed-text-v1'
            }
        },
        storageConfiguration={
            'type': 'OPENSEARCH_SERVERLESS',
            'opensearchServerlessConfiguration': {
                'collectionArn': get_opensearch_collection_arn(),
                'vectorIndexName': f'kb-index-{dataset_id}',
                'fieldMapping': {
                    'vectorField': 'embedding',
                    'textField': 'content',
                    'metadataField': 'metadata'
                }
            }
        }
    )
    
    # Ingest data
    bedrock_agent.start_ingestion_job(
        knowledgeBaseId=kb['knowledgeBaseId'],
        dataSourceId=create_data_source(embeddings_s3_path)
    )
    
    return {
        "knowledge_base_id": kb['knowledgeBaseId'],
        "num_documents": len(text_corpus),
        "status": "indexing"
    }
```

### B. Query Knowledge Base

```python
def query_knowledge_base(kb_id, question, model_id="anthropic.claude-3-sonnet-20240229-v1:0"):
    """
    Ask questions about dataset using RAG
    """
    # Retrieve relevant context
    response = bedrock_agent.retrieve_and_generate(
        input={
            'text': question
        },
        retrieveAndGenerateConfiguration={
            'type': 'KNOWLEDGE_BASE',
            'knowledgeBaseConfiguration': {
                'knowledgeBaseId': kb_id,
                'modelArn': f'arn:aws:bedrock:us-east-1::foundation-model/{model_id}',
                'retrievalConfiguration': {
                    'vectorSearchConfiguration': {
                        'numberOfResults': 5  # Top 5 relevant chunks
                    }
                }
            }
        }
    )
    
    return {
        "answer": response['output']['text'],
        "sources": [
            {
                "content": citation['generatedResponsePart']['textResponsePart']['text'],
                "source": citation['retrievedReferences'][0]['location']['s3Location'],
                "relevance_score": citation['retrievedReferences'][0]['metadata']['score']
            }
            for citation in response['citations']
        ]
    }
```

### C. Multi-Dataset RAG

```python
def create_research_assistant(dataset_ids, specialization):
    """
    Create RAG assistant across multiple datasets
    """
    # Create unified knowledge base
    combined_kb = bedrock_agent.create_knowledge_base(
        name=f"research-assistant-{specialization}",
        description=f"Multi-dataset RAG for {specialization} research"
    )
    
    # Add all datasets
    for dataset_id in dataset_ids:
        add_dataset_to_kb(combined_kb['knowledgeBaseId'], dataset_id)
    
    # Create agent with tools
    agent = bedrock_agent.create_agent(
        agentName=f"agent-{specialization}",
        foundationModel="anthropic.claude-3-opus-20240229-v1:0",
        instruction=f"""You are a research assistant specializing in {specialization}.
        You have access to multiple research datasets and can:
        1. Answer questions about the research data
        2. Compare findings across datasets
        3. Identify patterns and trends
        4. Suggest related research
        5. Generate summaries and reports
        
        Always cite your sources with timestamps and dataset references.""",
        actionGroups=[
            {
                'actionGroupName': 'dataset-operations',
                'actionGroupExecutor': {
                    'lambda': get_dataset_operations_lambda_arn()
                },
                'apiSchema': {
                    's3': {
                        'bucketName': 'agent-schemas',
                        'objectKey': 'dataset-operations-schema.json'
                    }
                }
            }
        ],
        knowledgeBases=[
            {
                'knowledgeBaseId': combined_kb['knowledgeBaseId'],
                'description': f'{specialization} research corpus'
            }
        ]
    )
    
    return {
        "agent_id": agent['agentId'],
        "agent_alias": create_agent_alias(agent['agentId']),
        "capabilities": [
            "answer_questions",
            "compare_datasets",
            "identify_patterns",
            "generate_reports"
        ]
    }
```

### RAG Use Cases

1. **Research Q&A**
   ```python
   # "What methodology did Dr. Chen use for coral sampling?"
   answer = query_knowledge_base(kb_id, question)
   # Returns: "Dr. Chen used systematic transect sampling at 10m intervals..."
   # Sources: [interview_chen_2024.wav at 23:45, field_notes.pdf page 12]
   ```

2. **Literature Review Assistant**
   ```python
   # "Summarize all findings related to climate impact"
   summary = query_knowledge_base(kb_id, 
       "Summarize all discussions of climate change impacts across all interviews")
   ```

3. **Cross-Dataset Analysis**
   ```python
   # Compare findings across multiple studies
   comparison = query_multi_dataset_kb(
       dataset_ids=["study-2021", "study-2022", "study-2023"],
       question="How have coral bleaching rates changed over time?"
   )
   ```

## 5. 🏪 Model Marketplace

### Share Models with Collaborators

```python
def publish_model_to_marketplace(model_id, visibility="team"):
    """
    Share trained model with others
    """
    model_metadata = get_model_metadata(model_id)
    
    marketplace_entry = {
        "model_id": model_id,
        "name": model_metadata['name'],
        "description": model_metadata['description'],
        "task": model_metadata['task'],  # "classification", "detection", etc.
        "training_dataset": model_metadata['dataset_id'],
        "performance_metrics": {
            "accuracy": model_metadata['accuracy'],
            "precision": model_metadata['precision'],
            "recall": model_metadata['recall'],
            "f1_score": model_metadata['f1']
        },
        "model_card": generate_model_card(model_id),
        "visibility": visibility,  # "private", "team", "institution", "public"
        "license": "CC-BY-4.0",
        "citation": generate_model_citation(model_id),
        "created_by": model_metadata['owner'],
        "created_at": model_metadata['created_at'],
        "downloads": 0,
        "tags": model_metadata['tags']
    }
    
    # Add to marketplace
    dynamodb.put_item(
        TableName='model-marketplace',
        Item=marketplace_entry
    )
    
    return {
        "marketplace_url": f"/models/marketplace/{model_id}",
        "visibility": visibility
    }
```

### Browse and Use Shared Models

```python
def search_model_marketplace(query, filters=None):
    """
    Find models in marketplace
    """
    # Search with filters
    results = search_marketplace(
        query=query,
        filters={
            "task": filters.get('task'),  # "species-classification"
            "domain": filters.get('domain'),  # "ecology", "medical", etc.
            "min_accuracy": filters.get('min_accuracy', 0.8),
            "visibility": ["public", "institution"]
        }
    )
    
    return [
        {
            "model_id": model['model_id'],
            "name": model['name'],
            "accuracy": model['performance_metrics']['accuracy'],
            "creator": model['created_by'],
            "downloads": model['downloads'],
            "preview": {
                "description": model['description'],
                "sample_predictions": get_sample_predictions(model['model_id'])
            }
        }
        for model in results
    ]
```

## 6. 🔬 Research Workflows

### Example: Species Identification Pipeline

```python
def create_species_identification_workflow(dataset_id):
    """
    Complete ML workflow for species identification
    """
    # Step 1: Extract images from dataset
    images = extract_dataset_images(dataset_id)
    
    # Step 2: Check marketplace for existing models
    existing_models = search_model_marketplace(
        query="species identification",
        filters={"domain": "ecology"}
    )
    
    if existing_models:
        # Use existing model
        model_endpoint = existing_models[0]['endpoint']
    else:
        # Step 3: Train new model
        model_endpoint = train_image_classifier(
            dataset_id=dataset_id,
            classes=extract_species_labels(dataset_id)
        )['endpoint_name']
    
    # Step 4: Run predictions
    predictions = []
    for image in images:
        result = invoke_sagemaker_endpoint(
            endpoint_name=model_endpoint,
            data=image.to_bytes()
        )
        predictions.append({
            "image_id": image.id,
            "species": result['predicted_class'],
            "confidence": result['confidence'],
            "top_5": result['top_5_predictions']
        })
    
    # Step 5: Human review (active learning)
    low_confidence = [p for p in predictions if p['confidence'] < 0.8]
    review_queue = create_review_tasks(low_confidence)
    
    # Step 6: Retrain with reviewed data
    if len(review_queue) > 100:
        reviewed_data = get_reviewed_labels(review_queue)
        fine_tune_model(model_endpoint, reviewed_data)
    
    # Step 7: Create knowledge base
    kb_id = create_knowledge_base_from_predictions(
        dataset_id=dataset_id,
        predictions=predictions
    )
    
    # Step 8: Publish model
    publish_model_to_marketplace(
        model_id=model_endpoint,
        visibility="institution"
    )
    
    return {
        "predictions": predictions,
        "model_endpoint": model_endpoint,
        "knowledge_base_id": kb_id,
        "accuracy": calculate_accuracy(predictions),
        "workflow_complete": True
    }
```

### Example: Audio Analysis Pipeline

```python
def create_audio_analysis_workflow(dataset_id, task="speaker_identification"):
    """
    ML workflow for audio analysis
    """
    # Extract audio files
    audio_files = extract_dataset_audio(dataset_id)
    
    # Train/fine-tune Whisper for domain
    transcription_model = fine_tune_whisper(
        dataset_id=dataset_id,
        base_model="openai/whisper-large-v3"
    )
    
    # Transcribe all audio
    transcripts = []
    for audio in audio_files:
        transcript = transcribe_with_model(
            audio_path=audio.path,
            model=transcription_model
        )
        transcripts.append(transcript)
    
    # Train speaker embedding model
    speaker_model = train_speaker_identification(
        audio_files=audio_files,
        num_speakers="auto"  # Automatically detect
    )
    
    # Create RAG knowledge base
    kb_id = create_knowledge_base_from_dataset(
        dataset_id=dataset_id,
        kb_config={"include_speaker_attribution": True}
    )
    
    # Create research assistant
    agent = create_research_assistant(
        dataset_ids=[dataset_id],
        specialization="oral history"
    )
    
    return {
        "transcripts": transcripts,
        "speaker_model": speaker_model,
        "knowledge_base_id": kb_id,
        "agent_id": agent['agent_id'],
        "capabilities": [
            "searchable_transcripts",
            "speaker_identification",
            "topic_extraction",
            "sentiment_analysis",
            "qa_interface"
        ]
    }
```

## 7. 💰 Cost Management

### Model Training Costs

```python
def estimate_training_cost(dataset_size, model_type, instance_type):
    """
    Estimate training cost before starting
    """
    # Pricing (as of 2024)
    instance_costs = {
        "ml.g5.xlarge": 1.006,    # $/hour
        "ml.g5.2xlarge": 1.212,
        "ml.g5.4xlarge": 1.624,
        "ml.g5.8xlarge": 2.448
    }
    
    # Estimate training time
    samples_per_hour = {
        "image_classification": 50000,
        "object_detection": 10000,
        "video_analysis": 100,  # hours of video
        "audio_transcription": 500  # hours of audio
    }
    
    estimated_hours = dataset_size / samples_per_hour[model_type]
    estimated_cost = estimated_hours * instance_costs[instance_type]
    
    # Add Bedrock fine-tuning costs if applicable
    if model_type in ["text_generation", "summarization"]:
        # Bedrock fine-tuning: $0.008 per 1000 tokens
        tokens = dataset_size * 1000  # Rough estimate
        bedrock_cost = (tokens / 1000) * 0.008
        estimated_cost += bedrock_cost
    
    return {
        "estimated_hours": estimated_hours,
        "estimated_cost_usd": estimated_cost,
        "spot_savings": estimated_cost * 0.7,  # 70% savings with spot
        "recommendation": "Use spot instances" if estimated_cost > 100 else "On-demand OK"
    }
```

### Model Serving Costs

```python
def calculate_inference_cost(monthly_requests, model_size):
    """
    Calculate monthly inference costs
    """
    # Bedrock pricing
    if model_size == "small":  # Claude Haiku
        input_cost = 0.25 / 1_000_000   # $0.25 per million tokens
        output_cost = 1.25 / 1_000_000
    elif model_size == "medium":  # Claude Sonnet
        input_cost = 3.00 / 1_000_000
        output_cost = 15.00 / 1_000_000
    else:  # Claude Opus
        input_cost = 15.00 / 1_000_000
        output_cost = 75.00 / 1_000_000
    
    # Average tokens per request
    avg_input_tokens = 1000
    avg_output_tokens = 500
    
    monthly_cost = monthly_requests * (
        (avg_input_tokens * input_cost) +
        (avg_output_tokens * output_cost)
    )
    
    # SageMaker serverless pricing
    # $0.20 per million inference requests + compute
    sagemaker_cost = (monthly_requests / 1_000_000) * 0.20
    sagemaker_cost += monthly_requests * 0.00001  # Compute time
    
    return {
        "bedrock_cost": monthly_cost,
        "sagemaker_cost": sagemaker_cost,
        "recommendation": "Use Bedrock" if monthly_cost < sagemaker_cost else "Use SageMaker"
    }
```

## 8. 🔐 Model Governance

### Model Registry

```python
def register_model_with_governance(model_artifact, metadata):
    """
    Register model with full governance tracking
    """
    model_entry = {
        "model_id": generate_model_id(),
        "name": metadata['name'],
        "version": metadata['version'],
        "framework": metadata['framework'],
        "artifact_location": model_artifact['s3_path'],
        
        # Training provenance
        "training": {
            "dataset_id": metadata['training_dataset'],
            "training_job_id": metadata['training_job'],
            "training_start": metadata['training_start'],
            "training_end": metadata['training_end'],
            "instance_type": metadata['instance_type'],
            "hyperparameters": metadata['hyperparameters']
        },
        
        # Performance metrics
        "metrics": metadata['metrics'],
        
        # Governance
        "owner": metadata['researcher_id'],
        "team": metadata['team_id'],
        "ethics_review": metadata.get('ethics_approved', False),
        "bias_check": run_bias_analysis(model_artifact),
        "explainability": generate_shap_values(model_artifact),
        
        # Usage tracking
        "deployments": [],
        "invocations": 0,
        "last_used": None,
        
        # Compliance
        "data_privacy": check_privacy_compliance(metadata['training_dataset']),
        "export_control": metadata.get('export_controlled', False),
        
        # Lifecycle
        "status": "registered",  # registered, deployed, deprecated, archived
        "deprecation_date": None,
        "replacement_model": None
    }
    
    # Store in model registry
    dynamodb.put_item(
        TableName='model-registry',
        Item=model_entry
    )
    
    return model_entry
```

## 9. 📊 Model Monitoring

### Performance Tracking

```python
def monitor_model_performance(model_id):
    """
    Track model performance over time
    """
    metrics = {
        "invocations_24h": count_invocations(model_id, hours=24),
        "avg_latency_ms": get_avg_latency(model_id),
        "error_rate": get_error_rate(model_id),
        "accuracy_drift": detect_accuracy_drift(model_id),
        "input_distribution_drift": detect_data_drift(model_id),
        "bias_metrics": check_fairness_metrics(model_id)
    }
    
    # Alert if issues detected
    if metrics['accuracy_drift'] > 0.1:
        send_alert(
            model_id=model_id,
            issue="accuracy_degradation",
            recommendation="Consider retraining with recent data"
        )
    
    return metrics
```

## 🎯 Summary

With BYOM, training, and RAG capabilities, researchers can:

1. ✅ **Use any model** - Import custom models or use foundation models
2. ✅ **Train on their data** - Fine-tune on domain-specific datasets
3. ✅ **Build knowledge bases** - RAG from all repository content
4. ✅ **Share models** - Collaborate via model marketplace
5. ✅ **Full governance** - Track provenance, monitor performance
6. ✅ **Cost optimized** - Spot instances, serverless inference

**This transforms the repository from passive storage into an active ML research platform.**

Cost examples:
- Train image classifier: $5-20 (spot instances)
- Fine-tune Claude: $50-200 (depending on dataset size)
- RAG knowledge base: $10-30/month (OpenSearch Serverless)
- Model inference: $0.072 per 1000 requests (Bedrock)

**ROI**: Enable research that would cost $50k-100k+ in commercial ML platforms.
