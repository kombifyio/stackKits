import { motion } from 'framer-motion';
import { ArrowRight, Shield, CheckCircle, Zap } from 'lucide-react';

export function Hero() {
  return (
    <section className="relative min-h-screen flex items-center justify-center overflow-hidden pt-20">
      {/* Background Effects */}
      <div className="absolute inset-0 overflow-hidden">
        <div className="absolute top-1/4 left-1/4 w-96 h-96 bg-indigo-500/20 rounded-full blur-3xl animate-pulse"></div>
        <div className="absolute bottom-1/4 right-1/4 w-96 h-96 bg-cyan-500/20 rounded-full blur-3xl animate-pulse delay-1000"></div>
        <div className="absolute inset-0 bg-[radial-gradient(ellipse_at_center,_transparent_0%,_#0f172a_70%)]"></div>
      </div>

      {/* Grid Pattern */}
      <div className="absolute inset-0 bg-[linear-gradient(rgba(99,102,241,0.03)_1px,transparent_1px),linear-gradient(90deg,rgba(99,102,241,0.03)_1px,transparent_1px)] bg-[size:64px_64px]"></div>

      <div className="relative max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-20">
        <div className="text-center">
          {/* Badge */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5 }}
            className="inline-flex items-center gap-2 px-4 py-2 rounded-full glass mb-8"
          >
            <span className="w-2 h-2 bg-emerald-400 rounded-full animate-pulse"></span>
            <span className="text-sm text-slate-300">IaC-First Architecture</span>
          </motion.div>

          {/* Headline */}
          <motion.h1
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5, delay: 0.1 }}
            className="text-5xl sm:text-6xl lg:text-7xl font-extrabold tracking-tight mb-6"
          >
            <span className="text-white">Declarative</span>{' '}
            <span className="gradient-text">Infrastructure</span>
            <br />
            <span className="text-white">Blueprints</span>
          </motion.h1>

          {/* Subheadline */}
          <motion.p
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5, delay: 0.2 }}
            className="text-lg sm:text-xl text-slate-400 max-w-2xl mx-auto mb-10"
          >
            Deploy validated, reproducible homelab infrastructure in minutes.
            Powered by <span className="text-cyan-400 font-semibold">CUE</span> for validation
            and <span className="text-indigo-400 font-semibold">OpenTofu</span> for provisioning.
          </motion.p>

          {/* CTA Buttons */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5, delay: 0.3 }}
            className="flex flex-col sm:flex-row items-center justify-center gap-4 mb-16"
          >
            <a
              href="#get-started"
              className="group flex items-center gap-2 px-8 py-4 bg-gradient-to-r from-indigo-500 to-cyan-500 rounded-xl text-white font-semibold hover:shadow-lg hover:shadow-indigo-500/25 transition-all"
            >
              Get Started
              <ArrowRight className="w-5 h-5 group-hover:translate-x-1 transition-transform" />
            </a>
            <a
              href="#overview"
              className="px-8 py-4 rounded-xl glass text-white font-semibold hover:bg-slate-700/50 transition-colors"
            >
              Explore StackKits
            </a>
          </motion.div>

          {/* Feature Pills */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5, delay: 0.4 }}
            className="flex flex-wrap items-center justify-center gap-6"
          >
            <div className="flex items-center gap-2 text-slate-400">
              <Shield className="w-5 h-5 text-emerald-400" />
              <span>Schema Validation</span>
            </div>
            <div className="flex items-center gap-2 text-slate-400">
              <CheckCircle className="w-5 h-5 text-cyan-400" />
              <span>Idempotent Deployments</span>
            </div>
            <div className="flex items-center gap-2 text-slate-400">
              <Zap className="w-5 h-5 text-amber-400" />
              <span>Minutes to Deploy</span>
            </div>
          </motion.div>
        </div>

        {/* Code Preview */}
        <motion.div
          initial={{ opacity: 0, y: 40 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.7, delay: 0.5 }}
          className="mt-20 max-w-4xl mx-auto"
        >
          <div className="glass rounded-2xl overflow-hidden glow">
            <div className="flex items-center gap-2 px-4 py-3 border-b border-slate-700/50">
              <div className="w-3 h-3 rounded-full bg-red-500"></div>
              <div className="w-3 h-3 rounded-full bg-amber-500"></div>
              <div className="w-3 h-3 rounded-full bg-emerald-500"></div>
              <span className="ml-4 text-sm text-slate-500">stack-spec.yaml</span>
            </div>
            <pre className="p-6 text-sm overflow-x-auto">
              <code className="text-slate-300">
{`stack:
  kit: base-homelab
  variant: default

nodes:
  - name: server-1
    ip: 192.168.1.100
    os: ubuntu-24
    ssh:
      user: admin
      keyFile: ~/.ssh/id_rsa

services:
  - traefik      # Reverse proxy
  - dokploy      # App deployment
  - uptime-kuma  # Monitoring`}
              </code>
            </pre>
          </div>
        </motion.div>
      </div>
    </section>
  );
}
