import { ArrowRight, Zap, Shield, Rocket, Users, Sparkles, AlertTriangle, Clock, Settings, TrendingUp, Heart, Target } from 'lucide-react';
import { Link } from 'react-router-dom';
import { Navbar } from '../components/Navbar';
import { Footer } from '../components/Footer';
import { Section } from '../components/Section';
import { Card } from '../components/Card';
import { Button } from '../components/Button';

export function Special() {
  return (
    <div className="min-h-screen bg-white">
      <Navbar />
      <main>
        {/* Hero Section */}
        <section className="bg-white py-32 md:py-40">
          <div className="container-custom">
            <div className="max-w-4xl mx-auto text-center">
              <h1 className="text-4xl md:text-5xl lg:text-6xl font-bold text-gray-900 mb-8 leading-tight">
                What Makes StackKits <span className="text-orange-500">Special</span>
              </h1>
              
              <p className="text-lg md:text-xl text-gray-600 mb-12 max-w-3xl mx-auto leading-relaxed">
                Stop wrestling with infrastructure. Start building the homelab of your dreams with validated, 
                production-ready blueprints that transform weeks of work into minutes of deployment.
              </p>

              <Link to="/get-started">
                <Button variant="primary" size="lg" className="flex items-center space-x-2">
                  <span>Experience the Difference</span>
                  <ArrowRight size={20} />
                </Button>
              </Link>
            </div>
          </div>
        </section>

        {/* Problem Statement Section */}
        <Section 
          title="The Homelab Struggle is Real"
          description="Every homelab enthusiast knows the pain. You're not alone in these challenges."
          className="bg-gray-50"
        >
          <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6 max-w-6xl mx-auto">
            <Card hover={false} className="border-l-4 border-red-400">
              <div className="flex items-start space-x-4">
                <div className="p-3 bg-red-100 rounded-lg flex-shrink-0">
                  <AlertTriangle size={24} className="text-red-600" />
                </div>
                <div>
                  <h3 className="font-semibold text-gray-900 mb-2">Overwhelming Complexity</h3>
                  <p className="text-gray-600 text-sm">
                    Documentation scattered across dozens of websites. Conflicting advice. 
                    You spend more time researching than building.
                  </p>
                </div>
              </div>
            </Card>

            <Card hover={false} className="border-l-4 border-red-400">
              <div className="flex items-start space-x-4">
                <div className="p-3 bg-red-100 rounded-lg flex-shrink-0">
                  <Clock size={24} className="text-red-600" />
                </div>
                <div>
                  <h3 className="font-semibold text-gray-900 mb-2">Weeks of Setup Time</h3>
                  <p className="text-gray-600 text-sm">
                    What should be exciting becomes a marathon of configuration files, 
                    debugging, and trial-and-error.
                  </p>
                </div>
              </div>
            </Card>

            <Card hover={false} className="border-l-4 border-red-400">
              <div className="flex items-start space-x-4">
                <div className="p-3 bg-red-100 rounded-lg flex-shrink-0">
                  <Settings size={24} className="text-red-600" />
                </div>
                <div>
                  <h3 className="font-semibold text-gray-900 mb-2">Configuration Drift</h3>
                  <p className="text-gray-600 text-sm">
                    One wrong command breaks everything. No rollback. No documentation 
                    of what changed. Start over from scratch.
                  </p>
                </div>
              </div>
            </Card>

            <Card hover={false} className="border-l-4 border-red-400">
              <div className="flex items-start space-x-4">
                <div className="p-3 bg-red-100 rounded-lg flex-shrink-0">
                  <Shield size={24} className="text-red-600" />
                </div>
                <div>
                  <h3 className="font-semibold text-gray-900 mb-2">Security Blind Spots</h3>
                  <p className="text-gray-600 text-sm">
                    Are you following best practices? Hard to know when you're 
                    piecing together tutorials from random sources.
                  </p>
                </div>
              </div>
            </Card>

            <Card hover={false} className="border-l-4 border-red-400">
              <div className="flex items-start space-x-4">
                <div className="p-3 bg-red-100 rounded-lg flex-shrink-0">
                  <TrendingUp size={24} className="text-red-600" />
                </div>
                <div>
                  <h3 className="font-semibold text-gray-900 mb-2">Upgrade Nightmares</h3>
                  <p className="text-gray-600 text-sm">
                    Updating services breaks dependencies. Version conflicts. 
                    Breaking changes that require hours to resolve.
                  </p>
                </div>
              </div>
            </Card>

            <Card hover={false} className="border-l-4 border-red-400">
              <div className="flex items-start space-x-4">
                <div className="p-3 bg-red-100 rounded-lg flex-shrink-0">
                  <Users size={24} className="text-red-600" />
                </div>
                <div>
                  <h3 className="font-semibold text-gray-900 mb-2">No Standardization</h3>
                  <p className="text-gray-600 text-sm">
                    Every homelab is different. No shared knowledge. 
                    No way to learn from others' proven setups.
                  </p>
                </div>
              </div>
            </Card>
          </div>
        </Section>

        {/* Unique Value Propositions Section */}
        <Section 
          title="The StackKits Revolution"
          description="We didn't just build another tool. We reimagined how homelabs should work."
        >
          <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-8 max-w-6xl mx-auto">
            <Card className="border-t-4 border-orange-500">
              <div className="mb-6">
                <div className="w-14 h-14 bg-orange-500 rounded-xl flex items-center justify-center mb-4">
                  <Sparkles size={28} className="text-white" />
                </div>
                <h3 className="text-xl font-bold text-gray-900 mb-3">
                  Declarative Infrastructure
                </h3>
              </div>
              <p className="text-gray-600 mb-4">
                <strong className="text-gray-900">Describe what you want, not how to build it.</strong> 
                Define your infrastructure in simple, human-readable configuration. 
                Let StackKits handle the complexity of making it happen.
              </p>
              <ul className="space-y-2">
                <li className="flex items-start text-sm text-gray-600">
                  <span className="text-orange-500 mr-2">✓</span>
                  <span>Zero manual configuration steps</span>
                </li>
                <li className="flex items-start text-sm text-gray-600">
                  <span className="text-orange-500 mr-2">✓</span>
                  <span>Predictable, reproducible deployments</span>
                </li>
                <li className="flex items-start text-sm text-gray-600">
                  <span className="text-orange-500 mr-2">✓</span>
                  <span>Version-controlled infrastructure</span>
                </li>
              </ul>
            </Card>

            <Card className="border-t-4 border-orange-500">
              <div className="mb-6">
                <div className="w-14 h-14 bg-orange-500 rounded-xl flex items-center justify-center mb-4">
                  <Shield size={28} className="text-white" />
                </div>
                <h3 className="text-xl font-bold text-gray-900 mb-3">
                  Validated Blueprints
                </h3>
              </div>
              <p className="text-gray-600 mb-4">
                <strong className="text-gray-900">Battle-tested configurations you can trust.</strong> 
                Every StackKit is rigorously tested across real-world scenarios. 
                No more hoping that random tutorial will work.
              </p>
              <ul className="space-y-2">
                <li className="flex items-start text-sm text-gray-600">
                  <span className="text-orange-500 mr-2">✓</span>
                  <span>Pre-tested, production-ready setups</span>
                </li>
                <li className="flex items-start text-sm text-gray-600">
                  <span className="text-orange-500 mr-2">✓</span>
                  <span>Security best practices built-in</span>
                </li>
                <li className="flex items-start text-sm text-gray-600">
                  <span className="text-orange-500 mr-2">✓</span>
                  <span>Proven by the community</span>
                </li>
              </ul>
            </Card>

            <Card className="border-t-4 border-orange-500">
              <div className="mb-6">
                <div className="w-14 h-14 bg-orange-500 rounded-xl flex items-center justify-center mb-4">
                  <Target size={28} className="text-white" />
                </div>
                <h3 className="text-xl font-bold text-gray-900 mb-3">
                  IaC-First Approach
                </h3>
              </div>
              <p className="text-gray-600 mb-4">
                <strong className="text-gray-900">Infrastructure as Code from day one.</strong> 
                Your homelab becomes a living, breathing codebase. 
                Track changes, collaborate, and evolve with confidence.
              </p>
              <ul className="space-y-2">
                <li className="flex items-start text-sm text-gray-600">
                  <span className="text-orange-500 mr-2">✓</span>
                  <span>Git-based version control</span>
                </li>
                <li className="flex items-start text-sm text-gray-600">
                  <span className="text-orange-500 mr-2">✓</span>
                  <span>Automated testing & validation</span>
                </li>
                <li className="flex items-start text-sm text-gray-600">
                  <span className="text-orange-500 mr-2">✓</span>
                  <span>Professional-grade workflows</span>
                </li>
              </ul>
            </Card>

            <Card className="border-t-4 border-orange-500">
              <div className="mb-6">
                <div className="w-14 h-14 bg-orange-500 rounded-xl flex items-center justify-center mb-4">
                  <Rocket size={28} className="text-white" />
                </div>
                <h3 className="text-xl font-bold text-gray-900 mb-3">
                  Lightning-Fast Deployment
                </h3>
              </div>
              <p className="text-gray-600 mb-4">
                <strong className="text-gray-900">Deploy in minutes, not days.</strong> 
                What used to take weeks of manual work now happens automatically. 
                Focus on what matters: building amazing things.
              </p>
              <ul className="space-y-2">
                <li className="flex items-start text-sm text-gray-600">
                  <span className="text-orange-500 mr-2">✓</span>
                  <span>Automated provisioning</span>
                </li>
                <li className="flex items-start text-sm text-gray-600">
                  <span className="text-orange-500 mr-2">✓</span>
                  <span>One-command deployments</span>
                </li>
                <li className="flex items-start text-sm text-gray-600">
                  <span className="text-orange-500 mr-2">✓</span>
                  <span>Instant rollbacks if needed</span>
                </li>
              </ul>
            </Card>

            <Card className="border-t-4 border-orange-500">
              <div className="mb-6">
                <div className="w-14 h-14 bg-orange-500 rounded-xl flex items-center justify-center mb-4">
                  <Users size={28} className="text-white" />
                </div>
                <h3 className="text-xl font-bold text-gray-900 mb-3">
                  Community-Driven
                </h3>
              </div>
              <p className="text-gray-600 mb-4">
                <strong className="text-gray-900">Open-source, collaborative, constantly improving.</strong> 
                Join thousands of enthusiasts sharing knowledge, contributing improvements, 
                and pushing the boundaries of what's possible.
              </p>
              <ul className="space-y-2">
                <li className="flex items-start text-sm text-gray-600">
                  <span className="text-orange-500 mr-2">✓</span>
                  <span>Active community contributions</span>
                </li>
                <li className="flex items-start text-sm text-gray-600">
                  <span className="text-orange-500 mr-2">✓</span>
                  <span>Shared knowledge & best practices</span>
                </li>
                <li className="flex items-start text-sm text-gray-600">
                  <span className="text-orange-500 mr-2">✓</span>
                  <span>Continuous innovation</span>
                </li>
              </ul>
            </Card>

            <Card className="border-t-4 border-orange-500">
              <div className="mb-6">
                <div className="w-14 h-14 bg-orange-500 rounded-xl flex items-center justify-center mb-4">
                  <Zap size={28} className="text-white" />
                </div>
                <h3 className="text-xl font-bold text-gray-900 mb-3">
                  Future-Proof Investment
                </h3>
              </div>
              <p className="text-gray-600 mb-4">
                <strong className="text-gray-900">Vendor-agnostic, portable, maintainable.</strong> 
                Your infrastructure isn't locked into any platform. 
                Adapt, scale, and evolve without starting over.
              </p>
              <ul className="space-y-2">
                <li className="flex items-start text-sm text-gray-600">
                  <span className="text-orange-500 mr-2">✓</span>
                  <span>Platform-independent designs</span>
                </li>
                <li className="flex items-start text-sm text-gray-600">
                  <span className="text-orange-500 mr-2">✓</span>
                  <span>Easy migration & scaling</span>
                </li>
                <li className="flex items-start text-sm text-gray-600">
                  <span className="text-orange-500 mr-2">✓</span>
                  <span>Long-term maintainability</span>
                </li>
              </ul>
            </Card>
          </div>
        </Section>

        {/* Benefits Section */}
        <Section 
          title="What You Gain"
          description="Transform your homelab experience from frustration to freedom."
          className="bg-gray-50"
        >
          <div className="grid md:grid-cols-2 gap-8 max-w-5xl mx-auto">
            <div className="flex items-start space-x-4">
              <div className="p-3 bg-orange-100 rounded-lg flex-shrink-0">
                <Clock size={24} className="text-orange-600" />
              </div>
              <div>
                <h3 className="text-xl font-bold text-gray-900 mb-2">Save Countless Hours</h3>
                <p className="text-gray-600">
                  Stop reinventing the wheel. Leverage battle-tested configurations and 
                  automated deployments. What took weeks now takes minutes.
                </p>
              </div>
            </div>

            <div className="flex items-start space-x-4">
              <div className="p-3 bg-orange-100 rounded-lg flex-shrink-0">
                <Shield size={24} className="text-orange-600" />
              </div>
              <div>
                <h3 className="text-xl font-bold text-gray-900 mb-2">Eliminate Costly Mistakes</h3>
                <p className="text-gray-600">
                  Validated blueprints mean fewer errors, less debugging, and 
                  more confidence. Learn best practices by osmosis.
                </p>
              </div>
            </div>

            <div className="flex items-start space-x-4">
              <div className="p-3 bg-orange-100 rounded-lg flex-shrink-0">
                <TrendingUp size={24} className="text-orange-600" />
              </div>
              <div>
                <h3 className="text-xl font-bold text-gray-900 mb-2">Professional-Grade Infrastructure</h3>
                <p className="text-gray-600">
                  Build homelabs that rival enterprise setups. 
                  Production-ready security, monitoring, and reliability.
                </p>
              </div>
            </div>

            <div className="flex items-start space-x-4">
              <div className="p-3 bg-orange-100 rounded-lg flex-shrink-0">
                <Users size={24} className="text-orange-600" />
              </div>
              <div>
                <h3 className="text-xl font-bold text-gray-900 mb-2">Join a Thriving Community</h3>
                <p className="text-gray-600">
                  Connect with like-minded enthusiasts. Share knowledge, 
                  contribute improvements, and grow together.
                </p>
              </div>
            </div>

            <div className="flex items-start space-x-4">
              <div className="p-3 bg-orange-100 rounded-lg flex-shrink-0">
                <Sparkles size={24} className="text-orange-600" />
              </div>
              <div>
                <h3 className="text-xl font-bold text-gray-900 mb-2">Future-Proof Your Investment</h3>
                <p className="text-gray-600">
                  Vendor-agnostic designs mean you're never locked in. 
                  Adapt, scale, and evolve without starting over.
                </p>
              </div>
            </div>

            <div className="flex items-start space-x-4">
              <div className="p-3 bg-orange-100 rounded-lg flex-shrink-0">
                <Heart size={24} className="text-orange-600" />
              </div>
              <div>
                <h3 className="text-xl font-bold text-gray-900 mb-2">Rediscover the Joy</h3>
                <p className="text-gray-600">
                  Remember why you started? Focus on building amazing things, 
                  not wrestling with configuration files.
                </p>
              </div>
            </div>
          </div>

          {/* CTA Section */}
          <div className="mt-16 text-center">
            <div className="max-w-2xl mx-auto">
              <h3 className="text-2xl md:text-3xl font-bold text-gray-900 mb-4">
                Ready to Transform Your Homelab?
              </h3>
              <p className="text-gray-600 mb-8">
                Join thousands of enthusiasts who've already made the switch. 
                Your dream homelab is closer than you think.
              </p>
              <Link to="/get-started">
                <Button variant="primary" size="lg" className="flex items-center space-x-2">
                  <span>Get Started Now</span>
                  <ArrowRight size={20} />
                </Button>
              </Link>
            </div>
          </div>
        </Section>
      </main>
      <Footer />
    </div>
  );
}
