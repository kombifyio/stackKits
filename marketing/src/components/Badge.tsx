import { HTMLAttributes, forwardRef } from 'react';
import { cn } from '../lib/utils';

type BadgeVariant = 'available' | 'planned' | 'required' | 'supported';

interface BadgeProps extends HTMLAttributes<HTMLSpanElement> {
  variant: BadgeVariant;
}

const variantStyles = {
  available: 'bg-orange-100 text-orange-700',
  planned: 'bg-gray-100 text-gray-700',
  required: 'bg-red-100 text-red-700',
  supported: 'bg-green-100 text-green-700',
};

export const Badge = forwardRef<HTMLSpanElement, BadgeProps>(
  ({ className, variant, children, ...props }, ref) => {
    return (
      <span
        ref={ref}
        className={cn(
          'px-3 py-1 rounded-full text-xs font-semibold',
          variantStyles[variant],
          className
        )}
        {...props}
      >
        {children}
      </span>
    );
  }
);

Badge.displayName = 'Badge';
