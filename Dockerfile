# Use a specific Node.js version for better reproducibility
FROM node:23.3.0-slim AS builder

# Install pnpm globally and install necessary build tools
RUN npm install -g pnpm@9.15.1 && \
    apt-get update && \
    apt-get install -y git python3 make g++ && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set Python 3 as the default python
RUN ln -s /usr/bin/python3 /usr/bin/python

# Set the working directory
WORKDIR /app

# Copy package files first for better caching
COPY package.json pnpm-lock.yaml ./

# Install dependencies with specific platform
RUN pnpm install --platform=linux --frozen-lockfile

# Copy the rest of the application code
COPY . .

# Build the project
RUN pnpm build

# Create a new stage for the final image
FROM node:23.3.0-slim

# Install runtime dependencies
RUN npm install -g pnpm@9.15.1 && \
    apt-get update && \
    apt-get install -y python3 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy built artifacts and production dependencies
COPY --from=builder /app/package.json /app/pnpm-lock.yaml ./
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/src ./src
COPY --from=builder /app/characters ./characters

# Set environment variable for production
ENV NODE_ENV=production

# Expose the port
EXPOSE 3000

# Set the command to run the application
CMD ["pnpm", "start"]
