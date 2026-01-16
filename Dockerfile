# Multi-stage build untuk optimasi ukuran image
FROM node:20-alpine AS deps
WORKDIR /app

# Install yarn
RUN npm install -g yarn

# Install dependencies
COPY package.json yarn.lock* ./
RUN yarn install --frozen-lockfile --production

# Build stage
FROM node:20-alpine AS builder
WORKDIR /app

# Install yarn
RUN npm install -g yarn

# Copy dependencies dari stage deps
COPY --from=deps /app/node_modules ./node_modules
COPY package.json yarn.lock* ./

# Install all dependencies (including dev dependencies untuk build)
RUN yarn install --frozen-lockfile

# Copy source code
COPY . .

# Build aplikasi
RUN yarn build

# Runtime stage
FROM node:20-alpine AS runtime
WORKDIR /app

ENV NODE_ENV=production

# Copy dependencies production
COPY --from=deps /app/node_modules ./node_modules
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/public ./public
COPY --from=builder /app/package.json ./package.json

# Expose port
EXPOSE 3000

# Start aplikasi
CMD ["yarn", "start"]
