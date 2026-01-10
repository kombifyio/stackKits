import { motion } from 'framer-motion';
import { HelpCircle, ExternalLink } from 'lucide-react';

interface Requirement {
  name: string;
  version: string;
  required: boolean;
  description: string;
  downloadUrl: string;
  icon: string;
}

const requirements: Requirement[] = [
  {
    name: 'Docker',
    version: '24.0+',
    required: true,
    description: 'Container runtime for running services',
    downloadUrl: 'https://docs.docker.com/get-docker/',
    icon: '🐳'
  },
  {
    name: 'OpenTofu',
    version: '1.6+',
    required: true,
    description: 'Infrastructure provisioning engine',
    downloadUrl: 'https://opentofu.org/docs/intro/install/',
    icon: '🔧'
  },
  {
    name: 'Terramate',
    version: '0.6+',
    required: false,
    description: 'Stack orchestration for advanced mode',
    downloadUrl: 'https://terramate.io/docs/cli/installation',
    icon: '📚'
  },
  {
    name: 'CUE',
    version: '0.9+',
    required: false,
    description: 'Schema development and local validation',
    downloadUrl: 'https://cuelang.org/docs/introduction/installation/',
    icon: '✨'
  }
];

const serverRequirements = {
  minimum: {
    cpu: '2 Cores',
    memory: '4 GB RAM',
    disk: '50 GB SSD'
  },
  recommended: {
    cpu: '4 Cores',
    memory: '8 GB RAM',
    disk: '100 GB SSD'
  }
};

const supportedOS = [
  { name: 'Ubuntu 24.04 LTS', status: 'recommended' },
  { name: 'Ubuntu 22.04 LTS', status: 'supported' },
  { name: 'Debian 12', status: 'supported' }
];

function RequirementCard({ req }: { req: Requirement }) {
  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      whileInView={{ opacity: 1, y: 0 }}
      viewport={{ once: true }}
      className="glass rounded-xl p-6 flex items-start gap-4"
    >
      <div className="text-4xl">{req.icon}</div>
      <div className="flex-grow">
        <div className="flex items-center gap-2 mb-1">
          <h3 className="text-lg font-semibold text-white">{req.name}</h3>
          <span className="text-sm text-slate-400">{req.version}</span>
          {req.required ? (
            <span className="px-2 py-0.5 rounded text-xs font-medium bg-indigo-500/20 text-indigo-400">Required</span>
          ) : (
            <span className="px-2 py-0.5 rounded text-xs font-medium bg-slate-500/20 text-slate-400">Optional</span>
          )}
        </div>
        <p className="text-sm text-slate-400 mb-3">{req.description}</p>
        <a
          href={req.downloadUrl}
          target="_blank"
          rel="noopener noreferrer"
          className="inline-flex items-center gap-1 text-sm text-indigo-400 hover:text-indigo-300 transition-colors"
        >
          Install Guide <ExternalLink className="w-3 h-3" />
        </a>
      </div>
    </motion.div>
  );
}

export function Requirements() {
  return (
    <section id="requirements" className="py-24 relative">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        {/* Section Header */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          className="text-center mb-16"
        >
          <h2 className="text-4xl sm:text-5xl font-bold text-white mb-4">
            Technical <span className="gradient-text">Requirements</span>
          </h2>
          <p className="text-lg text-slate-400 max-w-2xl mx-auto">
            Minimal dependencies. Maximum flexibility. Everything runs on standard hardware.
          </p>
        </motion.div>

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-8 mb-12">
          {/* Software Requirements */}
          <div>
            <h3 className="text-xl font-semibold text-white mb-6 flex items-center gap-2">
              <span className="w-8 h-8 rounded-lg bg-indigo-500/20 flex items-center justify-center text-indigo-400 text-sm">💻</span>
              Software Dependencies
            </h3>
            <div className="space-y-4">
              {requirements.map((req) => (
                <RequirementCard key={req.name} req={req} />
              ))}
            </div>
          </div>

          {/* Server Requirements */}
          <div>
            <h3 className="text-xl font-semibold text-white mb-6 flex items-center gap-2">
              <span className="w-8 h-8 rounded-lg bg-cyan-500/20 flex items-center justify-center text-cyan-400 text-sm">🖥️</span>
              Server Requirements
            </h3>

            {/* Hardware Specs */}
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              className="glass rounded-xl p-6 mb-6"
            >
              <div className="grid grid-cols-2 gap-6">
                <div>
                  <h4 className="text-sm font-medium text-slate-400 uppercase tracking-wide mb-4">Minimum</h4>
                  <ul className="space-y-3">
                    <li className="flex items-center gap-2 text-slate-300">
                      <div className="w-2 h-2 rounded-full bg-amber-400"></div>
                      {serverRequirements.minimum.cpu}
                    </li>
                    <li className="flex items-center gap-2 text-slate-300">
                      <div className="w-2 h-2 rounded-full bg-amber-400"></div>
                      {serverRequirements.minimum.memory}
                    </li>
                    <li className="flex items-center gap-2 text-slate-300">
                      <div className="w-2 h-2 rounded-full bg-amber-400"></div>
                      {serverRequirements.minimum.disk}
                    </li>
                  </ul>
                </div>
                <div>
                  <h4 className="text-sm font-medium text-slate-400 uppercase tracking-wide mb-4">Recommended</h4>
                  <ul className="space-y-3">
                    <li className="flex items-center gap-2 text-slate-300">
                      <div className="w-2 h-2 rounded-full bg-emerald-400"></div>
                      {serverRequirements.recommended.cpu}
                    </li>
                    <li className="flex items-center gap-2 text-slate-300">
                      <div className="w-2 h-2 rounded-full bg-emerald-400"></div>
                      {serverRequirements.recommended.memory}
                    </li>
                    <li className="flex items-center gap-2 text-slate-300">
                      <div className="w-2 h-2 rounded-full bg-emerald-400"></div>
                      {serverRequirements.recommended.disk}
                    </li>
                  </ul>
                </div>
              </div>
            </motion.div>

            {/* Supported OS */}
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              className="glass rounded-xl p-6"
            >
              <h4 className="text-sm font-medium text-slate-400 uppercase tracking-wide mb-4">Supported Operating Systems</h4>
              <ul className="space-y-3">
                {supportedOS.map((os) => (
                  <li key={os.name} className="flex items-center justify-between">
                    <span className="text-slate-300">{os.name}</span>
                    {os.status === 'recommended' ? (
                      <span className="px-2 py-0.5 rounded text-xs font-medium bg-emerald-500/20 text-emerald-400">Recommended</span>
                    ) : (
                      <span className="px-2 py-0.5 rounded text-xs font-medium bg-slate-500/20 text-slate-400">Supported</span>
                    )}
                  </li>
                ))}
              </ul>
            </motion.div>
          </div>
        </div>

        {/* Important Note */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          className="glass rounded-xl p-6 border border-amber-500/30"
        >
          <div className="flex items-start gap-4">
            <HelpCircle className="w-6 h-6 text-amber-400 flex-shrink-0 mt-0.5" />
            <div>
              <h4 className="text-white font-semibold mb-2">Note on Local Development</h4>
              <p className="text-slate-400 text-sm">
                For local development and testing, you only need Docker and OpenTofu installed on your workstation.
                The optional tools (Terramate, CUE) are only needed for advanced orchestration or custom schema development.
                Your target server just needs SSH access and Docker.
              </p>
            </div>
          </div>
        </motion.div>
      </div>
    </section>
  );
}
