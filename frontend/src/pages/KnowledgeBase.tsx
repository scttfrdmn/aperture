import React, { useState } from 'react';
import {
  Container,
  Header,
  SpaceBetween,
  Form,
  FormField,
  Input,
  Textarea,
  Button,
  Alert,
  Box,
  ColumnLayout,
  ExpandableSection,
  Tabs,
  Select,
  Badge,
  TextContent
} from '@cloudscape-design/components';
import { api } from '../services/api';

interface SearchResult {
  dataset_id: string;
  content: string;
  content_type: string;
  similarity: number;
  metadata?: any;
}

interface QueryResult {
  answer: string;
  sources: SearchResult[];
  confidence: number;
}

const KnowledgeBase: React.FC = () => {
  const [query, setQuery] = useState('');
  const [datasetId, setDatasetId] = useState('');
  const [topK, setTopK] = useState('5');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [queryResult, setQueryResult] = useState<QueryResult | null>(null);
  const [searchResults, setSearchResults] = useState<SearchResult[]>([]);
  const [activeTabId, setActiveTabId] = useState('query');

  const handleQuery = async () => {
    if (!query) {
      setError('Please enter a query');
      return;
    }

    setError('');
    setLoading(true);
    setQueryResult(null);

    try {
      const response = await api.queryKnowledgeBase(
        query,
        datasetId || undefined,
        parseInt(topK) || 5
      );
      setQueryResult(response);
    } catch (err: any) {
      setError(err.response?.data?.error || 'Failed to query knowledge base');
    } finally {
      setLoading(false);
    }
  };

  const handleSearch = async () => {
    if (!query) {
      setError('Please enter a search query');
      return;
    }

    setError('');
    setLoading(true);
    setSearchResults([]);

    try {
      const response = await api.semanticSearch(
        query,
        datasetId || undefined,
        parseInt(topK) || 10
      );
      setSearchResults(response.results || []);
    } catch (err: any) {
      setError(err.response?.data?.error || 'Failed to perform semantic search');
    } finally {
      setLoading(false);
    }
  };

  const handleIndexDataset = async () => {
    if (!datasetId) {
      setError('Please enter a dataset ID to index');
      return;
    }

    setError('');
    setLoading(true);

    try {
      await api.indexDataset(datasetId);
      setError(''); // Clear any previous errors
      // Show success message
      alert('Dataset indexed successfully!');
    } catch (err: any) {
      setError(err.response?.data?.error || 'Failed to index dataset');
    } finally {
      setLoading(false);
    }
  };

  const renderQueryTab = () => (
    <SpaceBetween size="l">
      <Form
        actions={
          <SpaceBetween direction="horizontal" size="xs">
            <Button
              variant="primary"
              onClick={handleQuery}
              loading={loading}
              disabled={!query}
            >
              Ask Question
            </Button>
          </SpaceBetween>
        }
      >
        <SpaceBetween size="m">
          <FormField
            label="Question"
            description="Ask a question about your research data"
          >
            <Textarea
              value={query}
              onChange={(e) => setQuery(e.detail.value)}
              placeholder="e.g., What pottery artifacts were found in the Bronze Age settlement?"
              rows={3}
            />
          </FormField>

          <ColumnLayout columns={2}>
            <FormField
              label="Dataset ID (optional)"
              description="Leave empty to search across all datasets"
            >
              <Input
                value={datasetId}
                onChange={(e) => setDatasetId(e.detail.value)}
                placeholder="dataset-12345"
              />
            </FormField>

            <FormField
              label="Number of sources"
              description="Number of relevant sources to use"
            >
              <Input
                type="number"
                value={topK}
                onChange={(e) => setTopK(e.detail.value)}
                placeholder="5"
              />
            </FormField>
          </ColumnLayout>
        </SpaceBetween>
      </Form>

      {error && (
        <Alert type="error" dismissible onDismiss={() => setError('')}>
          {error}
        </Alert>
      )}

      {queryResult && (
        <SpaceBetween size="l">
          <Container
            header={
              <Header
                variant="h2"
                description={`Confidence: ${(queryResult.confidence * 100).toFixed(1)}%`}
              >
                Answer
              </Header>
            }
          >
            <TextContent>
              <p style={{ whiteSpace: 'pre-wrap' }}>{queryResult.answer}</p>
            </TextContent>
          </Container>

          <Container
            header={
              <Header variant="h2">
                Sources ({queryResult.sources.length})
              </Header>
            }
          >
            <SpaceBetween size="m">
              {queryResult.sources.map((source, index) => (
                <ExpandableSection
                  key={index}
                  headerText={
                    <Box>
                      <SpaceBetween direction="horizontal" size="xs">
                        <strong>Dataset: {source.dataset_id}</strong>
                        <Badge color={source.similarity > 0.8 ? 'green' : 'blue'}>
                          {(source.similarity * 100).toFixed(1)}% match
                        </Badge>
                        <Badge>{source.content_type}</Badge>
                      </SpaceBetween>
                    </Box>
                  }
                  variant="container"
                >
                  <TextContent>
                    <p style={{ whiteSpace: 'pre-wrap' }}>{source.content}</p>
                  </TextContent>
                </ExpandableSection>
              ))}
            </SpaceBetween>
          </Container>
        </SpaceBetween>
      )}
    </SpaceBetween>
  );

  const renderSearchTab = () => (
    <SpaceBetween size="l">
      <Form
        actions={
          <SpaceBetween direction="horizontal" size="xs">
            <Button
              variant="primary"
              onClick={handleSearch}
              loading={loading}
              disabled={!query}
            >
              Search
            </Button>
          </SpaceBetween>
        }
      >
        <SpaceBetween size="m">
          <FormField
            label="Search query"
            description="Find semantically similar content"
          >
            <Textarea
              value={query}
              onChange={(e) => setQuery(e.detail.value)}
              placeholder="e.g., ceramic vessels from ancient civilizations"
              rows={3}
            />
          </FormField>

          <ColumnLayout columns={2}>
            <FormField
              label="Dataset ID (optional)"
              description="Leave empty to search across all datasets"
            >
              <Input
                value={datasetId}
                onChange={(e) => setDatasetId(e.detail.value)}
                placeholder="dataset-12345"
              />
            </FormField>

            <FormField
              label="Number of results"
              description="Maximum number of results to return"
            >
              <Input
                type="number"
                value={topK}
                onChange={(e) => setTopK(e.detail.value)}
                placeholder="10"
              />
            </FormField>
          </ColumnLayout>
        </SpaceBetween>
      </Form>

      {error && (
        <Alert type="error" dismissible onDismiss={() => setError('')}>
          {error}
        </Alert>
      )}

      {searchResults.length > 0 && (
        <Container
          header={
            <Header variant="h2">
              Search Results ({searchResults.length})
            </Header>
          }
        >
          <SpaceBetween size="m">
            {searchResults.map((result, index) => (
              <ExpandableSection
                key={index}
                headerText={
                  <Box>
                    <SpaceBetween direction="horizontal" size="xs">
                      <strong>#{index + 1} - {result.dataset_id}</strong>
                      <Badge color={result.similarity > 0.8 ? 'green' : result.similarity > 0.6 ? 'blue' : 'grey'}>
                        {(result.similarity * 100).toFixed(1)}% similarity
                      </Badge>
                      <Badge>{result.content_type}</Badge>
                    </SpaceBetween>
                  </Box>
                }
                variant="container"
              >
                <TextContent>
                  <p style={{ whiteSpace: 'pre-wrap' }}>{result.content}</p>
                </TextContent>
              </ExpandableSection>
            ))}
          </SpaceBetween>
        </Container>
      )}
    </SpaceBetween>
  );

  const renderManageTab = () => (
    <SpaceBetween size="l">
      <Container
        header={
          <Header
            variant="h2"
            description="Index dataset metadata and content for semantic search"
          >
            Index Dataset
          </Header>
        }
      >
        <Form
          actions={
            <SpaceBetween direction="horizontal" size="xs">
              <Button
                variant="primary"
                onClick={handleIndexDataset}
                loading={loading}
                disabled={!datasetId}
              >
                Index Dataset
              </Button>
            </SpaceBetween>
          }
        >
          <FormField
            label="Dataset ID"
            description="Enter the dataset ID to generate embeddings for semantic search"
          >
            <Input
              value={datasetId}
              onChange={(e) => setDatasetId(e.detail.value)}
              placeholder="dataset-12345"
            />
          </FormField>
        </Form>

        {error && (
          <Alert type="error" dismissible onDismiss={() => setError('')}>
            {error}
          </Alert>
        )}
      </Container>

      <Container
        header={
          <Header
            variant="h2"
            description="Information about the RAG Knowledge Base"
          >
            About
          </Header>
        }
      >
        <TextContent>
          <p>
            The RAG (Retrieval-Augmented Generation) Knowledge Base enables semantic search
            and question-answering across your research datasets.
          </p>
          <h3>Features:</h3>
          <ul>
            <li><strong>Smart Q&amp;A:</strong> Ask questions in natural language and get answers from your data</li>
            <li><strong>Semantic Search:</strong> Find content by meaning, not just keywords</li>
            <li><strong>Dataset Indexing:</strong> Automatically generate embeddings for searchable content</li>
            <li><strong>Cross-Dataset Search:</strong> Search across multiple datasets simultaneously</li>
          </ul>
          <h3>How it works:</h3>
          <p>
            1. Index your datasets to generate vector embeddings<br />
            2. Query uses semantic similarity to find relevant content<br />
            3. Claude AI generates answers based on retrieved context
          </p>
        </TextContent>
      </Container>
    </SpaceBetween>
  );

  return (
    <Container
      header={
        <Header
          variant="h1"
          description="Query research datasets using natural language and semantic search"
        >
          Knowledge Base
        </Header>
      }
    >
      <Tabs
        activeTabId={activeTabId}
        onChange={({ detail }) => setActiveTabId(detail.activeTabId)}
        tabs={[
          {
            id: 'query',
            label: 'Ask Questions',
            content: renderQueryTab()
          },
          {
            id: 'search',
            label: 'Semantic Search',
            content: renderSearchTab()
          },
          {
            id: 'manage',
            label: 'Manage & About',
            content: renderManageTab()
          }
        ]}
      />
    </Container>
  );
};

export default KnowledgeBase;
