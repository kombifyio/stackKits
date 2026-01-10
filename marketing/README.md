# StackKits Marketing Website

The official marketing website for StackKits - declarative infrastructure blueprints for homelab and self-hosted deployments.

## Tech Stack

- **React 18** - UI library
- **TypeScript** - Type-safe JavaScript
- **Vite** - Build tool and dev server
- **Tailwind CSS** - Utility-first CSS framework
- **Lucide React** - Icon library
- **Docker** - Containerization and deployment

## Getting Started

### Prerequisites

- Node.js 20 or higher
- npm or yarn package manager

### Local Development

1. Install dependencies:
```bash
npm install
```

2. Start the development server:
```bash
npm run dev
```

3. Open your browser to `http://localhost:5173`

### Build for Production

```bash
npm run build
```

The built files will be in the `dist/` directory.

## Docker Deployment

### Quick Start with Docker Compose

The easiest way to run the website with Docker is using Docker Compose:

1. Build and start the container:
```bash
docker-compose up --build
```

2. Access the website at `http://localhost:3000`

3. To stop the container:
```bash
docker-compose down
```

### Building the Docker Image Manually

If you prefer to build the Docker image manually:

```bash
docker build -t stackkits-marketing .
docker run -p 3000:80 stackkits-marketing
```

### Docker Configuration

The Docker setup uses a multi-stage build:

- **Build Stage**: Uses Node.js 20 Alpine to build the React application
- **Production Stage**: Uses nginx Alpine to serve the static files

The nginx configuration includes:
- Gzip compression for static assets
- Security headers
- SPA routing support (for client-side navigation)
- Static asset caching
- Health check endpoint at `/health`

### Available Ports

The default Docker Compose setup maps port `3000` on the host to port `80` in the container. You can change this by modifying the `ports` section in `docker-compose.yml`:

```yaml
ports:
  - "8080:80"  # Change 8080 to your preferred port
```

### Health Check

The container includes a health check that monitors the `/health` endpoint. You can check the health status:

```bash
docker-compose ps
```

Or manually check the health endpoint:

```bash
curl http://localhost:3000/health
```

## Project Structure

```
marketing/
├── public/           # Static assets (images, etc.)
├── src/
│   ├── components/    # React components
│   ├── lib/          # Utility functions
│   ├── App.tsx        # Main app component
│   ├── main.tsx       # Application entry point
│   └── index.css      # Global styles
├── Dockerfile         # Docker build configuration
├── docker-compose.yml # Docker Compose configuration
├── nginx.conf        # nginx configuration for production
└── package.json      # Project dependencies
```

## Scripts

- `npm run dev` - Start development server
- `npm run build` - Build for production
- `npm run preview` - Preview production build locally
- `npm run lint` - Run ESLint

## Features

- Responsive design for mobile, tablet, and desktop
- Smooth scrolling navigation
- Modal popups for StackKit details
- Health check endpoint for monitoring
- Optimized production build with gzip compression

## License

See LICENSE file in the root directory.
