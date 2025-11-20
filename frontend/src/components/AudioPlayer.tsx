import React, { useEffect, useRef, useState } from 'react';
import {
  Alert,
  Box,
  Button,
  SpaceBetween,
  Spinner,
  ColumnLayout
} from '@cloudscape-design/components';
import WaveSurfer from 'wavesurfer.js';

interface AudioPlayerProps {
  src: string;
  autoPlay?: boolean;
}

const AudioPlayer: React.FC<AudioPlayerProps> = ({ src, autoPlay = false }) => {
  const waveformRef = useRef<HTMLDivElement>(null);
  const wavesurferRef = useRef<WaveSurfer | null>(null);
  const [error, setError] = useState<string>('');
  const [loading, setLoading] = useState(true);
  const [isPlaying, setIsPlaying] = useState(false);
  const [currentTime, setCurrentTime] = useState('0:00');
  const [duration, setDuration] = useState('0:00');
  const [volume, setVolume] = useState(1);

  useEffect(() => {
    if (!waveformRef.current) return;

    const wavesurfer = WaveSurfer.create({
      container: waveformRef.current,
      waveColor: '#4a90e2',
      progressColor: '#2563eb',
      cursorColor: '#1e40af',
      barWidth: 2,
      barRadius: 3,
      cursorWidth: 1,
      height: 100,
      barGap: 2,
      responsive: true,
      normalize: true,
      backend: 'WebAudio'
    });

    wavesurferRef.current = wavesurfer;

    // Load audio
    wavesurfer.load(src);

    // Event listeners
    wavesurfer.on('ready', () => {
      setLoading(false);
      const dur = wavesurfer.getDuration();
      setDuration(formatTime(dur));
      if (autoPlay) {
        wavesurfer.play();
      }
    });

    wavesurfer.on('audioprocess', () => {
      const time = wavesurfer.getCurrentTime();
      setCurrentTime(formatTime(time));
    });

    wavesurfer.on('play', () => {
      setIsPlaying(true);
    });

    wavesurfer.on('pause', () => {
      setIsPlaying(false);
    });

    wavesurfer.on('finish', () => {
      setIsPlaying(false);
      setCurrentTime('0:00');
    });

    wavesurfer.on('error', (err) => {
      console.error('WaveSurfer error:', err);
      setError('Error loading audio file');
      setLoading(false);
    });

    // Cleanup
    return () => {
      wavesurfer.destroy();
    };
  }, [src, autoPlay]);

  const formatTime = (seconds: number): string => {
    const mins = Math.floor(seconds / 60);
    const secs = Math.floor(seconds % 60);
    return `${mins}:${secs.toString().padStart(2, '0')}`;
  };

  const handlePlayPause = () => {
    if (wavesurferRef.current) {
      wavesurferRef.current.playPause();
    }
  };

  const handleStop = () => {
    if (wavesurferRef.current) {
      wavesurferRef.current.stop();
      setCurrentTime('0:00');
    }
  };

  const handleVolumeChange = (newVolume: number) => {
    if (wavesurferRef.current) {
      wavesurferRef.current.setVolume(newVolume);
      setVolume(newVolume);
    }
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
            Loading audio...
          </Box>
        </Box>
      )}

      <SpaceBetween size="m">
        {/* Waveform visualization */}
        <div
          ref={waveformRef}
          style={{
            width: '100%',
            display: loading ? 'none' : 'block'
          }}
        />

        {!loading && (
          <>
            {/* Time display */}
            <ColumnLayout columns={2}>
              <Box textAlign="left">
                <Box variant="strong">{currentTime}</Box>
              </Box>
              <Box textAlign="right">
                <Box variant="strong">{duration}</Box>
              </Box>
            </ColumnLayout>

            {/* Controls */}
            <SpaceBetween direction="horizontal" size="xs">
              <Button
                onClick={handlePlayPause}
                iconName={isPlaying ? 'pause' : 'caret-right-filled'}
              >
                {isPlaying ? 'Pause' : 'Play'}
              </Button>
              <Button onClick={handleStop} iconName="close">
                Stop
              </Button>

              {/* Volume control */}
              <Box>
                <label htmlFor="volume-slider">
                  <Box variant="small" color="text-body-secondary">
                    Volume: {Math.round(volume * 100)}%
                  </Box>
                </label>
                <input
                  id="volume-slider"
                  type="range"
                  min="0"
                  max="1"
                  step="0.01"
                  value={volume}
                  onChange={(e) => handleVolumeChange(parseFloat(e.target.value))}
                  style={{ width: '120px', verticalAlign: 'middle', marginLeft: '8px' }}
                />
              </Box>
            </SpaceBetween>
          </>
        )}
      </SpaceBetween>
    </Box>
  );
};

export default AudioPlayer;
