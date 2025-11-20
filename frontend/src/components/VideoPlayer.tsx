import React, { useEffect, useRef, useState } from 'react';
import { Alert, Box, Spinner } from '@cloudscape-design/components';
import Hls from 'hls.js';

interface VideoPlayerProps {
  src: string;
  poster?: string;
  autoPlay?: boolean;
  controls?: boolean;
}

const VideoPlayer: React.FC<VideoPlayerProps> = ({
  src,
  poster,
  autoPlay = false,
  controls = true
}) => {
  const videoRef = useRef<HTMLVideoElement>(null);
  const [error, setError] = useState<string>('');
  const [loading, setLoading] = useState(true);
  const hlsRef = useRef<Hls | null>(null);

  useEffect(() => {
    const video = videoRef.current;
    if (!video) return;

    const initializePlayer = () => {
      // Check if HLS is supported
      if (src.endsWith('.m3u8') || src.includes('.m3u8')) {
        if (Hls.isSupported()) {
          // Use HLS.js for browsers that don't support HLS natively
          const hls = new Hls({
            enableWorker: true,
            lowLatencyMode: false,
            backBufferLength: 90
          });

          hls.loadSource(src);
          hls.attachMedia(video);

          hls.on(Hls.Events.MANIFEST_PARSED, () => {
            setLoading(false);
            if (autoPlay) {
              video.play().catch((err) => {
                console.error('Autoplay failed:', err);
              });
            }
          });

          hls.on(Hls.Events.ERROR, (event, data) => {
            if (data.fatal) {
              switch (data.type) {
                case Hls.ErrorTypes.NETWORK_ERROR:
                  setError('Network error loading video');
                  hls.startLoad();
                  break;
                case Hls.ErrorTypes.MEDIA_ERROR:
                  setError('Media error loading video');
                  hls.recoverMediaError();
                  break;
                default:
                  setError('Fatal error loading video');
                  hls.destroy();
                  break;
              }
            }
          });

          hlsRef.current = hls;
        } else if (video.canPlayType('application/vnd.apple.mpegurl')) {
          // Native HLS support (Safari)
          video.src = src;
          video.addEventListener('loadedmetadata', () => {
            setLoading(false);
          });
          video.addEventListener('error', () => {
            setError('Error loading video');
          });
        } else {
          setError('HLS not supported in this browser');
        }
      } else {
        // Regular video file (MP4, WebM, etc.)
        video.src = src;
        video.addEventListener('loadedmetadata', () => {
          setLoading(false);
        });
        video.addEventListener('error', () => {
          setError('Error loading video');
        });
      }
    };

    initializePlayer();

    // Cleanup
    return () => {
      if (hlsRef.current) {
        hlsRef.current.destroy();
        hlsRef.current = null;
      }
    };
  }, [src, autoPlay]);

  if (error) {
    return <Alert type="error">{error}</Alert>;
  }

  return (
    <Box>
      {loading && (
        <Box textAlign="center" padding="l">
          <Spinner size="large" />
          <Box variant="p" color="text-body-secondary">
            Loading video...
          </Box>
        </Box>
      )}
      <video
        ref={videoRef}
        poster={poster}
        controls={controls}
        style={{
          width: '100%',
          maxHeight: '600px',
          backgroundColor: '#000',
          display: loading ? 'none' : 'block'
        }}
      />
    </Box>
  );
};

export default VideoPlayer;
