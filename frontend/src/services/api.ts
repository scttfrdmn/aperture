import axios, { AxiosInstance, AxiosRequestConfig } from 'axios';
import { config } from '../config';

class ApiService {
  private client: AxiosInstance;

  constructor() {
    this.client = axios.create({
      baseURL: config.apiEndpoint,
      timeout: 30000,
      headers: {
        'Content-Type': 'application/json'
      }
    });

    // Request interceptor to add auth token
    this.client.interceptors.request.use(
      (config) => {
        const token = localStorage.getItem('accessToken');
        if (token) {
          config.headers.Authorization = `Bearer ${token}`;
        }
        return config;
      },
      (error) => {
        return Promise.reject(error);
      }
    );

    // Response interceptor for error handling
    this.client.interceptors.response.use(
      (response) => response,
      (error) => {
        if (error.response?.status === 401) {
          // Token expired or invalid
          localStorage.removeItem('accessToken');
          window.location.href = '/login';
        }
        return Promise.reject(error);
      }
    );
  }

  // Authentication endpoints
  async login(username: string, password: string) {
    const response = await this.client.post('/auth/login', { username, password });
    return response.data;
  }

  async logout() {
    const response = await this.client.post('/auth/logout');
    return response.data;
  }

  async verifyToken() {
    const response = await this.client.get('/auth/verify');
    return response.data;
  }

  // Presigned URLs
  async generatePresignedUrl(bucket: string, key: string, expiration?: number) {
    const response = await this.client.post('/urls/generate', {
      bucket,
      key,
      expiration: expiration || 3600
    });
    return response.data;
  }

  async generateBatchPresignedUrls(keys: Array<{ bucket: string; key: string }>) {
    const response = await this.client.post('/urls/batch', { keys });
    return response.data;
  }

  // DOI Management
  async mintDoi(metadata: any) {
    const response = await this.client.post('/doi/mint', metadata);
    return response.data;
  }

  async updateDoi(id: string, metadata: any) {
    const response = await this.client.put(`/doi/${id}`, metadata);
    return response.data;
  }

  async deleteDoi(id: string) {
    const response = await this.client.delete(`/doi/${id}`);
    return response.data;
  }

  // AI Analysis
  async analyzeImage(bucket: string, key: string, prompt?: string) {
    const response = await this.client.post('/ai/analyze-image', {
      bucket,
      key,
      prompt: prompt || 'Analyze this image in detail for academic research purposes.'
    });
    return response.data;
  }

  async extractMetadata(bucket: string, key: string, schemaType?: 'artifact' | 'dataset') {
    const response = await this.client.post('/ai/extract-metadata', {
      bucket,
      key,
      schema_type: schemaType || 'artifact'
    });
    return response.data;
  }

  async classifyArtifact(bucket: string, key: string) {
    const response = await this.client.post('/ai/classify-artifact', {
      bucket,
      key
    });
    return response.data;
  }

  async generateDescription(
    bucket: string,
    key: string,
    style?: 'academic' | 'catalog' | 'public'
  ) {
    const response = await this.client.post('/ai/generate-description', {
      bucket,
      key,
      style: style || 'academic'
    });
    return response.data;
  }

  async generateEmbeddings(bucket: string, key: string) {
    const response = await this.client.post('/ai/generate-embeddings', {
      bucket,
      key
    });
    return response.data;
  }

  async extractText(bucket: string, key: string) {
    const response = await this.client.post('/ai/extract-text', {
      bucket,
      key
    });
    return response.data;
  }

  async analyzeBatch(images: Array<{ bucket: string; key: string }>, operation: string) {
    const response = await this.client.post('/ai/analyze-batch', {
      images,
      operation
    });
    return response.data;
  }

  // RAG Knowledge Base
  async indexDataset(datasetId: string, metadata?: any) {
    const response = await this.client.post('/rag/index', {
      dataset_id: datasetId,
      metadata
    });
    return response.data;
  }

  async queryKnowledgeBase(
    query: string,
    datasetId?: string,
    topK?: number,
    filters?: any
  ) {
    const response = await this.client.post('/rag/query', {
      query,
      dataset_id: datasetId,
      top_k: topK || 5,
      filters
    });
    return response.data;
  }

  async semanticSearch(
    query: string,
    datasetId?: string,
    topK?: number,
    filters?: any
  ) {
    const response = await this.client.post('/rag/search', {
      query,
      dataset_id: datasetId,
      top_k: topK || 10,
      filters
    });
    return response.data;
  }

  async deleteDatasetEmbeddings(datasetId: string) {
    const response = await this.client.delete(`/rag/${datasetId}`);
    return response.data;
  }

  // Generic request method
  async request<T>(config: AxiosRequestConfig): Promise<T> {
    const response = await this.client.request<T>(config);
    return response.data;
  }
}

export const api = new ApiService();
