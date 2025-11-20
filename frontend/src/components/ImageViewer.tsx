import React, { useState } from 'react';
import {
  Alert,
  Box,
  Button,
  SpaceBetween,
  Spinner,
  ColumnLayout
} from '@cloudscape-design/components';
import { TransformWrapper, TransformComponent } from 'react-zoom-pan-pinch';

interface ImageViewerProps {
  src: string;
  alt?: string;
  maxHeight?: string;
}

const ImageViewer: React.FC<ImageViewerProps> = ({
  src,
  alt = 'Image',
  maxHeight = '600px'
}) => {
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string>('');
  const [imageInfo, setImageInfo] = useState<{
    width: number;
    height: number;
    size?: string;
  } | null>(null);

  const handleImageLoad = (event: React.SyntheticEvent<HTMLImageElement>) => {
    const img = event.currentTarget;
    setImageInfo({
      width: img.naturalWidth,
      height: img.naturalHeight
    });
    setLoading(false);
  };

  const handleImageError = () => {
    setError('Error loading image');
    setLoading(false);
  };

  if (error) {
    return <Alert type="error">{error}</Alert>;
  }

  return (
    <Box>
      {loading && (
        <Box textAlign="center" padding="l">
          <Spinner size="large" />
          <Box variant="p" color="text-body-secondary">
            Loading image...
          </Box>
        </Box>
      )}

      <SpaceBetween size="m">
        <TransformWrapper
          initialScale={1}
          minScale={0.5}
          maxScale={8}
          wheel={{ step: 0.1 }}
          doubleClick={{ mode: 'reset' }}
          panning={{ velocityDisabled: true }}
        >
          {({ zoomIn, zoomOut, resetTransform, centerView }) => (
            <>
              {/* Controls */}
              {!loading && (
                <SpaceBetween direction="horizontal" size="xs">
                  <Button onClick={() => zoomIn()} iconName="zoom-in">
                    Zoom In
                  </Button>
                  <Button onClick={() => zoomOut()} iconName="zoom-out">
                    Zoom Out
                  </Button>
                  <Button onClick={() => resetTransform()}>Reset</Button>
                  <Button onClick={() => centerView()}>Center</Button>

                  {imageInfo && (
                    <Box variant="small" color="text-body-secondary">
                      {imageInfo.width} × {imageInfo.height} pixels
                    </Box>
                  )}
                </SpaceBetween>
              )}

              {/* Image container */}
              <div
                style={{
                  border: '1px solid #d5dbdb',
                  borderRadius: '4px',
                  overflow: 'hidden',
                  backgroundColor: '#f2f3f3',
                  maxHeight: maxHeight,
                  display: 'flex',
                  justifyContent: 'center',
                  alignItems: 'center',
                  cursor: loading ? 'default' : 'move'
                }}
              >
                <TransformComponent
                  wrapperStyle={{
                    width: '100%',
                    height: '100%',
                    display: loading ? 'none' : 'flex',
                    justifyContent: 'center',
                    alignItems: 'center'
                  }}
                >
                  <img
                    src={src}
                    alt={alt}
                    onLoad={handleImageLoad}
                    onError={handleImageError}
                    style={{
                      maxWidth: '100%',
                      maxHeight: maxHeight,
                      objectFit: 'contain',
                      userSelect: 'none'
                    }}
                  />
                </TransformComponent>
              </div>
            </>
          )}
        </TransformWrapper>

        {!loading && (
          <Box variant="small" color="text-body-secondary">
            <strong>Tip:</strong> Use mouse wheel to zoom, click and drag to pan, or double-click
            to reset view
          </Box>
        )}
      </SpaceBetween>
    </Box>
  );
};

export default ImageViewer;
