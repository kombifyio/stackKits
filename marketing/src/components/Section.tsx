import { HTMLAttributes, forwardRef } from 'react';
import { cn } from '../lib/utils';

interface SectionProps extends HTMLAttributes<HTMLElement> {
  title?: string;
  description?: string;
  centered?: boolean;
}

export const Section = forwardRef<HTMLElement, SectionProps>(
  ({ className, title, description, centered = true, children, ...props }, ref) => {
    return (
      <section
        ref={ref as any}
        className={cn('section-padding', className)}
        {...props}
      >
        <div className="container-custom">
          {(title || description) && (
            <div className={cn('mb-16', centered && 'text-center')}>
              {title && (
                <h2 className="text-3xl md:text-4xl font-bold text-gray-900 mb-4">
                  {title}
                </h2>
              )}
              {description && (
                <p className="text-lg text-gray-600 max-w-2xl mx-auto">
                  {description}
                </p>
              )}
            </div>
          )}
          {children}
        </div>
      </section>
    );
  }
);

Section.displayName = 'Section';
