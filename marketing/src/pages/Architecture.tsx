import { ArrowRight, CheckCircle, Zap, Shield, TrendingUp, Code2 } from 'lucide-react';
import { Link } from 'react-router-dom';
import { Navbar } from '../components/Navbar';
import { Footer } from '../components/Footer';
import { Card } from '../components/Card';
import { Button } from '../components/Button';

export function Architecture() {
  return (
    <div className="min-h-screen bg-white">
      <Navbar />
      <main>
        {/* Hero Section */}
        <section className="bg-white py-32 md:py-40">
          <div className="container-custom">
            <div className="max-w-3xl mx-auto text-center">
              <h1 className="text-4xl md:text-5xl lg:text-6xl font-bold text-gray-900 mb-8 leading-tight">
                Architecture
              </h1>
              <p className="text-lg md:text-xl text-gray-600 mb-12 max-w-2xl mx-auto leading-relaxed">
                A declarative infrastructure framework combining CUE, OpenTofu, and Terraform to build professional, future-proof homelabs with automated deployments and drift detection.
              </p>
            </div>
          </div>
        </section>

        {/* Process Flow Section */}
        <section className="bg-gray-50 section-padding">
          <div className="container-custom">
            <div className="text-center mb-16">
              <h2 className="text-3xl md:text-4xl font-bold text-gray-900 mb-4">
                How It Works
              </h2>
              <p className="text-lg text-gray-600 max-w-2xl mx-auto">
                Three powerful components working together to automate your infrastructure
              </p>
            </div>

            {/* Process Diagram */}
            <div className="max-w-5xl mx-auto mb-20">
              <div className="bg-white rounded-2xl shadow-lg p-8 md:p-12">
                <svg viewBox="0 0 900 300" className="w-full h-auto" xmlns="http://www.w3.org/2000/svg">
                  {/* Background */}
                  <rect width="900" height="300" fill="white" />
                  
                  {/* CUE Box */}
                  <g>
                    <rect x="50" y="80" width="200" height="140" rx="12" fill="#fff7ed" stroke="#f97316" strokeWidth="2" />
                    <text x="150" y="130" textAnchor="middle" className="text-2xl font-bold" fill="#1f2937" fontSize="20" fontWeight="bold">CUE</text>
                    <text x="150" y="155" textAnchor="middle" fill="#6b7280" fontSize="14">Schema &</text>
                    <text x="150" y="175" textAnchor="middle" fill="#6b7280" fontSize="14">Configuration</text>
                    <text x="150" y="205" textAnchor="middle" fill="#f97316" fontSize="12" fontWeight="600">Type Validation</text>
                  </g>

                  {/* Arrow 1 */}
                  <g>
                    <line x1="260" y1="150" x2="330" y2="150" stroke="#f97316" strokeWidth="3" markerEnd="url(#arrowhead)" />
                    <text x="295" y="135" textAnchor="middle" fill="#6b7280" fontSize="11">Validates</text>
                  </g>

                  {/* OpenTofu Box */}
                  <g>
                    <rect x="340" y="80" width="200" height="140" rx="12" fill="#fff7ed" stroke="#f97316" strokeWidth="2" />
                    <text x="440" y="130" textAnchor="middle" fill="#1f2937" fontSize="20" fontWeight="bold">OpenTofu</text>
                    <text x="440" y="155" textAnchor="middle" fill="#6b7280" fontSize="14">Template</text>
                    <text x="440" y="175" textAnchor="middle" fill="#6b7280" fontSize="14">Engine</text>
                    <text x="440" y="205" textAnchor="middle" fill="#f97316" fontSize="12" fontWeight="600">Generates IaC</text>
                  </g>

                  {/* Arrow 2 */}
                  <g>
                    <line x1="550" y1="150" x2="620" y2="150" stroke="#f97316" strokeWidth="3" markerEnd="url(#arrowhead)" />
                    <text x="585" y="135" textAnchor="middle" fill="#6b7280" fontSize="11">Compiles</text>
                  </g>

                  {/* Terraform Box */}
                  <g>
                    <rect x="630" y="80" width="200" height="140" rx="12" fill="#fff7ed" stroke="#f97316" strokeWidth="2" />
                    <text x="730" y="130" textAnchor="middle" fill="#1f2937" fontSize="20" fontWeight="bold">Terraform</text>
                    <text x="730" y="155" textAnchor="middle" fill="#6b7280" fontSize="14">Infrastructure</text>
                    <text x="730" y="175" textAnchor="middle" fill="#6b7280" fontSize="14">as Code</text>
                    <text x="730" y="205" textAnchor="middle" fill="#f97316" fontSize="12" fontWeight="600">Deploys Resources</text>
                  </g>

                  {/* Arrow Marker Definition */}
                  <defs>
                    <marker id="arrowhead" markerWidth="10" markerHeight="7" refX="9" refY="3.5" orient="auto">
                      <polygon points="0 0, 10 3.5, 0 7" fill="#f97316" />
                    </marker>
                  </defs>

                  {/* User Input Indicator */}
                  <g>
                    <text x="150" y="50" textAnchor="middle" fill="#f97316" fontSize="12" fontWeight="600">User Defines Config</text>
                    <path d="M150 55 L150 75" stroke="#f97316" strokeWidth="2" markerEnd="url(#arrowhead)" />
                  </g>

                  {/* Infrastructure Output Indicator */}
                  <g>
                    <path d="M730 225 L730 245" stroke="#f97316" strokeWidth="2" markerEnd="url(#arrowhead)" />
                    <text x="730" y="265" textAnchor="middle" fill="#f97316" fontSize="12" fontWeight="600">Infrastructure Deployed</text>
                  </g>
                </svg>
              </div>
            </div>

            {/* Component Details */}
            <div className="grid md:grid-cols-3 gap-8 max-w-6xl mx-auto">
              <Card>
                <div className="p-4 rounded-xl bg-orange-100 w-fit mb-4">
                  <Code2 size={32} className="text-orange-600" />
                </div>
                <h3 className="text-xl font-bold text-gray-900 mb-3">CUE Schema</h3>
                <p className="text-gray-600 mb-4">
                  Declarative configuration language with strong type safety. Validates your infrastructure definitions before deployment.
                </p>
                <ul className="space-y-2">
                  {['Type-safe configuration', 'Schema validation', 'Composition & constraints'].map((item, i) => (
                    <li key={i} className="flex items-center space-x-2 text-sm text-gray-600">
                      <CheckCircle size={16} className="text-orange-500 flex-shrink-0" />
                      <span>{item}</span>
                    </li>
                  ))}
                </ul>
              </Card>

              <Card>
                <div className="p-4 rounded-xl bg-orange-100 w-fit mb-4">
                  <Zap size={32} className="text-orange-600" />
                </div>
                <h3 className="text-xl font-bold text-gray-900 mb-3">OpenTofu Templates</h3>
                <p className="text-gray-600 mb-4">
                  Template engine that transforms validated CUE configurations into Terraform-ready infrastructure code.
                </p>
                <ul className="space-y-2">
                  {['Code generation', 'Template inheritance', 'Modular design'].map((item, i) => (
                    <li key={i} className="flex items-center space-x-2 text-sm text-gray-600">
                      <CheckCircle size={16} className="text-orange-500 flex-shrink-0" />
                      <span>{item}</span>
                    </li>
                  ))}
                </ul>
              </Card>

              <Card>
                <div className="p-4 rounded-xl bg-orange-100 w-fit mb-4">
                  <Shield size={32} className="text-orange-600" />
                </div>
                <h3 className="text-xl font-bold text-gray-900 mb-3">Terraform IaC</h3>
                <p className="text-gray-600 mb-4">
                  Industry-standard infrastructure provisioning tool that deploys and manages your cloud and on-premise resources.
                </p>
                <ul className="space-y-2">
                  {['Resource provisioning', 'State management', 'Multi-cloud support'].map((item, i) => (
                    <li key={i} className="flex items-center space-x-2 text-sm text-gray-600">
                      <CheckCircle size={16} className="text-orange-500 flex-shrink-0" />
                      <span>{item}</span>
                    </li>
                  ))}
                </ul>
              </Card>
            </div>
          </div>
        </section>

        {/* Key Features Section */}
        <section className="bg-white section-padding">
          <div className="container-custom">
            <div className="text-center mb-16">
              <h2 className="text-3xl md:text-4xl font-bold text-gray-900 mb-4">
                Key Features
              </h2>
              <p className="text-lg text-gray-600 max-w-2xl mx-auto">
                Built-in capabilities that make your homelab professional-grade
              </p>
            </div>

            <div className="grid md:grid-cols-2 gap-8 max-w-5xl mx-auto">
              {/* Automation */}
              <Card className="border-l-4 border-orange-500">
                <div className="flex items-start space-x-4">
                  <div className="p-3 rounded-xl bg-orange-100 flex-shrink-0">
                    <Zap size={24} className="text-orange-600" />
                  </div>
                  <div>
                    <h3 className="text-xl font-bold text-gray-900 mb-2">Automated Deployments</h3>
                    <p className="text-gray-600 mb-4">
                      Define your infrastructure once and deploy it automatically across environments. The pipeline handles validation, code generation, and provisioning without manual intervention.
                    </p>
                    <ul className="space-y-1 text-sm text-gray-600">
                      <li>• One-command deployment</li>
                      <li>• Consistent environments</li>
                      <li>• Reduced human error</li>
                    </ul>
                  </div>
                </div>
              </Card>

              {/* Drift Detection */}
              <Card className="border-l-4 border-orange-500">
                <div className="flex items-start space-x-4">
                  <div className="p-3 rounded-xl bg-orange-100 flex-shrink-0">
                    <TrendingUp size={24} className="text-orange-600" />
                  </div>
                  <div>
                    <h3 className="text-xl font-bold text-gray-900 mb-2">Drift Detection</h3>
                    <p className="text-gray-600 mb-4">
                      Automatically detect when your actual infrastructure differs from your defined configuration. Get alerts and remediation steps before issues escalate.
                    </p>
                    <ul className="space-y-1 text-sm text-gray-600">
                      <li>• Real-time monitoring</li>
                      <li>• Automatic alerts</li>
                      <li>• Easy reconciliation</li>
                    </ul>
                  </div>
                </div>
              </Card>

              {/* Future-Proof */}
              <Card className="border-l-4 border-orange-500">
                <div className="flex items-start space-x-4">
                  <div className="p-3 rounded-xl bg-orange-100 flex-shrink-0">
                    <Shield size={24} className="text-orange-600" />
                  </div>
                  <div>
                    <h3 className="text-xl font-bold text-gray-900 mb-2">Future-Proof Design</h3>
                    <p className="text-gray-600 mb-4">
                      Built on industry-standard tools with strong community backing. Your infrastructure investments remain valuable as technologies evolve.
                    </p>
                    <ul className="space-y-1 text-sm text-gray-600">
                      <li>• Open-source foundation</li>
                      <li>• Vendor-agnostic</li>
                      <li>• Long-term maintainability</li>
                    </ul>
                  </div>
                </div>
              </Card>

              {/* Professional Standards */}
              <Card className="border-l-4 border-orange-500">
                <div className="flex items-start space-x-4">
                  <div className="p-3 rounded-xl bg-orange-100 flex-shrink-0">
                    <CheckCircle size={24} className="text-orange-600" />
                  </div>
                  <div>
                    <h3 className="text-xl font-bold text-gray-900 mb-2">Professional Standards</h3>
                    <p className="text-gray-600 mb-4">
                      Follows best practices from enterprise DevOps. Type safety, validation, and declarative configuration ensure reliability at scale.
                    </p>
                    <ul className="space-y-1 text-sm text-gray-600">
                      <li>• Type-safe configurations</li>
                      <li>• Pre-deployment validation</li>
                      <li>• Declarative approach</li>
                    </ul>
                  </div>
                </div>
              </Card>
            </div>
          </div>
        </section>

        {/* Technical Benefits Section */}
        <section className="bg-gray-50 section-padding">
          <div className="container-custom">
            <div className="text-center mb-16">
              <h2 className="text-3xl md:text-4xl font-bold text-gray-900 mb-4">
                Why This Architecture?
              </h2>
              <p className="text-lg text-gray-600 max-w-2xl mx-auto">
                Combining these tools creates a powerful, reliable infrastructure platform
              </p>
            </div>

            <div className="max-w-4xl mx-auto">
              <Card className="mb-8">
                <h3 className="text-2xl font-bold text-gray-900 mb-4">Declarative Approach</h3>
                <p className="text-gray-600 mb-4">
                  Describe <strong>what</strong> you want, not <strong>how</strong> to build it. The system figures out the implementation details, ensuring consistency and reducing complexity.
                </p>
                <div className="bg-orange-50 border border-orange-200 rounded-lg p-4">
                  <p className="text-sm text-gray-700">
                    <strong>Example:</strong> Instead of writing scripts to create a Docker network, you define "I need a network with these properties" and the system handles the creation automatically.
                  </p>
                </div>
              </Card>

              <Card className="mb-8">
                <h3 className="text-2xl font-bold text-gray-900 mb-4">Validation & Type Safety</h3>
                <p className="text-gray-600 mb-4">
                  CUE's strong type system catches configuration errors before deployment. This prevents runtime failures and ensures your infrastructure always matches your specifications.
                </p>
                <div className="bg-orange-50 border border-orange-200 rounded-lg p-4">
                  <p className="text-sm text-gray-700">
                    <strong>Benefit:</strong> Catch 90% of configuration errors during validation, not during deployment. Save hours of debugging and prevent production incidents.
                  </p>
                </div>
              </Card>

              <Card>
                <h3 className="text-2xl font-bold text-gray-900 mb-4">Integration & Workflow</h3>
                <p className="text-gray-600 mb-4">
                  Each component handles what it does best: CUE validates, OpenTofu generates, Terraform deploys. This separation of concerns creates a maintainable and extensible system.
                </p>
                <div className="bg-orange-50 border border-orange-200 rounded-lg p-4">
                  <p className="text-sm text-gray-700">
                    <strong>Result:</strong> A clear, predictable workflow that scales from single servers to complex multi-environment deployments.
                  </p>
                </div>
              </Card>
            </div>
          </div>
        </section>

        {/* CTA Section */}
        <section className="bg-white section-padding">
          <div className="container-custom">
            <div className="max-w-3xl mx-auto text-center">
              <h2 className="text-3xl md:text-4xl font-bold text-gray-900 mb-4">
                Ready to Build Your Homelab?
              </h2>
              <p className="text-lg text-gray-600 mb-8">
                Start with a validated StackKit and deploy professional infrastructure in minutes.
              </p>
              <Link to="/get-started">
                <Button variant="primary" size="lg" className="flex items-center space-x-2">
                  <span>Get Started</span>
                  <ArrowRight size={20} />
                </Button>
              </Link>
            </div>
          </div>
        </section>
      </main>
      <Footer />
    </div>
  );
}
