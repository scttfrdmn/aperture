import React, { useState } from 'react';
import {
  Container,
  Header,
  Table,
  Button,
  SpaceBetween,
  Box,
  Badge,
  Modal,
  Form,
  FormField,
  Input,
  Textarea,
  Select,
  Alert,
  Link
} from '@cloudscape-design/components';

interface DOIRecord {
  id: string;
  doi: string;
  title: string;
  creator: string;
  created: string;
  state: 'draft' | 'findable' | 'registered';
}

const DOIManagement: React.FC = () => {
  const [selectedItems, setSelectedItems] = useState<DOIRecord[]>([]);
  const [showMintModal, setShowMintModal] = useState(false);
  const [minting, setMinting] = useState(false);
  const [error, setError] = useState('');

  // Form state
  const [title, setTitle] = useState('');
  const [creators, setCreators] = useState('');
  const [publisher, setPublisher] = useState('University Repository');
  const [publicationYear, setPublicationYear] = useState('2024');
  const [resourceType, setResourceType] = useState({ label: 'Dataset', value: 'Dataset' });

  // Mock data - replace with actual API call
  const dois: DOIRecord[] = [
    {
      id: '1',
      doi: '10.5555/12345',
      title: 'Archaeological Survey Data 2024',
      creator: 'Dr. Jane Smith',
      created: '2024-01-15',
      state: 'findable'
    },
    {
      id: '2',
      doi: '10.5555/67890',
      title: 'Bronze Age Pottery Analysis',
      creator: 'Dr. John Doe',
      created: '2024-02-20',
      state: 'draft'
    }
  ];

  const resourceTypeOptions = [
    { label: 'Dataset', value: 'Dataset' },
    { label: 'Image', value: 'Image' },
    { label: 'Video', value: 'Video' },
    { label: 'Audio', value: 'Audio' },
    { label: 'Collection', value: 'Collection' }
  ];

  const handleMintDOI = async () => {
    setError('');
    setMinting(true);

    try {
      // TODO: Implement actual DOI minting
      console.log('Minting DOI:', {
        title,
        creators,
        publisher,
        publicationYear,
        resourceType: resourceType.value
      });

      // Simulate minting
      await new Promise((resolve) => setTimeout(resolve, 2000));

      setShowMintModal(false);
      // Reset form
      setTitle('');
      setCreators('');
    } catch (err: any) {
      setError(err.message || 'DOI minting failed. Please try again.');
    } finally {
      setMinting(false);
    }
  };

  const getStateBadge = (state: DOIRecord['state']) => {
    const colors = {
      draft: 'blue',
      findable: 'green',
      registered: 'grey'
    };
    return <Badge color={colors[state]}>{state}</Badge>;
  };

  return (
    <>
      <Table
        header={
          <Header
            variant="h1"
            counter={`(${dois.length})`}
            actions={
              <SpaceBetween direction="horizontal" size="xs">
                <Button onClick={() => setShowMintModal(true)} variant="primary">
                  Mint DOI
                </Button>
              </SpaceBetween>
            }
          >
            DOI Registry
          </Header>
        }
        columnDefinitions={[
          {
            id: 'doi',
            header: 'DOI',
            cell: (item) => (
              <Link external href={`https://doi.org/${item.doi}`}>
                {item.doi}
              </Link>
            )
          },
          {
            id: 'title',
            header: 'Title',
            cell: (item) => item.title
          },
          {
            id: 'creator',
            header: 'Creator',
            cell: (item) => item.creator
          },
          {
            id: 'created',
            header: 'Created',
            cell: (item) => item.created
          },
          {
            id: 'state',
            header: 'State',
            cell: (item) => getStateBadge(item.state)
          },
          {
            id: 'actions',
            header: 'Actions',
            cell: () => (
              <SpaceBetween direction="horizontal" size="xs">
                <Button>Edit</Button>
                <Button>Publish</Button>
              </SpaceBetween>
            )
          }
        ]}
        items={dois}
        selectionType="multi"
        selectedItems={selectedItems}
        onSelectionChange={({ detail }) => setSelectedItems(detail.selectedItems)}
        empty={
          <Box textAlign="center" color="inherit">
            <Box variant="strong" textAlign="center" color="inherit">
              No DOIs
            </Box>
            <Box variant="p" padding={{ bottom: 's' }} color="inherit">
              No DOIs registered yet.
            </Box>
            <Button onClick={() => setShowMintModal(true)} variant="primary">
              Mint Your First DOI
            </Button>
          </Box>
        }
      />

      <Modal
        visible={showMintModal}
        onDismiss={() => setShowMintModal(false)}
        header="Mint New DOI"
        footer={
          <Box float="right">
            <SpaceBetween direction="horizontal" size="xs">
              <Button variant="link" onClick={() => setShowMintModal(false)}>
                Cancel
              </Button>
              <Button variant="primary" loading={minting} onClick={handleMintDOI}>
                Mint DOI
              </Button>
            </SpaceBetween>
          </Box>
        }
      >
        <Form>
          <SpaceBetween size="l">
            {error && <Alert type="error">{error}</Alert>}

            <FormField label="Title" description="Dataset title">
              <Input
                value={title}
                onChange={({ detail }) => setTitle(detail.value)}
                placeholder="Enter title"
              />
            </FormField>

            <FormField
              label="Creators"
              description="Authors (comma separated, include ORCID if available)"
            >
              <Textarea
                value={creators}
                onChange={({ detail }) => setCreators(detail.value)}
                placeholder="Dr. Jane Smith (0000-0001-2345-6789)"
                rows={3}
              />
            </FormField>

            <FormField label="Publisher">
              <Input
                value={publisher}
                onChange={({ detail}) => setPublisher(detail.value)}
                placeholder="University Repository"
              />
            </FormField>

            <FormField label="Publication Year">
              <Input
                value={publicationYear}
                onChange={({ detail }) => setPublicationYear(detail.value)}
                placeholder="2024"
              />
            </FormField>

            <FormField label="Resource Type">
              <Select
                selectedOption={resourceType}
                onChange={({ detail }) => setResourceType(detail.selectedOption)}
                options={resourceTypeOptions}
              />
            </FormField>

            <Box variant="p" color="text-body-secondary">
              <strong>Note:</strong> DOI will be registered with DataCite. This action cannot be
              undone.
            </Box>
          </SpaceBetween>
        </Form>
      </Modal>
    </>
  );
};

export default DOIManagement;
