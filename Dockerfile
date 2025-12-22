# Multi-stage build for Entangled Halogen Frontend

# Stage 1: Build the application (supporting multi-arch)
ARG BUILDPLATFORM
ARG TARGETPLATFORM
ARG TARGETOS
ARG TARGETARCH
FROM --platform=$BUILDPLATFORM node:23.10.0 AS builder

# Helpful for debugging cross-builds
RUN echo "Building on $BUILDPLATFORM for $TARGETPLATFORM ($TARGETOS/$TARGETARCH)"

# Install required system dependencies (including build tools for native modules)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      git \
      curl \
      python3 \
      make \
      g++ \
      ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy package files
COPY package.json package-lock.json ./

# Install dependencies with network-friendly settings
RUN npm config set fetch-retries 5 && \
    npm config set fetch-retry-mintimeout 20000 && \
    npm config set fetch-retry-maxtimeout 120000 && \
    npm ci --prefer-offline --no-audit --unsafe-perm

# Copy source files
COPY . .

# Build the application
RUN npm run build

# Stage 2: Production server with Fastify only (multi-arch)
FROM node:23.10.0-alpine AS production

# Upgrade base OS packages to pick up security fixes
RUN apk -U --no-cache upgrade && \
    apk add --no-cache wget

# Set working directory
WORKDIR /app

# Create minimal package.json for BFF to avoid module type warning
RUN echo '{"type":"module"}' > package.json

# Install only BFF dependencies (not PureScript, vite, etc.)
RUN npm install --omit=dev --prefer-offline --no-audit \
    fastify@^5.1.0 \
    @fastify/cors@^10.0.1 \
    @fastify/http-proxy@^11.1.1 \
    @fastify/static@^8.0.1

# Copy built files from builder stage
COPY --from=builder /app/dist ./dist

# Copy BFF files
COPY bff/ ./bff/

# Copy PDFs directory for document serving
COPY pdfs/ ./pdfs/

# Copy start script
COPY bff/start.sh /app/start.sh
RUN chmod +x /app/start.sh

# Expose port 80 (Fastify serves everything)
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://localhost/health || exit 1

# Start Fastify server
CMD ["/app/start.sh"]

