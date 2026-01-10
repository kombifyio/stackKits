import { Github, Heart } from 'lucide-react';

export function Footer() {
  return (
    <footer className="py-12 border-t border-slate-800">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex flex-col md:flex-row items-center justify-between gap-6">
          {/* Logo & Copyright */}
          <div className="flex items-center gap-4">
            <img src="/logo.png" alt="StackKits" className="h-8 w-8" />
            <div className="text-slate-400 text-sm">
              © {new Date().getFullYear()} StackKits. Open source under MIT License.
            </div>
          </div>

          {/* Links */}
          <div className="flex items-center gap-6">
            <a
              href="https://github.com/kombihq/stackkits"
              target="_blank"
              rel="noopener noreferrer"
              className="text-slate-400 hover:text-white transition-colors"
            >
              <Github className="w-5 h-5" />
            </a>
            <a
              href="https://github.com/kombihq/stackkits/blob/main/docs/architecture.md"
              target="_blank"
              rel="noopener noreferrer"
              className="text-slate-400 hover:text-white transition-colors text-sm"
            >
              Docs
            </a>
            <a
              href="https://github.com/kombihq/stackkits/blob/main/LICENSE"
              target="_blank"
              rel="noopener noreferrer"
              className="text-slate-400 hover:text-white transition-colors text-sm"
            >
              License
            </a>
          </div>

          {/* Made with love */}
          <div className="flex items-center gap-2 text-sm text-slate-500">
            Made with <Heart className="w-4 h-4 text-red-500" fill="currentColor" /> by the KombiStack Team
          </div>
        </div>
      </div>
    </footer>
  );
}
