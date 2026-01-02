# Official Node image
FROM node:18-alpine

# Create app directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies (exact versions from lockfile)
RUN npm ci --quiet

# Copy source code
COPY . .

# Expose Angular port
EXPOSE 4200

# Start Angular dev server
# --host 0.0.0.0: makes it accessible from outside container
# --poll: fixes file watching issues in Docker/Jenkins
CMD ["npm", "start", "--", "--host", "0.0.0.0", "--poll=2000"]