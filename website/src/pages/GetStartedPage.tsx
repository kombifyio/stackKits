import { useState } from 'react';
import { motion } from 'framer-motion';
import { Copy, Check, Terminal, ArrowRight, Github, Zap } from 'lucide-react';
import { Link } from 'react-router-dom';

const quickStartSteps = [
  {
    number: '01',
    title: 'Prepare your environment',
    command: 'stackkit prepare',
    description: 'Validates dependencies and sets up your local environment.'
  },
  {
    number: '02',
    title: 'Initialize your homelab',
    command: 'stackkit init',
    description: 'Deploys your complete infrastructure - that\'s it!'
  }
];

const detailedSteps = [
  {
    number: '01',
    title: 'Clone the repository',
    command: 'git clone https://github.com/kombihq/stackkits.git\ncd stackkits'
  },
  {
    number: '02',
    title: 'Copy the default spec',
    command: 'cp base-homelab/default-spec.yaml my-spec.yaml'
  },
  {
    number: '03',
    title: 'Configure your server',
    command: '# Edit my-spec.yaml\n# Set your server IP, SSH credentials, and domain'
  },
  {
    number: '04',
    title: 'Validate your configuration',
    command: 'stackkit validate my-spec.yaml'
  },
  {
    number: '05',
    title: 'Deploy',
    command: 'stackkit apply my-spec.yaml'
  }
];

function CodeBlock({ command }: { command: string }) {
  const [copied, setCopied] = useState(false);

  const handleCopy = () => {
    navigator.clipboard.writeText(command);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  return (
    <div className="relative group">
      <pre className="bg-gray-900 text-gray-100 rounded-lg p-4 font-mono text-sm overflow-x-auto">
        {command}
      </pre>
      <button
        onClick={handleCopy}
        className="absolute top-2 right-2 p-2 rounded-lg bg-gray-800 hover:bg-gray-700 opacity-0 group-hover:opacity-100 transition-opacity"
      >
        {copied ? (
          <Check className="w-4 h-4 text-green-400" />
        ) : (
          <Copy className="w-4 h-4 text-gray-400" />
        )}
      </button>
    </div>
  );
}

export function GetStartedPage() {
  const [showDetailed, setShowDetailed] = useState(false);

  return (
    <div className="bg-white min-h-screen">
      {/* Header */}
      <section className="py-16 bg-gray-50">
        <div className="max-w-6xl mx-auto px-6">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            className="text-center"
          >
            <h1 className="text-4xl font-bold text-gray-900">Get Started</h1>
            <p className="mt-4 text-lg text-gray-600 max-w-2xl mx-auto">
              From zero to running homelab in two simple commands.
            </p>
          </motion.div>
        </div>
      </section>

      {/* Core Message */}
      <section className="py-12 bg-gradient-to-r from-orange-50 to-orange-100">
        <div className="max-w-4xl mx-auto px-6 text-center">
          <motion.div
            initial={{ opacity: 0, scale: 0.95 }}
            animate={{ opacity: 1, scale: 1 }}
            transition={{ delay: 0.2 }}
          >
            <Zap className="w-12 h-12 text-orange-500 mx-auto mb-4" />
            <h2 className="text-3xl font-bold text-gray-900 mb-4">
              Run One Command. Your Homelab Stands.
            </h2>
            <p className="text-lg text-gray-700">
              That's our vision: A CLI tool that makes infrastructure deployment as simple as possible.
            </p>
          </motion.div>
        </div>
      </section>

      {/* Quick Start - The Vision */}
      <section className="py-16">
        <div className="max-w-4xl mx-auto px-6">
          <div className="text-center mb-12">
            <h2 className="text-2xl font-bold text-gray-900 mb-4">The Simple Way (Vision)</h2>
            <p className="text-gray-600">
              Our goal: Two commands to deploy your entire homelab.
            </p>
          </div>

          <div className="grid md:grid-cols-2 gap-6 mb-12">
            {quickStartSteps.map((step, index) => (
              <motion.div
                key={step.number}
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: index * 0.1 }}
                className="bg-white rounded-xl border-2 border-orange-200 p-8 text-center"
              >
                <div className="text-5xl font-bold text-orange-200 mb-4">{step.number}</div>
                <h3 className="text-xl font-semibold text-gray-900 mb-3">{step.title}</h3>
                <div className="bg-gray-900 text-gray-100 rounded-lg p-4 mb-4 font-mono text-sm">
                  $ {step.command}
                </div>
                <p className="text-gray-600 text-sm">{step.description}</p>
              </motion.div>
            ))}
          </div>

          <div className="text-center">
            <button
              onClick={() => setShowDetailed(!showDetailed)}
              className="text-orange-500 hover:text-orange-600 font-medium"
            >
              {showDetailed ? '↑ Hide detailed steps' : '↓ Show current detailed steps'}
            </button>
          </div>
        </div>
      </section>

      {/* Detailed Steps */}
      {showDetailed && (
        <section className="py-16 bg-gray-50">
          <div className="max-w-3xl mx-auto px-6">
            <div className="text-center mb-12">
              <h2 className="text-2xl font-bold text-gray-900 mb-4">Current Process</h2>
              <p className="text-gray-600">
                Here's how it works today - we're working towards simplifying this.
              </p>
            </div>

            <div className="space-y-6">
              {detailedSteps.map((step, index) => (
                <motion.div
                  key={step.number}
                  initial={{ opacity: 0, x: -20 }}
                  animate={{ opacity: 1, x: 0 }}
                  transition={{ delay: index * 0.1 }}
                  className="bg-white rounded-xl p-8 card-shadow flex gap-6"
                >
                  <div className="flex-shrink-0">
                    <div className="w-12 h-12 rounded-full bg-orange-100 flex items-center justify-center">
                      <span className="text-orange-500 font-bold">{step.number}</span>
                    </div>
                  </div>
                  <div className="flex-1">
                    <h3 className="text-xl font-semibold text-gray-900 mb-3">{step.title}</h3>
                    <CodeBlock command={step.command} />
                  </div>
                </motion.div>
              ))}
            </div>

            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.6 }}
              className="mt-12 bg-orange-50 rounded-xl p-8 text-center"
            >
              <Terminal className="w-12 h-12 text-orange-500 mx-auto mb-4" />
              <h3 className="text-xl font-semibold text-gray-900 mb-2">Need Help?</h3>
              <p className="text-gray-600 mb-6">
                Check the documentation or join our community for support.
              </p>
              <a
                href="https://github.com/kombihq/stackkits"
                target="_blank"
                rel="noopener noreferrer"
                className="inline-flex items-center gap-2 bg-orange-500 hover:bg-orange-600 text-white px-6 py-3 rounded-lg font-medium transition-colors"
              >
                <Github className="w-5 h-5" />
                View on GitHub
                <ArrowRight className="w-4 h-4" />
              </a>
            </motion.div>
          </div>
        </section>
      )}

      {/* Why StackKits */}
      <section className="py-16">
        <div className="max-w-6xl mx-auto px-6">
          <div className="text-center mb-12">
            <h2 className="text-3xl font-bold text-gray-900 mb-4">Why StackKits?</h2>
          </div>

          <div className="grid md:grid-cols-3 gap-8">
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.1 }}
              className="text-center"
            >
              <div className="bg-orange-100 w-16 h-16 rounded-full flex items-center justify-center mx-auto mb-4">
                <Zap className="w-8 h-8 text-orange-500" />
              </div>
              <h3 className="text-xl font-semibold text-gray-900 mb-2">Lightning Fast</h3>
              <p className="text-gray-600">
                Deploy complex infrastructure in minutes, not hours or days.
              </p>
            </motion.div>

            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.2 }}
              className="text-center"
            >
              <div className="bg-orange-100 w-16 h-16 rounded-full flex items-center justify-center mx-auto mb-4">
                <Terminal className="w-8 h-8 text-orange-500" />
              </div>
              <h3 className="text-xl font-semibold text-gray-900 mb-2">Simple CLI</h3>
              <p className="text-gray-600">
                No complex configurations. Just simple, intuitive commands.
              </p>
            </motion.div>

            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.3 }}
              className="text-center"
            >
              <div className="bg-orange-100 w-16 h-16 rounded-full flex items-center justify-center mx-auto mb-4">
                <Github className="w-8 h-8 text-orange-500" />
              </div>
              <h3 className="text-xl font-semibold text-gray-900 mb-2">Open Source</h3>
              <p className="text-gray-600">
                Community-driven, transparent, and free to use and modify.
              </p>
            </motion.div>
          </div>
        </div>
      </section>

      {/* CTA */}
      <section className="py-16 bg-gray-900">
        <div className="max-w-4xl mx-auto px-6 text-center">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
          >
            <h2 className="text-3xl font-bold text-white mb-4">Ready to Start?</h2>
            <p className="text-gray-400 mb-8">
              Join hundreds of developers building better homelabs with StackKits.
            </p>
            <Link
              to="/how-it-works"
              className="inline-flex items-center gap-2 bg-orange-500 hover:bg-orange-600 text-white px-8 py-4 rounded-lg font-medium transition-colors"
            >
              Learn How It Works
              <ArrowRight className="w-5 h-5" />
            </Link>
          </motion.div>
        </div>
      </section>
    </div>
  );
}
