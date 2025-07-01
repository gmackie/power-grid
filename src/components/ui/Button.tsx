import React from 'react';
import { cn } from '../../utils/cn';

interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'default' | 'outline' | 'secondary' | 'destructive';
  size?: 'sm' | 'md' | 'lg';
  children: React.ReactNode;
}

const Button: React.FC<ButtonProps> = ({
  variant = 'default',
  size = 'md',
  className,
  children,
  disabled,
  ...props
}) => {
  const baseClasses = [
    'inline-flex items-center justify-center font-medium transition-all duration-200',
    'focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-offset-game-background',
    'disabled:opacity-50 disabled:cursor-not-allowed',
    'select-none rounded-lg'
  ];

  const variantClasses = {
    default: [
      'bg-game-primary hover:bg-blue-600 text-white',
      'focus:ring-blue-500'
    ],
    outline: [
      'border border-slate-600 bg-transparent hover:bg-slate-800 text-white',
      'focus:ring-slate-500'
    ],
    secondary: [
      'bg-game-secondary hover:bg-green-600 text-white',
      'focus:ring-green-500'
    ],
    destructive: [
      'bg-red-600 hover:bg-red-700 text-white',
      'focus:ring-red-500'
    ]
  };

  const sizeClasses = {
    sm: 'px-3 py-1.5 text-sm min-h-[36px]',
    md: 'px-4 py-2 text-base min-h-[44px]',
    lg: 'px-6 py-3 text-lg min-h-[52px]'
  };

  return (
    <button
      className={cn(
        baseClasses,
        variantClasses[variant],
        sizeClasses[size],
        className
      )}
      disabled={disabled}
      {...props}
    >
      {children}
    </button>
  );
};

export default Button;