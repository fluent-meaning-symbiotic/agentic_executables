# Multi-stage Dockerfile for Prompts Framework MCP Server

# Build stage
FROM dart:stable AS build

# Set working directory
WORKDIR /app

# Copy pubspec files
COPY pubspec.yaml pubspec.lock* ./

# Download dependencies
RUN dart pub get

# Copy source code and resources
COPY . .

# Compile to native executable
RUN dart compile exe bin/prompts_framework_mcp_server.dart -o server

# Runtime stage
FROM debian:bookworm-slim AS runtime

# Install minimal runtime dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN useradd -r -u 1000 -m -s /bin/bash mcpserver

# Set working directory
WORKDIR /app

# Copy compiled binary from build stage
COPY --from=build --chown=mcpserver:mcpserver /app/server /app/server

# Copy resources directory
COPY --from=build --chown=mcpserver:mcpserver /app/resources /app/resources

# Switch to non-root user
USER mcpserver

# Set entrypoint to the compiled binary
ENTRYPOINT ["/app/server"]

# Expose STDIO for MCP communication
# Note: STDIO is the default transport, no ports needed

