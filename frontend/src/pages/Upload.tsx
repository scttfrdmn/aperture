import React, { useState } from 'react';
import {
  Container,
  Header,
  Form,
  FormField,
  Input,
  Textarea,
  Select,
  Button,
  SpaceBetween,
  FileUpload,
  Alert,
  Box
} from '@cloudscape-design/components';
import { useNavigate } from 'react-router-dom';

const Upload: React.FC = () => {
  const navigate = useNavigate();
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [creators, setCreators] = useState('');
  const [keywords, setKeywords] = useState('');
  const [access, setAccess] = useState({ label: 'Public', value: 'public' });
  const [files, setFiles] = useState<File[]>([]);
  const [uploading, setUploading] = useState(false);
  const [error, setError] = useState('');

  const accessOptions = [
    { label: 'Public', value: 'public' },
    { label: 'Private', value: 'private' },
    { label: 'Restricted', value: 'restricted' },
    { label: 'Embargoed', value: 'embargoed' }
  ];

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setUploading(true);

    try {
      // TODO: Implement actual upload logic
      // 1. Upload files to S3 (use presigned URLs)
      // 2. Store metadata in DynamoDB
      // 3. Generate DOI if requested

      console.log('Uploading:', {
        title,
        description,
        creators,
        keywords,
        access: access.value,
        files: files.map((f) => f.name)
      });

      // Simulate upload
      await new Promise((resolve) => setTimeout(resolve, 2000));

      navigate('/browse');
    } catch (err: any) {
      setError(err.message || 'Upload failed. Please try again.');
    } finally {
      setUploading(false);
    }
  };

  return (
    <Container header={<Header variant="h1">Upload Dataset</Header>}>
      <form onSubmit={handleSubmit}>
        <Form
          actions={
            <SpaceBetween direction="horizontal" size="xs">
              <Button formAction="none" onClick={() => navigate('/browse')}>
                Cancel
              </Button>
              <Button variant="primary" loading={uploading} disabled={!title || files.length === 0}>
                Upload
              </Button>
            </SpaceBetween>
          }
        >
          <SpaceBetween size="l">
            {error && <Alert type="error">{error}</Alert>}

            <FormField label="Title" description="A descriptive title for your dataset">
              <Input
                value={title}
                onChange={({ detail }) => setTitle(detail.value)}
                placeholder="Enter dataset title"
              />
            </FormField>

            <FormField label="Description" description="Detailed description of the dataset">
              <Textarea
                value={description}
                onChange={({ detail }) => setDescription(detail.value)}
                placeholder="Describe your dataset"
                rows={4}
              />
            </FormField>

            <FormField
              label="Creators"
              description="Authors or creators (comma separated, include ORCID if available)"
            >
              <Input
                value={creators}
                onChange={({ detail }) => setCreators(detail.value)}
                placeholder="Dr. Jane Smith (0000-0001-2345-6789), Dr. John Doe"
              />
            </FormField>

            <FormField
              label="Keywords"
              description="Keywords or tags for discovery (comma separated)"
            >
              <Input
                value={keywords}
                onChange={({ detail }) => setKeywords(detail.value)}
                placeholder="archaeology, excavation, survey"
              />
            </FormField>

            <FormField
              label="Access Level"
              description="Choose who can access this dataset"
            >
              <Select
                selectedOption={access}
                onChange={({ detail }) => setAccess(detail.selectedOption)}
                options={accessOptions}
              />
            </FormField>

            <FormField label="Files" description="Select files to upload">
              <FileUpload
                value={files}
                onChange={({ detail }) => setFiles(detail.value)}
                multiple
                i18nStrings={{
                  uploadButtonText: (e) => (e ? 'Choose files' : 'Choose file'),
                  dropzoneText: (e) => (e ? 'Drop files to upload' : 'Drop file to upload'),
                  removeFileAriaLabel: (e) => `Remove file ${e + 1}`,
                  limitShowFewer: 'Show fewer files',
                  limitShowMore: 'Show more files',
                  errorIconAriaLabel: 'Error'
                }}
              />
            </FormField>

            <Box variant="p" color="text-body-secondary">
              <strong>Note:</strong> Large files will be uploaded in chunks. You can close this
              page and the upload will continue in the background.
            </Box>
          </SpaceBetween>
        </Form>
      </form>
    </Container>
  );
};

export default Upload;
