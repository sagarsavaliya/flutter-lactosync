import { NavLink, useNavigate } from 'react-router-dom'
import {
  LayoutDashboard,
  Building2,
  CreditCard,
  Banknote,
  Tag,
  LogOut,
} from 'lucide-react'
import { cn } from '../../lib/utils'
import { useAuthStore } from '../../stores/authStore'

interface AdminShellProps {
  children: React.ReactNode
  title: string
  rightSlot?: React.ReactNode
}

const navItems = [
  { to: '/dashboard', icon: LayoutDashboard, label: 'Dashboard' },
  { to: '/tenants', icon: Building2, label: 'Tenants' },
  { to: '/plans', icon: CreditCard, label: 'Plans' },
  { to: '/payments', icon: Banknote, label: 'Payments' },
  { to: '/coupons', icon: Tag, label: 'Coupons' },
]

export default function AdminShell({ children, title, rightSlot }: AdminShellProps) {
  const { adminEmail, logout } = useAuthStore()
  const navigate = useNavigate()

  const handleLogout = async () => {
    await logout()
    navigate('/login')
  }

  const initial = adminEmail?.[0]?.toUpperCase() || 'A'

  return (
    <div className="flex h-screen overflow-hidden" style={{ background: '#F0F5F2' }}>

      {/* ── Sidebar ───────────────────────────────────────────────── */}
      <aside
        className="w-64 shrink-0 flex flex-col h-full sidebar-scroll overflow-y-auto"
        style={{
          background: 'linear-gradient(180deg, #0A1F14 0%, #0C2118 60%, #0A1C13 100%)',
          boxShadow: '4px 0 24px rgba(0,0,0,0.35)',
        }}
      >
        {/* Logo */}
        <div className="h-[64px] flex items-center px-5 gap-3 shrink-0"
          style={{ borderBottom: '1px solid rgba(255,255,255,0.05)' }}>
          <div
            className="w-9 h-9 rounded-xl flex items-center justify-center shrink-0"
            style={{
              background: 'linear-gradient(135deg, #2D6A4F 0%, #1B4332 100%)',
              boxShadow: '0 2px 8px rgba(45,106,79,0.5)',
            }}
          >
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
              <path d="M12 3C7.5 3 4 6.5 4 11C4 14.5 6.5 17.5 10 18.5V20H14V18.5C17.5 17.5 20 14.5 20 11C20 6.5 16.5 3 12 3Z" fill="rgba(255,255,255,0.9)"/>
              <path d="M10 20H14V21C14 21.6 13.6 22 13 22H11C10.4 22 10 21.6 10 21V20Z" fill="rgba(255,255,255,0.7)"/>
            </svg>
          </div>
          <div>
            <p className="text-white text-[13px] font-bold tracking-tight leading-none">LactoSync</p>
            <p
              className="text-[10px] font-semibold tracking-[0.12em] uppercase leading-none mt-1"
              style={{ color: 'rgba(110,231,183,0.65)' }}
            >
              Super Admin
            </p>
          </div>
        </div>

        {/* Nav section label */}
        <div className="px-5 pt-5 pb-2">
          <p className="text-[10px] font-semibold tracking-[0.1em] uppercase"
            style={{ color: 'rgba(255,255,255,0.25)' }}>
            Navigation
          </p>
        </div>

        {/* Nav items */}
        <nav className="flex-1 px-3 pb-4 space-y-0.5">
          {navItems.map(({ to, icon: Icon, label }) => (
            <NavLink
              key={to}
              to={to}
              className={({ isActive }) =>
                cn(
                  'flex items-center gap-3 px-3 py-2.5 rounded-xl text-[13px] font-medium group relative',
                  isActive
                    ? 'text-white'
                    : 'hover:text-white/80'
                )
              }
              style={({ isActive }) => isActive ? {
                background: 'rgba(255,255,255,0.09)',
              } : {}}
            >
              {({ isActive }) => (
                <>
                  {/* Active left glow bar */}
                  {isActive && (
                    <div
                      className="absolute left-0 top-1/2 -translate-y-1/2 w-0.5 h-5 rounded-full"
                      style={{ background: 'linear-gradient(180deg, #6ee7b7, #34d399)' }}
                    />
                  )}

                  {/* Icon container */}
                  <div
                    className={cn(
                      'w-8 h-8 rounded-lg flex items-center justify-center shrink-0 transition-all',
                    )}
                    style={isActive ? {
                      background: 'rgba(52,211,153,0.18)',
                    } : {
                      background: 'rgba(255,255,255,0.04)',
                    }}
                  >
                    <Icon
                      className="w-[15px] h-[15px]"
                      style={{ color: isActive ? '#6ee7b7' : 'rgba(255,255,255,0.45)' }}
                    />
                  </div>

                  <span
                    className="flex-1"
                    style={{ color: isActive ? '#ffffff' : 'rgba(255,255,255,0.55)' }}
                  >
                    {label}
                  </span>
                </>
              )}
            </NavLink>
          ))}
        </nav>

        {/* Bottom: user row */}
        <div
          className="px-3 pb-4 pt-3 shrink-0"
          style={{ borderTop: '1px solid rgba(255,255,255,0.05)' }}
        >
          <div
            className="flex items-center gap-2.5 px-3 py-2 rounded-xl"
            style={{ background: 'rgba(255,255,255,0.04)' }}
          >
            <div
              className="w-7 h-7 rounded-full flex items-center justify-center text-[11px] font-bold shrink-0"
              style={{ background: 'rgba(52,211,153,0.2)', color: '#6ee7b7' }}
            >
              {initial}
            </div>
            <p
              className="flex-1 min-w-0 text-xs truncate"
              style={{ color: 'rgba(255,255,255,0.55)' }}
            >
              {adminEmail}
            </p>
            <button
              onClick={handleLogout}
              className="w-6 h-6 flex items-center justify-center rounded-lg shrink-0 transition-colors"
              style={{ color: 'rgba(255,255,255,0.3)' }}
              onMouseEnter={(e) => (e.currentTarget.style.color = '#f87171')}
              onMouseLeave={(e) => (e.currentTarget.style.color = 'rgba(255,255,255,0.3)')}
              title="Log out"
            >
              <LogOut className="w-3.5 h-3.5" />
            </button>
          </div>
        </div>
      </aside>

      {/* ── Main area ─────────────────────────────────────────────── */}
      <div className="flex-1 flex flex-col min-w-0 overflow-hidden">

        {/* Page header */}
        <header
          className="h-[64px] flex items-center justify-between px-7 shrink-0 sticky top-0 z-30"
          style={{
            background: 'rgba(255,255,255,0.85)',
            backdropFilter: 'blur(12px)',
            borderBottom: '1px solid rgba(45,106,79,0.1)',
            boxShadow: '0 1px 0 rgba(0,0,0,0.04)',
          }}
        >
          <div className="flex items-center gap-3">
            <h1
              className="text-[15px] font-semibold"
              style={{ color: '#0A1F14' }}
            >
              {title}
            </h1>
          </div>
          {rightSlot && <div className="flex items-center gap-3">{rightSlot}</div>}
        </header>

        {/* Content area */}
        <main className="flex-1 overflow-y-auto p-7">
          {children}
        </main>
      </div>
    </div>
  )
}
