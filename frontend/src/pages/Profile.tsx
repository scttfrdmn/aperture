import React from 'react';
import {
  Container,
  Header,
  SpaceBetween,
  ColumnLayout,
  Box,
  Badge
} from '@cloudscape-design/components';
import { useAuth } from '../contexts/AuthContext';

const Profile: React.FC = () => {
  const { user } = useAuth();

  return (
    <SpaceBetween size="l">
      <Container header={<Header variant="h1">User Profile</Header>}>
        <ColumnLayout columns={2} variant="text-grid">
          <div>
            <Box variant="awsui-key-label">Username</Box>
            <div>{user?.username}</div>
          </div>

          <div>
            <Box variant="awsui-key-label">Email</Box>
            <div>{user?.email || 'Not available'}</div>
          </div>

          <div>
            <Box variant="awsui-key-label">Groups</Box>
            <SpaceBetween direction="horizontal" size="xs">
              {user?.groups && user.groups.length > 0 ? (
                user.groups.map((group) => (
                  <Badge key={group} color="blue">
                    {group}
                  </Badge>
                ))
              ) : (
                <Box variant="p">No groups</Box>
              )}
            </SpaceBetween>
          </div>

          <div>
            <Box variant="awsui-key-label">Role</Box>
            <div>
              {user?.groups?.includes('admins')
                ? 'Administrator'
                : user?.groups?.includes('researchers')
                ? 'Researcher'
                : 'User'}
            </div>
          </div>
        </ColumnLayout>
      </Container>

      <Container header={<Header variant="h2">Permissions</Header>}>
        <SpaceBetween size="m">
          <Box variant="p">
            <strong>Upload datasets:</strong>{' '}
            {user?.groups?.includes('researchers') || user?.groups?.includes('admins')
              ? '✅ Allowed'
              : '❌ Not allowed'}
          </Box>
          <Box variant="p">
            <strong>Mint DOIs:</strong>{' '}
            {user?.groups?.includes('researchers') || user?.groups?.includes('admins')
              ? '✅ Allowed'
              : '❌ Not allowed'}
          </Box>
          <Box variant="p">
            <strong>Manage users:</strong>{' '}
            {user?.groups?.includes('admins') ? '✅ Allowed' : '❌ Not allowed'}
          </Box>
          <Box variant="p">
            <strong>Access restricted data:</strong>{' '}
            {user?.groups?.includes('researchers') || user?.groups?.includes('admins')
              ? '✅ Allowed'
              : '❌ Limited'}
          </Box>
        </SpaceBetween>
      </Container>
    </SpaceBetween>
  );
};

export default Profile;
