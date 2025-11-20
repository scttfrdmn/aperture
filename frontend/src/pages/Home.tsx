import React from 'react';
import {
  Container,
  Header,
  SpaceBetween,
  Box,
  Button,
  Cards,
  Link
} from '@cloudscape-design/components';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';

const Home: React.FC = () => {
  const navigate = useNavigate();
  const { user } = useAuth();

  const quickActions = [
    {
      title: 'Upload Dataset',
      description: 'Add new research data with metadata',
      action: () => navigate('/upload'),
      icon: '📤'
    },
    {
      title: 'Browse Datasets',
      description: 'Search and explore the repository',
      action: () => navigate('/browse'),
      icon: '🔍'
    },
    {
      title: 'AI Analysis',
      description: 'Analyze artifacts with AI-powered tools',
      action: () => navigate('/ai-analysis'),
      icon: '🤖'
    },
    {
      title: 'Mint DOI',
      description: 'Register a DOI for your dataset',
      action: () => navigate('/doi'),
      icon: '🏷️'
    }
  ];

  const recentStats = [
    { label: 'Total Datasets', value: '1,234' },
    { label: 'Your Uploads', value: '42' },
    { label: 'DOIs Minted', value: '987' },
    { label: 'Total Storage', value: '2.4 TB' }
  ];

  return (
    <SpaceBetween size="l">
      <Container header={<Header variant="h1">Welcome, {user?.username}</Header>}>
        <SpaceBetween size="m">
          <Box variant="p">
            Aperture is an academic media repository for storing, managing, and sharing research
            datasets with DOI minting, AI-powered analysis, and FAIR principles compliance.
          </Box>

          <SpaceBetween direction="horizontal" size="s">
            {recentStats.map((stat) => (
              <Box key={stat.label} textAlign="center" padding="m">
                <Box variant="h2" fontSize="heading-xl">
                  {stat.value}
                </Box>
                <Box variant="small" color="text-body-secondary">
                  {stat.label}
                </Box>
              </Box>
            ))}
          </SpaceBetween>
        </SpaceBetween>
      </Container>

      <Cards
        cardDefinition={{
          header: (item) => (
            <Header>
              <span style={{ fontSize: '2em', marginRight: '0.5em' }}>{item.icon}</span>
              {item.title}
            </Header>
          ),
          sections: [
            {
              id: 'description',
              content: (item) => item.description
            },
            {
              id: 'action',
              content: (item) => (
                <Button onClick={item.action} variant="primary">
                  Go
                </Button>
              )
            }
          ]
        }}
        cardsPerRow={[{ cards: 1 }, { minWidth: 500, cards: 3 }]}
        items={quickActions}
        header={<Header>Quick Actions</Header>}
      />

      <Container header={<Header variant="h2">Getting Started</Header>}>
        <SpaceBetween size="m">
          <Box variant="p">
            <strong>1. Upload your data:</strong> Use the upload page to add files and metadata
          </Box>
          <Box variant="p">
            <strong>2. Set access controls:</strong> Choose public, private, restricted, or
            embargoed access
          </Box>
          <Box variant="p">
            <strong>3. Analyze with AI:</strong> Use AI tools to classify, describe, and extract
            metadata from artifacts
          </Box>
          <Box variant="p">
            <strong>4. Mint a DOI:</strong> Register a persistent identifier for citation
          </Box>
          <Box variant="p">
            <strong>5. Share:</strong> Collaborate with researchers worldwide
          </Box>
          <Box variant="p">
            Learn more in the{' '}
            <Link external href="/docs">
              documentation
            </Link>
          </Box>
        </SpaceBetween>
      </Container>
    </SpaceBetween>
  );
};

export default Home;
