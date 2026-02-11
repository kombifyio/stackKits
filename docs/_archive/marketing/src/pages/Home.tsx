import { ArrowRight, Shield, Zap, CheckCircle } from 'lucide-react';
import { Link } from 'react-router-dom';
import { Button } from '../components/Button';
import { Card } from '../components/Card';
import { Section } from '../components/Section';
import { Navbar } from '../components/Navbar';
import { Footer } from '../components/Footer';

export function Home() {
  return (
    <div className="min-h-screen bg-white">
      <Navbar />
      <main>
        {/* Hero Section */}
        <section className="relative overflow-hidden bg-white py-20 md:py-32">
          {/* Subtle orange grid background */}
          <div className="absolute inset-0 bg-[linear-gradient(rgba(249,115,22,0.03)_1px,transparent_1px),linear-gradient(90deg,rgba(249,115,22,0.03)_1px,transparent_1px)] bg-[size:48px_48px]" />
          
          <div className="relative container-custom">
            <div className="grid lg:grid-cols-2 gap-12 items-center">
              {/* Left: Text Content */}
              <div className="max-w-2xl">
                <h1 className="text-4xl md:text-5xl lg:text-6xl font-bold text-gray-900 leading-tight mb-6">
                  Build Your Stack.
                  <br />
                  <span className="text-orange-500">Simplify Your Life.</span>
                </h1>
                
                <p className="text-lg md:text-xl text-gray-600 mb-8 max-w-lg leading-relaxed">
                  Get control of deploying, managing and evaluating your infrastructure. 
                  Reuse our blueprints and simplify your stack.
                </p>

                <div className="flex flex-wrap gap-4">
                  <Link to="/get-started">
                    <Button variant="primary" size="lg" className="flex items-center space-x-2">
                      <span>Get Started</span>
                      <ArrowRight size={20} />
                    </Button>
                  </Link>
                  <Link to="/overview">
                    <Button variant="secondary" size="lg">
                      Learn More
                    </Button>
                  </Link>
                </div>
              </div>

              {/* Right: Isometric Cubes Illustration */}
              <div className="relative">
                <div className="relative w-full aspect-square max-w-md mx-auto">
                  <IsometricCubes />
                </div>
              </div>
            </div>
          </div>
        </section>

        {/* Features Section */}
        <Section 
          title="Features"
          description="Everything you need to deploy and manage your homelab infrastructure."
          className="bg-gray-50"
        >
          <div className="grid md:grid-cols-3 gap-8">
            <Card hover={true}>
              <div className="w-12 h-12 bg-orange-100 rounded-xl flex items-center justify-center text-orange-500 mb-6">
                <Shield className="w-6 h-6" />
              </div>
              <h3 className="text-xl font-semibold text-gray-900 mb-3">Validated Configuration</h3>
              <p className="text-gray-600">
                CUE schemas catch configuration errors before deployment. Type-safe and constraint-validated.
              </p>
            </Card>
            
            <Card hover={true}>
              <div className="w-12 h-12 bg-orange-100 rounded-xl flex items-center justify-center text-orange-500 mb-6">
                <CheckCircle className="w-6 h-6" />
              </div>
              <h3 className="text-xl font-semibold text-gray-900 mb-3">IaC-First Approach</h3>
              <p className="text-gray-600">
                OpenTofu as execution engine. Declarative, idempotent, and fully auditable deployments.
              </p>
            </Card>
            
            <Card hover={true}>
              <div className="w-12 h-12 bg-orange-100 rounded-xl flex items-center justify-center text-orange-500 mb-6">
                <Zap className="w-6 h-6" />
              </div>
              <h3 className="text-xl font-semibold text-gray-900 mb-3">Minutes to Deploy</h3>
              <p className="text-gray-600">
                From zero to running homelab in minutes. Pre-built blueprints for common setups.
              </p>
            </Card>
          </div>
        </Section>

        {/* CTA Section */}
        <section className="py-20 bg-white">
          <div className="container-custom">
            <div className="max-w-4xl mx-auto text-center">
              <h2 className="text-3xl md:text-4xl font-bold text-gray-900 mb-4">
                Ready to simplify your homelab?
              </h2>
              <p className="text-lg text-gray-600 mb-8 max-w-2xl mx-auto">
                Start with our base-homelab StackKit and deploy your infrastructure today.
              </p>
              <Link to="/get-started">
                <Button variant="primary" size="lg" className="flex items-center space-x-2 mx-auto">
                  <span>Get Started Now</span>
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
