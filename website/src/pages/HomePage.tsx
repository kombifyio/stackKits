import { Link } from 'react-router-dom';
import { motion } from 'framer-motion';
import { ArrowRight, Shield, Zap, CheckCircle } from 'lucide-react';

export function HomePage() {
  return (
    <div className="bg-white">
      {/* Hero Section */}
      <section className="relative overflow-hidden">
        {/* Subtle grid background */}
        <div className="absolute inset-0 bg-[linear-gradient(rgba(249,115,22,0.03)_1px,transparent_1px),linear-gradient(90deg,rgba(249,115,22,0.03)_1px,transparent_1px)] bg-[size:48px_48px]" />
        
        <div className="relative max-w-6xl mx-auto px-6 py-24 lg:py-32">
          <div className="grid lg:grid-cols-2 gap-12 items-center">
            {/* Left: Text Content */}
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.6 }}
            >
              <h1 className="text-4xl sm:text-5xl lg:text-6xl font-extrabold leading-tight text-gray-900">
                Build Your Stack.
                <br />
                <span className="text-gradient">Simplify Your Life.</span>
              </h1>
              
              <p className="mt-6 text-lg text-gray-600 max-w-lg">
                Get control of deploying, managing and evaluating your infrastructure. 
                Reuse our blueprints and simplify your stack.
              </p>

              <div className="mt-8 flex flex-wrap gap-4">
                <Link
                  to="/get-started"
                  className="inline-flex items-center gap-2 px-6 py-3 bg-orange-500 text-white font-semibold rounded-lg hover:bg-orange-600 transition-colors"
                >
                  Get Started
                  <ArrowRight className="w-4 h-4" />
                </Link>
                <Link
                  to="/overview"
                  className="inline-flex items-center gap-2 px-6 py-3 border-2 border-gray-200 text-gray-700 font-semibold rounded-lg hover:border-orange-300 hover:text-orange-600 transition-colors"
                >
                  Learn More
                </Link>
              </div>
            </motion.div>

            {/* Right: Isometric Cubes Illustration */}
            <motion.div
              initial={{ opacity: 0, scale: 0.9 }}
              animate={{ opacity: 1, scale: 1 }}
              transition={{ duration: 0.6, delay: 0.2 }}
              className="relative"
            >
              <div className="relative w-full aspect-square max-w-md mx-auto">
                <IsometricCubes />
              </div>
            </motion.div>
          </div>
        </div>
      </section>

      {/* Features Section */}
      <section className="py-20 bg-gray-50">
        <div className="max-w-6xl mx-auto px-6">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            className="text-center mb-16"
          >
            <h2 className="text-3xl font-bold text-gray-900">Features</h2>
            <p className="mt-4 text-gray-600 max-w-2xl mx-auto">
              Everything you need to deploy and manage your homelab infrastructure.
            </p>
          </motion.div>

          <div className="grid md:grid-cols-3 gap-8">
            <FeatureCard
              icon={<Shield className="w-6 h-6" />}
              title="Validated Configuration"
              description="CUE schemas catch configuration errors before deployment. Type-safe and constraint-validated."
              delay={0}
            />
            <FeatureCard
              icon={<CheckCircle className="w-6 h-6" />}
              title="IaC-First Approach"
              description="OpenTofu as execution engine. Declarative, idempotent, and fully auditable deployments."
              delay={0.1}
            />
            <FeatureCard
              icon={<Zap className="w-6 h-6" />}
              title="Minutes to Deploy"
              description="From zero to running homelab in minutes. Pre-built blueprints for common setups."
              delay={0.2}
            />
          </div>
        </div>
      </section>

      {/* CTA Section */}
      <section className="py-20">
        <div className="max-w-4xl mx-auto px-6 text-center">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
          >
            <h2 className="text-3xl font-bold text-gray-900">Ready to simplify your homelab?</h2>
            <p className="mt-4 text-gray-600">
              Start with our base-homelab StackKit and deploy your infrastructure today.
            </p>
            <Link
              to="/get-started"
              className="mt-8 inline-flex items-center gap-2 px-8 py-4 bg-orange-500 text-white font-semibold rounded-lg hover:bg-orange-600 transition-colors"
            >
              Get Started Now
              <ArrowRight className="w-4 h-4" />
            </Link>
          </motion.div>
        </div>
      </section>
    </div>
  );
}

function FeatureCard({ icon, title, description, delay }: { icon: React.ReactNode; title: string; description: string; delay: number }) {
  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      whileInView={{ opacity: 1, y: 0 }}
      viewport={{ once: true }}
      transition={{ delay }}
      className="bg-white p-8 rounded-2xl card-shadow hover:card-shadow-hover transition-shadow"
    >
      <div className="w-12 h-12 bg-orange-100 rounded-xl flex items-center justify-center text-orange-500 mb-6">
        {icon}
      </div>
      <h3 className="text-xl font-semibold text-gray-900 mb-3">{title}</h3>
      <p className="text-gray-600">{description}</p>
    </motion.div>
  );
}

function IsometricCubes() {
  return (
    <svg viewBox="0 0 400 400" className="w-full h-full">
      <defs>
        <linearGradient id="orange1" x1="0%" y1="0%" x2="100%" y2="100%">
          <stop offset="0%" stopColor="#fdba74" />
          <stop offset="100%" stopColor="#fb923c" />
        </linearGradient>
        <linearGradient id="orange2" x1="0%" y1="0%" x2="100%" y2="100%">
          <stop offset="0%" stopColor="#fb923c" />
          <stop offset="100%" stopColor="#f97316" />
        </linearGradient>
        <linearGradient id="orange3" x1="0%" y1="0%" x2="100%" y2="100%">
          <stop offset="0%" stopColor="#f97316" />
          <stop offset="100%" stopColor="#ea580c" />
        </linearGradient>
        <linearGradient id="orange4" x1="0%" y1="0%" x2="100%" y2="100%">
          <stop offset="0%" stopColor="#ea580c" />
          <stop offset="100%" stopColor="#c2410c" />
        </linearGradient>
      </defs>
      
      {/* Bottom Layer */}
      <g transform="translate(200, 320)">
        <Cube x={-60} y={0} fill="url(#orange4)" />
        <Cube x={0} y={-35} fill="url(#orange3)" />
        <Cube x={60} y={0} fill="url(#orange4)" />
      </g>
      
      {/* Middle Layer */}
      <g transform="translate(200, 250)">
        <Cube x={-30} y={-17} fill="url(#orange2)" />
        <Cube x={30} y={-17} fill="url(#orange3)" />
        <Cube x={-90} y={17} fill="url(#orange3)" />
        <Cube x={90} y={17} fill="url(#orange3)" />
      </g>
      
      {/* Top Layer */}
      <g transform="translate(200, 180)">
        <Cube x={0} y={0} fill="url(#orange1)" />
        <Cube x={-60} y={35} fill="url(#orange2)" />
        <Cube x={60} y={35} fill="url(#orange2)" />
      </g>
      
      {/* Peak */}
      <g transform="translate(200, 110)">
        <Cube x={0} y={0} fill="url(#orange1)" />
      </g>
    </svg>
  );
}

function Cube({ x, y, fill }: { x: number; y: number; fill: string }) {
  const size = 50;
  return (
    <g transform={`translate(${x}, ${y})`}>
      {/* Top face */}
      <polygon
        points={`0,${-size * 0.5} ${size * 0.866},0 0,${size * 0.5} ${-size * 0.866},0`}
        fill={fill}
        opacity="0.9"
      />
      {/* Left face */}
      <polygon
        points={`${-size * 0.866},0 0,${size * 0.5} 0,${size * 1.2} ${-size * 0.866},${size * 0.7}`}
        fill={fill}
        opacity="0.7"
      />
      {/* Right face */}
      <polygon
        points={`${size * 0.866},0 0,${size * 0.5} 0,${size * 1.2} ${size * 0.866},${size * 0.7}`}
        fill={fill}
        opacity="0.5"
      />
    </g>
  );
}
