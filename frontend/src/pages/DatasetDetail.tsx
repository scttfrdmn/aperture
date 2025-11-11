import React, { useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import {
  Container,
  Header,
  SpaceBetween,
  ColumnLayout,
  Box,
  Badge,
  Button,
  Link,
  Tabs,
  Table
} from '@cloudscape-design/components';

const DatasetDetail: React.FC = () => {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const [activeTab, setActiveTab] = useState('metadata');

  // Mock data - replace with actual API call
  const dataset = {
    id: id,
    title: 'Archaeological Survey Data 2024',
    creator: 'Dr. Jane Smith',
    orcid: '0000-0001-2345-6789',
    created: '2024-01-15',
    modified: '2024-01-20',
    publisher: 'University Repository',
    publicationYear: 2024,
    resourceType: 'Dataset',
    size: '2.4 GB',
    files: 145,
    access: 'public' as const,
    doi: '10.5555/12345',
    description:
      'Comprehensive archaeological survey data from the 2024 excavation season, including field notes, photographs, and GIS data.',
    keywords: ['archaeology', 'survey', 'excavation', 'GIS'],
    subjects: ['Archaeology', 'Cultural Heritage'],
    rights: 'CC BY 4.0',
    bucket: 'public'
  };

  const files = [
    { name: 'field_notes.pdf', size: '15 MB', type: 'application/pdf' },
    { name: 'photos.zip', size: '1.2 GB', type: 'application/zip' },
    { name: 'gis_data.geojson', size: '8.4 MB', type: 'application/geo+json' },
    { name: 'report.docx', size: '2.1 MB', type: 'application/vnd.openxmlformats' }
  ];

  const handleDownload = (filename: string) => {
    console.log('Downloading:', filename);
    // TODO: Generate presigned URL and download
  };

  return (
    <SpaceBetween size="l">
      <Container
        header={
          <Header
            variant="h1"
            actions={
              <SpaceBetween direction="horizontal" size="xs">
                <Button onClick={() => navigate('/browse')}>Back to Browse</Button>
                <Button variant="primary">Download All</Button>
              </SpaceBetween>
            }
          >
            {dataset.title}
          </Header>
        }
      >
        <SpaceBetween size="m">
          <Box variant="p">{dataset.description}</Box>

          <ColumnLayout columns={3} variant="text-grid">
            <div>
              <Box variant="awsui-key-label">Creator</Box>
              <Link external href={`https://orcid.org/${dataset.orcid}`}>
                {dataset.creator}
              </Link>
            </div>

            <div>
              <Box variant="awsui-key-label">DOI</Box>
              <Link external href={`https://doi.org/${dataset.doi}`}>
                {dataset.doi}
              </Link>
            </div>

            <div>
              <Box variant="awsui-key-label">Access Level</Box>
              <Badge color="green">{dataset.access}</Badge>
            </div>

            <div>
              <Box variant="awsui-key-label">Publication Year</Box>
              <div>{dataset.publicationYear}</div>
            </div>

            <div>
              <Box variant="awsui-key-label">Size</Box>
              <div>{dataset.size}</div>
            </div>

            <div>
              <Box variant="awsui-key-label">Files</Box>
              <div>{dataset.files} files</div>
            </div>
          </ColumnLayout>
        </SpaceBetween>
      </Container>

      <Tabs
        activeTabId={activeTab}
        onChange={({ detail }) => setActiveTab(detail.activeTabId)}
        tabs={[
          {
            id: 'metadata',
            label: 'Metadata',
            content: (
              <Container>
                <ColumnLayout columns={2} variant="text-grid">
                  <div>
                    <Box variant="awsui-key-label">Publisher</Box>
                    <div>{dataset.publisher}</div>
                  </div>

                  <div>
                    <Box variant="awsui-key-label">Resource Type</Box>
                    <div>{dataset.resourceType}</div>
                  </div>

                  <div>
                    <Box variant="awsui-key-label">Rights</Box>
                    <div>{dataset.rights}</div>
                  </div>

                  <div>
                    <Box variant="awsui-key-label">Keywords</Box>
                    <SpaceBetween direction="horizontal" size="xs">
                      {dataset.keywords.map((keyword) => (
                        <Badge key={keyword}>{keyword}</Badge>
                      ))}
                    </SpaceBetween>
                  </div>

                  <div>
                    <Box variant="awsui-key-label">Created</Box>
                    <div>{dataset.created}</div>
                  </div>

                  <div>
                    <Box variant="awsui-key-label">Modified</Box>
                    <div>{dataset.modified}</div>
                  </div>
                </ColumnLayout>
              </Container>
            )
          },
          {
            id: 'files',
            label: 'Files',
            content: (
              <Table
                columnDefinitions={[
                  {
                    id: 'name',
                    header: 'Filename',
                    cell: (item) => item.name
                  },
                  {
                    id: 'size',
                    header: 'Size',
                    cell: (item) => item.size
                  },
                  {
                    id: 'type',
                    header: 'Type',
                    cell: (item) => item.type
                  },
                  {
                    id: 'actions',
                    header: 'Actions',
                    cell: (item) => (
                      <Button onClick={() => handleDownload(item.name)}>Download</Button>
                    )
                  }
                ]}
                items={files}
                header={<Header counter={`(${files.length})`}>Files</Header>}
              />
            )
          }
        ]}
      />
    </SpaceBetween>
  );
};

export default DatasetDetail;
