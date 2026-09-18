import type { Metadata } from 'next';
import './globals.css';

export const metadata: Metadata = {
  title: 'The Lab — Training Management',
  description: 'Teacher training, trainee progress, and trainer monitoring for The Lab Indonesia',
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body className="min-h-screen bg-background antialiased">{children}</body>
    </html>
  );
}
