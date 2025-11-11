import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  Container,
  Form,
  FormField,
  Input,
  Button,
  SpaceBetween,
  Header,
  Alert,
  Box
} from '@cloudscape-design/components';
import { useAuth } from '../contexts/AuthContext';

const Login: React.FC = () => {
  const navigate = useNavigate();
  const { login } = useAuth();
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setLoading(true);

    try {
      await login(username, password);
      navigate('/');
    } catch (err: any) {
      setError(err.message || 'Login failed. Please check your credentials.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <Box textAlign="center" padding={{ vertical: 'xxxl' }}>
      <Container>
        <form onSubmit={handleSubmit}>
          <Form
            header={<Header variant="h1">Aperture Repository</Header>}
            actions={
              <SpaceBetween direction="horizontal" size="xs">
                <Button formAction="none" variant="link">
                  Forgot password?
                </Button>
                <Button variant="primary" loading={loading} disabled={!username || !password}>
                  Sign in
                </Button>
              </SpaceBetween>
            }
          >
            <SpaceBetween size="l">
              {error && <Alert type="error">{error}</Alert>}

              <FormField label="Username or email">
                <Input
                  value={username}
                  onChange={({ detail }) => setUsername(detail.value)}
                  placeholder="Enter your username"
                  autoComplete="username"
                />
              </FormField>

              <FormField label="Password">
                <Input
                  value={password}
                  onChange={({ detail }) => setPassword(detail.value)}
                  placeholder="Enter your password"
                  type="password"
                  autoComplete="current-password"
                />
              </FormField>

              <Box variant="small" color="text-body-secondary">
                Sign in with your institutional credentials or ORCID account
              </Box>
            </SpaceBetween>
          </Form>
        </form>
      </Container>
    </Box>
  );
};

export default Login;
