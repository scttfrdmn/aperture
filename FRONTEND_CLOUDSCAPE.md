# Frontend Architecture - AWS Cloudscape Design System
## Professional AWS-Native User Interface

## Overview

The repository frontend uses **AWS Cloudscape Design System** - the same design system used by AWS Console. This provides:

✅ Professional AWS-native look and feel  
✅ Accessibility (WCAG 2.1 AA compliant)  
✅ Responsive design  
✅ Dark mode support  
✅ 60+ pre-built React components  
✅ Consistent UX with AWS services  

**Demo**: https://cloudscape.design/

## Tech Stack

```json
{
  "framework": "React 18",
  "ui_library": "@cloudscape-design/components",
  "routing": "react-router-dom v6",
  "state": "React Query + Zustand",
  "auth": "AWS Amplify",
  "api": "Axios",
  "charts": "Cloudscape Charts",
  "icons": "Cloudscape Icons",
  "build": "Vite"
}
```

## Installation

```bash
cd frontend

# Install dependencies
npm install @cloudscape-design/components \
            @cloudscape-design/global-styles \
            @cloudscape-design/collection-hooks \
            @cloudscape-design/board-components \
            @cloudscape-design/chat-components \
            aws-amplify \
            react-query \
            zustand \
            react-router-dom \
            axios

# Development
npm run dev

# Build
npm run build
```

## Project Structure

```
frontend/
├── public/
│   ├── index.html
│   └── favicon.ico
├── src/
│   ├── App.jsx                      # Main app with Cloudscape theme
│   ├── index.jsx                    # Entry point
│   │
│   ├── layouts/
│   │   ├── AppLayout.jsx            # Cloudscape AppLayout wrapper
│   │   ├── Navigation.jsx           # Side navigation
│   │   └── TopNavigation.jsx        # Top bar with user menu
│   │
│   ├── pages/
│   │   ├── Home.jsx                 # Dashboard / browse datasets
│   │   ├── DatasetDetail.jsx        # Dataset viewer with media players
│   │   ├── Upload.jsx               # Bulk upload with drag-drop
│   │   ├── MLWorkbench.jsx          # 🆕 ML training interface
│   │   ├── ModelMarketplace.jsx     # 🆕 Browse and use models
│   │   ├── KnowledgeBases.jsx       # 🆕 RAG knowledge bases
│   │   ├── Search.jsx               # Advanced search with filters
│   │   └── Admin.jsx                # Admin dashboard
│   │
│   ├── components/
│   │   ├── media/
│   │   │   ├── VideoPlayer.jsx      # HLS video player
│   │   │   ├── AudioPlayer.jsx      # Audio with waveform
│   │   │   ├── ImageViewer.jsx      # Zoomable image viewer
│   │   │   └── MediaGrid.jsx        # Thumbnail grid
│   │   │
│   │   ├── ai/
│   │   │   ├── AIAnalysisPanel.jsx  # AI insights sidebar
│   │   │   ├── ChatInterface.jsx    # Q&A with RAG
│   │   │   ├── TranscriptViewer.jsx # Interactive transcript
│   │   │   └── SimilarContent.jsx   # Recommendations
│   │   │
│   │   ├── ml/
│   │   │   ├── ModelTrainer.jsx     # 🆕 Training wizard
│   │   │   ├── ModelCard.jsx        # 🆕 Model info display
│   │   │   ├── TrainingProgress.jsx # 🆕 Job monitoring
│   │   │   └── InferenceTest.jsx    # 🆕 Test model predictions
│   │   │
│   │   ├── upload/
│   │   │   ├── DragDropZone.jsx     # File upload zone
│   │   │   ├── UploadProgress.jsx   # Multi-file progress
│   │   │   └── MetadataForm.jsx     # Dataset metadata input
│   │   │
│   │   └── common/
│   │       ├── LoadingState.jsx     # Loading indicators
│   │       ├── ErrorBoundary.jsx    # Error handling
│   │       └── EmptyState.jsx       # No data states
│   │
│   ├── hooks/
│   │   ├── useDatasets.js           # Dataset operations
│   │   ├── useModels.js             # 🆕 ML model operations
│   │   ├── useKnowledgeBase.js      # 🆕 RAG operations
│   │   └── useAuth.js               # Authentication
│   │
│   ├── services/
│   │   ├── api.js                   # API client
│   │   ├── auth.js                  # Amplify auth
│   │   └── storage.js               # S3 operations
│   │
│   ├── store/
│   │   ├── userStore.js             # User state (Zustand)
│   │   ├── uploadStore.js           # Upload state
│   │   └── mlStore.js               # 🆕 ML workflow state
│   │
│   └── utils/
│       ├── formatters.js            # Data formatting
│       ├── validators.js            # Input validation
│       └── constants.js             # App constants
│
├── package.json
├── vite.config.js
└── README.md
```

## Core Layouts

### 1. Main App Layout

```jsx
// src/App.jsx
import React from 'react';
import { BrowserRouter } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from 'react-query';
import { Amplify } from 'aws-amplify';
import '@cloudscape-design/global-styles/index.css';

import AppLayout from './layouts/AppLayout';
import awsConfig from './aws-config';

Amplify.configure(awsConfig);

const queryClient = new QueryClient();

function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <BrowserRouter>
        <AppLayout />
      </BrowserRouter>
    </QueryClientProvider>
  );
}

export default App;
```

### 2. AppLayout with Cloudscape

```jsx
// src/layouts/AppLayout.jsx
import React, { useState } from 'react';
import { Routes, Route } from 'react-router-dom';
import {
  AppLayout as CloudscapeAppLayout,
  ContentLayout,
  Header,
  BreadcrumbGroup,
  Flashbar
} from '@cloudscape-design/components';

import Navigation from './Navigation';
import TopNavigation from './TopNavigation';
import Home from '../pages/Home';
import DatasetDetail from '../pages/DatasetDetail';
import Upload from '../pages/Upload';
import MLWorkbench from '../pages/MLWorkbench';
import ModelMarketplace from '../pages/ModelMarketplace';
import KnowledgeBases from '../pages/KnowledgeBases';

function AppLayout() {
  const [navigationOpen, setNavigationOpen] = useState(true);
  const [notifications, setNotifications] = useState([]);

  return (
    <>
      <TopNavigation />
      
      <CloudscapeAppLayout
        navigation={<Navigation />}
        navigationOpen={navigationOpen}
        onNavigationChange={({ detail }) => setNavigationOpen(detail.open)}
        toolsHide={true}
        notifications={<Flashbar items={notifications} />}
        content={
          <ContentLayout
            header={
              <Header variant="h1">
                Academic Media Repository
              </Header>
            }
          >
            <Routes>
              <Route path="/" element={<Home />} />
              <Route path="/dataset/:id" element={<DatasetDetail />} />
              <Route path="/upload" element={<Upload />} />
              <Route path="/ml" element={<MLWorkbench />} />
              <Route path="/models" element={<ModelMarketplace />} />
              <Route path="/knowledge-bases" element={<KnowledgeBases />} />
            </Routes>
          </ContentLayout>
        }
      />
    </>
  );
}

export default AppLayout;
```

### 3. Navigation

```jsx
// src/layouts/Navigation.jsx
import React from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { SideNavigation } from '@cloudscape-design/components';

function Navigation() {
  const navigate = useNavigate();
  const location = useLocation();

  const navItems = [
    {
      type: 'section',
      text: 'Browse',
      items: [
        { type: 'link', text: 'Datasets', href: '/' },
        { type: 'link', text: 'Search', href: '/search' }
      ]
    },
    {
      type: 'section',
      text: 'Upload',
      items: [
        { type: 'link', text: 'Upload Data', href: '/upload' },
        { type: 'link', text: 'My Datasets', href: '/my-datasets' }
      ]
    },
    {
      type: 'section',
      text: 'AI & ML',
      items: [
        { type: 'link', text: 'ML Workbench', href: '/ml', info: '🆕' },
        { type: 'link', text: 'Model Marketplace', href: '/models', info: '🆕' },
        { type: 'link', text: 'Knowledge Bases', href: '/knowledge-bases', info: '🆕' },
        { type: 'link', text: 'Training Jobs', href: '/ml/jobs' }
      ]
    },
    {
      type: 'section',
      text: 'Admin',
      items: [
        { type: 'link', text: 'Dashboard', href: '/admin' },
        { type: 'link', text: 'Users', href: '/admin/users' },
        { type: 'link', text: 'Budget', href: '/admin/budget' }
      ]
    }
  ];

  return (
    <SideNavigation
      activeHref={location.pathname}
      header={{ text: 'Repository', href: '/' }}
      items={navItems}
      onFollow={(event) => {
        event.preventDefault();
        navigate(event.detail.href);
      }}
    />
  );
}

export default Navigation;
```

## Key Pages

### 1. Dataset Browser (Home)

```jsx
// src/pages/Home.jsx
import React, { useState } from 'react';
import {
  Container,
  Header,
  Cards,
  Box,
  SpaceBetween,
  Input,
  Select,
  Button,
  Badge
} from '@cloudscape-design/components';
import { useDatasets } from '../hooks/useDatasets';

function Home() {
  const [searchTerm, setSearchTerm] = useState('');
  const [filter, setFilter] = useState({ label: 'All', value: 'all' });
  const { data: datasets, isLoading } = useDatasets();

  return (
    <SpaceBetween size="l">
      <Container
        header={
          <Header
            variant="h2"
            description="Browse and search research datasets"
            actions={
              <Button variant="primary" href="/upload">
                Upload Dataset
              </Button>
            }
          >
            Datasets
          </Header>
        }
      >
        <SpaceBetween size="m">
          <Input
            placeholder="Search datasets..."
            value={searchTerm}
            onChange={({ detail }) => setSearchTerm(detail.value)}
            type="search"
          />
          
          <Select
            selectedOption={filter}
            onChange={({ detail }) => setFilter(detail.selectedOption)}
            options={[
              { label: 'All', value: 'all' },
              { label: 'Images', value: 'image' },
              { label: 'Videos', value: 'video' },
              { label: 'Audio', value: 'audio' }
            ]}
          />
        </SpaceBetween>
      </Container>

      <Cards
        cardDefinition={{
          header: item => (
            <Box>
              <Header variant="h3">{item.title}</Header>
              <Box fontSize="body-s" color="text-body-secondary">
                {item.creator}
              </Box>
            </Box>
          ),
          sections: [
            {
              id: 'description',
              content: item => item.description
            },
            {
              id: 'metadata',
              content: item => (
                <SpaceBetween direction="horizontal" size="xs">
                  <Badge color="blue">{item.fileCount} files</Badge>
                  <Badge>{item.size}</Badge>
                  {item.doi && <Badge color="green">DOI</Badge>}
                  {item.aiAnalyzed && <Badge color="purple">AI Analyzed</Badge>}
                </SpaceBetween>
              )
            }
          ]
        }}
        cardsPerRow={[
          { cards: 1 },
          { minWidth: 500, cards: 2 },
          { minWidth: 900, cards: 3 }
        ]}
        items={datasets || []}
        loading={isLoading}
        loadingText="Loading datasets..."
        empty={
          <Box textAlign="center" color="inherit">
            <b>No datasets</b>
            <Box padding={{ bottom: 's' }} variant="p" color="inherit">
              No datasets to display.
            </Box>
            <Button href="/upload">Upload Dataset</Button>
          </Box>
        }
      />
    </SpaceBetween>
  );
}

export default Home;
```

### 2. ML Workbench (NEW)

```jsx
// src/pages/MLWorkbench.jsx
import React, { useState } from 'react';
import {
  Container,
  Header,
  SpaceBetween,
  Tabs,
  Box,
  Button,
  Alert
} from '@cloudscape-design/components';

import ModelTrainer from '../components/ml/ModelTrainer';
import TrainingJobs from '../components/ml/TrainingJobs';
import BYOMPanel from '../components/ml/BYOMPanel';

function MLWorkbench() {
  const [activeTab, setActiveTab] = useState('train');

  return (
    <SpaceBetween size="l">
      <Container
        header={
          <Header
            variant="h1"
            description="Train, fine-tune, and deploy ML models on your data"
            info={<Box variant="small">AWS Bedrock + SageMaker</Box>}
          >
            ML Workbench
          </Header>
        }
      >
        <Alert
          type="info"
          header="Quick Start"
        >
          Select a dataset, choose a model type, and start training. Typical training costs: $5-50.
        </Alert>
      </Container>

      <Tabs
        activeTabId={activeTab}
        onChange={({ detail }) => setActiveTab(detail.activeTabId)}
        tabs={[
          {
            id: 'train',
            label: 'Train New Model',
            content: <ModelTrainer />
          },
          {
            id: 'byom',
            label: 'Bring Your Own Model',
            content: <BYOMPanel />
          },
          {
            id: 'jobs',
            label: 'Training Jobs',
            content: <TrainingJobs />
          }
        ]}
      />
    </SpaceBetween>
  );
}

export default MLWorkbench;
```

### 3. Model Marketplace (NEW)

```jsx
// src/pages/ModelMarketplace.jsx
import React from 'react';
import {
  Container,
  Header,
  Cards,
  Badge,
  Button,
  Box,
  SpaceBetween,
  ProgressBar
} from '@cloudscape-design/components';
import { useModels } from '../hooks/useModels';

function ModelMarketplace() {
  const { data: models, isLoading } = useModels({ visibility: 'public' });

  return (
    <SpaceBetween size="l">
      <Container
        header={
          <Header
            variant="h1"
            description="Browse and use models trained by other researchers"
          >
            Model Marketplace
          </Header>
        }
      />

      <Cards
        cardDefinition={{
          header: model => (
            <Header
              variant="h3"
              actions={
                <Button
                  iconName="download"
                  onClick={() => useModel(model.id)}
                >
                  Use Model
                </Button>
              }
            >
              {model.name}
            </Header>
          ),
          sections: [
            {
              id: 'description',
              content: model => model.description
            },
            {
              id: 'performance',
              content: model => (
                <Box>
                  <Box variant="small" color="text-body-secondary">
                    Accuracy
                  </Box>
                  <ProgressBar
                    value={model.accuracy * 100}
                    label={`${(model.accuracy * 100).toFixed(1)}%`}
                  />
                </Box>
              )
            },
            {
              id: 'metadata',
              content: model => (
                <SpaceBetween direction="horizontal" size="xs">
                  <Badge color="blue">{model.task}</Badge>
                  <Badge>{model.framework}</Badge>
                  <Badge color="green">{model.downloads} downloads</Badge>
                </SpaceBetween>
              )
            }
          ]
        }}
        cardsPerRow={[
          { cards: 1 },
          { minWidth: 500, cards: 2 }
        ]}
        items={models || []}
        loading={isLoading}
      />
    </SpaceBetween>
  );
}

export default ModelMarketplace;
```

### 4. Knowledge Bases (RAG) (NEW)

```jsx
// src/pages/KnowledgeBases.jsx
import React, { useState } from 'react';
import {
  Container,
  Header,
  SpaceBetween,
  Box,
  Button,
  Cards,
  Badge,
  Input,
  Textarea,
  StatusIndicator
} from '@cloudscape-design/components';
import { useKnowledgeBases } from '../hooks/useKnowledgeBase';
import ChatInterface from '../components/ai/ChatInterface';

function KnowledgeBases() {
  const [selectedKB, setSelectedKB] = useState(null);
  const { data: knowledgeBases } = useKnowledgeBases();

  return (
    <SpaceBetween size="l">
      <Container
        header={
          <Header
            variant="h1"
            description="Query your research data using natural language"
            actions={
              <Button
                iconName="add-plus"
                onClick={() => createKnowledgeBase()}
              >
                Create Knowledge Base
              </Button>
            }
          >
            Knowledge Bases (RAG)
          </Header>
        }
      />

      {!selectedKB ? (
        <Cards
          cardDefinition={{
            header: kb => (
              <Header variant="h3">
                {kb.name}
              </Header>
            ),
            sections: [
              {
                id: 'info',
                content: kb => (
                  <Box>
                    <SpaceBetween size="xs">
                      <Box variant="small">
                        {kb.documentCount} documents indexed
                      </Box>
                      <StatusIndicator type="success">
                        Ready
                      </StatusIndicator>
                    </SpaceBetween>
                  </Box>
                )
              },
              {
                id: 'actions',
                content: kb => (
                  <Button
                    fullWidth
                    onClick={() => setSelectedKB(kb)}
                  >
                    Query Knowledge Base
                  </Button>
                )
              }
            ]
          }}
          items={knowledgeBases || []}
        />
      ) : (
        <ChatInterface
          knowledgeBaseId={selectedKB.id}
          onClose={() => setSelectedKB(null)}
        />
      )}
    </SpaceBetween>
  );
}

export default KnowledgeBases;
```

## Key Components

### 1. Model Trainer Component (NEW)

```jsx
// src/components/ml/ModelTrainer.jsx
import React, { useState } from 'react';
import {
  Container,
  Form,
  FormField,
  Select,
  Button,
  SpaceBetween,
  Alert,
  ProgressBar,
  Box
} from '@cloudscape-design/components';
import { useTrainModel } from '../../hooks/useModels';

function ModelTrainer() {
  const [config, setConfig] = useState({
    dataset: null,
    modelType: null,
    baseModel: null
  });
  
  const { mutate: trainModel, isLoading, progress } = useTrainModel();

  const modelTypes = [
    { label: 'Image Classification', value: 'image_classification' },
    { label: 'Object Detection', value: 'object_detection' },
    { label: 'Audio Transcription', value: 'audio_transcription' },
    { label: 'Speaker Identification', value: 'speaker_id' },
    { label: 'Text Generation (Fine-tune Claude)', value: 'text_generation' }
  ];

  return (
    <Form
      actions={
        <SpaceBetween direction="horizontal" size="xs">
          <Button formAction="none" variant="link">
            Cancel
          </Button>
          <Button
            variant="primary"
            onClick={() => trainModel(config)}
            loading={isLoading}
          >
            Start Training
          </Button>
        </SpaceBetween>
      }
    >
      <SpaceBetween size="l">
        <FormField
          label="Select Dataset"
          description="Choose the dataset to train on"
        >
          <Select
            selectedOption={config.dataset}
            onChange={({ detail }) => 
              setConfig({ ...config, dataset: detail.selectedOption })
            }
            placeholder="Choose a dataset"
            options={[
              /* Load from API */
            ]}
          />
        </FormField>

        <FormField
          label="Model Type"
          description="What task should the model perform?"
        >
          <Select
            selectedOption={config.modelType}
            onChange={({ detail }) =>
              setConfig({ ...config, modelType: detail.selectedOption })
            }
            placeholder="Choose model type"
            options={modelTypes}
          />
        </FormField>

        <FormField
          label="Base Model"
          description="Start from a pre-trained model"
        >
          <Select
            selectedOption={config.baseModel}
            onChange={({ detail }) =>
              setConfig({ ...config, baseModel: detail.selectedOption })
            }
            placeholder="Choose base model"
            options={[
              { label: 'ResNet-50 (Image)', value: 'resnet50' },
              { label: 'Whisper Large (Audio)', value: 'whisper-large' },
              { label: 'Claude 3 Sonnet', value: 'claude-3-sonnet' }
            ]}
          />
        </FormField>

        {isLoading && (
          <Alert type="info">
            <SpaceBetween size="s">
              <Box>Training in progress...</Box>
              <ProgressBar
                value={progress}
                label={`${progress}% complete`}
              />
            </SpaceBetween>
          </Alert>
        )}
      </SpaceBetween>
    </Form>
  );
}

export default ModelTrainer;
```

### 2. Chat Interface (RAG)

```jsx
// src/components/ai/ChatInterface.jsx
import React, { useState } from 'react';
import {
  Container,
  Header,
  SpaceBetween,
  Box,
  Button,
  Input,
  Spinner
} from '@cloudscape-design/components';
import { ChatBubble } from '@cloudscape-design/chat-components';
import { useQueryKnowledgeBase } from '../../hooks/useKnowledgeBase';

function ChatInterface({ knowledgeBaseId, onClose }) {
  const [messages, setMessages] = useState([]);
  const [input, setInput] = useState('');
  const { mutate: query, isLoading } = useQueryKnowledgeBase();

  const sendMessage = () => {
    const userMessage = { role: 'user', content: input };
    setMessages([...messages, userMessage]);
    
    query(
      { knowledgeBaseId, question: input },
      {
        onSuccess: (data) => {
          setMessages(prev => [...prev, {
            role: 'assistant',
            content: data.answer,
            sources: data.sources
          }]);
        }
      }
    );
    
    setInput('');
  };

  return (
    <Container
      header={
        <Header
          variant="h2"
          actions={
            <Button onClick={onClose}>Close</Button>
          }
        >
          Ask Questions About Your Data
        </Header>
      }
    >
      <SpaceBetween size="m">
        <Box padding={{ vertical: 'l' }}>
          {messages.map((msg, idx) => (
            <ChatBubble
              key={idx}
              type={msg.role === 'user' ? 'outgoing' : 'incoming'}
              content={msg.content}
              ariaLabel={`Message from ${msg.role}`}
              actions={msg.sources && (
                <Box variant="small">
                  Sources: {msg.sources.map(s => s.source).join(', ')}
                </Box>
              )}
            />
          ))}
          {isLoading && <Spinner />}
        </Box>

        <SpaceBetween direction="horizontal" size="xs">
          <Input
            value={input}
            onChange={({ detail }) => setInput(detail.value)}
            placeholder="Ask a question..."
            onKeyDown={(e) => e.detail.key === 'Enter' && sendMessage()}
            disabled={isLoading}
          />
          <Button
            onClick={sendMessage}
            disabled={!input || isLoading}
          >
            Send
          </Button>
        </SpaceBetween>
      </SpaceBetween>
    </Container>
  );
}

export default ChatInterface;
```

## Cloudscape Features Used

### 1. Tables with Collection Hooks
```jsx
import { useCollection } from '@cloudscape-design/collection-hooks';
import { Table, Pagination, TextFilter } from '@cloudscape-design/components';

// Automatic pagination, filtering, sorting
const { items, actions, filteredItemsCount, collectionProps } = useCollection(
  datasets,
  {
    filtering: { empty: 'No datasets', noMatch: 'No matches' },
    pagination: { pageSize: 20 },
    sorting: {}
  }
);
```

### 2. Responsive Charts
```jsx
import { LineChart, BarChart, PieChart } from '@cloudscape-design/components';

<LineChart
  series={[
    {
      title: 'Storage Cost',
      type: 'line',
      data: monthlyCosts
    }
  ]}
  xDomain={months}
  yDomain={[0, 5000]}
  xTitle="Month"
  yTitle="Cost (USD)"
/>
```

### 3. Dark Mode Support
```jsx
import { applyMode, Mode } from '@cloudscape-design/global-styles';

// Toggle dark mode
const [theme, setTheme] = useState(Mode.Light);

useEffect(() => {
  applyMode(theme);
}, [theme]);
```

## Build & Deploy

```bash
# Development
npm run dev

# Build for production
npm run build

# Deploy to S3
aws s3 sync dist/ s3://your-frontend-bucket/

# Invalidate CloudFront cache
aws cloudfront create-invalidation \
  --distribution-id YOUR_DIST_ID \
  --paths "/*"
```

## Cloudscape Documentation

- Components: https://cloudscape.design/components/
- Patterns: https://cloudscape.design/patterns/
- GitHub: https://github.com/cloudscape-design/components
- Storybook: https://cloudscape.design/storybook/

## Benefits of Cloudscape

1. **Professional**: Same design system as AWS Console
2. **Accessible**: WCAG 2.1 AA compliant out of the box
3. **Responsive**: Mobile, tablet, desktop optimized
4. **Tested**: Used by millions via AWS Console
5. **Maintained**: Active development by AWS
6. **Free**: Apache 2.0 license
7. **AWS Integration**: Works seamlessly with Amplify, Cognito

**Result**: Enterprise-grade UI with minimal custom CSS needed.
