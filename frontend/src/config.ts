// Application Configuration
// Update these values based on your deployed infrastructure

export const config = {
  // API Gateway
  apiEndpoint: import.meta.env.VITE_API_ENDPOINT || 'https://your-api-gateway-url',

  // AWS Cognito
  cognito: {
    region: import.meta.env.VITE_AWS_REGION || 'us-east-1',
    userPoolId: import.meta.env.VITE_COGNITO_USER_POOL_ID || '',
    userPoolWebClientId: import.meta.env.VITE_COGNITO_CLIENT_ID || '',
    oauth: {
      domain: import.meta.env.VITE_COGNITO_DOMAIN || '',
      scope: ['email', 'openid', 'profile'],
      redirectSignIn: import.meta.env.VITE_APP_URL || 'http://localhost:3000/callback',
      redirectSignOut: import.meta.env.VITE_APP_URL || 'http://localhost:3000',
      responseType: 'code'
    }
  },

  // CloudFront
  cloudfront: {
    mediaUrl: import.meta.env.VITE_CLOUDFRONT_MEDIA_URL || '',
    frontendUrl: import.meta.env.VITE_CLOUDFRONT_FRONTEND_URL || ''
  },

  // Application
  app: {
    name: 'Aperture',
    description: 'Academic Media Repository',
    version: '0.1.0'
  }
};
