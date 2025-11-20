import React, { useState } from 'react';
import {
  Container,
  Header,
  SpaceBetween,
  Form,
  FormField,
  Select,
  Textarea,
  Button,
  Alert,
  Box,
  ColumnLayout,
  ExpandableSection,
  Tabs,
  CodeEditor
} from '@cloudscape-design/components';
import { api } from '../services/api';

interface AnalysisResult {
  analysis?: string;
  metadata?: any;
  classification?: {
    artifact_type: string;
    period: string;
    culture: string;
    material: string;
    confidence: number;
  };
  description?: string;
  embeddings?: number[];
  text?: string;
}

const AIAnalysis: React.FC = () => {
  const [bucket, setBucket] = useState({ label: 'Public', value: 'public' });
  const [objectKey, setObjectKey] = useState('');
  const [operation, setOperation] = useState({ label: 'Analyze Image', value: 'analyze' });
  const [customPrompt, setCustomPrompt] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [result, setResult] = useState<AnalysisResult | null>(null);

  const bucketOptions = [
    { label: 'Public', value: 'public' },
    { label: 'Private', value: 'private' },
    { label: 'Restricted', value: 'restricted' },
    { label: 'Embargoed', value: 'embargoed' }
  ];

  const operationOptions = [
    { label: 'Analyze Image', value: 'analyze' },
    { label: 'Extract Metadata', value: 'metadata' },
    { label: 'Classify Artifact', value: 'classify' },
    { label: 'Generate Description', value: 'description' },
    { label: 'Extract Text (OCR)', value: 'text' },
    { label: 'Generate Embeddings', value: 'embeddings' }
  ];

  const handleAnalyze = async () => {
    if (!objectKey) {
      setError('Please enter an object key');
      return;
    }

    setError('');
    setLoading(true);
    setResult(null);

    try {
      let response;
      const bucketName = `aperture-${bucket.value}-media`;

      switch (operation.value) {
        case 'analyze':
          response = await api.analyzeImage(bucketName, objectKey, customPrompt);
          setResult({ analysis: response.analysis });
          break;

        case 'metadata':
          response = await api.extractMetadata(bucketName, objectKey, 'artifact');
          setResult({ metadata: response.metadata });
          break;

        case 'classify':
          response = await api.classifyArtifact(bucketName, objectKey);
          setResult({ classification: response.classification });
          break;

        case 'description':
          response = await api.generateDescription(bucketName, objectKey, 'academic');
          setResult({ description: response.description });
          break;

        case 'text':
          response = await api.extractText(bucketName, objectKey);
          setResult({ text: response.text });
          break;

        case 'embeddings':
          response = await api.generateEmbeddings(bucketName, objectKey);
          setResult({ embeddings: response.embeddings });
          break;

        default:
          throw new Error('Unknown operation');
      }
    } catch (err: any) {
      setError(err.response?.data?.error || err.message || 'Analysis failed');
    } finally {
      setLoading(false);
    }
  };

  const renderResult = () => {
    if (!result) return null;

    return (
      <SpaceBetween size="l">
        {result.analysis && (
          <Box>
            <Header variant="h3">Analysis Result</Header>
            <Box variant="p">{result.analysis}</Box>
          </Box>
        )}

        {result.metadata && (
          <ExpandableSection headerText="Extracted Metadata" defaultExpanded>
            <CodeEditor
              ace={undefined}
              language="json"
              value={JSON.stringify(result.metadata, null, 2)}
              preferences={undefined}
              onPreferencesChange={() => {}}
              loading={false}
              i18nStrings={{
                loadingState: 'Loading code editor',
                errorState: 'There was an error loading the code editor.',
                errorStateRecovery: 'Retry',
                editorGroupAriaLabel: 'Code editor',
                statusBarGroupAriaLabel: 'Status bar',
                cursorPosition: (row, column) => `Ln ${row}, Col ${column}`,
                errorsTab: 'Errors',
                warningsTab: 'Warnings',
                preferencesButtonAriaLabel: 'Preferences',
                paneCloseButtonAriaLabel: 'Close',
                preferencesModalHeader: 'Preferences',
                preferencesModalCancel: 'Cancel',
                preferencesModalConfirm: 'Confirm',
                preferencesModalWrapLines: 'Wrap lines',
                preferencesModalTheme: 'Theme',
                preferencesModalLightThemes: 'Light themes',
                preferencesModalDarkThemes: 'Dark themes'
              }}
            />
          </ExpandableSection>
        )}

        {result.classification && (
          <ColumnLayout columns={2} variant="text-grid">
            <div>
              <Box variant="awsui-key-label">Artifact Type</Box>
              <div>{result.classification.artifact_type}</div>
            </div>
            <div>
              <Box variant="awsui-key-label">Period</Box>
              <div>{result.classification.period}</div>
            </div>
            <div>
              <Box variant="awsui-key-label">Culture</Box>
              <div>{result.classification.culture}</div>
            </div>
            <div>
              <Box variant="awsui-key-label">Material</Box>
              <div>{result.classification.material}</div>
            </div>
            <div>
              <Box variant="awsui-key-label">Confidence</Box>
              <div>{(result.classification.confidence * 100).toFixed(1)}%</div>
            </div>
          </ColumnLayout>
        )}

        {result.description && (
          <Box>
            <Header variant="h3">Generated Description</Header>
            <Box variant="p">{result.description}</Box>
          </Box>
        )}

        {result.text && (
          <Box>
            <Header variant="h3">Extracted Text</Header>
            <Box variant="p" fontFamily="monospace">
              {result.text}
            </Box>
          </Box>
        )}

        {result.embeddings && (
          <ExpandableSection headerText="Generated Embeddings">
            <Box variant="p">
              Vector of {result.embeddings.length} dimensions generated. First 10 values:
            </Box>
            <Box variant="code">
              [{result.embeddings.slice(0, 10).map((v) => v.toFixed(6)).join(', ')}, ...]
            </Box>
          </ExpandableSection>
        )}
      </SpaceBetween>
    );
  };

  return (
    <Container
      header={
        <Header
          variant="h1"
          description="Use AI to analyze images, extract metadata, classify artifacts, and more"
        >
          AI-Powered Analysis
        </Header>
      }
    >
      <SpaceBetween size="l">
        <Tabs
          tabs={[
            {
              label: 'Single Image Analysis',
              id: 'single',
              content: (
                <Form
                  actions={
                    <SpaceBetween direction="horizontal" size="xs">
                      <Button
                        variant="primary"
                        loading={loading}
                        onClick={handleAnalyze}
                        disabled={!objectKey}
                      >
                        Analyze
                      </Button>
                    </SpaceBetween>
                  }
                >
                  <SpaceBetween size="l">
                    {error && <Alert type="error">{error}</Alert>}

                    <FormField label="Bucket" description="Select the bucket containing the image">
                      <Select
                        selectedOption={bucket}
                        onChange={({ detail }) => setBucket(detail.selectedOption)}
                        options={bucketOptions}
                      />
                    </FormField>

                    <FormField
                      label="Object Key"
                      description="S3 object key (e.g., datasets/artifact-001/image.jpg)"
                    >
                      <Textarea
                        value={objectKey}
                        onChange={({ detail }) => setObjectKey(detail.value)}
                        placeholder="datasets/my-artifact/image.jpg"
                        rows={2}
                      />
                    </FormField>

                    <FormField label="Operation" description="Select the analysis operation">
                      <Select
                        selectedOption={operation}
                        onChange={({ detail }) => setOperation(detail.selectedOption)}
                        options={operationOptions}
                      />
                    </FormField>

                    {operation.value === 'analyze' && (
                      <FormField
                        label="Custom Prompt (Optional)"
                        description="Provide specific instructions for the analysis"
                      >
                        <Textarea
                          value={customPrompt}
                          onChange={({ detail }) => setCustomPrompt(detail.value)}
                          placeholder="Describe the ceramic patterns and estimate the time period..."
                          rows={3}
                        />
                      </FormField>
                    )}

                    <Box variant="p" color="text-body-secondary">
                      <strong>Note:</strong> Analysis uses Claude 3 Sonnet for vision tasks and
                      Amazon Titan for embeddings. Processing time varies by operation (typically
                      5-30 seconds).
                    </Box>
                  </SpaceBetween>
                </Form>
              )
            },
            {
              label: 'About AI Features',
              id: 'about',
              content: (
                <SpaceBetween size="l">
                  <Box>
                    <Header variant="h3">AI Analysis Capabilities</Header>
                    <ColumnLayout columns={1} variant="text-grid">
                      <div>
                        <Box variant="strong">Analyze Image</Box>
                        <Box variant="p">
                          Get detailed visual analysis of artifacts, including composition,
                          condition, notable features, and research-relevant observations.
                        </Box>
                      </div>
                      <div>
                        <Box variant="strong">Extract Metadata</Box>
                        <Box variant="p">
                          Automatically extract structured metadata following archaeological
                          standards (CIDOC-CRM compliant).
                        </Box>
                      </div>
                      <div>
                        <Box variant="strong">Classify Artifact</Box>
                        <Box variant="p">
                          Identify artifact type, historical period, cultural origin, and material
                          composition with confidence scores.
                        </Box>
                      </div>
                      <div>
                        <Box variant="strong">Generate Description</Box>
                        <Box variant="p">
                          Create publication-ready descriptions in academic, catalog, or public
                          styles.
                        </Box>
                      </div>
                      <div>
                        <Box variant="strong">Extract Text (OCR)</Box>
                        <Box variant="p">
                          Extract inscriptions, field notes, labels, or other text from images for
                          searchability and analysis.
                        </Box>
                      </div>
                      <div>
                        <Box variant="strong">Generate Embeddings</Box>
                        <Box variant="p">
                          Create vector embeddings for similarity search, clustering, and visual
                          search across your collection.
                        </Box>
                      </div>
                    </ColumnLayout>
                  </Box>

                  <Box>
                    <Header variant="h3">Best Practices</Header>
                    <ul>
                      <li>Use high-resolution images for better analysis accuracy</li>
                      <li>
                        Provide context in custom prompts (e.g., region, time period, excavation
                        site)
                      </li>
                      <li>
                        Extract embeddings for large collections to enable similarity search
                      </li>
                      <li>Use batch operations for processing multiple artifacts efficiently</li>
                      <li>
                        Always verify AI-generated classifications with expert knowledge
                      </li>
                    </ul>
                  </Box>

                  <Box>
                    <Header variant="h3">Model Information</Header>
                    <ColumnLayout columns={2} variant="text-grid">
                      <div>
                        <Box variant="awsui-key-label">Vision Model</Box>
                        <div>Claude 3 Sonnet (Anthropic)</div>
                      </div>
                      <div>
                        <Box variant="awsui-key-label">Embedding Model</Box>
                        <div>Amazon Titan Embed Image v1</div>
                      </div>
                      <div>
                        <Box variant="awsui-key-label">Context Window</Box>
                        <div>200K tokens</div>
                      </div>
                      <div>
                        <Box variant="awsui-key-label">Image Support</Box>
                        <div>PNG, JPEG, GIF, WebP</div>
                      </div>
                    </ColumnLayout>
                  </Box>
                </SpaceBetween>
              )
            }
          ]}
        />

        {result && (
          <Container header={<Header variant="h2">Results</Header>}>{renderResult()}</Container>
        )}
      </SpaceBetween>
    </Container>
  );
};

export default AIAnalysis;
