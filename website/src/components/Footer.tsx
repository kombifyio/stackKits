import { Link } from 'react-router-dom';
import { Github } from 'lucide-react';

export function Footer() {
  return (
    <footer className="bg-gray-50 border-t border-gray-100">
      <div className="max-w-6xl mx-auto px-6 py-12">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-8">
          {/* Brand */}
          <div className="md:col-span-1">
            <Link to="/" className="flex items-center gap-3 mb-4">
              <img src="/logo.png" alt="StackKits" className="h-8 w-8" />
              <div className="flex flex-col">
                <span className="text-xs text-gray-400 leading-none">kombify</span>
                <span className="text-lg font-bold text-orange-500 leading-tight">stackKits</span>
              </div>
            </Link>
            <p className="text-sm text-gray-500">
              Declarative infrastructure blueprints for homelabs.
            </p>
          </div>

          {/* Links */}
          <div>
            <h4 className="font-semibold text-gray-800 mb-4">Product</h4>
            <ul className="space-y-2">
              <li><Link to="/overview" className="text-sm text-gray-500 hover:text-orange-500">Overview</Link></li>
              <li><Link to="/how-it-works" className="text-sm text-gray-500 hover:text-orange-500">How it Works</Link></li>
              <li><Link to="/requirements" className="text-sm text-gray-500 hover:text-orange-500">Requirements</Link></li>
            </ul>
          </div>

          <div>
            <h4 className="font-semibold text-gray-800 mb-4">Resources</h4>
            <ul className="space-y-2">
              <li><a href="https://github.com/kombihq/stackkits" target="_blank" rel="noopener" className="text-sm text-gray-500 hover:text-orange-500">Documentation</a></li>
              <li><a href="https://github.com/kombihq/stackkits" target="_blank" rel="noopener" className="text-sm text-gray-500 hover:text-orange-500">GitHub</a></li>
            </ul>
          </div>

          <div>
            <h4 className="font-semibold text-gray-800 mb-4">Legal</h4>
            <ul className="space-y-2">
              <li><a href="#" className="text-sm text-gray-500 hover:text-orange-500">Privacy Policy</a></li>
              <li><a href="#" className="text-sm text-gray-500 hover:text-orange-500">Terms</a></li>
            </ul>
          </div>
        </div>

        <div className="mt-12 pt-8 border-t border-gray-200 flex flex-col md:flex-row items-center justify-between gap-4">
          <p className="text-sm text-gray-400">
            © {new Date().getFullYear()} kombify stackKits. Open source under MIT License.
          </p>
          <a
            href="https://github.com/kombihq/stackkits"
            target="_blank"
            rel="noopener"
            className="flex items-center gap-2 text-gray-400 hover:text-orange-500 transition-colors"
          >
            <Github className="w-5 h-5" />
          </a>
        </div>
      </div>
    </footer>
  );
}
