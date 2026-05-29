# all-dev-immich

High performance self-hosted photo and video management solution

## Overview

Immich is a high-performance self-hosted photo and video management solution with machine learning-powered search, face recognition, and automatic organization.

## Features

- **Photo & Video Backup**: Mobile app backup
- **Machine Learning**: Face recognition, object detection
- **Smart Search**: Natural language photo search
- **Timeline & Albums**: Organized media management
- **Multi-User**: Support for multiple users
- **Mobile Apps**: iOS and Android apps

## Quick Start

### Installation

```bash
sudo snap install all-dev-immich
```

### Enable Services

```bash
sudo snap start all-dev-immich.postgresql
sudo snap start all-dev-immich.createdb
sudo snap start all-dev-immich.server
sudo snap start all-dev-immich.ml
```

### Access

Navigate to: `http://localhost:3001`

## Documentation

For complete deployment and configuration documentation, see:
- **[Deployment Guide](docs/deployment-guide.md)** - Complete setup and configuration guide

## Requirements

- PostgreSQL 16 (via content interface or external)
- Redis/Valkey (external service)
- FFmpeg (via graphics content interface)

## Configuration

Configure via snap settings:

```bash
# Database settings
sudo snap set all-dev-immich DB_HOSTNAME="127.0.0.1"
sudo snap set all-dev-immich DB_PORT="5433"

# Redis settings
sudo snap set all-dev-immich REDIS_HOSTNAME="127.0.0.1"
```

## Mobile Apps

Download Immich mobile apps:
- **iOS**: App Store
- **Android**: Google Play Store

Connect to: `http://<device-ip>:3001`

## Support

- **Issues**: Report issues on GitHub
- **Documentation**: See [docs/deployment-guide.md](docs/deployment-guide.md)
- **Community**: Immich Discord

## License

CC-BY-NC-SA-4.0 AND AGPL-3.0