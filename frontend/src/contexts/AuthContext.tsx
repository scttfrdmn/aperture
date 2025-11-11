import React, { createContext, useContext, useState, useEffect, ReactNode } from 'react';
import { Amplify } from 'aws-amplify';
import { signIn, signOut, getCurrentUser, fetchAuthSession } from 'aws-amplify/auth';
import { config } from '../config';

// Configure Amplify
Amplify.configure({
  Auth: {
    Cognito: {
      userPoolId: config.cognito.userPoolId,
      userPoolClientId: config.cognito.userPoolWebClientId,
      loginWith: {
        oauth: {
          domain: config.cognito.oauth.domain,
          scopes: config.cognito.oauth.scope,
          redirectSignIn: [config.cognito.oauth.redirectSignIn],
          redirectSignOut: [config.cognito.oauth.redirectSignOut],
          responseType: config.cognito.oauth.responseType as 'code'
        }
      }
    }
  }
});

interface User {
  username: string;
  email?: string;
  groups?: string[];
}

interface AuthContextType {
  user: User | null;
  isAuthenticated: boolean;
  isLoading: boolean;
  login: (username: string, password: string) => Promise<void>;
  logout: () => Promise<void>;
  getAccessToken: () => Promise<string | null>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const AuthProvider: React.FC<{ children: ReactNode }> = ({ children }) => {
  const [user, setUser] = useState<User | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    checkAuthState();
  }, []);

  const checkAuthState = async () => {
    try {
      const currentUser = await getCurrentUser();
      const session = await fetchAuthSession();

      // Extract groups from token
      const groups = (session.tokens?.accessToken?.payload['cognito:groups'] as string[]) || [];

      setUser({
        username: currentUser.username,
        email: currentUser.signInDetails?.loginId,
        groups
      });
    } catch (error) {
      setUser(null);
    } finally {
      setIsLoading(false);
    }
  };

  const login = async (username: string, password: string) => {
    try {
      await signIn({ username, password });
      await checkAuthState();
    } catch (error) {
      console.error('Login error:', error);
      throw error;
    }
  };

  const logout = async () => {
    try {
      await signOut();
      setUser(null);
    } catch (error) {
      console.error('Logout error:', error);
      throw error;
    }
  };

  const getAccessToken = async (): Promise<string | null> => {
    try {
      const session = await fetchAuthSession();
      return session.tokens?.accessToken?.toString() || null;
    } catch (error) {
      return null;
    }
  };

  return (
    <AuthContext.Provider
      value={{
        user,
        isAuthenticated: !!user,
        isLoading,
        login,
        logout,
        getAccessToken
      }}
    >
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};
