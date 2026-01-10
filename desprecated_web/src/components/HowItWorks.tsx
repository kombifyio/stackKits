import { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { FileText, CheckCircle, Play, RefreshCw, ChevronRight, FileCode } from 'lucide-react';

interface Step {
  id: number;
  title: string;
  description: string;
  icon: React.ReactNode;
  details: {
    explanation: string;
    codeExample?: string;
    highlights: string[];
  };
}

const steps: Step[] = [
  {
    id: 1,
    title: 'Configure',
    description: 'Define your infrastructure in a simple YAML spec',
    icon: <FileText className="w-6 h-6" />,
    details: {
      explanation: 'Start with a default spec template. Define your nodes, SSH access, and select services. The YAML format is human-readable and version-controllable.',
      codeExample: `# my-spec.yaml
stack:
  kit: base-homelab
  variant: default

nodes:
  - name: server-1
    ip: 192.168.1.100
    os: ubuntu-24
    ssh:
      user: admin
      keyFile: ~/.ssh/id_rsa`,
      highlights: [
        'Human-readable YAML format',
        'Pre-built templates available',
        'Version control friendly'
      ]
    }
  },
  {
    id: 2,
    title: 'Validate',
    description: 'CUE schemas catch errors before deployment',
    icon: <CheckCircle className="w-6 h-6" />,
    details: {
      explanation: 'Before any infrastructure changes, CUE validates your configuration against strict schemas. Type mismatches, missing fields, and constraint violations are caught immediately.',
      codeExample: `$ stackkit validate my-spec.yaml

✓ Schema validation passed
✓ Node configuration valid
✓ Service dependencies resolved
✓ Network settings validated

Ready to deploy!`,
      highlights: [
        'Type-safe configuration',
        'Constraint validation',
        'Dependency checking',
        'Clear error messages'
      ]
    }
  },
  {
    id: 3,
    title: 'Deploy',
    description: 'OpenTofu provisions your infrastructure',
    icon: <Play className="w-6 h-6" />,
    details: {
      explanation: 'A single command triggers OpenTofu to provision your entire stack. Docker containers, networks, volumes, and configurations are created in the correct order with proper dependencies.',
      codeExample: `$ stackkit apply my-spec.yaml

Planning infrastructure changes...
  + docker_network.traefik
  + docker_container.traefik
  + docker_container.dokploy
  + docker_container.uptime_kuma

Apply complete! 4 resources created.
Dashboard: https://dokploy.homelab.local`,
      highlights: [
        'Single command deployment',
        'Automatic dependency ordering',
        'Progress visibility',
        'Rollback capability'
      ]
    }
  },
  {
    id: 4,
    title: 'Maintain',
    description: 'Drift detection keeps your stack consistent',
    icon: <RefreshCw className="w-6 h-6" />,
    details: {
      explanation: 'Running infrastructure can drift from your declared state. StackKits detects these changes and can automatically reconcile them, ensuring your homelab stays exactly as defined.',
      codeExample: `$ stackkit plan my-spec.yaml

Detecting drift...
~ docker_container.traefik
    image: "traefik:v2.10" → "traefik:v3.0"
  
1 resource has drifted.
Run 'stackkit apply' to reconcile.`,
      highlights: [
        'Automatic drift detection',
        'Clear change visibility',
        'Scheduled reconciliation',
        'State management'
      ]
    }
  }
];

function StepCard({ step, isActive, onClick }: { step: Step; isActive: boolean; onClick: () => void }) {
  return (
    <motion.button
      onClick={onClick}
      className={`w-full text-left p-6 rounded-xl transition-all ${
        isActive 
          ? 'glass border-indigo-500/50 border' 
          : 'bg-slate-800/30 hover:bg-slate-800/50'
      }`}
      whileHover={{ scale: 1.02 }}
      whileTap={{ scale: 0.98 }}
    >
      <div className="flex items-start gap-4">
        <div className={`w-12 h-12 rounded-xl flex items-center justify-center ${
          isActive 
            ? 'bg-gradient-to-r from-indigo-500 to-cyan-500 text-white' 
            : 'bg-slate-700 text-slate-400'
        }`}>
          {step.icon}
        </div>
        <div className="flex-grow">
          <div className="flex items-center justify-between">
            <h3 className={`text-lg font-semibold ${isActive ? 'text-white' : 'text-slate-300'}`}>
              {step.id}. {step.title}
            </h3>
            <ChevronRight className={`w-5 h-5 transition-transform ${isActive ? 'rotate-90 text-indigo-400' : 'text-slate-500'}`} />
          </div>
          <p className="text-sm text-slate-400 mt-1">{step.description}</p>
        </div>
      </div>
    </motion.button>
  );
}

function StepDetails({ step }: { step: Step }) {
  return (
    <motion.div
      initial={{ opacity: 0, x: 20 }}
      animate={{ opacity: 1, x: 0 }}
      exit={{ opacity: 0, x: -20 }}
      className="glass rounded-2xl p-8 h-full"
    >
      <h3 className="text-2xl font-bold text-white mb-4">{step.title}</h3>
      <p className="text-slate-300 mb-6">{step.details.explanation}</p>

      {step.details.codeExample && (
        <div className="bg-slate-900/50 rounded-xl p-4 mb-6 overflow-x-auto">
          <pre className="text-sm text-slate-300">
            <code>{step.details.codeExample}</code>
          </pre>
        </div>
      )}

      <div>
        <h4 className="text-sm font-semibold text-slate-400 uppercase tracking-wide mb-3">Key Benefits</h4>
        <ul className="space-y-2">
          {step.details.highlights.map((highlight, i) => (
            <li key={i} className="flex items-center gap-2 text-slate-300">
              <CheckCircle className="w-4 h-4 text-emerald-400 flex-shrink-0" />
              {highlight}
            </li>
          ))}
        </ul>
      </div>
    </motion.div>
  );
}

export function HowItWorks() {
  const [activeStep, setActiveStep] = useState(1);

  return (
    <section id="how-it-works" className="py-24 relative">
      {/* Background accent */}
      <div className="absolute inset-0 bg-gradient-to-b from-transparent via-indigo-500/5 to-transparent"></div>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 relative">
        {/* Section Header */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          className="text-center mb-16"
        >
          <h2 className="text-4xl sm:text-5xl font-bold text-white mb-4">
            How it <span className="gradient-text">Works</span>
          </h2>
          <p className="text-lg text-slate-400 max-w-2xl mx-auto">
            Four simple steps from configuration to running infrastructure. No complex setup, no surprises.
          </p>
        </motion.div>

        {/* Workflow Diagram */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          className="flex justify-center items-center gap-4 mb-16 overflow-x-auto pb-4"
        >
          {steps.map((step, index) => (
            <div key={step.id} className="flex items-center">
              <button
                onClick={() => setActiveStep(step.id)}
                className={`flex items-center gap-2 px-4 py-2 rounded-full transition-all ${
                  activeStep === step.id
                    ? 'bg-gradient-to-r from-indigo-500 to-cyan-500 text-white'
                    : 'bg-slate-800 text-slate-400 hover:text-white'
                }`}
              >
                {step.icon}
                <span className="font-medium whitespace-nowrap">{step.title}</span>
              </button>
              {index < steps.length - 1 && (
                <ChevronRight className="w-5 h-5 text-slate-600 mx-2 flex-shrink-0" />
              )}
            </div>
          ))}
        </motion.div>

        {/* Step Content */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
          {/* Steps List */}
          <div className="space-y-4">
            {steps.map((step) => (
              <StepCard
                key={step.id}
                step={step}
                isActive={activeStep === step.id}
                onClick={() => setActiveStep(step.id)}
              />
            ))}
          </div>

          {/* Active Step Details */}
          <div className="hidden lg:block">
            <AnimatePresence mode="wait">
              <StepDetails key={activeStep} step={steps[activeStep - 1]} />
            </AnimatePresence>
          </div>
        </div>

        {/* Mobile Details */}
        <div className="lg:hidden mt-8">
          <AnimatePresence mode="wait">
            <StepDetails key={activeStep} step={steps[activeStep - 1]} />
          </AnimatePresence>
        </div>

        {/* Architecture Link */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          className="mt-16 text-center"
        >
          <a
            href="https://github.com/kombihq/stackkits/blob/main/docs/architecture.md"
            target="_blank"
            rel="noopener noreferrer"
            className="inline-flex items-center gap-2 text-indigo-400 hover:text-indigo-300 transition-colors"
          >
            <FileCode className="w-5 h-5" />
            <span>Read the full architecture documentation</span>
            <ChevronRight className="w-4 h-4" />
          </a>
        </motion.div>
      </div>
    </section>
  );
}
