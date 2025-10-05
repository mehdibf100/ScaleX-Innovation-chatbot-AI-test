# Use official Node.js runtime
FROM node:18-alpine

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci

# Copy the rest of the app
COPY . .

# Generate Prisma client
RUN npx prisma generate

# Build TypeScript
RUN npm run build  
# Expose port
EXPOSE 3000

# Run the compiled JS
CMD ["node", "dist/index.js"]
