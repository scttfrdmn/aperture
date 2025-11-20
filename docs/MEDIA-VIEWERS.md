# Media Viewers Guide

## Overview

Aperture includes built-in media viewers for previewing video, audio, and image files directly in the browser without downloading. The media viewers provide rich functionality including HLS video streaming, audio waveform visualization, and image zoom/pan capabilities.

## Table of Contents

- [Features](#features)
- [Supported Formats](#supported-formats)
- [Components](#components)
- [Usage](#usage)
- [Configuration](#configuration)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)

## Features

### Video Player
- **HLS Streaming Support**: Native support for HTTP Live Streaming (HLS) with .m3u8 playlists
- **Adaptive Bitrate**: Automatically adjusts video quality based on network conditions
- **Standard Video Formats**: MP4, WebM, OGG support
- **Error Recovery**: Automatic recovery from network and media errors
- **Browser Compatibility**: Works across all modern browsers (Chrome, Firefox, Safari, Edge)
- **Native Controls**: Standard HTML5 video controls (play, pause, seek, volume, fullscreen)

### Audio Player
- **Waveform Visualization**: Real-time audio waveform display
- **Interactive Seeking**: Click on waveform to jump to any position
- **Playback Controls**: Play, pause, stop buttons
- **Volume Control**: Adjustable volume slider (0-100%)
- **Time Display**: Current time and total duration
- **Multiple Formats**: MP3, WAV, OGG, AAC, M4A, FLAC support
- **Responsive Design**: Adapts to container width

### Image Viewer
- **Zoom Controls**: Zoom in/out buttons (0.5x to 8x)
- **Mouse Wheel Zoom**: Scroll to zoom in/out
- **Pan**: Click and drag to move around zoomed images
- **Reset View**: One-click return to default view
- **Center View**: Center the image in the viewport
- **Double-Click Reset**: Double-click to reset zoom
- **Image Information**: Display native image dimensions
- **Multiple Formats**: JPEG, PNG, GIF, WebP, SVG, TIFF support

## Supported Formats

### Video

| Format | Extension | MIME Type | HLS Support |
|--------|-----------|-----------|-------------|
| MP4 | .mp4 | video/mp4 | ✅ (fallback) |
| WebM | .webm | video/webm | ✅ (fallback) |
| OGG | .ogg | video/ogg | ✅ (fallback) |
| HLS | .m3u8 | application/vnd.apple.mpegurl | ✅ (native) |
| DASH | .mpd | application/dash+xml | ❌ (future) |

**Note**: HLS (.m3u8) files are recommended for adaptive streaming. The player uses hls.js for browsers that don't support HLS natively (all except Safari).

### Audio

| Format | Extension | MIME Type | Waveform |
|--------|-----------|-----------|----------|
| MP3 | .mp3 | audio/mpeg | ✅ |
| WAV | .wav | audio/wav | ✅ |
| OGG | .ogg | audio/ogg | ✅ |
| AAC | .aac | audio/aac | ✅ |
| M4A | .m4a | audio/mp4 | ✅ |
| FLAC | .flac | audio/flac | ✅ |
| WMA | .wma | audio/x-ms-wma | ⚠️ (limited) |

**Note**: All formats support waveform visualization via WaveSurfer.js. FLAC and high-bitrate files may take longer to load.

### Images

| Format | Extension | MIME Type | Zoom/Pan |
|--------|-----------|-----------|----------|
| JPEG | .jpg, .jpeg | image/jpeg | ✅ |
| PNG | .png | image/png | ✅ |
| GIF | .gif | image/gif | ✅ |
| WebP | .webp | image/webp | ✅ |
| BMP | .bmp | image/bmp | ✅ |
| SVG | .svg | image/svg+xml | ✅ |
| TIFF | .tif, .tiff | image/tiff | ⚠️ (browser support varies) |

**Note**: SVG files support zoom/pan but may render differently depending on browser. TIFF support is limited in web browsers.

## Components

### VideoPlayer

Component for playing video files with HLS streaming support.

**Props:**
- `src` (string, required): URL to the video file
- `poster` (string, optional): URL to poster image displayed before playback
- `autoPlay` (boolean, optional): Auto-play video when loaded (default: false)
- `controls` (boolean, optional): Show video controls (default: true)

**Example:**
```tsx
import VideoPlayer from './components/VideoPlayer';

<VideoPlayer
  src="https://example.com/video.mp4"
  poster="https://example.com/poster.jpg"
  autoPlay={false}
  controls={true}
/>
```

**HLS Example:**
```tsx
<VideoPlayer
  src="https://example.com/stream.m3u8"
  controls={true}
/>
```

### AudioPlayer

Component for playing audio files with waveform visualization.

**Props:**
- `src` (string, required): URL to the audio file
- `autoPlay` (boolean, optional): Auto-play audio when loaded (default: false)

**Example:**
```tsx
import AudioPlayer from './components/AudioPlayer';

<AudioPlayer
  src="https://example.com/audio.mp3"
  autoPlay={false}
/>
```

**Features:**
- Displays waveform visualization
- Interactive seeking via waveform
- Play/pause/stop controls
- Volume slider
- Current time and duration display

### ImageViewer

Component for viewing images with zoom and pan capabilities.

**Props:**
- `src` (string, required): URL to the image file
- `alt` (string, optional): Alt text for the image (default: "Image")
- `maxHeight` (string, optional): Maximum height of the viewer (default: "600px")

**Example:**
```tsx
import ImageViewer from './components/ImageViewer';

<ImageViewer
  src="https://example.com/image.jpg"
  alt="Archaeological artifact"
  maxHeight="800px"
/>
```

**Controls:**
- Zoom In/Out buttons
- Reset button (return to default view)
- Center button (center image)
- Mouse wheel zoom
- Click and drag to pan
- Double-click to reset

### MediaViewer

Unified component that automatically selects the appropriate viewer based on file type.

**Props:**
- `src` (string, required): URL to the media file
- `filename` (string, required): Filename (used for type detection)
- `mimeType` (string, optional): MIME type (overrides filename detection)

**Example:**
```tsx
import MediaViewer from './components/MediaViewer';

<MediaViewer
  src="https://example.com/file.mp4"
  filename="excavation.mp4"
  mimeType="video/mp4"
/>
```

**Type Detection:**
1. Uses MIME type if provided
2. Falls back to file extension
3. Returns "unsupported" message if neither matches

## Usage

### In Dataset Detail Page

The media viewers are integrated into the DatasetDetail page with a Preview tab:

1. Navigate to a dataset detail page
2. Click on the **Files** tab
3. Click the **Preview** button next to any media file
4. The **Preview** tab opens automatically with the selected file

**Workflow:**
```
Dataset Detail → Files Tab → Click "Preview" → Preview Tab (with media viewer)
```

### Direct Component Usage

You can use individual viewer components directly in your pages:

```tsx
import { useState } from 'react';
import VideoPlayer from '../components/VideoPlayer';
import AudioPlayer from '../components/AudioPlayer';
import ImageViewer from '../components/ImageViewer';

function MyPage() {
  return (
    <div>
      {/* Video */}
      <VideoPlayer src="/path/to/video.mp4" controls />

      {/* Audio */}
      <AudioPlayer src="/path/to/audio.mp3" />

      {/* Image */}
      <ImageViewer src="/path/to/image.jpg" alt="Description" />
    </div>
  );
}
```

### With Presigned URLs

For S3 integration, use presigned URLs:

```tsx
import { useState, useEffect } from 'react';
import { api } from '../services/api';
import MediaViewer from '../components/MediaViewer';

function SecureMediaViewer({ bucket, key, filename, mimeType }) {
  const [url, setUrl] = useState('');
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // Generate presigned URL
    api.generatePresignedUrl(bucket, key, 3600)
      .then(response => {
        setUrl(response.url);
        setLoading(false);
      })
      .catch(error => {
        console.error('Failed to generate URL:', error);
        setLoading(false);
      });
  }, [bucket, key]);

  if (loading) return <div>Loading...</div>;
  if (!url) return <div>Failed to load media</div>;

  return (
    <MediaViewer
      src={url}
      filename={filename}
      mimeType={mimeType}
    />
  );
}
```

## Configuration

### Video Player Configuration

HLS.js configuration options (advanced):

```tsx
// In VideoPlayer.tsx, modify the Hls configuration:
const hls = new Hls({
  enableWorker: true,           // Use web worker for better performance
  lowLatencyMode: false,        // Enable for live streams
  backBufferLength: 90,         // Seconds of back buffer to maintain
  maxBufferLength: 30,          // Maximum buffer ahead of playhead
  maxMaxBufferLength: 600,      // Maximum possible buffer length
  maxBufferSize: 60 * 1000 * 1000, // Maximum buffer size (60 MB)
  maxBufferHole: 0.5,          // Maximum hole in buffer to jump over
});
```

### Audio Player Configuration

WaveSurfer.js configuration options:

```tsx
// In AudioPlayer.tsx, modify the WaveSurfer configuration:
const wavesurfer = WaveSurfer.create({
  container: waveformRef.current,
  waveColor: '#4a90e2',        // Waveform color
  progressColor: '#2563eb',    // Progress color
  cursorColor: '#1e40af',      // Cursor color
  barWidth: 2,                 // Width of waveform bars
  barRadius: 3,                // Border radius of bars
  cursorWidth: 1,              // Cursor width
  height: 100,                 // Waveform height
  barGap: 2,                   // Gap between bars
  responsive: true,            // Resize on window resize
  normalize: true,             // Normalize waveform
  backend: 'WebAudio'          // Use Web Audio API
});
```

### Image Viewer Configuration

React Zoom Pan Pinch options:

```tsx
// In ImageViewer.tsx, modify the TransformWrapper props:
<TransformWrapper
  initialScale={1}             // Initial zoom level
  minScale={0.5}              // Minimum zoom (0.5x)
  maxScale={8}                // Maximum zoom (8x)
  wheel={{ step: 0.1 }}       // Zoom step per wheel event
  doubleClick={{ mode: 'reset' }} // Double-click behavior
  panning={{ velocityDisabled: true }} // Disable momentum panning
/>
```

## Best Practices

### Video

**For Best Performance:**
- Use HLS (.m3u8) for videos longer than 5 minutes
- Provide multiple bitrate options in HLS manifest
- Include a poster image to reduce initial load time
- Keep video files under 500 MB for direct (non-HLS) playback

**Recommended Encoding:**
```bash
# Create HLS stream with multiple bitrates
ffmpeg -i input.mp4 \
  -c:v libx264 -crf 23 -preset medium \
  -c:a aac -b:a 128k \
  -f hls -hls_time 10 -hls_list_size 0 \
  -hls_segment_filename "segment_%03d.ts" \
  output.m3u8
```

### Audio

**For Best Quality:**
- Use 256 kbps MP3 for high-quality audio
- Use 128 kbps for voice recordings
- Keep audio files under 50 MB for fast waveform loading
- Avoid extremely high sample rates (>48kHz) unless necessary

**Waveform Performance:**
- Waveform generation may take 2-5 seconds for large files
- Consider pre-generating waveform data for files > 100 MB
- Use shorter excerpts for previews of long recordings

### Images

**For Best Display:**
- Use JPEG for photographs
- Use PNG for graphics with transparency
- Compress images to balance quality and file size
- Maximum recommended size: 20 MB (larger images may be slow to zoom)
- Provide reasonable dimensions (< 8000px on any side)

**Image Optimization:**
```bash
# Optimize JPEG (quality 85, progressive)
convert input.jpg -quality 85 -interlace Plane output.jpg

# Optimize PNG
pngquant --quality=70-85 input.png -o output.png
```

### Cross-Origin Resources (CORS)

If media files are hosted on a different domain, ensure CORS headers are set:

```
Access-Control-Allow-Origin: https://your-domain.com
Access-Control-Allow-Methods: GET, HEAD
Access-Control-Allow-Headers: Range, Content-Type
```

For S3 buckets, configure CORS in the bucket policy:

```json
{
  "CORSRules": [
    {
      "AllowedOrigins": ["https://your-domain.com"],
      "AllowedMethods": ["GET", "HEAD"],
      "AllowedHeaders": ["*"],
      "MaxAgeSeconds": 3000
    }
  ]
}
```

## Troubleshooting

### Video Issues

**Problem**: Video won't play

**Solutions:**
- Check browser console for errors
- Verify CORS headers if video is on different domain
- Ensure video codec is supported (H.264 for MP4)
- Try opening video URL directly in browser
- Check that file is accessible (not 404)

**Problem**: HLS stream not loading

**Solutions:**
- Verify .m3u8 file is valid (open in text editor)
- Ensure .ts segment files are accessible
- Check hls.js console logs for specific errors
- Verify MIME type is `application/vnd.apple.mpegurl`

**Problem**: Video loads but shows black screen

**Solutions:**
- Video codec may not be supported
- Re-encode video with H.264 codec
- Check video is not corrupted
- Try different browser

### Audio Issues

**Problem**: Waveform not displaying

**Solutions:**
- Check browser console for CORS errors
- Verify audio file is valid (try playing in media player)
- Ensure file format is supported
- Try smaller audio file to test

**Problem**: Audio plays but no controls

**Solutions:**
- WaveSurfer.js initialization may have failed
- Check browser console for JavaScript errors
- Verify wavesurfer.js is properly installed
- Try refreshing the page

**Problem**: Distorted or stuttering audio

**Solutions:**
- Audio file may be corrupted
- Try lower bitrate/sample rate
- Check browser CPU usage
- Clear browser cache

### Image Issues

**Problem**: Image won't zoom

**Solutions:**
- Verify react-zoom-pan-pinch is installed
- Check browser console for errors
- Try refreshing the page
- Ensure image loaded successfully

**Problem**: Pan/zoom is laggy

**Solutions:**
- Image may be too large (> 20 MB)
- Resize/compress image
- Use progressive JPEG
- Check browser performance

**Problem**: Image appears pixelated when zoomed

**Solutions:**
- This is normal for raster images
- Use higher resolution source image
- Consider using SVG for graphics

### General Issues

**Problem**: "Preview not available" message

**Solutions:**
- File type may not be supported
- Check file extension and MIME type
- Verify file URL is valid
- Check browser console for specific error

**Problem**: Loading spinner never completes

**Solutions:**
- File may be too large
- Network connection may be slow/interrupted
- Check browser console for errors
- Try with smaller file to test
- Verify presigned URL hasn't expired (if using S3)

## Dependencies

The media viewers require the following npm packages:

```json
{
  "hls.js": "^1.4.0",
  "wavesurfer.js": "^7.4.0",
  "react-zoom-pan-pinch": "^3.3.0"
}
```

Install with:
```bash
npm install hls.js wavesurfer.js react-zoom-pan-pinch
```

## Browser Compatibility

| Feature | Chrome | Firefox | Safari | Edge |
|---------|--------|---------|--------|------|
| Video (MP4) | ✅ | ✅ | ✅ | ✅ |
| HLS (native) | ❌ | ❌ | ✅ | ❌ |
| HLS (hls.js) | ✅ | ✅ | ✅ | ✅ |
| Audio | ✅ | ✅ | ✅ | ✅ |
| Waveform | ✅ | ✅ | ✅ | ✅ |
| Image Zoom | ✅ | ✅ | ✅ | ✅ |
| WebP | ✅ | ✅ | ✅ | ✅ |

**Minimum Versions:**
- Chrome 90+
- Firefox 88+
- Safari 14+
- Edge 90+

## Future Enhancements

Planned features for future releases:

- **3D Model Viewer**: Support for .obj, .gltf, .glb files
- **PDF Viewer**: Inline PDF preview with navigation
- **360° Image Viewer**: Panoramic image support
- **DASH Streaming**: Alternative to HLS for video streaming
- **Subtitle Support**: VTT/SRT subtitle display for videos
- **Playlist Support**: Sequential playback of multiple files
- **Annotation Tools**: Draw on images/videos for collaboration
- **Download Options**: Export cropped/zoomed images
- **Playback Speed Control**: Variable speed for audio/video
- **Keyboard Shortcuts**: Enhanced keyboard navigation

---

**Last Updated:** November 10, 2024
**Version:** 1.0.0
**Author:** Aperture Development Team
