# Multi-stage build for Entangled Halogen Frontend

# Stage 1: Build the application (supporting multi-arch)
ARG BUILDPLATFORM
ARG TARGETPLATFORM
ARG TARGETOS
ARG TARGETARCH
FROM --platform=$BUILDPLATFORM node:23.10.0-alpine AS builder

# Helpful for debugging cross-builds
RUN echo "Building on $BUILDPLATFORM for $TARGETPLATFORM ($TARGETOS/$TARGETARCH)"

# Install required system dependencies (including build tools for native modules)
RUN apk add --no-cache \
    git \
    curl \
    python3 \
    make \
    g++ \
    gcc \
    musl-dev \
    libc6-compat

# Set working directory
WORKDIR /app

# Copy package files
COPY package.json package-lock.json ./

# Install dependencies with network-friendly settings
RUN npm config set fetch-retries 5 && \
    npm config set fetch-retry-mintimeout 20000 && \
    npm config set fetch-retry-maxtimeout 120000 && \
    npm ci --prefer-offline --no-audit

# Copy source files
COPY . .

# Build the application
RUN npm run build

# Stage 2: Production server with nginx (multi-arch)
FROM --platform=$TARGETPLATFORM nginx:alpine AS production

# Copy custom nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy built files from builder stage
COPY --from=builder /app/dist /usr/share/nginx/html

# Expose port 80
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://localhost/ || exit 1

# Start nginx
CMD ["nginx", "-g", "daemon off;"]

