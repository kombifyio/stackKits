import { motion } from 'framer-motion';
import { ExternalLink, HelpCircle, Server, Cpu } from 'lucide-react';

interface Requirement {
  name: string;
  version: string;
  required: boolean;
  description: string;
  downloadUrl: string;
  icon: string;
}

const softwareRequirements: Requirement[] = [
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

const hardwareRequirements = {
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
  { name: 'Ubuntu 24.04 LTS', recommended: true },
  { name: 'Ubuntu 22.04 LTS', recommended: false },
  { name: 'Debian 12', recommended: false }
];

export function RequirementsPage() {
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
            <h1 className="text-4xl font-bold text-gray-900">Technical Requirements</h1>
            <p className="mt-4 text-lg text-gray-600 max-w-2xl mx-auto">
              Minimal dependencies. Maximum flexibility. Everything runs on standard hardware.
            </p>
          </motion.div>
        </div>
      </section>

      {/* Requirements Content */}
      <section className="py-16">
        <div className="max-w-6xl mx-auto px-6">
          <div className="grid lg:grid-cols-2 gap-12">
            {/* Software Requirements */}
            <div>
              <h2 className="text-2xl font-bold text-gray-900 mb-8 flex items-center gap-3">
                <Server className="w-6 h-6 text-orange-500" />
                Software Dependencies
              </h2>
              
              <div className="space-y-4">
                {softwareRequirements.map((req, index) => (
                  <motion.div
                    key={req.name}
                    initial={{ opacity: 0, y: 20 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ delay: index * 0.1 }}
                    className="bg-white rounded-xl border border-gray-100 p-6 card-shadow"
                  >
                    <div className="flex items-start gap-4">
                      <span className="text-3xl">{req.icon}</span>
                      <div className="flex-grow">
                        <div className="flex items-center gap-3 mb-2">
                          <h3 className="font-semibold text-gray-900">{req.name}</h3>
                          <span className="text-sm text-gray-500">{req.version}</span>
                          <span className={`px-2 py-0.5 rounded text-xs font-medium ${
                            req.required
                              ? 'bg-orange-100 text-orange-700'
                              : 'bg-gray-100 text-gray-500'
                          }`}>
                            {req.required ? 'Required' : 'Optional'}
                          </span>
                        </div>
                        <p className="text-sm text-gray-600 mb-3">{req.description}</p>
                        <a
                          href={req.downloadUrl}
                          target="_blank"
                          rel="noopener"
                          className="inline-flex items-center gap-1 text-sm text-orange-500 hover:text-orange-600"
                        >
                          Install Guide <ExternalLink className="w-3 h-3" />
                        </a>
                      </div>
                    </div>
                  </motion.div>
                ))}
              </div>
            </div>

            {/* Hardware Requirements */}
            <div>
              <h2 className="text-2xl font-bold text-gray-900 mb-8 flex items-center gap-3">
                <Cpu className="w-6 h-6 text-orange-500" />
                Server Requirements
              </h2>

              {/* Hardware Specs */}
              <motion.div
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                className="bg-white rounded-xl border border-gray-100 p-6 card-shadow mb-6"
              >
                <div className="grid grid-cols-2 gap-8">
                  <div>
                    <h3 className="text-sm font-medium text-gray-400 uppercase tracking-wide mb-4">Minimum</h3>
                    <ul className="space-y-3">
                      <li className="flex items-center gap-2 text-gray-700">
                        <div className="w-2 h-2 rounded-full bg-orange-300"></div>
                        {hardwareRequirements.minimum.cpu}
                      </li>
                      <li className="flex items-center gap-2 text-gray-700">
                        <div className="w-2 h-2 rounded-full bg-orange-300"></div>
                        {hardwareRequirements.minimum.memory}
                      </li>
                      <li className="flex items-center gap-2 text-gray-700">
                        <div className="w-2 h-2 rounded-full bg-orange-300"></div>
                        {hardwareRequirements.minimum.disk}
                      </li>
                    </ul>
                  </div>
                  <div>
                    <h3 className="text-sm font-medium text-gray-400 uppercase tracking-wide mb-4">Recommended</h3>
                    <ul className="space-y-3">
                      <li className="flex items-center gap-2 text-gray-700">
                        <div className="w-2 h-2 rounded-full bg-orange-500"></div>
                        {hardwareRequirements.recommended.cpu}
                      </li>
                      <li className="flex items-center gap-2 text-gray-700">
                        <div className="w-2 h-2 rounded-full bg-orange-500"></div>
                        {hardwareRequirements.recommended.memory}
                      </li>
                      <li className="flex items-center gap-2 text-gray-700">
                        <div className="w-2 h-2 rounded-full bg-orange-500"></div>
                        {hardwareRequirements.recommended.disk}
                      </li>
                    </ul>
                  </div>
                </div>
              </motion.div>

              {/* Supported OS */}
              <motion.div
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.1 }}
                className="bg-white rounded-xl border border-gray-100 p-6 card-shadow"
              >
                <h3 className="text-sm font-medium text-gray-400 uppercase tracking-wide mb-4">Supported Operating Systems</h3>
                <ul className="space-y-3">
                  {supportedOS.map((os) => (
                    <li key={os.name} className="flex items-center justify-between">
                      <span className="text-gray-700">{os.name}</span>
                      {os.recommended && (
                        <span className="px-2 py-0.5 rounded text-xs font-medium bg-green-100 text-green-700">
                          Recommended
                        </span>
                      )}
                    </li>
                  ))}
                </ul>
              </motion.div>
            </div>
          </div>

          {/* Note */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.3 }}
            className="mt-12 bg-orange-50 rounded-xl border border-orange-100 p-6"
          >
            <div className="flex items-start gap-4">
              <HelpCircle className="w-6 h-6 text-orange-500 flex-shrink-0" />
              <div>
                <h4 className="font-semibold text-gray-900 mb-2">Note on Local Development</h4>
                <p className="text-gray-600 text-sm">
                  For local development and testing, you only need Docker and OpenTofu on your workstation.
                  Optional tools (Terramate, CUE) are only needed for advanced orchestration or custom schema development.
                  Your target server just needs SSH access and Docker.
                </p>
              </div>
            </div>
          </motion.div>
        </div>
      </section>
    </div>
  );
}
