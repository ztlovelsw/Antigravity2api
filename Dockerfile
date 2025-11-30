# Multi-stage build to produce a lightweight runtime image
FROM node:18-slim AS builder
WORKDIR /app

# Install backend dependencies
COPY package.json package-lock.json ./
RUN npm ci

# Copy the rest of the source to build frontend assets
COPY . .

# Build the React admin console (outputs to client/dist)
RUN npm run build

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
