import React from 'react';
import { Routes, Route, Navigate } from 'react-router-dom';
import { AppLayout, ContentLayout } from '@cloudscape-design/components';
import { useAuth } from './contexts/AuthContext';
import Navigation from './components/Navigation';
import Header from './components/Header';
import Login from './pages/Login';
import Home from './pages/Home';
import Browse from './pages/Browse';
import Upload from './pages/Upload';
import DatasetDetail from './pages/DatasetDetail';
import DOIManagement from './pages/DOIManagement';
import Profile from './pages/Profile';
import AIAnalysis from './pages/AIAnalysis';

const ProtectedRoute: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const { isAuthenticated, isLoading } = useAuth();

  if (isLoading) {
    return <div>Loading...</div>;
  }

  return isAuthenticated ? <>{children}</> : <Navigate to="/login" replace />;
};

const App: React.FC = () => {
  const { isAuthenticated } = useAuth();

  return (
    <Routes>
      <Route path="/login" element={<Login />} />
      <Route
        path="/*"
        element={
          <ProtectedRoute>
            <AppLayout
              navigation={<Navigation />}
              content={
                <ContentLayout header={<Header />}>
                  <Routes>
                    <Route path="/" element={<Home />} />
                    <Route path="/browse" element={<Browse />} />
                    <Route path="/upload" element={<Upload />} />
                    <Route path="/dataset/:id" element={<DatasetDetail />} />
                    <Route path="/doi" element={<DOIManagement />} />
                    <Route path="/ai-analysis" element={<AIAnalysis />} />
                    <Route path="/profile" element={<Profile />} />
                  </Routes>
                </ContentLayout>
              }
              headerSelector="#header"
              navigationHide={!isAuthenticated}
              toolsHide
            />
          </ProtectedRoute>
        }
      />
    </Routes>
  );
};

export default App;
