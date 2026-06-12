import { useState, useCallback } from 'react'
import { useNavigate } from 'react-router-dom'
import { useQuery } from '@tanstack/react-query'
import {
  Building2,
  Users,
  UserCheck,
  ShoppingBag,
  CircleDollarSign,
  Receipt,
  AlertCircle,
  RefreshCw,
  Loader2,
  MoreHorizontal,
  Eye,
  Banknote,
  CreditCard,
  TrendingUp,
  ArrowRight,
} from 'lucide-react'
import { format } from 'date-fns'
import AdminShell from '../components/layout/AdminShell'
import { Badge } from '../components/ui/badge'
import { Button } from '../components/ui/button'
import { Skeleton } from '../components/ui/skeleton'
import { Alert, AlertTitle, AlertDescription } from '../components/ui/alert'
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
  DropdownMenuSeparator,
} from '../components/ui/dropdown-menu'
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '../components/ui/table'
import { formatCurrency, formatDate } from '../lib/utils'
import apiClient from '../api/client'
import RecordPaymentModal from '../components/modals/RecordPaymentModal'

interface KpiData {
  total_tenants: number
  active_subscriptions: number
  total_customers: number
  todays_orders: number
  monthly_collected: string
  monthly_billed: string
  total_outstanding: string
}

interface TenantRow {
  id: number
  name: string
  phone: string
  plan_name: string | null
  plan_status: 'active' | 'grace_period' | 'suspended' | 'paused' | null
  renewal_date: string | null
  days_until_renewal: number | null
  last_payment_date: string | null
  last_payment_amount: string
  outstanding_balance: string
  customer_count: number
  subscription_count: number
}

interface DashboardData {
  kpis: KpiData
  tenants: TenantRow[]
}

function StatusBadge({ status, days }: { status: TenantRow['plan_status']; days?: number | null }) {
  switch (status) {
    case 'active':
      return <Badge className="bg-emerald-100 text-emerald-800 border-emerald-200 text-xs">Active</Badge>
    case 'grace_period':
      return <Badge className="bg-amber-100 text-amber-800 border-amber-200 text-xs">{`Grace — ${days ?? 0}d`}</Badge>
    case 'suspended':
      return <Badge className="bg-red-100 text-red-800 border-red-200 text-xs">Suspended</Badge>
    case 'paused':
      return <Badge className="bg-blue-100 text-blue-800 border-blue-200 text-xs">Paused</Badge>
    default:
      return <Badge variant="outline" className="text-gray-400 text-xs border-gray-200">No Plan</Badge>
  }
}

function DaysLeft({ days }: { days: number | null }) {
  if (days === null) return <span className="text-gray-300">—</span>
  if (days < 0) return <span className="text-red-600 font-semibold text-xs">Overdue</span>
  if (days <= 3) return <span className="text-red-600 font-bold text-xs">{days}d</span>
  if (days <= 7) return <span className="text-amber-600 font-semibold text-xs">{days}d</span>
  return <span className="text-emerald-600 font-medium text-xs">{days}d</span>
}

interface KpiCardProps {
  label: string
  value: React.ReactNode
  sub?: string
  icon: React.ReactNode
  accent: string
  iconBg: string
  isLoading: boolean
}

function KpiCard({ label, value, sub, icon, accent, iconBg, isLoading }: KpiCardProps) {
  return (
    <div className={`rounded-xl p-5 border ${accent} bg-white relative overflow-hidden`}>
      <div className="flex items-start justify-between">
        <div className="flex-1 min-w-0">
          <p className="text-xs font-semibold text-gray-500 uppercase tracking-widest mb-1">{label}</p>
          {isLoading ? (
            <>
              <Skeleton className="h-8 w-20 mt-1" />
              {sub && <Skeleton className="h-3 w-28 mt-2" />}
            </>
          ) : (
            <>
              <p className="text-2xl font-bold text-gray-900 leading-tight">{value}</p>
              {sub && <p className="text-xs text-gray-400 mt-1">{sub}</p>}
            </>
          )}
        </div>
        <div className={`w-10 h-10 rounded-xl flex items-center justify-center shrink-0 ${iconBg}`}>
          {icon}
        </div>
      </div>
    </div>
  )
}

export default function DashboardPage() {
  const navigate = useNavigate()
  const [lastRefreshed, setLastRefreshed] = useState<Date>(new Date())
  const [recordPaymentTenant, setRecordPaymentTenant] = useState<{ id: string; name: string } | null>(null)
  const [paymentModalOpen, setPaymentModalOpen] = useState(false)

  const { data, isLoading, isError, isFetching, refetch } = useQuery<DashboardData>({
    queryKey: ['dashboard'],
    queryFn: () =>
      apiClient.get('/api/admin/v1/dashboard').then((r) => {
        setLastRefreshed(new Date())
        return r.data
      }),
    refetchInterval: 60_000,
  })

  const handleRefresh = useCallback(() => { refetch() }, [refetch])

  const openRecordPayment = (tenant: TenantRow) => {
    setRecordPaymentTenant({ id: String(tenant.id), name: tenant.name })
    setPaymentModalOpen(true)
  }

  const kpis = data?.kpis
  const tenants = data?.tenants ?? []

  const collectedAmt = parseFloat(kpis?.monthly_collected ?? '0')
  const billedAmt    = parseFloat(kpis?.monthly_billed ?? '0')
  const collectRate  = billedAmt > 0 ? Math.round((collectedAmt / billedAmt) * 100) : 0

  const rightSlot = (
    <div className="flex items-center gap-3">
      <span className="text-xs text-gray-400 hidden sm:block">
        Refreshed {format(lastRefreshed, 'HH:mm:ss')}
      </span>
      <button
        onClick={handleRefresh}
        className="w-8 h-8 rounded-lg border border-gray-200 flex items-center justify-center text-gray-400 hover:text-gray-600 hover:border-gray-300 transition-colors"
        aria-label="Refresh dashboard"
      >
        {isFetching ? <Loader2 className="w-4 h-4 animate-spin" /> : <RefreshCw className="w-4 h-4" />}
      </button>
    </div>
  )

  return (
    <AdminShell title="Dashboard" rightSlot={rightSlot}>

      {isError && (
        <Alert variant="destructive" className="mb-6">
          <AlertCircle className="h-4 w-4" />
          <AlertTitle>Failed to load dashboard</AlertTitle>
          <AlertDescription>
            Could not fetch data.{' '}
            <Button variant="link" className="p-0 h-auto" onClick={handleRefresh}>Try again</Button>
          </AlertDescription>
        </Alert>
      )}

      {/* ── KPI grid ─────────────────────────────────────── */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-4">
        <KpiCard
          label="Total Tenants"
          value={kpis?.total_tenants ?? 0}
          sub={`${kpis?.active_subscriptions ?? 0} with active plan`}
          icon={<Building2 className="w-5 h-5 text-violet-600" />}
          accent="border-violet-100"
          iconBg="bg-violet-50"
          isLoading={isLoading}
        />
        <KpiCard
          label="Customers"
          value={kpis?.total_customers ?? 0}
          sub="Across all tenants"
          icon={<UserCheck className="w-5 h-5 text-blue-600" />}
          accent="border-blue-100"
          iconBg="bg-blue-50"
          isLoading={isLoading}
        />
        <KpiCard
          label="Active Subscriptions"
          value={kpis?.active_subscriptions ?? 0}
          sub="Milk-delivery subs"
          icon={<Users className="w-5 h-5 text-emerald-600" />}
          accent="border-emerald-100"
          iconBg="bg-emerald-50"
          isLoading={isLoading}
        />
        <KpiCard
          label="Today's Orders"
          value={kpis?.todays_orders ?? 0}
          sub={format(new Date(), 'EEEE, d MMM')}
          icon={<ShoppingBag className="w-5 h-5 text-orange-500" />}
          accent="border-orange-100"
          iconBg="bg-orange-50"
          isLoading={isLoading}
        />
      </div>

      {/* ── Revenue row ──────────────────────────────────── */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-4 mb-8">
        {/* Collected */}
        <div className="rounded-xl p-5 bg-gradient-to-br from-emerald-600 to-emerald-700 text-white relative overflow-hidden">
          <div className="absolute right-0 top-0 w-32 h-32 bg-white/5 rounded-full -translate-y-10 translate-x-10" />
          <p className="text-xs font-semibold uppercase tracking-widest text-emerald-200 mb-1">Collected</p>
          {isLoading ? <Skeleton className="h-8 w-28 bg-white/20" /> : (
            <p className="text-2xl font-bold">{formatCurrency(kpis?.monthly_collected ?? '0')}</p>
          )}
          <p className="text-xs text-emerald-200 mt-1">This month</p>
          <CircleDollarSign className="absolute bottom-4 right-4 w-8 h-8 text-white/20" />
        </div>

        {/* Billed */}
        <div className="rounded-xl p-5 bg-white border border-gray-200 relative overflow-hidden">
          <p className="text-xs font-semibold uppercase tracking-widest text-gray-500 mb-1">Total Billed</p>
          {isLoading ? <Skeleton className="h-8 w-28" /> : (
            <p className="text-2xl font-bold text-gray-900">{formatCurrency(kpis?.monthly_billed ?? '0')}</p>
          )}
          <p className="text-xs text-gray-400 mt-1">This month</p>
          {!isLoading && billedAmt > 0 && (
            <div className="mt-3">
              <div className="flex justify-between text-xs text-gray-400 mb-1">
                <span>Collection rate</span>
                <span className={collectRate >= 80 ? 'text-emerald-600 font-semibold' : 'text-amber-600 font-semibold'}>
                  {collectRate}%
                </span>
              </div>
              <div className="h-1.5 rounded-full bg-gray-100 overflow-hidden">
                <div
                  className={`h-full rounded-full transition-all ${collectRate >= 80 ? 'bg-emerald-500' : 'bg-amber-500'}`}
                  style={{ width: `${Math.min(collectRate, 100)}%` }}
                />
              </div>
            </div>
          )}
          <Receipt className="absolute bottom-4 right-4 w-8 h-8 text-gray-100" />
        </div>

        {/* Outstanding */}
        <div className={`rounded-xl p-5 relative overflow-hidden border ${
          parseFloat(kpis?.total_outstanding ?? '0') > 0
            ? 'bg-red-50 border-red-200'
            : 'bg-white border-gray-200'
        }`}>
          <p className="text-xs font-semibold uppercase tracking-widest text-gray-500 mb-1">Outstanding</p>
          {isLoading ? <Skeleton className="h-8 w-28" /> : (
            <p className={`text-2xl font-bold ${parseFloat(kpis?.total_outstanding ?? '0') > 0 ? 'text-red-700' : 'text-gray-900'}`}>
              {formatCurrency(kpis?.total_outstanding ?? '0')}
            </p>
          )}
          <p className="text-xs text-gray-400 mt-1">Pending across all tenants</p>
          <AlertCircle className="absolute bottom-4 right-4 w-8 h-8 text-red-100" />
        </div>
      </div>

      {/* ── Tenant table ─────────────────────────────────── */}
      <div>
        <div className="flex items-center justify-between mb-3">
          <div>
            <h2 className="text-sm font-semibold text-gray-800">All Tenants</h2>
            <p className="text-xs text-gray-400 mt-0.5">{tenants.length} total</p>
          </div>
          <Button
            variant="outline"
            size="sm"
            className="text-xs"
            onClick={() => navigate('/tenants')}
          >
            Manage tenants <ArrowRight className="w-3 h-3 ml-1.5" />
          </Button>
        </div>

        <div className="rounded-xl border border-gray-200 bg-white overflow-hidden">
          {isLoading ? (
            <div className="p-4 space-y-3">
              {Array.from({ length: 4 }).map((_, i) => (
                <Skeleton key={i} className="h-10 w-full" />
              ))}
            </div>
          ) : tenants.length === 0 ? (
            <div className="flex flex-col items-center justify-center py-16 text-center">
              <Building2 className="w-12 h-12 text-gray-200 mb-3" />
              <p className="text-sm font-medium text-gray-500">No tenants yet</p>
              <p className="text-xs text-gray-400 mt-1">Tenants you onboard will appear here.</p>
            </div>
          ) : (
            <Table>
              <TableHeader>
                <TableRow className="bg-gray-50 hover:bg-gray-50">
                  <TableHead className="text-xs font-semibold text-gray-500 uppercase tracking-wide">Tenant</TableHead>
                  <TableHead className="text-xs font-semibold text-gray-500 uppercase tracking-wide">Plan</TableHead>
                  <TableHead className="text-xs font-semibold text-gray-500 uppercase tracking-wide">Status</TableHead>
                  <TableHead className="text-xs font-semibold text-gray-500 uppercase tracking-wide">Renewal</TableHead>
                  <TableHead className="text-xs font-semibold text-gray-500 uppercase tracking-wide text-right">Days</TableHead>
                  <TableHead className="text-xs font-semibold text-gray-500 uppercase tracking-wide text-right">Outstanding</TableHead>
                  <TableHead className="w-10" />
                </TableRow>
              </TableHeader>
              <TableBody>
                {tenants.map((tenant) => (
                  <TableRow
                    key={tenant.id}
                    className={cn(
                      'transition-colors',
                      tenant.plan_status === 'suspended' ? 'bg-red-50/60' : ''
                    )}
                  >
                    <TableCell>
                      <button
                        onClick={() => navigate(`/tenants/${tenant.id}`)}
                        className="font-medium text-sm text-gray-800 hover:text-emerald-700 transition-colors text-left"
                      >
                        {tenant.name}
                      </button>
                      <p className="text-xs text-gray-400">{tenant.phone}</p>
                    </TableCell>
                    <TableCell>
                      <span className="text-sm text-gray-600">{tenant.plan_name || <span className="text-gray-300 italic">No plan</span>}</span>
                    </TableCell>
                    <TableCell>
                      <StatusBadge status={tenant.plan_status} days={tenant.days_until_renewal} />
                    </TableCell>
                    <TableCell>
                      <span className="text-xs text-gray-500">{formatDate(tenant.renewal_date)}</span>
                    </TableCell>
                    <TableCell className="text-right">
                      <DaysLeft days={tenant.days_until_renewal} />
                    </TableCell>
                    <TableCell className="text-right">
                      <span className={`text-sm font-semibold ${parseFloat(String(tenant.outstanding_balance)) > 0 ? 'text-red-600' : 'text-gray-400'}`}>
                        {formatCurrency(tenant.outstanding_balance)}
                      </span>
                    </TableCell>
                    <TableCell>
                      <DropdownMenu>
                        <DropdownMenuTrigger asChild>
                          <Button variant="ghost" size="icon" className="h-7 w-7">
                            <MoreHorizontal className="w-4 h-4" />
                          </Button>
                        </DropdownMenuTrigger>
                        <DropdownMenuContent align="end">
                          <DropdownMenuItem onClick={() => navigate(`/tenants/${tenant.id}`)}>
                            <Eye className="w-4 h-4 mr-2" /> View Details
                          </DropdownMenuItem>
                          <DropdownMenuItem onClick={() => openRecordPayment(tenant)}>
                            <Banknote className="w-4 h-4 mr-2" /> Record Payment
                          </DropdownMenuItem>
                          <DropdownMenuSeparator />
                          <DropdownMenuItem onClick={() => navigate(`/tenants/${tenant.id}#plan`)}>
                            <CreditCard className="w-4 h-4 mr-2" /> Manage Plan
                          </DropdownMenuItem>
                        </DropdownMenuContent>
                      </DropdownMenu>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          )}
        </div>

        {/* Collection rate footnote */}
        {!isLoading && tenants.length > 0 && (
          <div className="mt-3 flex items-center gap-1.5 text-xs text-gray-400">
            <TrendingUp className="w-3.5 h-3.5" />
            <span>
              {tenants.filter(t => t.plan_status === 'active').length} active ·{' '}
              {tenants.filter(t => t.plan_status === 'grace_period').length} in grace ·{' '}
              {tenants.filter(t => t.plan_status === 'suspended').length} suspended ·{' '}
              {tenants.filter(t => !t.plan_status || t.plan_status === null).length} no plan
            </span>
          </div>
        )}
      </div>

      {/* Record Payment Modal */}
      <RecordPaymentModal
        open={paymentModalOpen}
        onOpenChange={setPaymentModalOpen}
        tenantId={recordPaymentTenant?.id}
        tenantName={recordPaymentTenant?.name}
        onSuccess={() => refetch()}
      />
    </AdminShell>
  )
}

function cn(...classes: (string | boolean | undefined)[]) {
  return classes.filter(Boolean).join(' ')
}
