# Required inputs & outputs of Immich

## Snap Details

- **Snap name**: `all-dev-immich`
- **Version**: `2.5.6`
- **Base**: `core24`
- **Description**: High performance self-hosted photo and video management solution
- **Confinement**: `strict`
- **License**: `CC-BY-NC-SA-4.0 AND AGPL-3.0`

---

## Overview

Immich is a high-performance self-hosted photo and video management solution with:
- Photo and video backup from mobile devices
- Machine learning-powered search and organization
- Face recognition and object detection
- Timeline and album management
- Multi-user support
- Mobile apps for iOS and Android

This snap is optimized for Ubuntu Core and modular infrastructure deployments with dedicated content interfaces for PostgreSQL, FFmpeg, and graphics runtimes.

---

## Inputs

### From User

1. **Database Configuration** (via environment variables)
2. **Redis Configuration** (via environment variables)
3. **Media Storage Path** (via plugs)

### Auto-assigned from Control Tower

1. `ct-callback-url` - URL for Control Tower callbacks
2. `ct-deployment-id` - Unique deployment identifier
3. `ct-node-id` - Node identifier in the cluster

### Default Configuration

- **Server Port**: 3001
- **Database**: PostgreSQL 16 (via content interface)
- **Cache**: Redis/Valkey (external service)
- **Machine Learning**: Included (CPU-optimized)

---

## Outputs

| Message Type | Description | Example |
|--------------|-------------|---------|
| `message_initial` | Initial status on installation | "Immich server started on port 3001" |
| `message` | Periodic status updates | "Server running, ML service active" |
| `deployment_stop` | Shutdown notification | "Immich stopped" |

**Output Mode**: `logs`  
**Interval**: 60 seconds

---

## Configuration Template (CT Deployment Payload)

```json
{
  "snaps": [
    {
      "name": "all-dev-immich",
      "refresh": true
    }
  ],
  "snap_config": [
    {
      "snap": "all-dev-immich",
      "settings": {
        "DB_HOSTNAME": "127.0.0.1",
        "DB_PORT": "5433",
        "DB_USERNAME": "postgres",
        "DB_PASSWORD": "postgres",
        "DB_DATABASE_NAME": "immich",
        "REDIS_HOSTNAME": "127.0.0.1",
        "REDIS_PORT": "6379",
        "ct-node-id": "<ALL_APP_NODE_ID>",
        "ct-callback-url": "<ALL_APP_CALLBACK_URL>",
        "ct-deployment-id": "<ALL_APP_DEPLOYMENT_ID>"
      }
    }
  ],
  "ignore_failures": false,
  "pre_service_actions": [],
  "post_service_actions": [
    {
      "names": [
        "all-dev-immich"
      ],
      "action": "restart"
    }
  ],
  "interface_connections": [
    {
      "plug": "all-dev-immich:postgresql",
      "slot": "dilyn-postgresql:pg-content",
      "action": "connect"
    },
    {
      "plug": "all-dev-immich:graphics-core22",
      "slot": "dilyn-jellyfin-ffmpeg:graphics-libs",
      "action": "connect"
    },
    {
      "plug": "all-dev-immich:network",
      "slot": ":network",
      "action": "connect"
    },
    {
      "plug": "all-dev-immich:network-bind",
      "slot": ":network-bind",
      "action": "connect"
    },
    {
      "plug": "all-dev-immich:removable-media",
      "slot": ":removable-media",
      "action": "connect"
    },
    {
      "plug": "all-dev-immich:opengl",
      "slot": ":opengl",
      "action": "connect"
    }
  ]
}
```

---

## Usage Examples

### Basic Deployment

```json
{
  "snaps": [{"name": "all-dev-immich"}],
  "snap_config": [{
    "snap": "all-dev-immich",
    "settings": {
      "DB_HOSTNAME": "127.0.0.1",
      "DB_PORT": "5433",
      "REDIS_HOSTNAME": "127.0.0.1"
    }
  }]
}
```

### With Custom Database

```json
{
  "snaps": [{"name": "all-dev-immich"}],
  "snap_config": [{
    "snap": "all-dev-immich",
    "settings": {
      "DB_HOSTNAME": "postgres.example.com",
      "DB_PORT": "5432",
      "DB_USERNAME": "immich_user",
      "DB_PASSWORD": "secure_password",
      "DB_DATABASE_NAME": "immich_prod",
      "REDIS_HOSTNAME": "redis.example.com",
      "REDIS_PORT": "6379"
    }
  }]
}
```

---

## Configuration Parameters Reference

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `DB_HOSTNAME` | string | Yes | `127.0.0.1` | PostgreSQL hostname |
| `DB_PORT` | string | Yes | `5433` | PostgreSQL port |
| `DB_USERNAME` | string | Yes | `postgres` | Database username |
| `DB_PASSWORD` | string | Yes | `postgres` | Database password |
| `DB_DATABASE_NAME` | string | Yes | `immich` | Database name |
| `REDIS_HOSTNAME` | string | Yes | `127.0.0.1` | Redis/Valkey hostname |
| `REDIS_PORT` | string | Yes | `6379` | Redis/Valkey port |
| `NODE_ENV` | string | No | `production` | Node environment |
| `IMMICH_ENV` | string | No | `production` | Immich environment |
| `ct-callback-url` | string | No | - | Control Tower callback URL |
| `ct-deployment-id` | string | No | - | Deployment identifier |
| `ct-node-id` | string | No | - | Node identifier |

---

## Services

Immich snap includes multiple services:

### 1. Server Service
- **App**: `all-dev-immich.server`
- **Purpose**: Main API server and web interface
- **Port**: 3001
- **Dependencies**: PostgreSQL, Redis

### 2. PostgreSQL Service
- **App**: `all-dev-immich.postgresql`
- **Purpose**: Embedded PostgreSQL database
- **Port**: 5433
- **Data**: `$SNAP_COMMON/postgresql/database`

### 3. Machine Learning Service
- **App**: `all-dev-immich.ml`
- **Purpose**: AI-powered features (face recognition, object detection)
- **Dependencies**: Server service
- **Optimization**: CPU-only (no GPU required)

### 4. Database Creation Service
- **App**: `all-dev-immich.createdb`
- **Purpose**: One-shot service to initialize database
- **Runs**: Once on first start

---

## Post-Installation Setup

### 1. Enable Services

```bash
sudo snap start all-dev-immich.postgresql
sudo snap start all-dev-immich.createdb
sudo snap start all-dev-immich.server
sudo snap start all-dev-immich.ml
```

### 2. Access Web Interface

Navigate to: `http://<device-ip>:3001`

### 3. Create Admin Account

On first access, you'll be prompted to create an admin account.

### 4. Configure Mobile Apps

Download Immich mobile apps:
- iOS: App Store
- Android: Google Play Store

Connect to your server using: `http://<device-ip>:3001`

---

## Content Interfaces

### PostgreSQL Interface
- **Provider**: `dilyn-postgresql`
- **Content**: `pg-content`
- **Purpose**: PostgreSQL 16 binaries and libraries

### Graphics Interface
- **Provider**: `dilyn-jellyfin-ffmpeg`
- **Content**: `graphics-libs`
- **Purpose**: FFmpeg, OpenCL, and graphics runtimes for video transcoding

---

## Interface Connections Reference

### Required Plugs

| Plug | Purpose |
|------|---------|
| `postgresql` | PostgreSQL database access |
| `graphics-core22` | FFmpeg and graphics libraries |
| `network` | Network access |
| `network-bind` | Bind to network ports |
| `opengl` | GPU acceleration (optional) |
| `removable-media` | Access to external storage |
| `mount-observe` | Filesystem monitoring |

---

## Storage Configuration

### Media Storage

By default, Immich stores media in:
- `$SNAP_COMMON/upload` - User uploads
- `$SNAP_COMMON/library` - Organized library
- `$SNAP_COMMON/thumbs` - Thumbnails
- `$SNAP_COMMON/encoded-video` - Transcoded videos

### External Storage

To use external storage, connect the `removable-media` plug and configure paths in the web interface.

---

## Machine Learning Features

The ML service provides:
- **Face Recognition**: Automatic face detection and grouping
- **Object Detection**: Smart search by objects in photos
- **CLIP Search**: Natural language photo search
- **Smart Albums**: Automatic album creation

**Note**: ML models are downloaded on first run (~2GB). Ensure sufficient disk space.

---

## Video Transcoding

Immich uses FFmpeg for video transcoding:
- **Hardware Acceleration**: Supported via OpenCL (Intel/AMD)
- **Formats**: MP4, MOV, AVI, MKV, and more
- **Quality Profiles**: Configurable in web interface

---

## Backup and Restore

### Database Backup

```bash
sudo snap run all-dev-immich.postgresql pg_dump immich > immich_backup.sql
```

### Media Backup

```bash
sudo tar -czf immich_media.tar.gz $SNAP_COMMON/upload $SNAP_COMMON/library
```

### Restore

```bash
# Restore database
sudo snap run all-dev-immich.postgresql psql immich < immich_backup.sql

# Restore media
sudo tar -xzf immich_media.tar.gz -C /
```

---

## Performance Tuning

### Database Optimization

Edit PostgreSQL configuration:
```bash
sudo nano $SNAP_COMMON/postgresql/database/postgresql.conf
```

Recommended settings for 4GB+ RAM:
```
shared_buffers = 1GB
effective_cache_size = 3GB
maintenance_work_mem = 256MB
```

### ML Service Memory

The ML service uses mimalloc for better memory management. Monitor with:
```bash
sudo snap logs all-dev-immich.ml
```

---

## Troubleshooting

### Check Service Status

```bash
sudo snap services all-dev-immich
```

### View Logs

```bash
# Server logs
sudo snap logs all-dev-immich.server

# ML logs
sudo snap logs all-dev-immich.ml

# Database logs
sudo snap logs all-dev-immich.postgresql
```

### Database Connection Issues

Verify PostgreSQL is running:
```bash
sudo snap start all-dev-immich.postgresql
```

Check connection:
```bash
sudo snap run all-dev-immich.postgresql psql -h 127.0.0.1 -p 5433 -U postgres -d immich
```

---

## Security Considerations

- **HTTPS**: Use reverse proxy (Caddy, Nginx) for HTTPS
- **Database Password**: Change default PostgreSQL password
- **Network Access**: Restrict to trusted networks
- **User Management**: Enable multi-user mode and set strong passwords
- **Backup**: Regular backups of database and media

---

## Architecture Notes

- **Node.js 22**: Latest LTS version
- **Python 3**: For ML service
- **PostgreSQL 16**: Via content interface
- **FFmpeg**: Via graphics content interface
- **libvips**: For image processing
- **Sharp**: Node.js image library

---

## Notes

- Immich requires PostgreSQL 16 and Redis/Valkey
- ML service is CPU-optimized (no GPU required)
- First run downloads ML models (~2GB)
- Mobile apps available for iOS and Android
- Supports hardware-accelerated video transcoding
- Optimized for Ubuntu Core deployments
- Refresh mode: standard (services restart during updates)