# Docker Setup for Entangled Halogen Frontend

This guide explains how to build and run the Entangled Halogen Frontend using Docker.

## Prerequisites

- Docker (version 20.10 or higher)
- Docker Compose (optional, for easier management)

## Quick Start

### Using Docker Compose (Recommended)

1. **Build and start the container:**
   ```bash
   docker-compose up -d
   ```

2. **View the application:**
   Open your browser and navigate to `http://localhost:8080`

3. **View logs:**
   ```bash
   docker-compose logs -f
   ```

4. **Stop the container:**
   ```bash
   docker-compose down
   ```

### Using Docker CLI

1. **Build the image:**
   ```bash
   docker build -t entangled-halogen-frontend:latest .
   ```

2. **Run the container:**
   ```bash
   docker run -d \
     --name entangled-frontend \
     -p 8080:80 \
     --restart unless-stopped \
     entangled-halogen-frontend:latest
   ```

3. **View the application:**
   Open your browser and navigate to `http://localhost:8080`

4. **View logs:**
   ```bash
   docker logs -f entangled-frontend
   ```

5. **Stop and remove the container:**
   ```bash
   docker stop entangled-frontend
   docker rm entangled-frontend
   ```

## Docker Image Details

### Multi-Stage Build

The Dockerfile uses a multi-stage build for optimal image size:

- **Stage 1 (builder):** Uses Node.js 23.10.0 Alpine to build the application
- **Stage 2 (production):** Uses Node.js Alpine with Fastify to serve static files and BFF API

### Features

- ✅ Optimized for production with Fastify
- ✅ Multi-stage build for smaller image size
- ✅ Health checks configured
- ✅ Serves both frontend static files and BFF API endpoints
- ✅ SPA routing support

## Configuration

### Ports

- **Default:** Port 8080 (host) → Port 80 (container)
- **Custom:** Change the port mapping in `docker-compose.yml` or the docker run command:
  ```bash
  docker run -p 3000:80 entangled-halogen-frontend:latest
  ```

### Environment Variables

Currently, no environment variables are required. Add them in `docker-compose.yml` if needed:

```yaml
environment:
  - CUSTOM_VAR=value
```

## Deployment

### Production Deployment

For production deployment with SSL/TLS:

1. Use a reverse proxy (e.g., Traefik, Caddy, or Nginx Proxy Manager)
2. Configure SSL certificates
3. Update the port mappings accordingly

### Example with Traefik

```yaml
version: '3.8'

services:
  entangled-frontend:
    build: .
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.entangled.rule=Host(`your-domain.com`)"
      - "traefik.http.routers.entangled.entrypoints=websecure"
      - "traefik.http.routers.entangled.tls.certresolver=letsencrypt"
```

## Troubleshooting

### Build fails

If the build fails, ensure:
- Docker has enough resources (memory, disk space)
- Node.js version matches the requirement (v23.10.0)
- You have a stable internet connection for downloading dependencies

### Container won't start

Check logs:
```bash
docker logs entangled-frontend
```

### Health check fails

Verify the container is running:
```bash
docker ps
docker inspect entangled-frontend
```

## Development

For development, you might want to mount volumes for hot reloading:

```yaml
services:
  entangled-frontend-dev:
    build:
      context: .
      target: builder
    volumes:
      - ./src:/app/src
      - ./public:/app/public
    command: npm run dev
    ports:
      - "5173:5173"
```

## Maintenance

### Update the image

```bash
# Rebuild the image
docker-compose build

# Restart with the new image
docker-compose up -d
```

### Remove old images

```bash
docker image prune -f
```

## Performance

The production image includes:
- Fastify server serving static files and BFF API
- Health check endpoint
- Minimal Alpine Linux base

## Security

Security features included:
- Non-root Node.js process
- Minimal attack surface with Alpine Linux
- Environment variable configuration for sensitive data

