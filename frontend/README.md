# Aperture Frontend

React-based web application for the Aperture Academic Media Repository using AWS Cloudscape Design System.

## Overview

Modern, accessible web interface for managing research datasets with features including:

- **User Authentication**: AWS Cognito integration with ORCID federation
- **Dataset Management**: Upload, browse, search, and download research data
- **DOI Registry**: Mint and manage DataCite DOIs
- **Access Control**: Public, private, restricted, and embargoed datasets
- **Role-Based Permissions**: Admin, researcher, reviewer, and user roles

## Technology Stack

- **React 18** - UI library
- **TypeScript** - Type safety
- **AWS Cloudscape** - Design system
- **Vite** - Build tool
- **React Router** - Client-side routing
- **AWS Amplify** - AWS service integrations
- **Axios** - HTTP client

## Prerequisites

- Node.js 18+ and npm
- Deployed Aperture backend infrastructure (API Gateway, Cognito, S3, etc.)
- AWS account with configured resources

## Quick Start

### 1. Install Dependencies

```bash
cd frontend
npm install
```

### 2. Configure Environment

Copy the example environment file:

```bash
cp .env.example .env.local
```

Edit `.env.local` with your AWS infrastructure values:

```env
# Get these from Terraform outputs
VITE_API_ENDPOINT=https://your-api-id.execute-api.us-east-1.amazonaws.com/prod
VITE_COGNITO_USER_POOL_ID=us-east-1_XXXXXXXXX
VITE_COGNITO_CLIENT_ID=your-client-id
VITE_COGNITO_DOMAIN=your-domain.auth.us-east-1.amazoncognito.com
VITE_CLOUDFRONT_MEDIA_URL=https://d123456.cloudfront.net
VITE_CLOUDFRONT_FRONTEND_URL=https://d789012.cloudfront.net
VITE_APP_URL=http://localhost:3000
```

### 3. Run Development Server

```bash
npm run dev
```

Application will be available at http://localhost:3000

### 4. Build for Production

```bash
npm run build
```

Production build will be in `build/` directory.

## Getting Values from Terraform

After deploying the infrastructure, get configuration values:

```bash
# API Gateway endpoint
terraform output api_gateway_invoke_url

# Cognito User Pool ID
terraform output cognito_user_pool_id

# Cognito App Client ID
terraform output cognito_web_app_client_id

# Cognito Domain
terraform output cognito_user_pool_domain

# CloudFront URLs
terraform output cloudfront_public_media_url
terraform output cloudfront_frontend_url
```

## Project Structure

```
frontend/
├── public/              # Static assets
├── src/
│   ├── components/      # Reusable UI components
│   │   ├── Header.tsx
│   │   └── Navigation.tsx
│   ├── contexts/        # React contexts
│   │   └── AuthContext.tsx
│   ├── pages/           # Page components
│   │   ├── Browse.tsx
│   │   ├── DatasetDetail.tsx
│   │   ├── DOIManagement.tsx
│   │   ├── Home.tsx
│   │   ├── Login.tsx
│   │   ├── Profile.tsx
│   │   └── Upload.tsx
│   ├── services/        # API services
│   │   └── api.ts
│   ├── utils/           # Utility functions
│   ├── App.tsx          # Main app component
│   ├── config.ts        # Configuration
│   └── main.tsx         # Entry point
├── index.html
├── package.json
├── tsconfig.json
├── vite.config.ts
└── README.md
```

## Features

### Authentication

- Username/password login with AWS Cognito
- ORCID federation support
- JWT token management
- Automatic token refresh
- Role-based access control (RBAC)

### Dataset Management

**Browse Page**:
- Table view of all datasets
- Search and filter
- Access level badges
- DOI links
- Multi-select

**Dataset Detail Page**:
- Full metadata display
- File listing with download buttons
- Creator information with ORCID links
- Access level information
- Tabbed interface (Metadata, Files)

**Upload Page**:
- Multi-file upload
- Metadata form (title, description, creators, keywords)
- Access level selection
- File drag-and-drop

### DOI Management

- View all registered DOIs
- Mint new DOIs with DataCite
- Edit DOI metadata
- Publish draft DOIs
- DOI state badges (draft, findable, registered)

### User Profile

- View user information
- Display user groups/roles
- Show permissions
- Account settings

## API Integration

The frontend communicates with the backend API Gateway. API service is in `src/services/api.ts`:

```typescript
import { api } from './services/api';

// Authentication
await api.login(username, password);
await api.logout();
await api.verifyToken();

// Presigned URLs
const url = await api.generatePresignedUrl('public', 'dataset/file.pdf');
const urls = await api.generateBatchPresignedUrls([...]);

// DOI Management
const doi = await api.mintDoi(metadata);
await api.updateDoi(id, metadata);
await api.deleteDoi(id);
```

## Authentication Flow

1. User navigates to app
2. `AuthContext` checks for existing session
3. If not authenticated, redirect to `/login`
4. User enters credentials
5. AWS Amplify authenticates with Cognito
6. Tokens stored in localStorage
7. Access token added to API requests via interceptor
8. Protected routes accessible

## Access Control

Four access levels supported:

- **Public**: Anyone can view/download
- **Private**: Researchers and above
- **Restricted**: Dataset-specific permissions
- **Embargoed**: Time-based restrictions

User groups determine permissions:

- **admins**: Full access to everything
- **researchers**: Upload, mint DOIs, access restricted data
- **reviewers**: Review submissions, limited access
- **users**: Basic read access to public data

## Development

### Adding New Pages

1. Create page component in `src/pages/`
2. Add route in `src/App.tsx`
3. Add navigation link in `src/components/Navigation.tsx`

Example:

```typescript
// src/pages/NewPage.tsx
import React from 'react';
import { Container, Header } from '@cloudscape-design/components';

const NewPage: React.FC = () => {
  return (
    <Container header={<Header variant="h1">New Page</Header>}>
      Content here
    </Container>
  );
};

export default NewPage;
```

```typescript
// src/App.tsx
import NewPage from './pages/NewPage';

<Routes>
  <Route path="/new" element={<NewPage />} />
</Routes>
```

### Adding API Endpoints

Add methods to `src/services/api.ts`:

```typescript
async getDatasets() {
  const response = await this.client.get('/datasets');
  return response.data;
}
```

## Deployment

### Deploy to S3/CloudFront

```bash
# Build production bundle
npm run build

# Upload to S3 frontend bucket
aws s3 sync build/ s3://your-frontend-bucket/ --delete

# Invalidate CloudFront cache
aws cloudfront create-invalidation \
  --distribution-id YOUR_DISTRIBUTION_ID \
  --paths "/*"
```

### Automated Deployment

Use GitHub Actions workflow (see `.github/workflows/deploy-frontend.yml` when added).

## Troubleshooting

### CORS Errors

Ensure `cors_allowed_origins` in Terraform includes your frontend URL:

```hcl
cors_allowed_origins = [
  "http://localhost:3000",
  "https://your-domain.com"
]
```

### Authentication Errors

1. Check Cognito configuration in `.env.local`
2. Verify OAuth callback URLs in Cognito User Pool
3. Check browser console for detailed errors
4. Verify tokens in localStorage

### API Errors

1. Check API Gateway endpoint URL
2. Verify network requests in browser DevTools
3. Check CORS configuration
4. Verify JWT token is being sent in Authorization header

### Build Errors

```bash
# Clear node_modules and reinstall
rm -rf node_modules package-lock.json
npm install

# Clear Vite cache
rm -rf node_modules/.vite
npm run dev
```

## Browser Support

- Chrome/Edge (latest 2 versions)
- Firefox (latest 2 versions)
- Safari (latest 2 versions)

## Accessibility

Built with AWS Cloudscape which follows WCAG 2.1 Level AA standards:

- Keyboard navigation
- Screen reader support
- High contrast mode
- Focus indicators

## Performance

- Code splitting with React.lazy
- Optimized bundle size
- CloudFront CDN for fast global access
- Lazy loading for images and large components

## Security

- HTTPS only in production
- JWT tokens in localStorage (consider httpOnly cookies for production)
- CSRF protection via SameSite cookies
- Content Security Policy headers
- No sensitive data in client-side code

## Future Enhancements

- [ ] 3D model viewer for photogrammetry
- [ ] Advanced search with filters
- [ ] Batch upload with progress tracking
- [ ] Dataset versioning UI
- [ ] Collaborative annotations
- [ ] Real-time notifications
- [ ] Analytics dashboard
- [ ] Export citations (BibTeX, RIS)
- [ ] Dataset comparison tool
- [ ] Mobile responsive design improvements

## License

Part of the Aperture Academic Media Repository Platform.

## Support

For issues or questions:
- GitHub Issues: https://github.com/scttfrdmn/aperture/issues
- Documentation: https://docs.aperture.example.com
