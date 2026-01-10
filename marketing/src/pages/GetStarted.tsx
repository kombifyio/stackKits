import { ArrowRight, Download, BookOpen, MessageSquare, Github } from 'lucide-react';
import { Link } from 'react-router-dom';
import { Navbar } from '../components/Navbar';
import { Footer } from '../components/Footer';
import { Card } from '../components/Card';
import { Button } from '../components/Button';

const quickStartSteps = [
  {
    title: 'Clone the Repository',
    description: 'Get the StackKits code from GitHub and explore available StackKits.',
    icon: <Github size={32} className="text-orange-600" />
  },
  {
    title: 'Install Prerequisites',
    description: 'Ensure Docker and OpenTofu are installed on your system.',
    icon: <Download size={32} className="text-green-600" />
  },
  {
    title: 'Choose Your StackKit',
    description: 'Select Base, Modern, or HA StackKit based on your needs.',
    icon: <BookOpen size={32} className="text-gray-600" />
  },
  {
    title: 'Deploy & Enjoy',
    description: 'Run the deployment commands and start using your new infrastructure.',
    icon: <MessageSquare size={32} className="text-gray-600" />
  }
];

const resources = [
  {
    title: 'Documentation',
    description: 'Comprehensive guides and reference documentation for all StackKits.',
    link: '#',
    icon: <BookOpen size={24} />
  },
  {
    title: 'GitHub Repository',
    description: 'Source code, issues, and contribution guidelines.',
    link: 'https://github.com/stackkits',
    icon: <Github size={24} />
  },
  {
    title: 'Community Support',
    description: 'Get help from the community and share your experiences.',
    link: '#',
    icon: <MessageSquare size={24} />
  }
];

export function GetStarted() {
  return (
    <div className="min-h-screen bg-white">
      <Navbar />
      <main>
        {/* Section Header */}
        <section className="section-padding bg-white">
          <div className="container-custom">
            <div className="text-center mb-16">
              <h2 className="text-3xl md:text-4xl font-bold text-gray-900 mb-4">
                Get Started Today
              </h2>
              <p className="text-lg text-gray-600 max-w-2xl mx-auto">
                Ready to build your homelab? Follow these simple steps to get started with StackKits.
              </p>
            </div>

            {/* Quick Start Steps */}
            <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-6 mb-16">
              {quickStartSteps.map((step, index) => (
                <Card key={index} className="text-center">
                  <div className="flex justify-center mb-4">
                    <div className="p-4 bg-gray-50 rounded-xl">
                      {step.icon}
                    </div>
                  </div>
                  <h3 className="text-lg font-bold text-gray-900 mb-2">
                    {step.title}
                  </h3>
                  <p className="text-gray-600 text-sm">
                    {step.description}
                  </p>
                </Card>
              ))}
            </div>

            {/* CTA Section */}
            <Card hover={false} className="p-8 md:p-12 mb-16">
              <div className="grid md:grid-cols-2 gap-8 items-center">
                <div>
                  <h3 className="text-2xl md:text-3xl font-bold text-gray-900 mb-4">
                    Ready to Deploy Your First StackKit?
                  </h3>
                  <p className="text-gray-600 mb-6">
                    Start with Base Homelab - the perfect entry point for beginners. 
                    It includes everything you need to get started with your self-hosted infrastructure.
                  </p>
                  <div className="flex flex-col sm:flex-row gap-4">
                    <a
                      href="https://github.com/stackkits"
                      target="_blank"
                      rel="noopener noreferrer"
                      className="flex items-center space-x-2"
                    >
                      <Button variant="primary" size="md" className="flex items-center space-x-2">
                        <span>View on GitHub</span>
                        <ArrowRight size={20} />
                      </Button>
                    </a>
                    <Link to="/overview">
                      <Button variant="secondary" size="md" className="flex items-center space-x-2">
                        <span>Explore StackKits</span>
                      </Button>
                    </Link>
                  </div>
                </div>
                <div className="bg-gradient-to-br from-orange-500 to-orange-600 rounded-xl p-8 text-white text-center">
                  <div className="text-5xl font-bold mb-2">Free</div>
                  <div className="text-xl mb-4">Open Source</div>
                  <p className="text-orange-100">
                    StackKits is completely free and open source. 
                    Use it, modify it, and contribute back to the community.
                  </p>
                </div>
              </div>
            </Card>

            {/* Resources */}
            <div>
              <h3 className="text-2xl font-bold text-gray-900 mb-8 text-center">
                Additional Resources
              </h3>
              <div className="grid md:grid-cols-3 gap-6">
                {resources.map((resource, index) => (
                  <a
                    key={index}
                    href={resource.link}
                    target={resource.link.startsWith('http') ? '_blank' : undefined}
                    rel={resource.link.startsWith('http') ? 'noopener noreferrer' : undefined}
                    className="block"
                  >
                    <Card className="group">
                      <div className="flex items-start space-x-4 mb-4">
                        <div className="p-3 bg-orange-50 rounded-lg text-orange-600 group-hover:bg-orange-600 group-hover:text-white transition-colors">
                          {resource.icon}
                        </div>
                        <div className="flex-1">
                          <h4 className="font-semibold text-gray-900 mb-2">
                            {resource.title}
                          </h4>
                          <p className="text-sm text-gray-600">
                            {resource.description}
                          </p>
                        </div>
                      </div>
                      <div className="flex items-center text-orange-600 font-medium text-sm group-hover:translate-x-2 transition-transform">
                        <span>Learn More</span>
                        <ArrowRight size={16} className="ml-1" />
                      </div>
                    </Card>
                  </a>
                ))}
              </div>
            </div>

            {/* Community Note */}
            <div className="mt-12 bg-gradient-to-r from-orange-50 to-orange-100 rounded-2xl p-8">
              <div className="flex flex-col md:flex-row items-center justify-between gap-6">
                <div className="flex-1">
                  <h4 className="text-xl font-bold text-gray-900 mb-2">
                    Join Our Community
                  </h4>
                  <p className="text-gray-600">
                    Connect with other homelab enthusiasts, share your setups, and get help when you need it. 
                    Our community is growing every day!
                  </p>
                </div>
                <a
                  href="#"
                  className="flex items-center space-x-2 whitespace-nowrap"
                >
                  <Button variant="primary" size="md" className="flex items-center space-x-2">
                    <MessageSquare size={20} />
                    <span>Join Community</span>
                  </Button>
                </a>
              </div>
            </div>
          </div>
        </section>
      </main>
      <Footer />
    </div>
  );
}
