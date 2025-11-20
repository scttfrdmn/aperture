import React from 'react';
import { SideNavigation, SideNavigationProps } from '@cloudscape-design/components';
import { useNavigate, useLocation } from 'react-router-dom';

const Navigation: React.FC = () => {
  const navigate = useNavigate();
  const location = useLocation();

  const navItems: SideNavigationProps.Item[] = [
    { type: 'link', text: 'Home', href: '/' },
    { type: 'divider' },
    {
      type: 'section',
      text: 'Datasets',
      items: [
        { type: 'link', text: 'Browse', href: '/browse' },
        { type: 'link', text: 'Upload', href: '/upload' }
      ]
    },
    { type: 'divider' },
    {
      type: 'section',
      text: 'AI & Search',
      items: [
        { type: 'link', text: 'AI Analysis', href: '/ai-analysis' },
        { type: 'link', text: 'Knowledge Base', href: '/knowledge-base' }
      ]
    },
    { type: 'divider' },
    {
      type: 'section',
      text: 'Management',
      items: [
        { type: 'link', text: 'DOI Registry', href: '/doi' },
        { type: 'link', text: 'My Profile', href: '/profile' }
      ]
    }
  ];

  const onFollow: SideNavigationProps['onFollow'] = (event) => {
    if (!event.detail.external) {
      event.preventDefault();
      navigate(event.detail.href);
    }
  };

  return (
    <SideNavigation
      activeHref={location.pathname}
      header={{ text: 'Aperture', href: '/' }}
      items={navItems}
      onFollow={onFollow}
    />
  );
};

export default Navigation;
