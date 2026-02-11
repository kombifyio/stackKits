import { Link } from 'react-router-dom';
import { Github, Mail, Heart } from 'lucide-react';

export function Footer() {
  const currentYear = new Date().getFullYear();

  return (
    <footer className="bg-gray-900 text-gray-300">
      <div className="container-custom section-padding">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-8 mb-8">
          {/* Brand */}
          <div className="md:col-span-2">
            <div className="flex items-center space-x-2 mb-4">
              <img src="/logo.png" alt="StackKits" className="h-8 w-auto" />
              <span className="text-xl font-bold text-white">StackKits</span>
            </div>
            <p className="text-gray-400 max-w-md">
              Declarative infrastructure blueprints for homelab and self-hosted deployments. 
              Build your perfect infrastructure with validated configurations.
            </p>
          </div>

          {/* Quick Links */}
          <div>
            <h3 className="text-white font-semibold mb-4">Quick Links</h3>
            <ul className="space-y-2">
              <li>
                <Link to="/overview" className="hover:text-orange-400 transition-colors">
                  Overview
                </Link>
              </li>
              <li>
                <Link to="/how-it-works" className="hover:text-orange-400 transition-colors">
                  How it Works
                </Link>
              </li>
              <li>
                <Link to="/requirements" className="hover:text-orange-400 transition-colors">
                  Requirements
                </Link>
              </li>
              <li>
                <Link to="/architecture" className="hover:text-orange-400 transition-colors">
                  Architecture
                </Link>
              </li>
              <li>
                <Link to="/special" className="hover:text-orange-400 transition-colors">
                  What Makes StackKits Special
                </Link>
              </li>
              <li>
                <Link to="/get-started" className="hover:text-orange-400 transition-colors">
                  Get Started
                </Link>
              </li>
            </ul>
          </div>

          {/* Contact */}
          <div>
            <h3 className="text-white font-semibold mb-4">Connect</h3>
            <div className="space-y-3">
              <a
                href="https://github.com/stackkits"
                target="_blank"
                rel="noopener noreferrer"
                className="flex items-center space-x-2 hover:text-primary-400 transition-colors"
              >
                <Github size={18} />
                <span>GitHub</span>
              </a>
              <a
                href="mailto:hello@stackkits.dev"
                className="flex items-center space-x-2 hover:text-primary-400 transition-colors"
              >
                <Mail size={18} />
                <span>Email Us</span>
              </a>
            </div>
          </div>
        </div>

        {/* Bottom Bar */}
        <div className="border-t border-gray-800 pt-8 flex flex-col md:flex-row justify-between items-center">
          <p className="text-sm text-gray-500">
            © {currentYear} StackKits. All rights reserved.
          </p>
          <p className="text-sm text-gray-500 flex items-center space-x-1 mt-4 md:mt-0">
            <span>Made with</span>
            <Heart size={14} className="text-red-500 fill-red-500" />
            <span>for the homelab community</span>
          </p>
        </div>
      </div>
    </footer>
  );
}
