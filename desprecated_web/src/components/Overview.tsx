import { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Server, Cloud, Shield, X, Check, Clock, Users, Database, Globe } from 'lucide-react';

interface StackKitInfo {
  id: string;
  name: string;
  tagline: string;
  description: string;
  icon: React.ReactNode;
  gradient: string;
  status: 'available' | 'planned';
  nodes: string;
  cloud: boolean;
  features: string[];
  services: string[];
  useCases: string[];
}

const stackkits: StackKitInfo[] = [
  {
    id: 'base-homelab',
    name: 'Base Homelab',
    tagline: 'Perfect for beginners',
    description: 'Single-server setup with Docker, reverse proxy, and monitoring. Everything you need to start your homelab journey.',
    icon: <Server className="w-8 h-8" />,
    gradient: 'from-emerald-500 to-teal-500',
    status: 'available',
    nodes: '1 Node',
    cloud: false,
    features: [
      'Docker-based deployments',
      'Traefik reverse proxy',
      'Automatic TLS certificates',
      'Uptime monitoring',
      'Dokploy PaaS interface'
    ],
    services: ['Traefik', 'Dokploy', 'Uptime Kuma', 'Dozzle'],
    useCases: [
      'Personal blogs & websites',
      'Home automation dashboards',
      'Media servers',
      'Development environments'
    ]
  },
  {
    id: 'modern-homelab',
    name: 'Modern Homelab',
    tagline: 'Local + Cloud hybrid',
    description: 'Multi-server hybrid setup that connects local and cloud infrastructure. Scale beyond your home network.',
    icon: <Cloud className="w-8 h-8" />,
    gradient: 'from-indigo-500 to-purple-500',
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
    services: ['Headscale/Tailscale', 'Coolify', 'Prometheus', 'Grafana'],
    useCases: [
      'SaaS applications',
      'Public-facing services',
      'Remote team access',
      'Disaster recovery'
    ]
  },
  {
    id: 'ha-homelab',
    name: 'HA Homelab',
    tagline: 'Enterprise-grade reliability',
    description: 'High-availability Kubernetes cluster with automatic failover. Production-ready infrastructure at home.',
    icon: <Shield className="w-8 h-8" />,
    gradient: 'from-amber-500 to-orange-500',
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
    services: ['K3s', 'Flux', 'Longhorn', 'Thanos', 'Velero'],
    useCases: [
      'Critical applications',
      'Learning Kubernetes',
      'Enterprise-like environments',
      'Zero-downtime deployments'
    ]
  }
];

function StackKitCard({ kit, onSelect }: { kit: StackKitInfo; onSelect: () => void }) {
  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      whileInView={{ opacity: 1, y: 0 }}
      viewport={{ once: true }}
      whileHover={{ y: -5 }}
      className="relative group"
    >
      <div className={`absolute inset-0 bg-gradient-to-r ${kit.gradient} rounded-2xl blur-xl opacity-20 group-hover:opacity-30 transition-opacity`}></div>
      <div className="relative glass rounded-2xl p-8 h-full flex flex-col">
        {/* Status Badge */}
        <div className={`absolute top-4 right-4 px-3 py-1 rounded-full text-xs font-medium ${
          kit.status === 'available' 
            ? 'bg-emerald-500/20 text-emerald-400' 
            : 'bg-amber-500/20 text-amber-400'
        }`}>
          {kit.status === 'available' ? 'Available' : 'Coming Soon'}
        </div>

        {/* Icon */}
        <div className={`w-16 h-16 rounded-xl bg-gradient-to-r ${kit.gradient} flex items-center justify-center text-white mb-6`}>
          {kit.icon}
        </div>

        {/* Content */}
        <h3 className="text-2xl font-bold text-white mb-2">{kit.name}</h3>
        <p className="text-sm text-indigo-400 mb-4">{kit.tagline}</p>
        <p className="text-slate-400 mb-6 flex-grow">{kit.description}</p>

        {/* Quick Stats */}
        <div className="flex items-center gap-4 mb-6 text-sm">
          <div className="flex items-center gap-2 text-slate-400">
            <Server className="w-4 h-4" />
            {kit.nodes}
          </div>
          <div className={`flex items-center gap-2 ${kit.cloud ? 'text-cyan-400' : 'text-slate-500'}`}>
            <Cloud className="w-4 h-4" />
            {kit.cloud ? 'Cloud-Ready' : 'Local Only'}
          </div>
        </div>

        {/* Action Button */}
        <button
          onClick={onSelect}
          className={`w-full py-3 rounded-xl font-medium transition-all ${
            kit.status === 'available'
              ? `bg-gradient-to-r ${kit.gradient} text-white hover:shadow-lg`
              : 'bg-slate-700 text-slate-300 cursor-not-allowed'
          }`}
        >
          {kit.status === 'available' ? 'View Details' : 'Coming Soon'}
        </button>
      </div>
    </motion.div>
  );
}

function DetailModal({ kit, onClose }: { kit: StackKitInfo | null; onClose: () => void }) {
  if (!kit) return null;

  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm"
      onClick={onClose}
    >
      <motion.div
        initial={{ scale: 0.9, opacity: 0 }}
        animate={{ scale: 1, opacity: 1 }}
        exit={{ scale: 0.9, opacity: 0 }}
        onClick={(e) => e.stopPropagation()}
        className="relative w-full max-w-3xl max-h-[90vh] overflow-y-auto glass rounded-2xl"
      >
        {/* Header */}
        <div className={`bg-gradient-to-r ${kit.gradient} p-8 rounded-t-2xl`}>
          <button
            onClick={onClose}
            className="absolute top-4 right-4 p-2 rounded-full bg-white/20 hover:bg-white/30 transition-colors"
          >
            <X className="w-5 h-5 text-white" />
          </button>
          <div className="flex items-center gap-4">
            <div className="w-16 h-16 rounded-xl bg-white/20 flex items-center justify-center text-white">
              {kit.icon}
            </div>
            <div>
              <h2 className="text-3xl font-bold text-white">{kit.name}</h2>
              <p className="text-white/80">{kit.tagline}</p>
            </div>
          </div>
        </div>

        {/* Content */}
        <div className="p-8 space-y-8">
          {/* Description */}
          <div>
            <p className="text-lg text-slate-300">{kit.description}</p>
          </div>

          {/* Quick Stats */}
          <div className="grid grid-cols-2 sm:grid-cols-4 gap-4">
            <div className="glass rounded-xl p-4 text-center">
              <Server className="w-6 h-6 text-indigo-400 mx-auto mb-2" />
              <p className="text-sm text-slate-400">Nodes</p>
              <p className="text-white font-semibold">{kit.nodes}</p>
            </div>
            <div className="glass rounded-xl p-4 text-center">
              <Cloud className="w-6 h-6 text-cyan-400 mx-auto mb-2" />
              <p className="text-sm text-slate-400">Cloud</p>
              <p className="text-white font-semibold">{kit.cloud ? 'Supported' : 'Local Only'}</p>
            </div>
            <div className="glass rounded-xl p-4 text-center">
              <Clock className="w-6 h-6 text-emerald-400 mx-auto mb-2" />
              <p className="text-sm text-slate-400">Setup Time</p>
              <p className="text-white font-semibold">~15 min</p>
            </div>
            <div className="glass rounded-xl p-4 text-center">
              <Users className="w-6 h-6 text-amber-400 mx-auto mb-2" />
              <p className="text-sm text-slate-400">Skill Level</p>
              <p className="text-white font-semibold">{kit.id === 'base-homelab' ? 'Beginner' : 'Advanced'}</p>
            </div>
          </div>

          {/* Features */}
          <div>
            <h3 className="text-lg font-semibold text-white mb-4 flex items-center gap-2">
              <Check className="w-5 h-5 text-emerald-400" />
              Features
            </h3>
            <ul className="grid grid-cols-1 sm:grid-cols-2 gap-3">
              {kit.features.map((feature, i) => (
                <li key={i} className="flex items-center gap-2 text-slate-300">
                  <div className="w-1.5 h-1.5 rounded-full bg-indigo-400"></div>
                  {feature}
                </li>
              ))}
            </ul>
          </div>

          {/* Services */}
          <div>
            <h3 className="text-lg font-semibold text-white mb-4 flex items-center gap-2">
              <Database className="w-5 h-5 text-cyan-400" />
              Included Services
            </h3>
            <div className="flex flex-wrap gap-2">
              {kit.services.map((service, i) => (
                <span key={i} className="px-3 py-1 rounded-full bg-slate-700 text-slate-300 text-sm">
                  {service}
                </span>
              ))}
            </div>
          </div>

          {/* Use Cases */}
          <div>
            <h3 className="text-lg font-semibold text-white mb-4 flex items-center gap-2">
              <Globe className="w-5 h-5 text-purple-400" />
              Use Cases
            </h3>
            <ul className="space-y-2">
              {kit.useCases.map((useCase, i) => (
                <li key={i} className="flex items-center gap-2 text-slate-300">
                  <Check className="w-4 h-4 text-emerald-400" />
                  {useCase}
                </li>
              ))}
            </ul>
          </div>

          {/* CTA */}
          {kit.status === 'available' && (
            <a
              href="#get-started"
              onClick={onClose}
              className={`block w-full py-4 rounded-xl bg-gradient-to-r ${kit.gradient} text-white font-semibold text-center hover:shadow-lg transition-all`}
            >
              Get Started with {kit.name}
            </a>
          )}
        </div>
      </motion.div>
    </motion.div>
  );
}

export function Overview() {
  const [selectedKit, setSelectedKit] = useState<StackKitInfo | null>(null);

  return (
    <section id="overview" className="py-24 relative">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        {/* Section Header */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          className="text-center mb-16"
        >
          <h2 className="text-4xl sm:text-5xl font-bold text-white mb-4">
            Choose Your <span className="gradient-text">StackKit</span>
          </h2>
          <p className="text-lg text-slate-400 max-w-2xl mx-auto">
            Three blueprints designed for different homelab needs. Start simple, scale when ready.
          </p>
        </motion.div>

        {/* StackKit Cards */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
          {stackkits.map((kit) => (
            <StackKitCard
              key={kit.id}
              kit={kit}
              onSelect={() => kit.status === 'available' && setSelectedKit(kit)}
            />
          ))}
        </div>
      </div>

      {/* Detail Modal */}
      <AnimatePresence>
        {selectedKit && (
          <DetailModal kit={selectedKit} onClose={() => setSelectedKit(null)} />
        )}
      </AnimatePresence>
    </section>
  );
}
