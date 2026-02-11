import { CheckCircle, AlertCircle, Cpu, HardDrive, Network } from 'lucide-react';
import { Navbar } from '../components/Navbar';
import { Footer } from '../components/Footer';
import { Card } from '../components/Card';
import { Badge } from '../components/Badge';

const requirements = [
  {
    category: 'Software',
    icon: <Cpu size={24} className="text-orange-600" />,
    items: [
      {
        name: 'Docker',
        version: '24.0+',
        description: 'Container platform for running services',
        required: true
      },
      {
        name: 'OpenTofu',
        version: '1.6+',
        description: 'Infrastructure as Code tool for deployment',
        required: true
      }
    ]
  },
  {
    category: 'Operating System',
    icon: <HardDrive size={24} className="text-green-600" />,
    items: [
      {
        name: 'Ubuntu',
        version: '24.04 LTS (Recommended)',
        description: 'Latest LTS release with best support',
        required: false
      },
      {
        name: 'Ubuntu',
        version: '22.04 LTS',
        description: 'Previous LTS release, still supported',
        required: false
      },
      {
        name: 'Debian',
        version: '12 (Bookworm)',
        description: 'Stable Debian release',
        required: false
      }
    ]
  },
  {
    category: 'Network',
    icon: <Network size={24} className="text-gray-600" />,
    items: [
      {
        name: 'Internet Connection',
        version: 'Required',
        description: 'For downloading packages and initial setup',
        required: true
      },
      {
        name: 'SSH Access',
        version: 'Required',
        description: 'For remote management and deployment',
        required: true
      }
    ]
  }
];

export function Requirements() {
  return (
    <div className="min-h-screen bg-white">
      <Navbar />
      <main>
        {/* Section Header */}
        <section className="section-padding bg-white">
          <div className="container-custom">
            <div className="text-center mb-16">
              <h2 className="text-3xl md:text-4xl font-bold text-gray-900 mb-4">
                Technical Requirements
              </h2>
              <p className="text-lg text-gray-600 max-w-2xl mx-auto">
                Ensure your environment meets these requirements before deploying StackKits.
              </p>
            </div>

            {/* Requirements Grid */}
            <div className="grid md:grid-cols-3 gap-8 mb-12">
              {requirements.map((req, index) => (
                <Card key={index} hover={false} className="p-6">
                  {/* Header */}
                  <div className="flex items-center space-x-3 mb-6">
                    {req.icon}
                    <h3 className="text-xl font-bold text-gray-900">
                      {req.category}
                    </h3>
                  </div>

                  {/* Items */}
                  <div className="space-y-4">
                    {req.items.map((item, itemIndex) => (
                      <div
                        key={itemIndex}
                        className={`p-4 rounded-lg border-2 ${
                          item.required
                            ? 'border-red-200 bg-red-50'
                            : 'border-gray-200 bg-gray-50'
                        }`}
                      >
                        <div className="flex items-start justify-between mb-2">
                          <div className="flex items-center space-x-2">
                            {item.required ? (
                              <AlertCircle size={18} className="text-red-500 flex-shrink-0" />
                            ) : (
                              <CheckCircle size={18} className="text-green-500 flex-shrink-0" />
                            )}
                            <h4 className="font-semibold text-gray-900">
                              {item.name}
                            </h4>
                          </div>
                          <Badge variant={item.required ? 'required' : 'supported'}>
                            {item.required ? 'Required' : 'Supported'}
                          </Badge>
                        </div>
                        <p className="text-sm text-gray-600 mb-2">
                          {item.version}
                        </p>
                        <p className="text-sm text-gray-500">
                          {item.description}
                        </p>
                      </div>
                    ))}
                  </div>
                </Card>
              ))}
            </div>

            {/* Hardware Recommendations */}
            <Card hover={false} className="p-8">
              <h3 className="text-2xl font-bold text-gray-900 mb-6 flex items-center space-x-2">
                <Cpu size={28} className="text-orange-600" />
                <span>Hardware Recommendations</span>
              </h3>
              
              <div className="grid md:grid-cols-3 gap-6">
                <div className="bg-gray-50 rounded-xl p-6">
                  <h4 className="font-semibold text-gray-900 mb-3">Base Homelab</h4>
                  <ul className="space-y-2 text-sm text-gray-600">
                    <li className="flex items-start space-x-2">
                      <CheckCircle size={16} className="text-green-500 flex-shrink-0 mt-0.5" />
                      <span>4+ CPU cores</span>
                    </li>
                    <li className="flex items-start space-x-2">
                      <CheckCircle size={16} className="text-green-500 flex-shrink-0 mt-0.5" />
                      <span>8+ GB RAM</span>
                    </li>
                    <li className="flex items-start space-x-2">
                      <CheckCircle size={16} className="text-green-500 flex-shrink-0 mt-0.5" />
                      <span>100+ GB storage</span>
                    </li>
                  </ul>
                </div>

                <div className="bg-gray-50 rounded-xl p-6">
                  <h4 className="font-semibold text-gray-900 mb-3">Modern Homelab</h4>
                  <ul className="space-y-2 text-sm text-gray-600">
                    <li className="flex items-start space-x-2">
                      <CheckCircle size={16} className="text-green-500 flex-shrink-0 mt-0.5" />
                      <span>8+ CPU cores per server</span>
                    </li>
                    <li className="flex items-start space-x-2">
                      <CheckCircle size={16} className="text-green-500 flex-shrink-0 mt-0.5" />
                      <span>16+ GB RAM per server</span>
                    </li>
                    <li className="flex items-start space-x-2">
                      <CheckCircle size={16} className="text-green-500 flex-shrink-0 mt-0.5" />
                      <span>250+ GB storage per server</span>
                    </li>
                  </ul>
                </div>

                <div className="bg-gray-50 rounded-xl p-6">
                  <h4 className="font-semibold text-gray-900 mb-3">HA Homelab</h4>
                  <ul className="space-y-2 text-sm text-gray-600">
                    <li className="flex items-start space-x-2">
                      <CheckCircle size={16} className="text-green-500 flex-shrink-0 mt-0.5" />
                      <span>16+ CPU cores per node</span>
                    </li>
                    <li className="flex items-start space-x-2">
                      <CheckCircle size={16} className="text-green-500 flex-shrink-0 mt-0.5" />
                      <span>32+ GB RAM per node</span>
                    </li>
                    <li className="flex items-start space-x-2">
                      <CheckCircle size={16} className="text-green-500 flex-shrink-0 mt-0.5" />
                      <span>500+ GB storage per node</span>
                    </li>
                  </ul>
                </div>
              </div>
            </Card>

            {/* Note */}
            <div className="mt-8 bg-orange-50 border border-orange-200 rounded-xl p-6">
              <div className="flex items-start space-x-3">
                <AlertCircle size={24} className="text-orange-600 flex-shrink-0 mt-0.5" />
                <div>
                  <h4 className="font-semibold text-gray-900 mb-2">
                    Need Help Setting Up?
                  </h4>
                  <p className="text-gray-600">
                    Check our documentation for detailed setup guides and troubleshooting tips. 
                    The community is also available to help you get started.
                  </p>
                </div>
              </div>
            </div>
          </div>
        </section>
      </main>
      <Footer />
    </div>
  );
}
