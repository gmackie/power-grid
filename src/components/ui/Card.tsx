import React from 'react';
import { cn } from '../../utils/cn';

interface CardProps extends React.HTMLAttributes<HTMLDivElement> {
  children: React.ReactNode;
}

const Card: React.FC<CardProps> = ({ className, children, ...props }) => {
  return (
    <div
      className={cn(
        'bg-game-card rounded-lg shadow-lg border border-slate-600',
        'backdrop-blur-sm',
        className
      )}
      {...props}
    >
      {children}
    </div>
  );
};

export default Card;