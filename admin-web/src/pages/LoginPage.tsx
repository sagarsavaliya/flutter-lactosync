import { useState, useRef, useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
import { Loader2, AlertCircle, CheckCircle2 } from 'lucide-react'
import { Input } from '../components/ui/input'
import { Button } from '../components/ui/button'
import { Label } from '../components/ui/label'
import { Alert, AlertTitle, AlertDescription } from '../components/ui/alert'
import { useAuthStore } from '../stores/authStore'
import apiClient from '../api/client'

const FEATURES = [
  'Tenant subscription lifecycle',
  'SaaS plan governance & pricing',
  'Payment tracking & audit trail',
  'Real-time dashboard KPIs',
]

type ErrorType = 'invalid' | 'locked' | 'network' | null

export default function LoginPage() {
  const navigate = useNavigate()
  const { setAuth } = useAuthStore()

  const [email, setEmail] = useState('')
  const [pin, setPin] = useState<string[]>(Array(6).fill(''))
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<ErrorType>(null)
  const [locked, setLocked] = useState(false)
  const [lockoutSeconds, setLockoutSeconds] = useState(0)

  const pinRefs = useRef<Array<HTMLInputElement | null>>(Array(6).fill(null))

  useEffect(() => {
    if (!locked || lockoutSeconds <= 0) return
    const interval = setInterval(() => {
      setLockoutSeconds((s) => {
        if (s <= 1) {
          clearInterval(interval)
          setLocked(false)
          setError(null)
          setTimeout(() => {
            const el = document.getElementById('email')
            if (el) (el as HTMLInputElement).focus()
          }, 50)
          return 0
        }
        return s - 1
      })
    }, 1000)
    return () => clearInterval(interval)
  }, [locked, lockoutSeconds])

  const formatCountdown = (secs: number) => {
    const m = Math.floor(secs / 60).toString().padStart(2, '0')
    const s = (secs % 60).toString().padStart(2, '0')
    return `${m}:${s}`
  }

  const handlePinChange = (index: number, value: string) => {
    if (locked) return
    const digit = value.replace(/\D/g, '').slice(-1)
    const newPin = [...pin]
    newPin[index] = digit
    setPin(newPin)
    if (digit && index < 5) pinRefs.current[index + 1]?.focus()
  }

  const handlePinKeyDown = (index: number, e: React.KeyboardEvent<HTMLInputElement>) => {
    if (e.key === 'Backspace') {
      if (!pin[index] && index > 0) {
        const newPin = [...pin]
        newPin[index - 1] = ''
        setPin(newPin)
        pinRefs.current[index - 1]?.focus()
      } else {
        const newPin = [...pin]
        newPin[index] = ''
        setPin(newPin)
      }
    }
  }

  const handlePinPaste = (e: React.ClipboardEvent) => {
    e.preventDefault()
    const text = e.clipboardData.getData('text').replace(/\D/g, '').slice(0, 6)
    const newPin = [...pin]
    for (let i = 0; i < text.length; i++) newPin[i] = text[i]
    setPin(newPin)
    pinRefs.current[Math.min(text.length, 5)]?.focus()
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    if (locked) return
    const pinValue = pin.join('')
    if (!email || pinValue.length < 6) return

    setLoading(true)
    setError(null)

    try {
      const res = await apiClient.post('/api/admin/v1/auth/login', { email, pin: pinValue })
      const { data } = res.data  // { success, data: { token, email, name } }
      setAuth(data.token, data.email || email)
      navigate('/dashboard')
    } catch (err: unknown) {
      const axiosErr = err as { response?: { status: number; data?: { error?: { retry_after?: number } } } }
      if (axiosErr.response?.status === 423) {
        setError('locked')
        setLocked(true)
        setLockoutSeconds(axiosErr.response?.data?.error?.retry_after || 900)
      } else if (axiosErr.response?.status === 401) {
        setError('invalid')
        setPin(Array(6).fill(''))
        pinRefs.current[0]?.focus()
      } else {
        setError('network')
      }
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen flex">

      {/* ── Left branding panel (desktop only) ─────────────── */}
      <div className="hidden lg:flex lg:w-[52%] flex-col justify-between p-12 relative overflow-hidden"
        style={{ background: 'linear-gradient(180deg, #0A1F14 0%, #0C2118 60%, #0A1C13 100%)' }}>

        {/* Radial glow */}
        <div className="absolute inset-0 pointer-events-none"
          style={{ background: 'radial-gradient(ellipse 70% 55% at 45% 60%, rgba(45,106,79,0.30) 0%, transparent 70%)' }}
        />

        {/* Top: Logo */}
        <div className="relative flex items-center gap-3">
          <div
            className="w-9 h-9 rounded-xl flex items-center justify-center shrink-0"
            style={{ background: 'linear-gradient(135deg, #2D6A4F 0%, #1B4332 100%)', boxShadow: '0 2px 10px rgba(45,106,79,0.5)' }}
          >
            <span className="text-white text-base font-bold select-none">L</span>
          </div>
          <span className="text-white font-bold text-xl tracking-tight">LactoSync</span>
          <span
            className="text-[11px] font-semibold px-2 py-0.5 rounded-full tracking-wide"
            style={{ background: 'rgba(52,211,153,0.12)', color: '#6ee7b7', border: '1px solid rgba(52,211,153,0.2)' }}
          >
            Admin
          </span>
        </div>

        {/* Middle: Hero copy + feature list */}
        <div className="relative">
          <h1 className="text-white text-[2.6rem] font-bold leading-snug mb-4 tracking-tight">
            Your dairy platform,<br />fully in control.
          </h1>
          <p className="text-slate-400 text-base mb-10 leading-relaxed max-w-sm">
            One place to manage every tenant, subscription,
            and payment across your SaaS platform.
          </p>
          <ul className="space-y-3.5">
            {FEATURES.map((f) => (
              <li key={f} className="flex items-center gap-3">
                <div
                  className="w-5 h-5 rounded-full flex items-center justify-center shrink-0"
                  style={{ background: 'rgba(52,211,153,0.12)', border: '1px solid rgba(52,211,153,0.25)' }}
                >
                  <CheckCircle2 className="w-3 h-3" style={{ color: '#6ee7b7' }} />
                </div>
                <span className="text-slate-300 text-sm">{f}</span>
              </li>
            ))}
          </ul>
        </div>

        {/* Bottom: Copyright */}
        <p className="relative text-xs" style={{ color: 'rgba(255,255,255,0.2)' }}>
          © 2026 Aksharatech · All rights reserved
        </p>
      </div>

      {/* ── Right form panel ────────────────────────────────── */}
      <div className="flex-1 flex items-center justify-center px-8 py-12" style={{ background: '#F4F7F5' }}>
        <div
          className="w-full max-w-[380px] rounded-2xl bg-white p-9"
          style={{ boxShadow: '0 4px 32px rgba(10,31,20,0.10), 0 1px 4px rgba(10,31,20,0.06)' }}
        >

          {/* Mobile logo */}
          <div className="lg:hidden flex items-center gap-2.5 mb-8">
            <div
              className="w-8 h-8 rounded-lg flex items-center justify-center"
              style={{ background: 'linear-gradient(135deg, #2D6A4F 0%, #1B4332 100%)' }}
            >
              <span className="text-white font-bold text-sm">L</span>
            </div>
            <span className="font-bold text-slate-900 text-lg tracking-tight">LactoSync</span>
          </div>

          <h2 className="text-[1.5rem] font-bold mb-1 tracking-tight" style={{ color: '#0A1F14' }}>
            Welcome back
          </h2>
          <p className="text-sm mb-8" style={{ color: '#6B7280' }}>
            Sign in to your admin account to continue.
          </p>

          <form onSubmit={handleSubmit} className="space-y-5">

            {/* Email */}
            <div>
              <Label htmlFor="email" className="text-sm font-medium text-slate-700 mb-1.5 block">
                Email address
              </Label>
              <Input
                id="email"
                type="email"
                placeholder="you@aksharatech.com"
                autoComplete="email"
                autoFocus
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                disabled={locked || loading}
                className="h-10 bg-[#F4F7F5] border-[#D1DDD8] focus-visible:ring-[#2D6A4F]/30 focus-visible:border-[#2D6A4F]"
              />
            </div>

            {/* PIN */}
            <div>
              <Label id="pin-label" className="text-sm font-medium text-slate-700 mb-2 block">
                6-digit PIN
              </Label>
              <div
                role="group"
                aria-labelledby="pin-label"
                className="grid grid-cols-6 gap-2"
                onPaste={handlePinPaste}
              >
                {pin.map((digit, i) => (
                  <input
                    key={i}
                    ref={(el) => { pinRefs.current[i] = el }}
                    type="text"
                    inputMode="numeric"
                    maxLength={1}
                    value={digit}
                    onChange={(e) => handlePinChange(i, e.target.value)}
                    onKeyDown={(e) => handlePinKeyDown(i, e)}
                    disabled={locked || loading}
                    aria-label={`PIN digit ${i + 1}`}
                    className={[
                      'w-full h-12 text-center text-xl font-semibold rounded-lg',
                      'border bg-[#F4F7F5] text-[#0A1F14]',
                      'focus:outline-none transition-colors duration-150',
                      '[appearance:textfield] [&::-webkit-inner-spin-button]:appearance-none',
                      'disabled:opacity-40 disabled:cursor-not-allowed',
                    ].join(' ')}
                    style={{ borderColor: '#D1DDD8' }}
                    onFocus={(e) => { e.currentTarget.style.borderColor = '#2D6A4F'; e.currentTarget.style.boxShadow = '0 0 0 3px rgba(45,106,79,0.15)' }}
                    onBlur={(e) => { e.currentTarget.style.borderColor = '#D1DDD8'; e.currentTarget.style.boxShadow = 'none' }}
                  />
                ))}
              </div>
            </div>

            {/* Submit */}
            <Button
              type="submit"
              className="w-full h-10 text-white font-semibold text-sm transition-colors"
              style={{ background: '#2D6A4F' }}
              onMouseEnter={(e) => ((e.currentTarget as HTMLButtonElement).style.background = '#245940')}
              onMouseLeave={(e) => ((e.currentTarget as HTMLButtonElement).style.background = '#2D6A4F')}
              disabled={locked || loading}
            >
              {loading
                ? <><Loader2 className="w-4 h-4 animate-spin mr-2" />Signing in…</>
                : 'Sign in'
              }
            </Button>

            {/* Alerts */}
            <div aria-live="polite" className="space-y-0">
              {error === 'invalid' && (
                <Alert variant="destructive">
                  <AlertCircle className="h-4 w-4" />
                  <AlertTitle>Invalid credentials</AlertTitle>
                  <AlertDescription>
                    The email or PIN you entered is incorrect. Please try again.
                  </AlertDescription>
                </Alert>
              )}
              {error === 'network' && (
                <Alert variant="destructive">
                  <AlertCircle className="h-4 w-4" />
                  <AlertTitle>Something went wrong</AlertTitle>
                  <AlertDescription>
                    Could not reach the server. Check your connection and try again.
                  </AlertDescription>
                </Alert>
              )}
              {error === 'locked' && (
                <Alert className="border-amber-300 bg-amber-50 text-amber-800">
                  <AlertTitle>Too many attempts</AlertTitle>
                  <AlertDescription aria-live="polite">
                    Try again in{' '}
                    <span className="font-mono font-semibold">
                      {formatCountdown(lockoutSeconds)}
                    </span>
                  </AlertDescription>
                </Alert>
              )}
            </div>
          </form>

          <p className="mt-10 text-center text-xs text-slate-400 lg:hidden">
            © 2026 Aksharatech · All rights reserved
          </p>
        </div>
      </div>
    </div>
  )
}
