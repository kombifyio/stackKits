import { FileText, CheckCircle, Play, ChevronRight } from 'lucide-react';
import { Link } from 'react-router-dom';
import { Navbar } from '../components/Navbar';
import { Footer } from '../components/Footer';
import { Card } from '../components/Card';

const steps = [
  {
    number: '01',
    title: 'Choose Your StackKit',
    description: 'Select the StackKit that matches your needs - from simple single-server to high-availability clusters.',
    icon: <FileText size={28} className="text-orange-600" />,
    link: '/overview'
  },
  {
    number: '02',
    title: 'Customize Configuration',
    description: 'Use CUE schemas to define your infrastructure. Validated configurations ensure everything works together.',
    icon: <CheckCircle size={28} className="text-green-600" />,
    link: 'https://cue.dev'
  },
  {
    number: '03',
    title: 'Deploy with OpenTofu',
    description: 'Apply your infrastructure with OpenTofu. IaC-first approach means reproducible, version-controlled deployments.',
    icon: <Play size={28} className="text-gray-600" />,
    link: 'https://opentofu.org'
  },
  {
    number: '04',
    title: 'Manage & Scale',
    description: 'Use the CLI or KombiStack Web UI to manage your infrastructure. Add services, monitor, and scale as needed.',
    icon: <ChevronRight size={28} className="text-gray-600" />,
    link: '/get-started'
  }
];

export function HowItWorks() {
  return (
    <div className="min-h-screen bg-white">
      <Navbar />
      <main>
        {/* Section Header */}
        <section className="section-padding bg-white">
          <div className="container-custom">
            <div className="text-center mb-16">
              <h2 className="text-3xl md:text-4xl font-bold text-gray-900 mb-4">
                How StackKits Works
              </h2>
              <p className="text-lg text-gray-600 max-w-2xl mx-auto">
                Get your homelab up and running in four simple steps. No complex configuration required.
              </p>
            </div>

            {/* Steps */}
            <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-8">
              {steps.map((step, index) => (
                <div key={index} className="relative group">
                  {/* Step Number Badge */}
                  <div className="absolute -top-4 -left-4 w-12 h-12 bg-orange-600 text-white rounded-full flex items-center justify-center font-bold text-sm shadow-lg">
                    {step.number}
                  </div>

                  {/* Card */}
                  <Card hover className="pt-10 h-full border-2 border-transparent group-hover:border-orange-200">
                    {/* Icon */}
                    <div className="mb-4">
                      {step.icon}
                    </div>

                    {/* Title */}
                    <h3 className="text-xl font-bold text-gray-900 mb-3">
                      {step.title}
                    </h3>

                    {/* Description */}
                    <p className="text-gray-600 mb-4">
                      {step.description}
                    </p>

                    {/* Learn More Link */}
                    {step.link.startsWith('/') ? (
                      <Link
                        to={step.link}
                        className="inline-flex items-center space-x-1 text-orange-600 hover:text-orange-700 font-medium text-sm transition-colors"
                      >
                        <span>Learn More</span>
                        <ChevronRight size={16} />
                      </Link>
                    ) : (
                      <a
                        href={step.link}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="inline-flex items-center space-x-1 text-orange-600 hover:text-orange-700 font-medium text-sm transition-colors"
                      >
                        <span>Learn More</span>
                        <ChevronRight size={16} />
                      </a>
                    )}
                  </Card>

                  {/* Connector Line (Desktop) */}
                  {index < steps.length - 1 && (
                    <div className="hidden lg:block absolute top-1/2 -right-4 w-8 border-t-2 border-dashed border-gray-300"></div>
                  )}
                </div>
              ))}
            </div>

            {/* Additional Info */}
            <div className="mt-16 bg-orange-50 rounded-2xl p-8 md:p-12">
              <div className="grid md:grid-cols-2 gap-8 items-center">
                <div>
                  <h3 className="text-2xl font-bold text-gray-900 mb-4">
                    Why This Approach?
                  </h3>
                  <p className="text-gray-700 mb-4">
                    StackKits combines the power of declarative configuration with validated blueprints. 
                    This means you get the flexibility of IaC without the complexity of starting from scratch.
                  </p>
                  <ul className="space-y-2">
                    <li className="flex items-start space-x-2">
                      <CheckCircle size={20} className="text-green-500 flex-shrink-0 mt-0.5" />
                      <span className="text-gray-700">Validated configurations prevent errors</span>
                    </li>
                    <li className="flex items-start space-x-2">
                      <CheckCircle size={20} className="text-green-500 flex-shrink-0 mt-0.5" />
                      <span className="text-gray-700">Version control for all your infrastructure</span>
                    </li>
                    <li className="flex items-start space-x-2">
                      <CheckCircle size={20} className="text-green-500 flex-shrink-0 mt-0.5" />
                      <span className="text-gray-700">Reproducible deployments every time</span>
                    </li>
                  </ul>
                </div>
                <div className="text-center">
                  <div className="bg-white rounded-xl shadow-lg p-6 inline-block">
                    <div className="text-4xl font-bold text-orange-600 mb-2">4</div>
                    <div className="text-gray-600 font-medium">Simple Steps</div>
                    <div className="text-sm text-gray-500 mt-1">To Deploy Your StackKit</div>
                  </div>
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
