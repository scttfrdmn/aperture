import React from 'react';
import { Header as CloudscapeHeader, SpaceBetween, Button } from '@cloudscape-design/components';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';

const Header: React.FC = () => {
  const navigate = useNavigate();
  const { user, logout } = useAuth();

  const handleLogout = async () => {
    await logout();
    navigate('/login');
  };

  return (
    <CloudscapeHeader
      variant="h1"
      actions={
        <SpaceBetween direction="horizontal" size="xs">
          <Button onClick={() => navigate('/profile')} variant="link">
            {user?.username}
          </Button>
          <Button onClick={handleLogout}>Logout</Button>
        </SpaceBetween>
      }
    >
      Aperture Repository
    </CloudscapeHeader>
  );
};

export default Header;
