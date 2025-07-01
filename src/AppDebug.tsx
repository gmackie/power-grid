import React from 'react';

function AppDebug() {
  return (
    <div style={{ padding: '20px', fontFamily: 'monospace' }}>
      <h1>React App is Loading!</h1>
      <p>If you see this, React is working.</p>
      <p>Time: {new Date().toLocaleTimeString()}</p>
      
      <div style={{ marginTop: '20px', padding: '10px', background: '#f0f0f0' }}>
        <h2>Debug Info:</h2>
        <p>Vite HMR: {import.meta.hot ? 'Enabled' : 'Disabled'}</p>
        <p>Environment: {import.meta.env.MODE}</p>
        <p>Base URL: {import.meta.env.BASE_URL}</p>
      </div>
      
      <div style={{ marginTop: '20px' }}>
        <button onClick={() => alert('Button clicked!')}>
          Test Button
        </button>
      </div>
    </div>
  );
}

export default AppDebug;