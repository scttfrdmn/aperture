# Aperture - AI-Powered Research Media Platform
## Opening Research to the World

**Store, Analyze, and Secure Research Images, Video & Audio**

---

## 🎯 What is Aperture?

**Aperture** is an AI-powered platform specifically designed for research multimedia data (images, video, audio). Built on AWS S3, it solves the real-world challenges of large media files: storage costs, streaming, AI analysis, ML training, and scientific watermarking—while maintaining FAIR principles.

**"Opening research to the world"**

### Core Capabilities
- 📦 **Smart Storage**: Up to 5 TB per file with 78% cost savings
- 🤖 **AI Analysis**: Automatic description, tagging, transcription
- 🔬 **ML Platform**: Train custom models on your data
- 🔐 **Scientific Watermarking**: Stegano integration preserves data integrity
- 💎 **Professional UI**: AWS Cloudscape design

---

## Executive Summary

A serverless, cost-optimized repository specifically designed for academic multimedia data (images, video, audio) on AWS S3. Solves real-world challenges of large media files: storage costs, streaming, preview generation, metadata extraction, transcription, and long-term preservation while maintaining FAIR principles.

## Key Differentiators vs. Existing Platforms

### Comparison Matrix (Multimedia Research Data)

| Feature | Aperture | Zenodo | Figshare | YouTube | SoundCloud | OMERO | TIB AV-Portal |
|---------|----------|---------|----------|---------|------------|-------|---------------|
| Storage Cost (100 TB/yr) | $2,300-$12,000* | Free (50GB limit) | 20GB free | Free | 3hrs free | Self-hosted | Free (EU) |
| Max File Size | **5 TB** | 50 GB | 20 GB | 256 GB | 5 GB | Unlimited | 20 GB |
| AI Analysis | **✅ Auto** | ❌ | ❌ | Limited | ❌ | ❌ | ❌ |
| ML Training | **✅ Integrated** | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Scientific Watermarking | **✅ Stegano** | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Video Streaming | HLS/DASH | Download only | Download only | ✅ | ❌ | ❌ | ✅ |
| Audio Streaming | ✅ | Download only | Download only | ✅ (in video) | ✅ | ❌ | ✅ |
| Waveform Visualization | ✅ | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ |
| Speech-to-Text | ✅ (AWS Transcribe) | ❌ | ❌ | ✅ | ❌ | ❌ | ✅ |
| Automated Thumbnails | ✅ | ❌ | Manual | ✅ | ✅ | ✅ (images) | ✅ |
| Frame/Sample Extraction | ✅ | ❌ | ❌ | Limited | Limited | ✅ | ❌ |
| Scientific Formats | TIFF, DNG, CZI, WAV, FLAC | Generic | Generic | Consumer | Consumer | Microscopy | Consumer |
| EXIF/Metadata Extract | ✅ | ❌ | Manual | ✅ | ✅ | ✅ | ✅ |
| DOI Minting | DataCite | DataCite | DataCite | ❌ | ❌ | Manual | DataCite |
| Automated Tiering | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Computational Access | S3 API, presigned | Download | Download | API limited | API limited | API | Download |
| Budget Controls | ✅ | N/A | N/A | N/A | Paid tiers | Self-managed | N/A |

*Depends on access patterns, streaming usage, and tiering policies

**Aperture is the only platform with integrated AI analysis, ML training, and scientific watermarking.**

### Problems This Solves (Multimedia-Specific)

#### 1. **Massive Storage Costs for High-Quality Media**
- **Problem**: 
  - 4K video = 375 MB/min. A field study with 100 hours = 2.2 TB
  - Uncompressed audio (96kHz/24-bit) = 17 MB/min. 1000 hours of interviews = 1 TB
  - High-res microscopy images = 500 MB each. 10,000 images = 5 TB
  - Traditional repos can't handle it or charge prohibitively
- **Solution**: Intelligent tiering based on access patterns
  - Active research (< 90 days): S3 Standard - immediate access for analysis
  - Published datasets (90-365 days): S3 IA - occasional viewing
  - Historical data (1-3 years): Glacier Instant - same-day retrieval
  - Archive (3+ years): Deep Archive - $0.00099/GB/mo (10TB = $9.90/month)
  - **Example**: 100TB multimedia archive over 5 years: $27,600 (Standard) vs $5,940 (Tiered) = 78% savings

#### 2. **Streaming vs. Download Dilemma**
- **Problem**: Researchers need to preview media but don't want to download multi-GB files
- **Solution**: 
  - **Video**: Auto-generate 480p proxies, HLS streaming for in-browser playback
  - **Audio**: Web-optimized MP3/AAC proxies, waveform images, streaming via CloudFront
  - **Images**: Progressive JPEG, WebP conversions, IIIF-compatible tiling for gigapixel images
  - Original lossless files available for computational analysis
  - **Cost**: Streaming 100 hours = $85 vs. 100 full-quality downloads = $900 egress

#### 3. **No Previews or Visual Navigation**
- **Problem**: Can't visually browse datasets without downloading everything
- **Solution**: Automated on-upload
  - **Video**: Thumbnails at 0%, 25%, 50%, 75%, GIF preview, contact sheet
  - **Audio**: Waveform visualization (PNG), spectrograms, peak markers
  - **Images**: Multiple resolution thumbnails (150px, 500px, 1200px)
  - All stored as web-optimized formats (< 100KB each)
  - Enables visual search and browsing without downloads

#### 4. **Lost Scientific Metadata**
- **Problem**: Critical research metadata lost on generic platforms
- **Solution**: Automatic extraction on upload
  - **Images**: EXIF (GPS, timestamp, camera settings), TIFF tags, microscopy metadata (OME-TIFF, CZI, ND2)
  - **Video**: Container metadata (codec, bitrate, duration, fps, color space), timecode
  - **Audio**: ID3 tags, BWF metadata, sampling rate, bit depth, channels, timecode, recording equipment
  - Store in searchable JSON-LD alongside files
  - **Examples**: 
    - Ecology: Every photo has GPS → automatic map visualization
    - Oral history: BWF metadata captures interviewer, location, rights information

#### 5. **Frame/Sample Extraction for Computational Analysis**
- **Problem**: ML researchers need specific frames or audio segments, not entire files
- **Solution**: On-demand extraction API
  - **Video**: "Extract frame 1000", "Every 30th frame", "Frames 100-200"
  - **Audio**: "Extract 2:30-2:45 segment", "Export at 16kHz for speech recognition"
  - **Images**: "Extract ROI at coordinates (x,y,w,h)"
  - Lambda functions process extractions on-demand
  - Avoids re-downloading and re-processing gigabytes

#### 6. **Audio Transcription & Searchability**
- **Problem**: Hours of interviews/lectures unsearchable without manual transcription ($60-120/hour)
- **Solution**: Automated speech-to-text with AWS Transcribe
  - Cost: $0.024/min = $1.44/hour (vs $60-120 manual)
  - Generate WebVTT/SRT subtitles with timestamps
  - Full-text search across all audio content
  - Speaker diarization (who said what when)
  - Citation with timestamps: "See interview XYZ at 23:45"
  - **Example**: 1000 hours of oral histories = $1,440 to transcribe (automated) vs. $60,000-$120,000 (manual)

#### 7. **Format Obsolescence & Long-Term Preservation**
- **Problem**: Proprietary formats become unreadable over time
- **Solution**: Normalize to preservation formats on ingest
  - **Video**: H.264/H.265 for access + FFV1 (lossless) for preservation
  - **Audio**: FLAC or WAV (PCM) for preservation, Opus/AAC for streaming
  - **Images**: TIFF (uncompressed) for preservation, WebP/JPEG for access
  - Keep originals in Deep Archive ($0.00099/GB)
  - Automated format migration policies using PRONOM registry
  - 50-year preservation planning built-in

#### 8. **No Computational Access**
- **Problem**: Download-only repos break computational workflows (Python, R, MATLAB, ImageJ)
- **Solution**: Direct S3 API access
  - Presigned URLs with custom expiration (1 hour to 7 days)
  - S3 Select for querying metadata without full download
  - AWS Batch integration for large-scale processing
  - Jupyter notebook integration (read directly from S3)
  - **Example**: Train ML model on 50,000 images without downloading (EC2 in same region = no transfer fees)

#### 9. **Duplicate Detection**
- **Problem**: Researchers upload same content multiple times, wasting storage
- **Solution**: Intelligent deduplication
  - Perceptual hashing for images (pHash) - detects similar images
  - Audio fingerprinting (Chromaprint) - detects duplicate recordings
  - Video content hashing - detects re-encoded versions
  - SHA-256 for exact duplicates
  - Alert before upload: "Similar file exists in dataset XYZ"

#### 10. **Abandoned Datasets & Zombie Accounts**
- **Problem**: Graduated students and retired faculty leave orphaned data
- **Solution**: 
  - Mandatory PI (Principal Investigator) assignment
  - Automated ownership transfer workflows
  - Dataset "check-in" requirements for active data
  - No access in 2 years → auto-tier to Deep Archive
  - "Digital executor" policy for departing researchers

#### 11. **Hidden Egress Costs**
- **Problem**: Popular datasets generate massive unexpected egress charges ($0.09/GB)
- **Solution**:
  - CloudFront caching (85% of requests served from cache)
  - S3 Requester Pays for high-demand datasets
  - Budget alerts on high-egress datasets  
  - Regional mirrors for international collaborations
  - **Example**: 10TB dataset with 1000 downloads/year
    - Direct S3: $900/month
    - CloudFront cached: $140/month (84% savings)

#### 12. **Version Control Nightmare**
- **Problem**: Multiple versions, unclear which is canonical, no diff tools for media
- **Solution**:
  - S3 versioning with version-specific DOIs (10.5555/dataset.v1, v2, v3)
  - Automatic version metadata in JSON-LD
  - Immutable published versions (cannot be deleted)
  - Visual diff tools for images (side-by-side, overlay, difference map)
  - Audio diff (waveform comparison)
  - Version changelog auto-generated from metadata

## Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                       CloudFront CDN                              │
│         (Frontend + Public Media Delivery + Caching)              │
└──────────┬────────────────────────────┬────────────────┬─────────┘
           │                            │                │
  ┌────────▼─────────┐      ┌──────────▼──────────┐    │
  │  S3: Frontend    │      │  S3: Public Media   │    │
  │  (Static React)  │      │  (Open Access)      │    │
  └──────────────────┘      └─────────────────────┘    │
           │                                             │
  ┌────────▼─────────────────────────────────────────┐  │
  │         API Gateway + Lambda Functions            │  │
  │                                                    │  │
  │  ┌──────────────────────────────────────────┐   │  │
  │  │ • Auth (Cognito + ORCID federation)      │   │  │
  │  │ • DOI Minting (DataCite API)             │   │  │
  │  │ • Presigned URLs                          │   │  │
  │  │ • Access Control (RBAC)                   │   │  │
  │  │ • Bulk Upload Coordinator                 │   │  │
  │  │ • OAI-PMH Harvesting Endpoint             │   │  │
  │  │ • Frame/Sample Extraction                 │   │  │
  │  │ • Metadata Query (S3 Select)              │   │  │
  │  └──────────────────────────────────────────┘   │  │
  └─────────┬──────────────────────────────┬─────────┘  │
            │                              │             │
  ┌─────────▼──────────┐       ┌──────────▼─────────────┴──────┐
  │  S3: Private Media │       │  S3: Restricted/Embargoed     │
  │  (Pre-publication) │       │  (Authenticated Users)         │
  └────────────────────┘       └────────────────────────────────┘
            │                              │
            └──────────┬───────────────────┘
                       │
         ┌─────────────▼────────────────┐
         │    EventBridge Rules          │
         │  • S3 Upload Events           │
         │  • Scheduled (Embargo expiry) │
         │  • Budget Threshold           │
         └──────┬───────────────┬────────┘
                │               │
    ┌───────────▼──────┐   ┌───▼──────────────────┐
    │  Lambda:         │   │  Lambda:              │
    │  Media           │   │  Lifecycle            │
    │  Processing      │   │  Management           │
    │                  │   │                       │
    │  • Thumbnail Gen │   │  • Tier to Glacier    │
    │  • Proxy Videos  │   │  • Budget Alerts      │
    │  • Waveforms     │   │  • Embargo Release    │
    │  • Metadata      │   │  • Orphan Detection   │
    │    Extraction    │   │  • Duplicate Check    │
    │  • Transcription │   │  • DOI Updates        │
    └──────────────────┘   └───────────────────────┘
                │
    ┌───────────▼──────────────┐
    │  DynamoDB Tables          │
    │  • Users & Permissions    │
    │  • DOI Registry           │
    │  • Access Logs Summary    │
    │  • Budget Tracking        │
    └───────────────────────────┘
                │
    ┌───────────▼──────────────┐
    │  S3: Processing Output    │
    │  • Thumbnails             │
    │  • Proxy Media            │
    │  • Transcriptions         │
    │  • Waveforms              │
    └───────────────────────────┘
                │
    ┌───────────▼──────────────┐
    │  Athena + Glue            │
    │  • Query Access Logs      │
    │  • Compliance Reports     │
    │  • Usage Analytics        │
    └───────────────────────────┘
```

## S3 Bucket Structure

```
repo-media-public/                        # Public datasets
├── datasets/
│   ├── doi-10.5555-ecology-2024-001/
│   │   ├── manifest.json                 # FAIR metadata
│   │   ├── README.txt                    # Human-readable
│   │   ├── LICENSE.txt                   # CC-BY-4.0
│   │   ├── originals/
│   │   │   ├── video-001.mp4            # Original 4K (2.5GB)
│   │   │   ├── video-001.json           # Sidecar metadata
│   │   │   ├── audio-interview-01.wav   # Original 96kHz/24-bit
│   │   │   └── image-specimen-001.tif   # Original TIFF
│   │   ├── access/
│   │   │   ├── video-001-720p.mp4       # Web proxy
│   │   │   ├── video-001.m3u8           # HLS playlist
│   │   │   ├── audio-interview-01.mp3   # Web audio
│   │   │   └── image-specimen-001.jpg   # Web JPEG
│   │   ├── previews/
│   │   │   ├── video-001-thumb.jpg      # Thumbnail
│   │   │   ├── video-001-contact.jpg    # Contact sheet
│   │   │   ├── audio-01-waveform.png    # Waveform
│   │   │   └── audio-01-transcript.vtt  # Transcription
│   │   └── derivatives/
│   │       ├── frames/                   # Extracted frames
│   │       └── clips/                    # Extracted clips
│   └── doi-10.5555-linguistics-2024-002/
│       └── ...
└── collections/
    └── oral-histories-2024/
        └── collection-manifest.json

repo-media-embargoed/                     # Time-locked datasets
├── datasets/
│   └── doi-10.5555-medicine-2024-003/
│       ├── manifest.json
│       ├── embargo_until: 2026-01-01
│       └── data/...

repo-media-restricted/                    # Auth required
├── datasets/
│   └── project-sensitive-species/
│       └── data/...

repo-media-private/                       # Pre-publication
├── users/
│   └── researcher-abc123/
│       └── draft-dataset-xyz/
│           └── data/...

repo-frontend/                            # Static website
├── index.html
├── assets/
│   ├── js/
│   ├── css/
│   └── img/
└── error.html
```

## FAIR-Compliant Metadata Schema (JSON-LD)

```json
{
  "@context": [
    "https://schema.org/",
    "http://purl.org/dc/terms/",
    {
      "datacite": "http://purl.org/spar/datacite/"
    }
  ],
  "@type": "Dataset",
  "@id": "https://repo.university.edu/datasets/doi-10.5555-ecology-2024-001",
  
  "identifier": {
    "@type": "PropertyValue",
    "propertyID": "DOI",
    "value": "10.5555/ecology.2024.001"
  },
  
  "datacite": {
    "creators": [
      {
        "@type": "Person",
        "name": "Smith, Jane R.",
        "givenName": "Jane",
        "familyName": "Smith",
        "@id": "https://orcid.org/0000-0002-1825-0097",
        "affiliation": {
          "@type": "Organization",
          "name": "University of Example",
          "@id": "https://ror.org/example"
        }
      }
    ],
    "title": "Migration Patterns of Arctic Terns: Video Documentation 2024",
    "publisher": "University of Example Research Data Repository",
    "publicationYear": "2024",
    "resourceType": {
      "resourceTypeGeneral": "Audiovisual",
      "resourceType": "Video Dataset"
    },
    "subjects": [
      {"subject": "Ecology"},
      {"subject": "Bird Migration"},
      {"subject": "Arctic Ecosystems"},
      {"subject": "Climate Change"},
      {"subjectScheme": "LCSH", "subject": "Terns--Migration"}
    ],
    "contributors": [
      {
        "@type": "Person",
        "name": "Doe, John",
        "contributorType": "DataCollector",
        "@id": "https://orcid.org/0000-0003-1234-5678"
      }
    ],
    "dates": [
      {"date": "2024-06-15", "dateType": "Created"},
      {"date": "2024-09-01", "dateType": "Available"},
      {"date": "2024-08-30", "dateType": "Submitted"},
      {"date": "2024-06-15/2024-07-30", "dateType": "Collected"}
    ],
    "language": "en",
    "version": "1.0",
    "rights": [
      {
        "@type": "CreativeWork",
        "name": "Creative Commons Attribution 4.0 International",
        "license": "https://creativecommons.org/licenses/by/4.0/",
        "identifier": "CC-BY-4.0"
      }
    ],
    "descriptions": [
      {
        "description": "Time-lapse video recordings of Arctic Tern migration patterns observed over 6 weeks in the Svalbard archipelago. Includes 120 hours of 4K video documentation showing feeding behaviors, flight patterns, and nesting sites. Supplemented with audio recordings of vocalizations and GPS tracking data.",
        "descriptionType": "Abstract"
      },
      {
        "description": "Recorded using Canon EOS R5 with 100-400mm lens. Video: 4K 60fps, H.265 codec. Audio: Rode VideoMic Pro+ with Zoom H6 backup recorder at 96kHz/24-bit.",
        "descriptionType": "Methods"
      }
    ],
    "geoLocations": [
      {
        "geoLocationPlace": "Svalbard, Norway",
        "geoLocationPoint": {
          "pointLatitude": 78.2232,
          "pointLongitude": 15.6267
        },
        "geoLocationBox": {
          "westBoundLongitude": 15.0,
          "eastBoundLongitude": 16.0,
          "southBoundLatitude": 78.0,
          "northBoundLatitude": 79.0
        }
      }
    ],
    "fundingReferences": [
      {
        "funderName": "National Science Foundation",
        "funderIdentifier": "https://ror.org/021nxhr62",
        "awardNumber": "NSF-2024-12345",
        "awardTitle": "Arctic Climate Change Impact Study"
      }
    ],
    "relatedIdentifiers": [
      {
        "relatedIdentifier": "10.5555/related-paper-2024",
        "relatedIdentifierType": "DOI",
        "relationType": "IsSupplementTo"
      },
      {
        "relatedIdentifier": "https://protocols.io/view/arctic-tern-observation-xyz",
        "relatedIdentifierType": "URL",
        "relationType": "IsDocumentedBy"
      }
    ]
  },
  
  "files": [
    {
      "@type": "MediaObject",
      "name": "video-week1-nest-site-A.mp4",
      "encodingFormat": "video/mp4",
      "contentSize": "2684354560",
      "duration": "PT2H15M30S",
      "uploadDate": "2024-06-20",
      "sha256": "a3b5c6d7e8f9g0h1i2j3k4l5m6n7o8p9",
      "url": "s3://repo-media-public/datasets/doi-10.5555-ecology-2024-001/originals/video-week1-nest-site-A.mp4",
      "thumbnailUrl": "https://repo.university.edu/thumbnails/video-week1-nest-site-A-thumb.jpg",
      "metadata": {
        "videoCodec": "hevc",
        "audioCodec": "aac",
        "resolution": "3840x2160",
        "frameRate": 60,
        "bitrate": 2650000,
        "colorSpace": "bt709"
      }
    },
    {
      "@type": "AudioObject",
      "name": "audio-vocalizations-day12.wav",
      "encodingFormat": "audio/wav",
      "contentSize": "1073741824",
      "duration": "PT1H",
      "uploadDate": "2024-06-27",
      "sha256": "b4c5d6e7f8g9h0i1j2k3l4m5n6o7p8q9",
      "url": "s3://repo-media-public/datasets/doi-10.5555-ecology-2024-001/originals/audio-vocalizations-day12.wav",
      "metadata": {
        "sampleRate": 96000,
        "bitDepth": 24,
        "channels": 2,
        "recordingEquipment": "Zoom H6 with Rode NTG4+ microphones"
      }
    }
  ],
  
  "access": {
    "status": "public",
    "embargoUntil": null,
    "conditions": "Attribution required (CC-BY-4.0)",
    "accessURL": "https://repo.university.edu/datasets/doi-10.5555-ecology-2024-001"
  },
  
  "provenance": {
    "equipment": [
      "Canon EOS R5",
      "Canon RF 100-400mm f/5.6-8 IS USM",
      "Rode VideoMic Pro+",
      "Zoom H6 Handy Recorder"
    ],
    "software": [
      "DaVinci Resolve 18 (color grading)",
      "Adobe Audition 2024 (audio cleanup)"
    ],
    "methodology": "https://protocols.io/view/arctic-tern-observation-xyz",
    "dataQuality": "Raw footage with minimal processing. Color balanced for Arctic daylight conditions."
  },
  
  "s3Lifecycle": {
    "currentStorageClass": "STANDARD",
    "transitionRules": [
      {
        "days": 90,
        "storageClass": "STANDARD_IA"
      },
      {
        "days": 365,
        "storageClass": "GLACIER_IR"
      },
      {
        "days": 1095,
        "storageClass": "DEEP_ARCHIVE"
      }
    ],
    "lastAccessed": "2024-11-01T14:30:00Z",
    "accessCount30Days": 45,
    "accessCount365Days": 234
  },
  
  "budget": {
    "storageClass": "STANDARD",
    "estimatedMonthlyCost": 57.85,
    "actualMonthlyCost": 52.34,
    "egressCost30Days": 12.50,
    "projectedAnnualCost": 628.08
  }
}
```