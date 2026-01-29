import { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Server, Cloud, Shield, X, Check, ChevronRight } from 'lucide-react';

interface StackKit {
  id: string;
  name: string;
  tagline: string;
  description: string;
  icon: React.ReactNode;
  status: 'available' | 'planned';
  nodes: string;
  cloud: boolean;
  features: string[];
  services: string[];
}

const stackkits: StackKit[] = [
  {
    id: 'base-homelab',
    name: 'Base Homelab',
    tagline: 'Single-server, local-only',
    description: 'Single-server setup with Docker, reverse proxy, and monitoring. Everything you need for a professional homelab.',
    icon: <Server className="w-6 h-6" />,
    status: 'available',
    nodes: '1 Node',
    cloud: false,
    features: [
      'Docker-based deployments',
      'Traefik reverse proxy',
      'Automatic TLS certificates',
      'Uptime monitoring with Uptime Kuma',
      'Dokploy PaaS interface'
    ],
    services: ['Traefik', 'Dokploy', 'Uptime Kuma', 'Dozzle']
  },
  {
    id: 'modern-homelab',
    name: 'Modern Homelab',
    tagline: 'Local + Cloud hybrid',
    description: 'Multi-server hybrid setup that connects local and cloud infrastructure. Scale beyond your home network.',
    icon: <Cloud className="w-6 h-6" />,
    status: 'planned',
    nodes: '2+ Nodes',
    cloud: true,
    features: [
      'VPN overlay network',
      'Hybrid local/cloud nodes',
      'Coolify deployment platform',
      'Distributed storage',
      'Public access support'
    ],
    services: ['Headscale/Tailscale', 'Coolify', 'Prometheus', 'Grafana']
  },
  {
    id: 'ha-homelab',
    name: 'HA Homelab',
    tagline: 'Enterprise-grade reliability',
    description: 'High-availability Kubernetes cluster with automatic failover. Production-ready infrastructure at home.',
    icon: <Shield className="w-6 h-6" />,
    status: 'planned',
    nodes: '3+ Nodes',
    cloud: true,
    features: [
      'K3s Kubernetes cluster',
      'Automatic failover',
      'GitOps with Flux',
      'Distributed storage (Longhorn)',
      'Enterprise observability'
    ],
    services: ['K3s', 'Flux', 'Longhorn', 'Thanos', 'Velero']
  }
];

export function OverviewPage() {
  const [selectedKit, setSelectedKit] = useState<StackKit | null>(null);

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
            <h1 className="text-4xl font-bold text-gray-900">StackKits Overview</h1>
            <p className="mt-4 text-lg text-gray-600 max-w-2xl mx-auto">
              Three blueprints designed for different homelab needs. Start simple, scale when ready.
            </p>
          </motion.div>
        </div>
      </section>

      {/* StackKits Grid */}
      <section className="py-16">
        <div className="max-w-6xl mx-auto px-6">
          <div className="grid md:grid-cols-3 gap-8">
            {stackkits.map((kit, index) => (
              <motion.div
                key={kit.id}
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: index * 0.1 }}
                className="bg-white rounded-2xl border border-gray-100 p-8 card-shadow hover:card-shadow-hover transition-all cursor-pointer group"
                onClick={() => setSelectedKit(kit)}
              >
                {/* Status Badge */}
                <div className="flex items-center justify-between mb-6">
                  <div className="w-12 h-12 bg-orange-100 rounded-xl flex items-center justify-center text-orange-500">
                    {kit.icon}
                  </div>
                  <span className={`px-3 py-1 rounded-full text-xs font-medium ${
                    kit.status === 'available'
                      ? 'bg-green-100 text-green-700'
                      : 'bg-gray-100 text-gray-500'
                  }`}>
                    {kit.status === 'available' ? 'Available' : 'Coming Soon'}
                  </span>
                </div>

                <h3 className="text-xl font-bold text-gray-900 mb-2">{kit.name}</h3>
                <p className="text-sm text-orange-500 mb-4">{kit.tagline}</p>
                <p className="text-gray-600 mb-6">{kit.description}</p>

                {/* Quick Stats */}
                <div className="flex items-center gap-4 text-sm text-gray-500 mb-6">
                  <div className="flex items-center gap-1">
                    <Server className="w-4 h-4" />
                    {kit.nodes}
                  </div>
                  <div className={`flex items-center gap-1 ${kit.cloud ? 'text-orange-500' : ''}`}>
                    <Cloud className="w-4 h-4" />
                    {kit.cloud ? 'Cloud-Ready' : 'Local Only'}
                  </div>
                </div>

                <button className="flex items-center gap-2 text-orange-500 font-medium group-hover:gap-3 transition-all">
                  View Details
                  <ChevronRight className="w-4 h-4" />
                </button>
              </motion.div>
            ))}
          </div>
        </div>
      </section>

      {/* Detail Modal */}
      <AnimatePresence>
        {selectedKit && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/40"
            onClick={() => setSelectedKit(null)}
          >
            <motion.div
              initial={{ scale: 0.95, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              exit={{ scale: 0.95, opacity: 0 }}
              className="bg-white rounded-2xl max-w-2xl w-full max-h-[90vh] overflow-y-auto"
              onClick={(e) => e.stopPropagation()}
            >
              {/* Modal Header */}
              <div className="p-8 border-b border-gray-100">
                <div className="flex items-start justify-between">
                  <div className="flex items-center gap-4">
                    <div className="w-14 h-14 bg-orange-100 rounded-xl flex items-center justify-center text-orange-500">
                      {selectedKit.icon}
                    </div>
                    <div>
                      <h2 className="text-2xl font-bold text-gray-900">{selectedKit.name}</h2>
                      <p className="text-orange-500">{selectedKit.tagline}</p>
                    </div>
                  </div>
                  <button
                    onClick={() => setSelectedKit(null)}
                    className="p-2 hover:bg-gray-100 rounded-lg transition-colors"
                  >
                    <X className="w-5 h-5 text-gray-400" />
                  </button>
                </div>
              </div>

              {/* Modal Content */}
              <div className="p-8 space-y-8">
                <p className="text-gray-600">{selectedKit.description}</p>

                {/* Features */}
                <div>
                  <h3 className="font-semibold text-gray-900 mb-4">Features</h3>
                  <ul className="space-y-3">
                    {selectedKit.features.map((feature, i) => (
                      <li key={i} className="flex items-start gap-3">
                        <Check className="w-5 h-5 text-orange-500 flex-shrink-0 mt-0.5" />
                        <span className="text-gray-600">{feature}</span>
                      </li>
                    ))}
                  </ul>
                </div>

                {/* Services */}
                <div>
                  <h3 className="font-semibold text-gray-900 mb-4">Included Services</h3>
                  <div className="flex flex-wrap gap-2">
                    {selectedKit.services.map((service, i) => (
                      <span key={i} className="px-3 py-1.5 bg-gray-100 text-gray-700 rounded-lg text-sm">
                        {service}
                      </span>
                    ))}
                  </div>
                </div>

                {selectedKit.status === 'available' && (
                  <a
                    href="/get-started"
                    className="block w-full py-3 bg-orange-500 text-white font-semibold rounded-xl text-center hover:bg-orange-600 transition-colors"
                  >
                    Get Started with {selectedKit.name}
                  </a>
                )}
              </div>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}
