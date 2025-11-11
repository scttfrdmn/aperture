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

  // Generic request method
  async request<T>(config: AxiosRequestConfig): Promise<T> {
    const response = await this.client.request<T>(config);
    return response.data;
  }
}

export const api = new ApiService();
