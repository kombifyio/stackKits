import { motion } from 'framer-motion';
import { Layers, Shield, Zap, GitBranch, FileCode, Box, ArrowRight, Terminal } from 'lucide-react';

const architectureComponents = [
  {
    icon: FileCode,
    name: 'CUE',
    color: 'text-blue-600',
    bgColor: 'bg-blue-50',
    role: 'Schema & Validation',
    description: 'Defines and validates your infrastructure configuration. Type-safe YAML with built-in validation ensures your specs are correct before deployment.'
  },
  {
    icon: Box,
    name: 'OpenTofu',
    color: 'text-purple-600',
    bgColor: 'bg-purple-50',
    role: 'Infrastructure Provisioning',
    description: 'Open-source Terraform fork that provisions your infrastructure. Manages state, dependencies, and ensures idempotent deployments.'
  },
  {
    icon: GitBranch,
    name: 'Terramate',
    color: 'text-green-600',
    bgColor: 'bg-green-50',
    role: 'Stack Orchestration',
    description: 'Orchestrates multiple Terraform stacks. Handles dependency graphs, parallel execution, and change detection across your infrastructure.'
  }
];

const benefits = [
  {
    icon: Shield,
    title: 'Type-Safe Configuration',
    description: 'CUE validates your configuration before deployment, catching errors early and preventing invalid states.'
  },
  {
    icon: Zap,
    title: 'Fast & Efficient',
    description: 'Terramate detects changes and only applies what\'s needed. Parallel execution speeds up large deployments.'
  },
  {
    icon: Layers,
    title: 'Composable Architecture',
    description: 'Mix and match base kits, variants, and services. Build complex infrastructures from simple, tested components.'
  }
];

export function HowItWorksPage() {
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
            <h1 className="text-4xl font-bold text-gray-900">How It Works</h1>
            <p className="mt-4 text-lg text-gray-600 max-w-3xl mx-auto">
              StackKits combines three powerful tools to create a robust, type-safe infrastructure deployment platform.
            </p>
          </motion.div>
        </div>
      </section>

      {/* Core Vision */}
      <section className="py-16">
        <div className="max-w-4xl mx-auto px-6">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.1 }}
            className="text-center mb-16"
          >
            <Terminal className="w-16 h-16 text-orange-500 mx-auto mb-6" />
            <h2 className="text-3xl font-bold text-gray-900 mb-4">
              One Vision: Simplicity
            </h2>
            <p className="text-xl text-gray-700 mb-6">
              Our goal is to reduce infrastructure deployment to its essence:
            </p>
            <div className="bg-gray-900 text-gray-100 rounded-xl p-8 inline-block font-mono text-left">
              <div className="text-green-400 mb-2">$ stackkit prepare</div>
              <div className="text-gray-400 text-sm mb-4">✓ Environment validated</div>
              <div className="text-green-400 mb-2">$ stackkit init</div>
              <div className="text-gray-400 text-sm">✓ Your homelab is running!</div>
            </div>
            <p className="text-gray-600 mt-6">
              Two commands. No complexity. Your infrastructure stands.
            </p>
          </motion.div>
        </div>
      </section>

      {/* Architecture Components */}
      <section className="py-16 bg-gray-50">
        <div className="max-w-6xl mx-auto px-6">
          <div className="text-center mb-12">
            <h2 className="text-3xl font-bold text-gray-900 mb-4">The Architecture</h2>
            <p className="text-lg text-gray-600 max-w-2xl mx-auto">
              Three best-in-class tools work together seamlessly.
            </p>
          </div>

          <div className="grid md:grid-cols-3 gap-8 mb-12">
            {architectureComponents.map((component, index) => {
              const Icon = component.icon;
              return (
                <motion.div
                  key={component.name}
                  initial={{ opacity: 0, y: 20 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ delay: index * 0.1 }}
                  className="bg-white rounded-xl p-8 card-shadow"
                >
                  <div className={`${component.bgColor} w-16 h-16 rounded-lg flex items-center justify-center mb-6`}>
                    <Icon className={`w-8 h-8 ${component.color}`} />
                  </div>
                  <h3 className="text-2xl font-bold text-gray-900 mb-2">{component.name}</h3>
                  <div className="text-sm font-semibold text-orange-500 mb-4">{component.role}</div>
                  <p className="text-gray-600 leading-relaxed">{component.description}</p>
                </motion.div>
              );
            })}
          </div>

          {/* Architecture Flow */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.4 }}
            className="bg-white rounded-xl p-8 card-shadow"
          >
            <h3 className="text-xl font-bold text-gray-900 mb-6 text-center">The Flow</h3>
            <div className="flex flex-col md:flex-row items-center justify-center gap-4">
              <div className="text-center">
                <div className="bg-blue-50 text-blue-600 rounded-lg px-6 py-3 font-semibold">
                  YAML Spec
                </div>
              </div>
              <ArrowRight className="w-6 h-6 text-gray-400 rotate-90 md:rotate-0" />
              <div className="text-center">
                <div className="bg-blue-50 text-blue-600 rounded-lg px-6 py-3 font-semibold">
                  CUE Validation
                </div>
              </div>
              <ArrowRight className="w-6 h-6 text-gray-400 rotate-90 md:rotate-0" />
              <div className="text-center">
                <div className="bg-green-50 text-green-600 rounded-lg px-6 py-3 font-semibold">
                  Terramate Orchestration
                </div>
              </div>
              <ArrowRight className="w-6 h-6 text-gray-400 rotate-90 md:rotate-0" />
              <div className="text-center">
                <div className="bg-purple-50 text-purple-600 rounded-lg px-6 py-3 font-semibold">
                  OpenTofu Deploy
                </div>
              </div>
            </div>
            <p className="text-center text-gray-600 mt-6">
              Your configuration flows through validation, orchestration, and provisioning - all automated.
            </p>
          </motion.div>
        </div>
      </section>

      {/* Why This Stack? */}
      <section className="py-16">
        <div className="max-w-6xl mx-auto px-6">
          <div className="text-center mb-12">
            <h2 className="text-3xl font-bold text-gray-900 mb-4">Why This Makes StackKits Great</h2>
            <p className="text-lg text-gray-600 max-w-2xl mx-auto">
              Each tool brings essential capabilities to the platform.
            </p>
          </div>

          <div className="grid md:grid-cols-3 gap-8">
            {benefits.map((benefit, index) => {
              const Icon = benefit.icon;
              return (
                <motion.div
                  key={benefit.title}
                  initial={{ opacity: 0, y: 20 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ delay: index * 0.1 }}
                  className="bg-gradient-to-br from-orange-50 to-white rounded-xl p-8 border border-orange-100"
                >
                  <Icon className="w-12 h-12 text-orange-500 mb-4" />
                  <h3 className="text-xl font-bold text-gray-900 mb-3">{benefit.title}</h3>
                  <p className="text-gray-600 leading-relaxed">{benefit.description}</p>
                </motion.div>
              );
            })}
          </div>
        </div>
      </section>

      {/* Technical Deep Dive */}
      <section className="py-16 bg-gray-50">
        <div className="max-w-4xl mx-auto px-6">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            className="bg-white rounded-xl p-8 card-shadow"
          >
            <h2 className="text-2xl font-bold text-gray-900 mb-6">Technical Benefits</h2>
            
            <div className="space-y-6">
              <div>
                <h3 className="text-lg font-semibold text-gray-900 mb-2">🔒 Type Safety with CUE</h3>
                <p className="text-gray-600">
                  CUE brings type safety to infrastructure configuration. Unlike plain YAML, CUE enforces constraints, validates relationships, and catches configuration errors before deployment. This means fewer runtime failures and more confidence in your infrastructure.
                </p>
              </div>

              <div>
                <h3 className="text-lg font-semibold text-gray-900 mb-2">🚀 Declarative Infrastructure with OpenTofu</h3>
                <p className="text-gray-600">
                  OpenTofu manages your infrastructure state and ensures idempotency. It provisions resources in the correct order, handles dependencies, and makes infrastructure changes predictable and reversible. As an open-source Terraform fork, it's community-driven and enterprise-ready.
                </p>
              </div>

              <div>
                <h3 className="text-lg font-semibold text-gray-900 mb-2">⚡ Smart Orchestration with Terramate</h3>
                <p className="text-gray-600">
                  Terramate adds intelligent orchestration on top of OpenTofu. It detects which stacks have changed, executes them in the correct order based on dependencies, and can run independent stacks in parallel. This dramatically speeds up large infrastructure deployments.
                </p>
              </div>

              <div>
                <h3 className="text-lg font-semibold text-gray-900 mb-2">🎯 The Result: StackKits</h3>
                <p className="text-gray-600">
                  By combining these tools, StackKits provides pre-validated infrastructure templates that "just work". The complexity is hidden behind simple commands, but the power and flexibility remain available when you need them.
                </p>
              </div>
            </div>
          </motion.div>
        </div>
      </section>
    </div>
  );
}
