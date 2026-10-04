import React, { useEffect, useRef, useState } from 'react';
import type { City } from '../types/game';

interface GameBoardProps {
  cities: City[];
  mapId?: string;
  selectedId?: string | null;
  /** Cities the player can build in now (drawn highlighted). */
  buildable?: ReadonlySet<string>;
  /** Cities outside the active regions (drawn faded). */
  outOfPlay?: ReadonlySet<string>;
  onSelect?: (city: City) => void;
}

const ASPECT = 3 / 4; // board art is 1600×1200; city x/y are normalised to it

/** Canvas map: sharp on high-DPI screens, tap-friendly hit areas, board art underneath. */
const GameBoard: React.FC<GameBoardProps> = ({ cities, mapId, selectedId, buildable, outOfPlay, onSelect }) => {
  const wrapRef = useRef<HTMLDivElement>(null);
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const [width, setWidth] = useState(0);
  const [art, setArt] = useState<HTMLImageElement | null>(null);
  const height = Math.round(width * ASPECT);

  useEffect(() => {
    if (!mapId) return;
    const img = new Image();
    img.onload = () => setArt(img);
    img.onerror = () => setArt(null);
    img.src = `/art/game/boards/${mapId}.svg`;
  }, [mapId]);

  useEffect(() => {
    const el = wrapRef.current;
    if (!el) return;
    const ro = new ResizeObserver(([entry]) => setWidth(Math.floor(entry.contentRect.width)));
    ro.observe(el);
    return () => ro.disconnect();
  }, []);

  const radius = Math.max(7, Math.min(13, width / 55));

  useEffect(() => {
    const canvas = canvasRef.current;
    const ctx = canvas?.getContext('2d');
    if (!canvas || !ctx || width === 0) return;
    const dpr = window.devicePixelRatio || 1;
    canvas.width = Math.round(width * dpr);
    canvas.height = Math.round(height * dpr);
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);

    ctx.fillStyle = '#1e293b';
    ctx.fillRect(0, 0, width, height);
    if (art) ctx.drawImage(art, 0, 0, width, height);

    const pos = (c: City) => [c.x * width, c.y * height] as const;
    const byId = new Map(cities.map((c) => [c.id, c]));

    // The board art already draws routes, costs and names; without it we draw our own.
    const plain = !art;

    // Connections (each edge once) with cost labels
    if (plain) {
    ctx.lineWidth = 1.5;
    ctx.font = `600 ${Math.max(9, radius * 0.85)}px system-ui, sans-serif`;
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    for (const c of cities) {
      for (const e of c.connections) {
        if (e.to < c.id) continue;
        const t = byId.get(e.to);
        if (!t) continue;
        const [x1, y1] = pos(c);
        const [x2, y2] = pos(t);
        const faded = outOfPlay?.has(c.id) || outOfPlay?.has(t.id);
        ctx.strokeStyle = faded ? 'rgba(71,85,105,0.35)' : 'rgba(30,41,59,0.85)';
        ctx.beginPath(); ctx.moveTo(x1, y1); ctx.lineTo(x2, y2); ctx.stroke();
        if (!faded && width >= 340) {
          const mx = (x1 + x2) / 2, my = (y1 + y2) / 2;
          ctx.fillStyle = 'rgba(15,23,42,0.85)';
          ctx.beginPath(); ctx.arc(mx, my, radius * 0.75, 0, Math.PI * 2); ctx.fill();
          ctx.fillStyle = '#e2e8f0';
          ctx.fillText(String(e.cost), mx, my);
        }
      }
    }
    }

    // Cities
    for (const c of cities) {
      const [x, y] = pos(c);
      const faded = outOfPlay?.has(c.id);
      ctx.globalAlpha = faded ? 0.35 : 1;
      if (c.id === selectedId) {
        ctx.fillStyle = '#60a5fa';
        ctx.beginPath(); ctx.arc(x, y, radius + 5, 0, Math.PI * 2); ctx.fill();
      } else if (buildable?.has(c.id)) {
        ctx.strokeStyle = '#4ade80';
        ctx.lineWidth = 3;
        ctx.beginPath(); ctx.arc(x, y, radius + 3, 0, Math.PI * 2); ctx.stroke();
      }
      if (plain || c.houses.length > 0) {
        ctx.fillStyle = '#f6efd9';
        ctx.strokeStyle = '#141414';
        ctx.lineWidth = 2;
        ctx.beginPath(); ctx.arc(x, y, radius, 0, Math.PI * 2); ctx.fill(); ctx.stroke();
      }
      // Houses as pie slices in owner colours
      c.houses.forEach((h, i) => {
        ctx.fillStyle = h.playerColor;
        ctx.beginPath();
        ctx.moveTo(x, y);
        ctx.arc(x, y, radius - 2, -Math.PI / 2 + (i * 2 * Math.PI) / 3, -Math.PI / 2 + ((i + 1) * 2 * Math.PI) / 3);
        ctx.closePath();
        ctx.fill();
      });
      if (plain && width >= 340) {
        ctx.font = `600 ${Math.max(9, radius * 0.8)}px system-ui, sans-serif`;
        ctx.lineWidth = 3;
        ctx.strokeStyle = 'rgba(15,23,42,0.9)';
        ctx.strokeText(c.name, x, y + radius + 8);
        ctx.fillStyle = '#ffffff';
        ctx.fillText(c.name, x, y + radius + 8);
      }
      ctx.globalAlpha = 1;
    }
  }, [cities, art, width, height, radius, selectedId, buildable, outOfPlay]);

  const handleTap = (e: React.PointerEvent<HTMLCanvasElement>) => {
    if (!onSelect) return;
    const rect = e.currentTarget.getBoundingClientRect();
    const px = e.clientX - rect.left;
    const py = e.clientY - rect.top;
    let best: City | undefined;
    let bestD = Math.max(22, radius * 2); // finger-sized hit area in CSS px
    for (const c of cities) {
      const d = Math.hypot(c.x * width - px, c.y * height - py);
      if (d < bestD) { best = c; bestD = d; }
    }
    if (best) onSelect(best);
  };

  return (
    <div ref={wrapRef} className="relative w-full" data-testid="game-board">
      <canvas
        ref={canvasRef}
        style={{ width, height, touchAction: 'manipulation' }}
        className="block rounded-lg"
        onPointerUp={handleTap}
        data-testid="city"
      />
    </div>
  );
};

export default GameBoard;
