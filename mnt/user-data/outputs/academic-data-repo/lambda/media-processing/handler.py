"""
Media Processing Lambda Function
Triggered by S3 ObjectCreated events
Generates thumbnails, proxies, extracts metadata for images, video, and audio
"""

import json
import os
import boto3
import subprocess
import tempfile
from pathlib import Path
from typing import Dict, Any, List, Tuple
import logging
from PIL import Image
import mutagen
from mutagen.id3 import ID3
from mutagen.wave import WAVE

logger = logging.getLogger()
logger.setLevel(logging.INFO)

# AWS clients
s3 = boto3.client('s3')
transcribe = boto3.client('transcribe')

# Environment variables
PROCESSING_BUCKET = os.environ['PROCESSING_BUCKET']
FFMPEG_PATH = '/opt/bin/ffmpeg'  # From Lambda Layer
FFPROBE_PATH = '/opt/bin/ffprobe'


def lambda_handler(event, context):
    """
    Process media file uploaded to S3
    
    Event comes from S3 via EventBridge:
    {
        "Records": [{
            "s3": {
                "bucket": {"name": "bucket"},
                "object": {"key": "path/to/file.mp4"}
            }
        }]
    }
    """
    try:
        # Parse S3 event
        record = event['Records'][0]
        bucket = record['s3']['bucket']['name']
        key = record['s3']['object']['key']
        
        logger.info(f"Processing: s3://{bucket}/{key}")
        
        # Download file to /tmp
        local_path = download_file(bucket, key)
        
        # Detect media type
        media_type = detect_media_type(local_path)
        logger.info(f"Detected media type: {media_type}")
        
        # Process based on type
        if media_type == 'image':
            results = process_image(local_path, bucket, key)
        elif media_type == 'video':
            results = process_video(local_path, bucket, key)
        elif media_type == 'audio':
            results = process_audio(local_path, bucket, key)
        else:
            logger.warning(f"Unsupported media type: {media_type}")
            return {'statusCode': 200, 'body': 'Unsupported media type'}
        
        # Update manifest with derivative URLs
        update_manifest(bucket, key, results)
        
        # Cleanup
        os.remove(local_path)
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Processing complete',
                'results': results
            })
        }
        
    except Exception as e:
        logger.error(f"Error processing media: {str(e)}", exc_info=True)
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }


def download_file(bucket: str, key: str) -> str:
    """Download S3 file to /tmp"""
    local_path = f"/tmp/{Path(key).name}"
    s3.download_file(bucket, key, local_path)
    return local_path


def detect_media_type(file_path: str) -> str:
    """Detect media type from file"""
    ext = Path(file_path).suffix.lower()
    
    image_exts = {'.jpg', '.jpeg', '.png', '.tif', '.tiff', '.gif', '.webp', '.bmp', '.dng', '.raw'}
    video_exts = {'.mp4', '.mov', '.avi', '.mkv', '.webm', '.m4v', '.mpg', '.mpeg'}
    audio_exts = {'.mp3', '.wav', '.flac', '.m4a', '.aac', '.ogg', '.opus', '.wma'}
    
    if ext in image_exts:
        return 'image'
    elif ext in video_exts:
        return 'video'
    elif ext in audio_exts:
        return 'audio'
    else:
        return 'unknown'


def process_image(file_path: str, source_bucket: str, source_key: str) -> Dict[str, Any]:
    """
    Process image file:
    1. Extract EXIF metadata
    2. Generate thumbnails (150px, 500px, 1200px)
    3. Convert to web-friendly formats (WebP, Progressive JPEG)
    """
    results = {
        'type': 'image',
        'metadata': {},
        'derivatives': []
    }
    
    # Extract EXIF
    try:
        with Image.open(file_path) as img:
            exif = img.getexif()
            if exif:
                results['metadata']['exif'] = {
                    str(k): str(v) for k, v in exif.items()
                }
            
            results['metadata']['format'] = img.format
            results['metadata']['mode'] = img.mode
            results['metadata']['size'] = img.size
            
            # Generate thumbnails
            for size in [150, 500, 1200]:
                thumb_path = generate_thumbnail(img, file_path, size)
                thumb_key = upload_derivative(thumb_path, source_key, f'thumb-{size}px')
                results['derivatives'].append({
                    'type': 'thumbnail',
                    'size': f'{size}px',
                    'url': f's3://{PROCESSING_BUCKET}/{thumb_key}'
                })
                os.remove(thumb_path)
            
            # Generate WebP version
            webp_path = f"/tmp/{Path(file_path).stem}.webp"
            img.save(webp_path, 'WEBP', quality=85, method=6)
            webp_key = upload_derivative(webp_path, source_key, 'webp')
            results['derivatives'].append({
                'type': 'webp',
                'url': f's3://{PROCESSING_BUCKET}/{webp_key}'
            })
            os.remove(webp_path)
            
    except Exception as e:
        logger.error(f"Error processing image: {str(e)}")
    
    return results


def generate_thumbnail(img: Image.Image, original_path: str, max_size: int) -> str:
    """Generate thumbnail maintaining aspect ratio"""
    thumb = img.copy()
    thumb.thumbnail((max_size, max_size), Image.Resampling.LANCZOS)
    
    thumb_path = f"/tmp/{Path(original_path).stem}_thumb_{max_size}.jpg"
    thumb.save(thumb_path, 'JPEG', quality=85, optimize=True)
    return thumb_path


def process_video(file_path: str, source_bucket: str, source_key: str) -> Dict[str, Any]:
    """
    Process video file:
    1. Extract metadata (duration, codec, resolution, fps, bitrate)
    2. Generate thumbnails at 0%, 25%, 50%, 75%
    3. Generate contact sheet
    4. Create 480p proxy video
    5. Generate HLS playlist for streaming
    """
    results = {
        'type': 'video',
        'metadata': {},
        'derivatives': []
    }
    
    # Extract metadata with ffprobe
    try:
        metadata = extract_video_metadata(file_path)
        results['metadata'] = metadata
        
        duration = float(metadata.get('duration', 0))
        
        # Generate thumbnails at key points
        for percent in [0, 25, 50, 75]:
            timestamp = duration * (percent / 100)
            thumb_path = extract_video_frame(file_path, timestamp)
            thumb_key = upload_derivative(thumb_path, source_key, f'thumb-{percent}pct')
            results['derivatives'].append({
                'type': 'thumbnail',
                'position': f'{percent}%',
                'url': f's3://{PROCESSING_BUCKET}/{thumb_key}'
            })
            os.remove(thumb_path)
        
        # Generate contact sheet (grid of frames)
        contact_sheet_path = generate_contact_sheet(file_path, duration)
        contact_key = upload_derivative(contact_sheet_path, source_key, 'contact-sheet')
        results['derivatives'].append({
            'type': 'contact_sheet',
            'url': f's3://{PROCESSING_BUCKET}/{contact_key}'
        })
        os.remove(contact_sheet_path)
        
        # Generate 480p proxy
        proxy_path = generate_video_proxy(file_path)
        proxy_key = upload_derivative(proxy_path, source_key, '480p-proxy')
        results['derivatives'].append({
            'type': 'proxy_video',
            'resolution': '480p',
            'url': f's3://{PROCESSING_BUCKET}/{proxy_key}'
        })
        os.remove(proxy_path)
        
        # Generate HLS playlist for streaming
        hls_dir = generate_hls_playlist(file_path)
        hls_keys = upload_directory(hls_dir, source_key, 'hls')
        results['derivatives'].append({
            'type': 'hls_playlist',
            'url': f's3://{PROCESSING_BUCKET}/{hls_keys[0]}'  # m3u8 file
        })
        
    except Exception as e:
        logger.error(f"Error processing video: {str(e)}")
    
    return results


def extract_video_metadata(file_path: str) -> Dict[str, Any]:
    """Extract video metadata using ffprobe"""
    cmd = [
        FFPROBE_PATH,
        '-v', 'quiet',
        '-print_format', 'json',
        '-show_format',
        '-show_streams',
        file_path
    ]
    
    result = subprocess.run(cmd, capture_output=True, text=True)
    data = json.loads(result.stdout)
    
    video_stream = next((s for s in data['streams'] if s['codec_type'] == 'video'), {})
    audio_stream = next((s for s in data['streams'] if s['codec_type'] == 'audio'), {})
    
    return {
        'duration': data['format'].get('duration'),
        'size': data['format'].get('size'),
        'bitrate': data['format'].get('bit_rate'),
        'video': {
            'codec': video_stream.get('codec_name'),
            'width': video_stream.get('width'),
            'height': video_stream.get('height'),
            'fps': eval(video_stream.get('r_frame_rate', '0/1')),  # e.g., "30/1" -> 30.0
            'color_space': video_stream.get('color_space')
        },
        'audio': {
            'codec': audio_stream.get('codec_name'),
            'sample_rate': audio_stream.get('sample_rate'),
            'channels': audio_stream.get('channels')
        }
    }


def extract_video_frame(file_path: str, timestamp: float) -> str:
    """Extract single frame from video at timestamp"""
    output_path = f"/tmp/frame_{timestamp}.jpg"
    
    cmd = [
        FFMPEG_PATH,
        '-ss', str(timestamp),
        '-i', file_path,
        '-vframes', '1',
        '-q:v', '2',
        output_path
    ]
    
    subprocess.run(cmd, check=True, capture_output=True)
    return output_path


def generate_contact_sheet(file_path: str, duration: float) -> str:
    """Generate contact sheet (grid of frames)"""
    # Extract 12 frames evenly spaced
    num_frames = 12
    frame_paths = []
    
    for i in range(num_frames):
        timestamp = duration * (i / (num_frames - 1))
        frame_path = extract_video_frame(file_path, timestamp)
        frame_paths.append(frame_path)
    
    # Create grid using PIL
    images = [Image.open(fp) for fp in frame_paths]
    
    # Resize all to same size
    thumb_size = (320, 180)
    images = [img.resize(thumb_size) for img in images]
    
    # Create grid (4x3)
    grid_width = thumb_size[0] * 4
    grid_height = thumb_size[1] * 3
    grid = Image.new('RGB', (grid_width, grid_height))
    
    for i, img in enumerate(images):
        x = (i % 4) * thumb_size[0]
        y = (i // 4) * thumb_size[1]
        grid.paste(img, (x, y))
    
    output_path = "/tmp/contact_sheet.jpg"
    grid.save(output_path, 'JPEG', quality=85)
    
    # Cleanup
    for fp in frame_paths:
        os.remove(fp)
    
    return output_path


def generate_video_proxy(file_path: str) -> str:
    """Generate 480p proxy video"""
    output_path = f"/tmp/{Path(file_path).stem}_480p.mp4"
    
    cmd = [
        FFMPEG_PATH,
        '-i', file_path,
        '-vf', 'scale=-2:480',  # -2 maintains aspect ratio
        '-c:v', 'libx264',
        '-preset', 'fast',
        '-crf', '23',
        '-c:a', 'aac',
        '-b:a', '128k',
        output_path
    ]
    
    subprocess.run(cmd, check=True, capture_output=True)
    return output_path


def generate_hls_playlist(file_path: str) -> str:
    """Generate HLS playlist for streaming"""
    output_dir = "/tmp/hls"
    os.makedirs(output_dir, exist_ok=True)
    
    cmd = [
        FFMPEG_PATH,
        '-i', file_path,
        '-c:v', 'libx264',
        '-c:a', 'aac',
        '-b:a', '128k',
        '-vf', 'scale=-2:480',
        '-f', 'hls',
        '-hls_time', '10',
        '-hls_playlist_type', 'vod',
        '-hls_segment_filename', f'{output_dir}/segment%03d.ts',
        f'{output_dir}/playlist.m3u8'
    ]
    
    subprocess.run(cmd, check=True, capture_output=True)
    return output_dir


def process_audio(file_path: str, source_bucket: str, source_key: str) -> Dict[str, Any]:
    """
    Process audio file:
    1. Extract metadata (duration, bitrate, sample rate, channels)
    2. Generate waveform image
    3. Generate spectrogram
    4. Create web-optimized proxy (MP3 128kbps)
    5. Trigger transcription for speech content
    """
    results = {
        'type': 'audio',
        'metadata': {},
        'derivatives': []
    }
    
    try:
        # Extract metadata
        metadata = extract_audio_metadata(file_path)
        results['metadata'] = metadata
        
        # Generate waveform
        waveform_path = generate_waveform(file_path)
        waveform_key = upload_derivative(waveform_path, source_key, 'waveform')
        results['derivatives'].append({
            'type': 'waveform',
            'url': f's3://{PROCESSING_BUCKET}/{waveform_key}'
        })
        os.remove(waveform_path)
        
        # Generate spectrogram
        spectrogram_path = generate_spectrogram(file_path)
        spectrogram_key = upload_derivative(spectrogram_path, source_key, 'spectrogram')
        results['derivatives'].append({
            'type': 'spectrogram',
            'url': f's3://{PROCESSING_BUCKET}/{spectrogram_key}'
        })
        os.remove(spectrogram_path)
        
        # Generate MP3 proxy
        proxy_path = generate_audio_proxy(file_path)
        proxy_key = upload_derivative(proxy_path, source_key, 'mp3-proxy')
        results['derivatives'].append({
            'type': 'proxy_audio',
            'format': 'mp3',
            'url': f's3://{PROCESSING_BUCKET}/{proxy_key}'
        })
        os.remove(proxy_path)
        
        # Trigger transcription (async)
        if should_transcribe(metadata):
            trigger_transcription(source_bucket, source_key, metadata)
            results['transcription'] = 'pending'
        
    except Exception as e:
        logger.error(f"Error processing audio: {str(e)}")
    
    return results


def extract_audio_metadata(file_path: str) -> Dict[str, Any]:
    """Extract audio metadata using mutagen and ffprobe"""
    metadata = {}
    
    # Use mutagen for tags
    try:
        audio = mutagen.File(file_path)
        if audio:
            metadata['tags'] = {k: str(v) for k, v in audio.items() if v}
            if hasattr(audio.info, 'length'):
                metadata['duration'] = audio.info.length
            if hasattr(audio.info, 'sample_rate'):
                metadata['sample_rate'] = audio.info.sample_rate
            if hasattr(audio.info, 'channels'):
                metadata['channels'] = audio.info.channels
            if hasattr(audio.info, 'bitrate'):
                metadata['bitrate'] = audio.info.bitrate
    except:
        pass
    
    # Use ffprobe for comprehensive metadata
    cmd = [
        FFPROBE_PATH,
        '-v', 'quiet',
        '-print_format', 'json',
        '-show_format',
        '-show_streams',
        file_path
    ]
    
    result = subprocess.run(cmd, capture_output=True, text=True)
    data = json.loads(result.stdout)
    
    audio_stream = next((s for s in data['streams'] if s['codec_type'] == 'audio'), {})
    
    metadata.update({
        'duration': data['format'].get('duration'),
        'size': data['format'].get('size'),
        'bitrate': data['format'].get('bit_rate'),
        'codec': audio_stream.get('codec_name'),
        'sample_rate': audio_stream.get('sample_rate'),
        'channels': audio_stream.get('channels'),
        'bit_depth': audio_stream.get('bits_per_sample')
    })
    
    return metadata


def generate_waveform(file_path: str) -> str:
    """Generate waveform image using ffmpeg"""
    output_path = "/tmp/waveform.png"
    
    cmd = [
        FFMPEG_PATH,
        '-i', file_path,
        '-filter_complex', 'showwavespic=s=1200x400:colors=0x003366',
        '-frames:v', '1',
        output_path
    ]
    
    subprocess.run(cmd, check=True, capture_output=True)
    return output_path


def generate_spectrogram(file_path: str) -> str:
    """Generate spectrogram image using ffmpeg"""
    output_path = "/tmp/spectrogram.png"
    
    cmd = [
        FFMPEG_PATH,
        '-i', file_path,
        '-lavfi', 'showspectrumpic=s=1200x400:legend=1',
        '-frames:v', '1',
        output_path
    ]
    
    subprocess.run(cmd, check=True, capture_output=True)
    return output_path


def generate_audio_proxy(file_path: str) -> str:
    """Generate MP3 proxy for web playback"""
    output_path = f"/tmp/{Path(file_path).stem}_proxy.mp3"
    
    cmd = [
        FFMPEG_PATH,
        '-i', file_path,
        '-codec:a', 'libmp3lame',
        '-b:a', '128k',
        '-ar', '44100',
        output_path
    ]
    
    subprocess.run(cmd, check=True, capture_output=True)
    return output_path


def should_transcribe(metadata: Dict[str, Any]) -> bool:
    """Determine if audio should be transcribed"""
    # Only transcribe if duration < 4 hours (AWS Transcribe limit)
    # and sample rate is reasonable
    duration = float(metadata.get('duration', 0))
    return 0 < duration < 14400  # 4 hours


def trigger_transcription(bucket: str, key: str, metadata: Dict[str, Any]):
    """Start AWS Transcribe job"""
    job_name = f"transcribe-{Path(key).stem}-{int(datetime.now().timestamp())}"
    
    transcribe.start_transcription_job(
        TranscriptionJobName=job_name,
        Media={'MediaFileUri': f's3://{bucket}/{key}'},
        MediaFormat=Path(key).suffix[1:].lower(),
        LanguageCode='en-US',  # Could be detected or specified in metadata
        OutputBucketName=PROCESSING_BUCKET,
        OutputKey=f"transcripts/{Path(key).stem}.json"
    )
    
    logger.info(f"Started transcription job: {job_name}")


def upload_derivative(local_path: str, source_key: str, suffix: str) -> str:
    """Upload derivative file to processing bucket"""
    # Construct derivative key
    source_path = Path(source_key)
    derivative_key = f"{source_path.parent}/derivatives/{source_path.stem}_{suffix}{Path(local_path).suffix}"
    
    s3.upload_file(local_path, PROCESSING_BUCKET, derivative_key)
    logger.info(f"Uploaded derivative: s3://{PROCESSING_BUCKET}/{derivative_key}")
    
    return derivative_key


def upload_directory(local_dir: str, source_key: str, suffix: str) -> List[str]:
    """Upload entire directory to processing bucket"""
    uploaded_keys = []
    source_path = Path(source_key)
    
    for file_path in Path(local_dir).rglob('*'):
        if file_path.is_file():
            relative_path = file_path.relative_to(local_dir)
            derivative_key = f"{source_path.parent}/derivatives/{source_path.stem}_{suffix}/{relative_path}"
            s3.upload_file(str(file_path), PROCESSING_BUCKET, derivative_key)
            uploaded_keys.append(derivative_key)
    
    logger.info(f"Uploaded {len(uploaded_keys)} files from {local_dir}")
    return uploaded_keys


def update_manifest(bucket: str, key: str, processing_results: Dict[str, Any]):
    """Update dataset manifest with processing results"""
    # Find manifest.json in parent directory
    manifest_key = str(Path(key).parent / 'manifest.json')
    
    try:
        response = s3.get_object(Bucket=bucket, Key=manifest_key)
        manifest = json.loads(response['Body'].read())
        
        # Find the file entry
        file_name = Path(key).name
        for file_entry in manifest.get('files', []):
            if file_entry.get('name') == file_name or file_entry.get('path', '').endswith(file_name):
                # Add processing results
                file_entry['metadata'] = processing_results['metadata']
                file_entry['derivatives'] = processing_results['derivatives']
                break
        
        # Upload updated manifest
        s3.put_object(
            Bucket=bucket,
            Key=manifest_key,
            Body=json.dumps(manifest, indent=2),
            ContentType='application/json'
        )
        
        logger.info(f"Updated manifest: {manifest_key}")
        
    except Exception as e:
        logger.error(f"Error updating manifest: {str(e)}")
