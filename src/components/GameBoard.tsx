import React, { useRef, useEffect, useState } from 'react';
import { City, Player } from '../types/game';
import { useDeviceStore } from '../store/gameStore';
import { MapPin, Home } from 'lucide-react';
import { cn } from '../utils/cn';

interface GameBoardProps {
  cities: City[];
  selectedCity: City | null;
  hoveredCity: City | null;
  onCityClick: (city: City) => void;
  onCityHover: (city: City | null) => void;
  currentPlayer?: Player;
}

const GameBoard: React.FC<GameBoardProps> = ({
  cities,
  selectedCity,
  hoveredCity,
  onCityClick,
  onCityHover,
  currentPlayer
}) => {
  const { isMobile } = useDeviceStore();
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const [dimensions, setDimensions] = useState({ width: 800, height: 600 });
  
  // Handle resize
  useEffect(() => {
    const handleResize = () => {
      if (canvasRef.current?.parentElement) {
        const rect = canvasRef.current.parentElement.getBoundingClientRect();
        setDimensions({
          width: rect.width,
          height: Math.min(rect.width * 0.75, 600) // Maintain aspect ratio
        });
      }
    };
    
    handleResize();
    window.addEventListener('resize', handleResize);
    return () => window.removeEventListener('resize', handleResize);
  }, []);
  
  // Draw board
  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    
    const ctx = canvas.getContext('2d');
    if (!ctx) return;
    
    // Clear canvas
    ctx.clearRect(0, 0, dimensions.width, dimensions.height);
    
    // Draw background
    ctx.fillStyle = '#1e293b';
    ctx.fillRect(0, 0, dimensions.width, dimensions.height);
    
    // Draw connections
    ctx.strokeStyle = '#475569';
    ctx.lineWidth = 2;
    
    cities.forEach(city => {
      city.connections.forEach(connection => {
        const targetCity = cities.find(c => c.id === connection.to);
        if (targetCity) {
          ctx.beginPath();
          ctx.moveTo(city.x * dimensions.width, city.y * dimensions.height);
          ctx.lineTo(targetCity.x * dimensions.width, targetCity.y * dimensions.height);
          ctx.stroke();
          
          // Draw connection cost
          const midX = (city.x + targetCity.x) / 2 * dimensions.width;
          const midY = (city.y + targetCity.y) / 2 * dimensions.height;
          
          ctx.fillStyle = '#0f172a';
          ctx.fillRect(midX - 15, midY - 10, 30, 20);
          
          ctx.fillStyle = '#cbd5e1';
          ctx.font = '12px sans-serif';
          ctx.textAlign = 'center';
          ctx.textBaseline = 'middle';
          ctx.fillText(`$${connection.cost}`, midX, midY);
        }
      });
    });
    
    // Draw cities
    cities.forEach(city => {
      const x = city.x * dimensions.width;
      const y = city.y * dimensions.height;
      const radius = isMobile ? 20 : 15;
      
      // Highlight if selected or hovered
      if (city === selectedCity) {
        ctx.fillStyle = '#3b82f6';
        ctx.beginPath();
        ctx.arc(x, y, radius + 5, 0, Math.PI * 2);
        ctx.fill();
      } else if (city === hoveredCity) {
        ctx.fillStyle = '#6366f1';
        ctx.beginPath();
        ctx.arc(x, y, radius + 3, 0, Math.PI * 2);
        ctx.fill();
      }
      
      // Draw city circle
      ctx.fillStyle = city.houses.length >= 3 ? '#ef4444' : '#10b981';
      ctx.beginPath();
      ctx.arc(x, y, radius, 0, Math.PI * 2);
      ctx.fill();
      
      // Draw houses
      if (city.houses.length > 0) {
        const houseSize = 8;
        city.houses.forEach((house, idx) => {
          const angle = (idx / 3) * Math.PI * 2 - Math.PI / 2;
          const hx = x + Math.cos(angle) * (radius - houseSize);
          const hy = y + Math.sin(angle) * (radius - houseSize);
          
          ctx.fillStyle = house.playerColor;
          ctx.fillRect(hx - houseSize/2, hy - houseSize/2, houseSize, houseSize);
        });
      }
      
      // Draw city name
      ctx.fillStyle = '#ffffff';
      ctx.font = `${isMobile ? '14px' : '12px'} sans-serif`;
      ctx.textAlign = 'center';
      ctx.textBaseline = 'top';
      ctx.fillText(city.name, x, y + radius + 5);
    });
    
  }, [cities, selectedCity, hoveredCity, dimensions, isMobile]);
  
  // Handle click
  const handleCanvasClick = (e: React.MouseEvent<HTMLCanvasElement>) => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    
    const rect = canvas.getBoundingClientRect();
    const x = (e.clientX - rect.left) / dimensions.width;
    const y = (e.clientY - rect.top) / dimensions.height;
    
    // Find clicked city
    const clickRadius = isMobile ? 0.05 : 0.03; // Larger touch target on mobile
    
    const clickedCity = cities.find(city => {
      const dx = Math.abs(city.x - x);
      const dy = Math.abs(city.y - y);
      return Math.sqrt(dx * dx + dy * dy) < clickRadius;
    });
    
    if (clickedCity) {
      onCityClick(clickedCity);
    }
  };
  
  // Handle hover
  const handleCanvasMove = (e: React.MouseEvent<HTMLCanvasElement>) => {
    if (isMobile) return; // No hover on mobile
    
    const canvas = canvasRef.current;
    if (!canvas) return;
    
    const rect = canvas.getBoundingClientRect();
    const x = (e.clientX - rect.left) / dimensions.width;
    const y = (e.clientY - rect.top) / dimensions.height;
    
    const hoverRadius = 0.03;
    
    const hoveredCity = cities.find(city => {
      const dx = Math.abs(city.x - x);
      const dy = Math.abs(city.y - y);
      return Math.sqrt(dx * dx + dy * dy) < hoverRadius;
    });
    
    onCityHover(hoveredCity || null);
  };
  
  return (
    <div className="relative">
      <canvas
        ref={canvasRef}
        width={dimensions.width}
        height={dimensions.height}
        className="w-full cursor-pointer rounded-lg"
        onClick={handleCanvasClick}
        onMouseMove={handleCanvasMove}
        onMouseLeave={() => onCityHover(null)}
      />
      
      {/* Legend */}
      <div className="absolute bottom-4 left-4 bg-game-surface/90 backdrop-blur-sm rounded-lg p-3">
        <div className="space-y-2 text-xs">
          <div className="flex items-center gap-2">
            <div className="w-4 h-4 bg-green-500 rounded-full" />
            <span className="text-slate-300">Available City</span>
          </div>
          <div className="flex items-center gap-2">
            <div className="w-4 h-4 bg-red-500 rounded-full" />
            <span className="text-slate-300">Full City (3 houses)</span>
          </div>
          <div className="flex items-center gap-2">
            <div className="w-4 h-4 bg-blue-500 rounded-full" />
            <span className="text-slate-300">Selected City</span>
          </div>
        </div>
      </div>
      
      {/* Selected City Info */}
      {selectedCity && (
        <div className="absolute top-4 right-4 bg-game-surface/90 backdrop-blur-sm rounded-lg p-3 max-w-xs">
          <h4 className="font-semibold text-white mb-1">{selectedCity.name}</h4>
          <p className="text-xs text-slate-400 mb-2">
            {selectedCity.region} • {selectedCity.houses.length}/3 houses
          </p>
          
          {selectedCity.houses.length > 0 && (
            <div className="flex items-center gap-1 flex-wrap">
              {selectedCity.houses.map((house, idx) => (
                <div
                  key={idx}
                  className="w-6 h-6 rounded border border-white flex items-center justify-center"
                  style={{ backgroundColor: house.playerColor }}
                >
                  <Home className="w-3 h-3 text-white" />
                </div>
              ))}
            </div>
          )}
        </div>
      )}
    </div>
  );
};

export default GameBoard;