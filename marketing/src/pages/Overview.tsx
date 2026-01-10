import { useState } from 'react';
import { Server, Cloud, ShieldCheck, CheckCircle, Info } from 'lucide-react';
import { Navbar } from '../components/Navbar';
import { Footer } from '../components/Footer';
import { Card } from '../components/Card';
import { Badge } from '../components/Badge';
import { Modal } from '../components/Modal';

interface StackKit {
  id: string;
  name: string;
  status: 'Available' | 'Planned';
  icon: React.ReactNode;
  description: string;
  features: string[];
  details: string[];
  color: string;
}

const stackKits: StackKit[] = [
  {
    id: 'base',
    name: 'Base Homelab',
    status: 'Available',
    icon: <Server size={32} />,
    description: 'Single server, Docker-based setup perfect for beginners starting their homelab journey.',
    features: [
      'Single server deployment',
      'Docker containerization',
      'Traefik reverse proxy',
      'Dokploy deployment tool',
      'Uptime Kuma monitoring',
      'Dozzle log viewer'
    ],
    details: [
      'Perfect for beginners new to homelabs',
      'Minimal hardware requirements',
      'Quick setup with validated configurations',
      'Includes essential services out of the box',
      'Easy to expand and customize',
      'Production-ready security defaults'
    ],
    color: 'bg-orange-500'
  },
  {
    id: 'modern',
    name: 'Modern Homelab',
    status: 'Planned',
    icon: <Cloud size={32} />,
    description: 'Multi-server hybrid setup combining cloud and local resources with advanced monitoring.',
    features: [
      'Multi-server architecture',
      'Hybrid cloud + local deployment',
      'Coolify PaaS integration',
      'VPN overlay (Headscale/Tailscale)',
      'Prometheus + Grafana monitoring',
      'Loki log aggregation'
    ],
    details: [
      'Scale across multiple servers',
      'Public internet access with VPN',
      'Enterprise-grade monitoring stack',
      'Platform as a Service capabilities',
      'Seamless cloud integration',
      'Advanced observability features'
    ],
    color: 'bg-gray-400'
  },
  {
    id: 'ha',
    name: 'HA Homelab',
    status: 'Planned',
    icon: <ShieldCheck size={32} />,
    description: 'High-availability Kubernetes cluster with distributed storage for production workloads.',
    features: [
      'Kubernetes with k3s',
      'High availability architecture',
      'Distributed storage (Longhorn/Ceph)',
      'Automatic failover',
      'Enterprise-grade reliability',
      'Production workload support'
    ],
    details: [
      'Built for mission-critical applications',
      'Zero-downtime deployments',
      'Self-healing infrastructure',
      'Scalable storage solution',
      'Load balancing included',
      'Enterprise security features'
    ],
    color: 'bg-gray-500'
  }
];

export function Overview() {
  const [selectedKit, setSelectedKit] = useState<StackKit | null>(null);

  return (
    <div className="min-h-screen bg-white">
      <Navbar />
      <main>
        {/* Section Header */}
        <section className="bg-gray-50 section-padding">
          <div className="container-custom">
            <div className="text-center mb-16">
              <h2 className="text-3xl md:text-4xl font-bold text-gray-900 mb-4">
                Choose Your StackKit
              </h2>
              <p className="text-lg text-gray-600 max-w-2xl mx-auto">
                From simple single-server setups to high-availability clusters, find the perfect blueprint for your needs.
              </p>
            </div>

            {/* StackKit Cards */}
            <div className="grid md:grid-cols-3 gap-8">
              {stackKits.map((kit) => (
                <Card key={kit.id} className="cursor-pointer border-2 border-transparent hover:border-orange-200">
                  {/* Status Badge */}
                  <div className="flex justify-between items-start mb-6">
                    <div className={`p-3 rounded-xl bg-gradient-to-br ${kit.color} text-white`}>
                      {kit.icon}
                    </div>
                    <Badge variant={kit.status === 'Available' ? 'available' : 'planned'}>
                      {kit.status}
                    </Badge>
                  </div>

                  {/* Title */}
                  <h3 className="text-xl font-bold text-gray-900 mb-3">
                    {kit.name}
                  </h3>

                  {/* Description */}
                  <p className="text-gray-600 mb-6 line-clamp-3">
                    {kit.description}
                  </p>

                  {/* Features Preview */}
                  <div className="space-y-2 mb-6">
                    {kit.features.slice(0, 3).map((feature, index) => (
                      <div key={index} className="flex items-center space-x-2 text-sm text-gray-600">
                        <CheckCircle size={16} className="text-green-500 flex-shrink-0" />
                        <span>{feature}</span>
                      </div>
                    ))}
                    {kit.features.length > 3 && (
                      <p className="text-sm text-gray-500 italic">
                        +{kit.features.length - 3} more features
                      </p>
                    )}
                  </div>

                  {/* View Details Button */}
                  <button 
                    onClick={() => setSelectedKit(kit)}
                    className="w-full flex items-center justify-center space-x-2 text-orange-600 hover:text-orange-700 font-medium transition-colors"
                  >
                    <Info size={18} />
                    <span>View Details</span>
                  </button>
                </Card>
              ))}
            </div>
          </div>
        </section>

        {/* Modal */}
        <Modal
          isOpen={selectedKit !== null}
          onClose={() => setSelectedKit(null)}
          title={selectedKit?.name || ''}
        >
          {selectedKit && (
            <div className="space-y-6">
              {/* Description */}
              <div>
                <h4 className="text-lg font-semibold text-gray-900 mb-2">Overview</h4>
                <p className="text-gray-600">{selectedKit.description}</p>
              </div>

              {/* Features */}
              <div>
                <h4 className="text-lg font-semibold text-gray-900 mb-3">Features</h4>
                <div className="grid sm:grid-cols-2 gap-3">
                  {selectedKit.features.map((feature, index) => (
                    <div key={index} className="flex items-start space-x-2">
                      <CheckCircle size={18} className="text-green-500 flex-shrink-0 mt-0.5" />
                      <span className="text-gray-700">{feature}</span>
                    </div>
                  ))}
                </div>
              </div>

              {/* Details */}
              <div>
                <h4 className="text-lg font-semibold text-gray-900 mb-3">Why Choose This StackKit?</h4>
                <ul className="space-y-2">
                  {selectedKit.details.map((detail, index) => (
                    <li key={index} className="flex items-start space-x-2">
                      <span className="text-orange-600 mt-1">•</span>
                      <span className="text-gray-700">{detail}</span>
                    </li>
                  ))}
                </ul>
              </div>

              {/* Status */}
              <div className={`p-4 rounded-lg ${
                selectedKit.status === 'Available' 
                  ? 'bg-orange-50 border border-orange-200' 
                  : 'bg-yellow-50 border border-yellow-200'
              }`}>
                <p className="text-sm font-medium text-gray-900">
                  Status: {selectedKit.status}
                </p>
                <p className="text-sm text-gray-600 mt-1">
                  {selectedKit.status === 'Available' 
                    ? 'This StackKit is ready to deploy today!'
                    : 'Coming soon! We\'re working hard to bring you this StackKit.'}
                </p>
              </div>
            </div>
          )}
        </Modal>
      </main>
      <Footer />
    </div>
  );
}
