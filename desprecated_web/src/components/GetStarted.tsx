import { useState } from 'react';
import { motion } from 'framer-motion';
import { Copy, Check, Terminal, FileText, Rocket, ArrowRight, Github } from 'lucide-react';

const steps = [
  {
    number: '01',
    title: 'Clone the repository',
    command: 'git clone https://github.com/kombihq/stackkits.git\ncd stackkits',
    description: 'Get the latest StackKits blueprints'
  },
  {
    number: '02',
    title: 'Copy the default spec',
    command: 'cp base-homelab/default-spec.yaml my-spec.yaml',
    description: 'Start with a ready-to-use template'
  },
  {
    number: '03',
    title: 'Configure your server',
    command: '# Edit my-spec.yaml\n# Set your server IP, SSH credentials, and domain',
    description: 'Customize for your environment'
  },
  {
    number: '04',
    title: 'Deploy',
    command: 'stackkit apply my-spec.yaml',
    description: 'One command to provision everything'
  }
];

function CodeBlock({ code, showCopy = true }: { code: string; showCopy?: boolean }) {
  const [copied, setCopied] = useState(false);

  const handleCopy = () => {
    navigator.clipboard.writeText(code.replace(/^#.*\n?/gm, '').trim());
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  return (
    <div className="relative group">
      <pre className="bg-slate-900/70 rounded-lg p-4 text-sm overflow-x-auto">
        <code className="text-emerald-400">{code}</code>
      </pre>
      {showCopy && (
        <button
          onClick={handleCopy}
          className="absolute top-2 right-2 p-2 rounded-lg bg-slate-700/50 opacity-0 group-hover:opacity-100 transition-opacity hover:bg-slate-700"
        >
          {copied ? (
            <Check className="w-4 h-4 text-emerald-400" />
          ) : (
            <Copy className="w-4 h-4 text-slate-400" />
          )}
        </button>
      )}
    </div>
  );
}

export function GetStarted() {
  return (
    <section id="get-started" className="py-24 relative">
      {/* Background */}
      <div className="absolute inset-0 bg-gradient-to-b from-transparent via-cyan-500/5 to-transparent"></div>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 relative">
        {/* Section Header */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          className="text-center mb-16"
        >
          <h2 className="text-4xl sm:text-5xl font-bold text-white mb-4">
            Get <span className="gradient-text">Started</span>
          </h2>
          <p className="text-lg text-slate-400 max-w-2xl mx-auto">
            From zero to running homelab in four simple steps. No complex setup required.
          </p>
        </motion.div>

        {/* Quick Start Steps */}
        <div className="max-w-3xl mx-auto mb-16">
          <div className="space-y-6">
            {steps.map((step, index) => (
              <motion.div
                key={step.number}
                initial={{ opacity: 0, x: -20 }}
                whileInView={{ opacity: 1, x: 0 }}
                viewport={{ once: true }}
                transition={{ delay: index * 0.1 }}
                className="glass rounded-xl p-6"
              >
                <div className="flex items-start gap-6">
                  <div className="flex-shrink-0">
                    <span className="text-3xl font-bold text-indigo-500/50">{step.number}</span>
                  </div>
                  <div className="flex-grow">
                    <h3 className="text-lg font-semibold text-white mb-2">{step.title}</h3>
                    <p className="text-sm text-slate-400 mb-4">{step.description}</p>
                    <CodeBlock code={step.command} />
                  </div>
                </div>
              </motion.div>
            ))}
          </div>
        </div>

        {/* Additional Resources */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-16"
        >
          <a
            href="https://github.com/kombihq/stackkits/blob/main/docs/cli-reference.md"
            target="_blank"
            rel="noopener noreferrer"
            className="glass rounded-xl p-6 group hover:border-indigo-500/50 border border-transparent transition-all"
          >
            <Terminal className="w-8 h-8 text-indigo-400 mb-4" />
            <h3 className="text-lg font-semibold text-white mb-2 group-hover:text-indigo-400 transition-colors">
              CLI Reference
            </h3>
            <p className="text-sm text-slate-400 mb-4">
              Complete command documentation for power users
            </p>
            <span className="text-indigo-400 text-sm flex items-center gap-1 group-hover:gap-2 transition-all">
              Read docs <ArrowRight className="w-4 h-4" />
            </span>
          </a>

          <a
            href="https://github.com/kombihq/stackkits/blob/main/docs/creating-stackkits.md"
            target="_blank"
            rel="noopener noreferrer"
            className="glass rounded-xl p-6 group hover:border-cyan-500/50 border border-transparent transition-all"
          >
            <FileText className="w-8 h-8 text-cyan-400 mb-4" />
            <h3 className="text-lg font-semibold text-white mb-2 group-hover:text-cyan-400 transition-colors">
              Create Your Own
            </h3>
            <p className="text-sm text-slate-400 mb-4">
              Build custom StackKits for your specific needs
            </p>
            <span className="text-cyan-400 text-sm flex items-center gap-1 group-hover:gap-2 transition-all">
              Learn more <ArrowRight className="w-4 h-4" />
            </span>
          </a>

          <a
            href="https://github.com/kombihq/stackkits/blob/main/DEFAULT_SPECS_README.md"
            target="_blank"
            rel="noopener noreferrer"
            className="glass rounded-xl p-6 group hover:border-emerald-500/50 border border-transparent transition-all"
          >
            <Rocket className="w-8 h-8 text-emerald-400 mb-4" />
            <h3 className="text-lg font-semibold text-white mb-2 group-hover:text-emerald-400 transition-colors">
              Spec Templates
            </h3>
            <p className="text-sm text-slate-400 mb-4">
              Ready-to-use configuration templates
            </p>
            <span className="text-emerald-400 text-sm flex items-center gap-1 group-hover:gap-2 transition-all">
              View templates <ArrowRight className="w-4 h-4" />
            </span>
          </a>
        </motion.div>

        {/* CTA */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          className="text-center"
        >
          <a
            href="https://github.com/kombihq/stackkits"
            target="_blank"
            rel="noopener noreferrer"
            className="inline-flex items-center gap-3 px-8 py-4 bg-gradient-to-r from-indigo-500 to-cyan-500 rounded-xl text-white font-semibold hover:shadow-lg hover:shadow-indigo-500/25 transition-all"
          >
            <Github className="w-5 h-5" />
            View on GitHub
            <ArrowRight className="w-5 h-5" />
          </a>
        </motion.div>
      </div>
    </section>
  );
}
