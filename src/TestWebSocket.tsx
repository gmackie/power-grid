import React, { useEffect, useState } from 'react';

const TestWebSocket: React.FC = () => {
  const [status, setStatus] = useState('Not connected');
  const [messages, setMessages] = useState<string[]>([]);

  useEffect(() => {
    console.log('TestWebSocket: Attempting to connect to ws://localhost:4080/ws');
    const ws = new WebSocket('ws://localhost:4080/ws');

    ws.onopen = () => {
      console.log('TestWebSocket: Connected!');
      setStatus('Connected to ws://localhost:4080/ws');
      ws.send(JSON.stringify({
        type: 'CONNECT',
        data: { player_name: 'TestPlayer' }
      }));
    };

    ws.onmessage = (event) => {
      console.log('TestWebSocket: Received:', event.data);
      setMessages(prev => [...prev, event.data]);
    };

    ws.onerror = (error) => {
      console.error('TestWebSocket: Error:', error);
      setStatus('Error connecting');
    };

    ws.onclose = () => {
      console.log('TestWebSocket: Closed');
      setStatus('Disconnected');
    };

    return () => {
      ws.close();
    };
  }, []);

  return (
    <div style={{ padding: '20px', fontFamily: 'monospace' }}>
      <h2>WebSocket Test</h2>
      <p>Status: {status}</p>
      <h3>Messages:</h3>
      <div style={{ background: '#f0f0f0', padding: '10px', maxHeight: '200px', overflow: 'auto' }}>
        {messages.map((msg, i) => (
          <div key={i} style={{ marginBottom: '5px' }}>{msg}</div>
        ))}
      </div>
    </div>
  );
};

export default TestWebSocket;