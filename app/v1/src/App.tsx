import { useState, useEffect } from 'react'
import './App.css'

/* ---- V1 Config ---- */
const CONFIG = {
  version: '1.0.0',
  environment: 'BLUE',
  envLabel: 'Stable Production',
  themeClass: 'blue-theme',
  buildId: '#1,247',
  deployedAt: 'Today 21:18 IST',
  port: '8081',
}

/* ---- Types ---- */
interface HealthItem { name: string; status: 'healthy' | 'warning' | 'critical'; latency: string }
interface Feature { name: string; status: 'enabled' | 'disabled' | 'beta'; description: string; isNew?: boolean }
interface Deployment { version: string; time: string; status: 'success' | 'rollback' | 'failed'; duration: string }

/* ---- Animated counter hook ---- */
function useCounter(target: number, duration = 1600) {
  const [val, setVal] = useState(0)
  useEffect(() => {
    const start = Date.now()
    const tick = setInterval(() => {
      const p = Math.min((Date.now() - start) / duration, 1)
      const eased = 1 - Math.pow(1 - p, 3)
      setVal(Math.round(eased * target))
      if (p >= 1) clearInterval(tick)
    }, 16)
    return () => clearInterval(tick)
  }, [target, duration])
  return val
}

/* ================================================================
   APP COMPONENT
   ================================================================ */
export default function App() {
  const [time, setTime] = useState(new Date())
  const [cpu, setCpu] = useState(42.3)
  const [mem, setMem] = useState(61.0)
  const [rps, setRps] = useState(847)

  // Live metric updates every 2 s
  useEffect(() => {
    const t = setInterval(() => {
      setTime(new Date())
      setCpu(p => +Math.max(22, Math.min(78, p + (Math.random() - 0.5) * 7)).toFixed(1))
      setMem(p => +Math.max(48, Math.min(82, p + (Math.random() - 0.5) * 3)).toFixed(1))
      setRps(p => Math.max(580, Math.min(1100, p + Math.round((Math.random() - 0.5) * 90))))
    }, 2000)
    return () => clearInterval(t)
  }, [])

  // Animated stats
  const uptime   = useCounter(9990)
  const deploys  = useCounter(247)
  const success  = useCounter(98)
  const respTime = useCounter(124)

  const health: HealthItem[] = [
    { name: 'Application Server',  status: 'healthy', latency: '12ms' },
    { name: 'PostgreSQL Database', status: 'healthy', latency: '4ms'  },
    { name: 'Redis Cache',         status: 'healthy', latency: '1ms'  },
    { name: 'RabbitMQ Queue',      status: 'healthy', latency: '8ms'  },
    { name: 'CDN / Static Assets', status: 'healthy', latency: '23ms' },
    { name: 'Auth Service (JWT)',  status: 'healthy', latency: '6ms'  },
  ]

  const features: Feature[] = [
    { name: 'Zero-Downtime Deployments', status: 'enabled',  description: 'Blue-Green strategy active'   },
    { name: 'Automatic Rollback',        status: 'enabled',  description: 'Health-check driven recovery' },
    { name: 'CI/CD Pipeline',           status: 'enabled',  description: 'Automated build & deploy'     },
    { name: 'Container Security Scan',  status: 'enabled',  description: 'Trivy vulnerability scanning' },
    { name: 'Advanced Analytics',       status: 'disabled', description: 'Available in v2.0'            },
    { name: 'AI Deployment Prediction', status: 'disabled', description: 'Available in v2.0'            },
  ]

  const history: Deployment[] = [
    { version: 'v1.0.0', time: '2 hours ago',  status: 'success',  duration: '1m 42s' },
    { version: 'v0.9.8', time: '1 day ago',    status: 'success',  duration: '1m 38s' },
    { version: 'v0.9.7', time: '3 days ago',   status: 'rollback', duration: '0m 31s' },
    { version: 'v0.9.6', time: '5 days ago',   status: 'success',  duration: '1m 55s' },
  ]

  return (
    <div className={`app ${CONFIG.themeClass}`}>

      {/* ── Header ─────────────────────────────────────── */}
      <header className="header">
        <div className="header-left">
          <div className="logo">
            <span className="logo-icon">🚀</span>
            <span className="logo-text">DeployOps</span>
          </div>
          <div className="env-badge">
            <span className="env-dot" />
            {CONFIG.environment} · {CONFIG.envLabel}
          </div>
        </div>

        <div className="header-left nav-links">
          <span className="nav-link active">Overview</span>
          <span className="nav-link">Deployments</span>
          <span className="nav-link">Metrics</span>
          <span className="nav-link">Settings</span>
        </div>

        <div className="header-right">
          <div className="version-tag">v{CONFIG.version}</div>
          <div className="live-indicator">
            <span className="pulse" />
            LIVE
          </div>
          <div className="time">{time.toLocaleTimeString()}</div>
        </div>
      </header>

      {/* ── Stats Bar ──────────────────────────────────── */}
      <div className="stats-bar">
        <StatCard icon="⚡" label="Uptime"          value={`${(uptime/100).toFixed(1)}%`} sub="30-day SLA"    />
        <StatCard icon="⏱️" label="Response Time"   value={`${respTime}ms`}               sub="p95 latency"  />
        <StatCard icon="🚀" label="Deployments"     value={`${deploys}`}                  sub="all time"     />
        <StatCard icon="✅" label="Success Rate"    value={`${success}%`}                 sub="last 30 days" />
      </div>

      {/* ── Main Grid ──────────────────────────────────── */}
      <main className="main-grid">

        {/* Left column */}
        <div className="col">

          {/* System Health */}
          <div className="card">
            <div className="card-header">
              <span className="card-icon">🏥</span>
              <h3>System Health</h3>
              <span className="tag-success">All Systems Operational</span>
            </div>
            <div className="health-list">
              {health.map(h => (
                <div key={h.name} className="health-item">
                  <span className={`h-dot ${h.status}`} />
                  <span className="h-name">{h.name}</span>
                  <span className="h-latency">{h.latency}</span>
                  <span className={`badge ${h.status}`}>{h.status}</span>
                </div>
              ))}
            </div>
          </div>

          {/* Feature Flags */}
          <div className="card">
            <div className="card-header">
              <span className="card-icon">🎛️</span>
              <h3>Feature Flags</h3>
            </div>
            <div className="feature-list">
              {features.map(f => (
                <div key={f.name} className="feature-item">
                  <div className={`toggle ${f.status}`} />
                  <div className="f-info">
                    <div className="f-name-row">
                      <span className="f-name">{f.name}</span>
                      {f.isNew && <span className="new-tag">NEW</span>}
                    </div>
                    <span className="f-desc">{f.description}</span>
                  </div>
                  <span className={`badge ${f.status}`}>{f.status}</span>
                </div>
              ))}
            </div>
          </div>

        </div>

        {/* Right column */}
        <div className="col">

          {/* Live Performance */}
          <div className="card">
            <div className="card-header">
              <span className="card-icon">📊</span>
              <h3>Live Performance</h3>
              <span className="tag-live">● LIVE</span>
            </div>
            <div className="perf-list">
              <ProgressBar label="CPU Usage"    value={cpu} color="#3b82f6"   />
              <ProgressBar label="Memory Usage" value={mem} color="#a855f7"   />
              <ProgressBar label="Disk Usage"   value={34}  color="#f59e0b"   />
              <div className="rps-card">
                <span className="rps-label">Requests / second</span>
                <span className="rps-value">{rps.toLocaleString()}</span>
              </div>
            </div>
          </div>

          {/* Deployment History */}
          <div className="card">
            <div className="card-header">
              <span className="card-icon">📅</span>
              <h3>Deployment History</h3>
            </div>
            <div className="timeline">
              {history.map((d, i) => (
                <div key={i} className={`tl-item ${d.status}`}>
                  <div className="tl-dot" />
                  <div className="tl-body">
                    <div className="tl-top">
                      <span className="tl-version">{d.version}</span>
                      <span className={`badge ${d.status}`}>{d.status}</span>
                    </div>
                    <div className="tl-bottom">
                      <span>{d.time}</span>
                      <span>⏱ {d.duration}</span>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Deployment Info */}
          <div className="card info-card">
            <div className="info-grid">
              <InfoItem label="Strategy"      value="Blue-Green"    />
              <InfoItem label="Zero Downtime" value="✅ Enabled"    />
              <InfoItem label="Auto Rollback" value="✅ Enabled"    />
              <InfoItem label="Environment"   value={CONFIG.environment} />
              <InfoItem label="Build ID"      value={CONFIG.buildId}    />
              <InfoItem label="Deployed At"   value={CONFIG.deployedAt} />
            </div>
          </div>

        </div>
      </main>

      {/* ── Footer ─────────────────────────────────────── */}
      <footer className="footer">
        <span>🔵 DeployOps Platform · v{CONFIG.version}</span>
        <span>Blue-Green Deployment · Zero Downtime · Auto Rollback</span>
        <span>© 2026 DeployOps · All systems operational</span>
      </footer>
    </div>
  )
}

/* ================================================================
   SUB-COMPONENTS
   ================================================================ */
function StatCard({ icon, label, value, sub }: { icon: string; label: string; value: string; sub: string }) {
  return (
    <div className="stat-card">
      <div className="stat-icon">{icon}</div>
      <div>
        <span className="stat-value">{value}</span>
        <span className="stat-label">{label}</span>
        <span className="stat-sub">{sub}</span>
      </div>
    </div>
  )
}

function ProgressBar({ label, value, color }: { label: string; value: number; color: string }) {
  return (
    <div className="prog-metric">
      <div className="prog-header">
        <span>{label}</span>
        <span style={{ color, fontWeight: 700 }}>{Math.round(value)}%</span>
      </div>
      <div className="prog-bar">
        <div className="prog-fill" style={{ width: `${value}%`, background: color }} />
      </div>
    </div>
  )
}

function InfoItem({ label, value }: { label: string; value: string }) {
  return (
    <div className="info-item">
      <span className="info-label">{label}</span>
      <span className="info-value">{value}</span>
    </div>
  )
}
