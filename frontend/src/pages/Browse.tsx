import React, { useState } from 'react';
import {
  Table,
  Header,
  Pagination,
  TextFilter,
  SpaceBetween,
  Button,
  Box,
  Badge,
  Link
} from '@cloudscape-design/components';
import { useNavigate } from 'react-router-dom';

interface Dataset {
  id: string;
  title: string;
  creator: string;
  created: string;
  size: string;
  access: 'public' | 'private' | 'restricted' | 'embargoed';
  doi?: string;
}

const Browse: React.FC = () => {
  const navigate = useNavigate();
  const [selectedItems, setSelectedItems] = useState<Dataset[]>([]);
  const [filteringText, setFilteringText] = useState('');

  // Mock data - replace with actual API call
  const datasets: Dataset[] = [
    {
      id: '1',
      title: 'Archaeological Survey Data 2024',
      creator: 'Dr. Jane Smith',
      created: '2024-01-15',
      size: '2.4 GB',
      access: 'public',
      doi: '10.5555/12345'
    },
    {
      id: '2',
      title: 'Bronze Age Pottery Analysis',
      creator: 'Dr. John Doe',
      created: '2024-02-20',
      size: '1.8 GB',
      access: 'embargoed',
      doi: undefined
    },
    {
      id: '3',
      title: '3D Photogrammetry Models',
      creator: 'Dr. Alice Johnson',
      created: '2024-03-10',
      size: '5.2 GB',
      access: 'restricted'
    }
  ];

  const getAccessBadge = (access: Dataset['access']) => {
    const colors = {
      public: 'green',
      private: 'blue',
      restricted: 'red',
      embargoed: 'grey'
    };
    return <Badge color={colors[access]}>{access}</Badge>;
  };

  return (
    <Table
      header={
        <Header
          variant="h1"
          counter={`(${datasets.length})`}
          actions={
            <SpaceBetween direction="horizontal" size="xs">
              <Button onClick={() => navigate('/upload')}>Upload Dataset</Button>
            </SpaceBetween>
          }
        >
          Browse Datasets
        </Header>
      }
      columnDefinitions={[
        {
          id: 'title',
          header: 'Title',
          cell: (item) => (
            <Link onFollow={() => navigate(`/dataset/${item.id}`)}>{item.title}</Link>
          ),
          sortingField: 'title'
        },
        {
          id: 'creator',
          header: 'Creator',
          cell: (item) => item.creator,
          sortingField: 'creator'
        },
        {
          id: 'created',
          header: 'Created',
          cell: (item) => item.created,
          sortingField: 'created'
        },
        {
          id: 'size',
          header: 'Size',
          cell: (item) => item.size
        },
        {
          id: 'access',
          header: 'Access',
          cell: (item) => getAccessBadge(item.access)
        },
        {
          id: 'doi',
          header: 'DOI',
          cell: (item) =>
            item.doi ? (
              <Link external href={`https://doi.org/${item.doi}`}>
                {item.doi}
              </Link>
            ) : (
              <Box color="text-status-inactive">-</Box>
            )
        }
      ]}
      items={datasets}
      selectionType="multi"
      selectedItems={selectedItems}
      onSelectionChange={({ detail }) => setSelectedItems(detail.selectedItems)}
      filter={
        <TextFilter
          filteringText={filteringText}
          onChange={({ detail }) => setFilteringText(detail.filteringText)}
          filteringPlaceholder="Search datasets"
        />
      }
      pagination={<Pagination currentPageIndex={1} pagesCount={1} />}
      empty={
        <Box textAlign="center" color="inherit">
          <Box variant="strong" textAlign="center" color="inherit">
            No datasets
          </Box>
          <Box variant="p" padding={{ bottom: 's' }} color="inherit">
            No datasets to display.
          </Box>
          <Button onClick={() => navigate('/upload')}>Upload Dataset</Button>
        </Box>
      }
    />
  );
};

export default Browse;
