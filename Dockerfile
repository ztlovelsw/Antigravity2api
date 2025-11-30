# Multi-stage build to produce a lightweight runtime image
FROM node:18-slim AS builder
WORKDIR /app

# Install backend dependencies first to leverage Docker layer caching
COPY package.json package-lock.json ./
RUN npm ci

# Install frontend dependencies separately so the build step does not need to
# re-download packages each time
COPY client/package.json client/package-lock.json ./client/
RUN npm ci --prefix client

# Copy the full source for the actual build
COPY . .

# Build the React admin console (outputs to client/dist)
RUN npm run build --prefix client

FROM node:18-slim AS runner
WORKDIR /app
ENV NODE_ENV=production

# Install only production dependencies
COPY package.json package-lock.json ./
RUN npm ci --omit=dev

# Copy server code and pre-built frontend assets from the builder
COPY --from=builder /app/src ./src
COPY --from=builder /app/config.json ./config.json
COPY --from=builder /app/scripts ./scripts
COPY --from=builder /app/public ./public
COPY --from=builder /app/client/dist ./client/dist

# Ensure data directories can be mounted as volumes
VOLUME ["/app/data", "/app/uploads"]

EXPOSE 8045
CMD ["npm", "start"]
