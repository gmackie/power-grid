import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import './index.css'
import App from './App.tsx'

console.log('Main.tsx is loading...');

const rootElement = document.getElementById('root');
if (!rootElement) {
  console.error('Root element not found!');
} else {
  console.log('Root element found, creating React root...');

  // Add app-loaded class to hide the loading spinner
  document.body.classList.add('app-loaded');

  createRoot(rootElement).render(
    <StrictMode>
      <App />
    </StrictMode>,
  );

  console.log('React app rendered!');
}
