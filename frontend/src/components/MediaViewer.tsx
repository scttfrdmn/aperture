import React from 'react';
import { Alert, Box } from '@cloudscape-design/components';
import VideoPlayer from './VideoPlayer';
import AudioPlayer from './AudioPlayer';
import ImageViewer from './ImageViewer';

interface MediaViewerProps {
  src: string;
  filename: string;
  mimeType?: string;
}

const MediaViewer: React.FC<MediaViewerProps> = ({ src, filename, mimeType }) => {
  // Determine media type from MIME type or filename extension
  const getMediaType = (): 'video' | 'audio' | 'image' | 'unsupported' => {
    // Check MIME type first
    if (mimeType) {
      if (mimeType.startsWith('video/')) return 'video';
      if (mimeType.startsWith('audio/')) return 'audio';
      if (mimeType.startsWith('image/')) return 'image';
    }

    // Fall back to file extension
    const extension = filename.split('.').pop()?.toLowerCase();

    // Video extensions
    const videoExtensions = ['mp4', 'webm', 'ogg', 'mov', 'avi', 'mkv', 'm3u8', 'mpd'];
    if (extension && videoExtensions.includes(extension)) return 'video';

    // Audio extensions
    const audioExtensions = ['mp3', 'wav', 'ogg', 'aac', 'm4a', 'flac', 'wma'];
    if (extension && audioExtensions.includes(extension)) return 'audio';

    // Image extensions
    const imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'svg', 'tiff', 'tif'];
    if (extension && imageExtensions.includes(extension)) return 'image';

    return 'unsupported';
  };

  const mediaType = getMediaType();

  // Render appropriate viewer based on media type
  switch (mediaType) {
    case 'video':
      return (
        <Box>
          <Box variant="h3" padding={{ bottom: 's' }}>
            Video Player
          </Box>
          <VideoPlayer src={src} controls autoPlay={false} />
        </Box>
      );

    case 'audio':
      return (
        <Box>
          <Box variant="h3" padding={{ bottom: 's' }}>
            Audio Player
          </Box>
          <AudioPlayer src={src} autoPlay={false} />
        </Box>
      );

    case 'image':
      return (
        <Box>
          <Box variant="h3" padding={{ bottom: 's' }}>
            Image Viewer
          </Box>
          <ImageViewer src={src} alt={filename} />
        </Box>
      );

    case 'unsupported':
    default:
      return (
        <Alert type="info">
          Preview not available for this file type. Click Download to view the file locally.
        </Alert>
      );
  }
};

export default MediaViewer;
