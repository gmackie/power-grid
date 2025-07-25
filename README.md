# Power Grid Web Frontend

[![Deploy Frontend](https://github.com/YOUR_USERNAME/power-grid-web/actions/workflows/deploy-frontend.yml/badge.svg)](https://github.com/YOUR_USERNAME/power-grid-web/actions/workflows/deploy-frontend.yml)

React-based web frontend for the Power Grid digital board game.

**Live Demo**: [https://power-grid.gmac.io](https://power-grid.gmac.io)

## Overview

This is the web frontend for Power Grid, a digital adaptation of the classic board game. It connects to a Go WebSocket server to provide real-time multiplayer gameplay.

## Features

- 🎮 Real-time multiplayer gameplay
- 🎨 Modern React UI with TypeScript
- 🔌 WebSocket communication for live updates
- 📱 Responsive design
- 🚀 Automatic deployments with GitHub Actions
- 🔒 SSL/TLS encryption

## Tech Stack

- **Frontend**: React 18, TypeScript, Vite
- **State Management**: Zustand
- **Styling**: Tailwind CSS
- **WebSocket**: Native WebSocket API
- **Deployment**: Docker, Kubernetes (K3s)
- **CI/CD**: GitHub Actions

## Development

### Prerequisites

- Node.js 18+
- npm or yarn

### Local Development

```bash
# Install dependencies
npm install

# Start development server
npm run dev

# Build for production
npm run build

# Preview production build
npm run preview

# Run linting
npm run lint
```

### Environment Variables

Create a `.env.local` file for local development:

```env
VITE_WS_URL=ws://localhost:5080/ws
VITE_WS_PORT=5080
```

In production, the app automatically connects to `wss://ws.power-grid.gmac.io`.

## Deployment

### Automatic Deployment

The application is automatically deployed when:
- **Production**: Push to `main` or `master` branch → https://power-grid.gmac.io
- **Staging**: Open a pull request → https://staging-pr-{number}.gmac.io

### Manual Deployment

1. Build the Docker image:
   ```bash
   docker build -t power-grid-web .
   ```

2. Run locally:
   ```bash
   docker run -p 8080:80 power-grid-web
   ```

### Required Secrets

Configure these GitHub secrets for deployment:
- `REGISTRY_USERNAME`: Gitea registry username
- `REGISTRY_PASSWORD`: Gitea registry password
- `KUBECONFIG`: Base64-encoded K3s kubeconfig

## Architecture

```
┌─────────────────────┐     ┌──────────────────────┐
│   React Frontend    │────▶│   WebSocket Server   │
│ power-grid.gmac.io  │     │ ws.power-grid.gmac.io│
└─────────────────────┘     └──────────────────────┘
         │                            │
         └────────────┬───────────────┘
                      │
                 ┌────▼────┐
                 │   K3s   │
                 │ Cluster │
                 └─────────┘
```

## Project Structure

```
src/
├── components/      # React components
│   ├── admin/      # Admin dashboard
│   ├── phases/     # Game phase components
│   ├── screens/    # Main screens
│   └── ui/         # Reusable UI components
├── hooks/          # Custom React hooks
├── services/       # API and WebSocket services
├── store/          # Zustand state management
├── types/          # TypeScript type definitions
└── utils/          # Utility functions
```

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.