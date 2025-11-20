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
import MediaViewer from '../components/MediaViewer';

const DatasetDetail: React.FC = () => {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const [activeTab, setActiveTab] = useState('metadata');
  const [selectedFile, setSelectedFile] = useState<{
    name: string;
    size: string;
    type: string;
    url: string;
  } | null>(null);

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
    {
      name: 'artifact_001.jpg',
      size: '3.2 MB',
      type: 'image/jpeg',
      url: 'https://images.unsplash.com/photo-1518998053901-5348d3961a04?w=1200'
    },
    {
      name: 'excavation_site.mp4',
      size: '125 MB',
      type: 'video/mp4',
      url: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4'
    },
    {
      name: 'field_recording.mp3',
      size: '8.5 MB',
      type: 'audio/mpeg',
      url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3'
    },
    {
      name: 'pottery_fragment.png',
      size: '5.1 MB',
      type: 'image/png',
      url: 'https://images.unsplash.com/photo-1582721478779-0ae163c05a60?w=1200'
    },
    { name: 'field_notes.pdf', size: '15 MB', type: 'application/pdf', url: '' },
    { name: 'photos.zip', size: '1.2 GB', type: 'application/zip', url: '' },
    { name: 'gis_data.geojson', size: '8.4 MB', type: 'application/geo+json', url: '' },
    { name: 'report.docx', size: '2.1 MB', type: 'application/vnd.openxmlformats', url: '' }
  ];

  const handleDownload = (filename: string) => {
    console.log('Downloading:', filename);
    // TODO: Generate presigned URL and download
  };

  const handlePreview = (file: {
    name: string;
    size: string;
    type: string;
    url: string;
  }) => {
    if (file.url) {
      setSelectedFile(file);
      setActiveTab('preview');
    }
  };

  const canPreview = (file: { type: string; url: string }): boolean => {
    return (
      file.url !== '' &&
      (file.type.startsWith('image/') ||
        file.type.startsWith('video/') ||
        file.type.startsWith('audio/'))
    );
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
            id: 'preview',
            label: 'Preview',
            content: selectedFile ? (
              <Container>
                <SpaceBetween size="m">
                  <Box>
                    <Box variant="h2">{selectedFile.name}</Box>
                    <Box variant="small" color="text-body-secondary">
                      {selectedFile.type} • {selectedFile.size}
                    </Box>
                  </Box>
                  <MediaViewer
                    src={selectedFile.url}
                    filename={selectedFile.name}
                    mimeType={selectedFile.type}
                  />
                </SpaceBetween>
              </Container>
            ) : (
              <Container>
                <Box textAlign="center" padding="xxl">
                  <Box variant="p" color="text-body-secondary">
                    No file selected for preview. Go to the Files tab and click Preview on a media
                    file.
                  </Box>
                </Box>
              </Container>
            )
          },
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
                      <SpaceBetween direction="horizontal" size="xs">
                        {canPreview(item) && (
                          <Button onClick={() => handlePreview(item)} iconName="view">
                            Preview
                          </Button>
                        )}
                        <Button onClick={() => handleDownload(item.name)}>Download</Button>
                      </SpaceBetween>
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
