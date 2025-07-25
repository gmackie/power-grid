# Power Grid Web Frontend Deployment Guide

This guide explains how to deploy the Power Grid React frontend to power-grid.gmac.io using the gmac-io-ci infrastructure.

## Architecture Overview

The Power Grid application is split into two separate deployments:
- **Frontend** (this repo): React web client at `power-grid.gmac.io`
- **Backend** (separate repo): Go WebSocket server at `ws.power-grid.gmac.io`

## Prerequisites

1. DNS A record for `power-grid.gmac.io` pointing to `5.78.92.8`
2. Repository pushed to Gitea at `ci.gmac.io` as `power-grid-web`
3. Gitea secrets configured:
   - `REGISTRY_USERNAME` - Gitea username
   - `REGISTRY_PASSWORD` - Gitea password/token
   - `KUBECONFIG` - Base64-encoded kubeconfig for K3s cluster

## Deployment Configuration

### Files Created

1. **React Client Dockerfile** (`react_client/Dockerfile`)
   - Multi-stage build with Node.js and nginx
   - Optimized for production with gzip and caching headers
   - No server proxy configuration (handled separately)

2. **Gitea Workflow** (`.gitea/workflows/deploy.yml`)
   - Builds React client Docker image only
   - Deploys to K3s with 2 replicas for high availability
   - Supports staging environments for PRs

3. **Environment Configuration** (`react_client/.env.production`)
   - Sets WebSocket URL to `wss://ws.power-grid.gmac.io`

## WebSocket Configuration

The React client automatically determines the WebSocket URL:
- **Production**: `wss://ws.power-grid.gmac.io`
- **Development**: `ws://localhost:5080/ws`
- **Custom**: Set `VITE_WS_URL` environment variable

Configuration in `src/services/websocket.ts`:
```typescript
const getWebSocketUrl = (): string => {
  if (import.meta.env.VITE_WS_URL) {
    return import.meta.env.VITE_WS_URL;
  }
  if (import.meta.env.PROD) {
    return 'wss://ws.power-grid.gmac.io';
  }
  const port = import.meta.env.VITE_WS_PORT || '5080';
  return `ws://localhost:${port}/ws`;
};
```

## Deployment Process

### Initial Setup

1. Push code to Gitea repository:
   ```bash
   git remote add gitea https://ci.gmac.io/YOUR_USERNAME/power-grid-web.git
   git push gitea main
   ```

2. The workflow will automatically:
   - Build React app with production optimizations
   - Create Docker image with nginx
   - Push to `ci.gmac.io/power-grid-web` registry
   - Deploy to K3s cluster
   - Configure SSL certificate via Let's Encrypt
   - Make available at https://power-grid.gmac.io

### Staging Deployments

Pull requests automatically deploy to staging URLs:
- `https://staging-pr-123.gmac.io`

### Resource Limits

The frontend is lightweight with conservative limits:
- **Memory**: 64Mi request, 128Mi limit
- **CPU**: 50m request, 100m limit
- **Replicas**: 2 for high availability

## Monitoring

Check deployment status:
```bash
kubectl get pods -n default
kubectl logs deployment/power-grid-web
kubectl describe ingress power-grid-web
```

## Troubleshooting

1. **WebSocket Connection Issues**
   - Verify ws.power-grid.gmac.io is accessible
   - Check browser console for connection errors
   - Ensure backend server is running

2. **Build Failures**
   - Check Gitea Actions tab for build logs
   - Verify all npm dependencies are listed
   - Check for TypeScript errors

3. **404 Errors on Refresh**
   - nginx is configured for SPA routing
   - All routes should redirect to index.html

## Local Development

```bash
cd react_client
npm install
npm run dev  # Starts on http://localhost:5173
```

For production build testing:
```bash
npm run build
npm run preview
```

Docker testing:
```bash
docker build -t power-grid-web .
docker run -p 8080:80 power-grid-web
```

## Next Steps

1. Deploy backend server to ws.power-grid.gmac.io
2. Configure DNS for both domains
3. Push to Gitea to trigger deployment
4. Monitor logs and performance