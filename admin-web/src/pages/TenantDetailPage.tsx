import { useState } from 'react'
import { useParams, useNavigate, Link } from 'react-router-dom'
import { useQuery, useQueryClient } from '@tanstack/react-query'
import {
  Phone,
  Mail,
  MapPin,
  Calendar,
  PauseCircle,
  PlayCircle,
  Plus,
  Pencil,
  Trash2,
  MoreHorizontal,
  AlertCircle,
  Building2,
  FileText,
  ToggleLeft,
  ToggleRight,
  Layers,
  Upload,
  Download,
} from 'lucide-react'
import AdminShell from '../components/layout/AdminShell'
import { Card, CardContent, CardTitle } from '../components/ui/card'
import { Badge } from '../components/ui/badge'
import { Button } from '../components/ui/button'
import { Skeleton } from '../components/ui/skeleton'
import { Separator } from '../components/ui/separator'
import { Progress } from '../components/ui/progress'
import { Alert, AlertTitle, AlertDescription } from '../components/ui/alert'
import { Input } from '../components/ui/input'
import { Label } from '../components/ui/label'
import {
  Sheet,
  SheetContent,
  SheetDescription,
  SheetHeader,
  SheetTitle,
} from '../components/ui/sheet'
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '../components/ui/table'
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from '../components/ui/dropdown-menu'
import { AlertDialog, AlertDialogAction, AlertDialogCancel, AlertDialogContent, AlertDialogDescription, AlertDialogFooter, AlertDialogHeader, AlertDialogTitle } from '../components/ui/alert-dialog'
import { formatCurrency, formatDate, formatDateTime } from '../lib/utils'
import apiClient from '../api/client'
import RecordPaymentModal from '../components/modals/RecordPaymentModal'
import PlanActionModals from '../components/modals/PlanActionModals'
import { toast } from '../components/ui/use-toast'

interface PaymentRecord {
  id: number
  amount: number
  payment_date: string | null
  due_date: string | null
  payment_method: string
  paid_by_name: string | null
  reference: string | null
  notes: string | null
  created_at: string
}

interface ActivityEntry {
  action: string
  from_plan: string | null
  to_plan: string | null
  changed_at: string | null
  reason: string | null
}

interface TenantDetail {
  profile: {
    id: number
    name: string
    phone: string
    email: string | null
    is_active: boolean
    farm_name: string | null
    address_line: string | null
    city: string | null
    state: string | null
    zip: string | null
    gst_number: string | null
    created_at: string
  }
  current_plan: {
    plan_name: string | null
    status: 'active' | 'grace_period' | 'suspended' | 'paused'
    start_date: string | null
    renewal_date: string | null
    days_until_renewal: number | null
    paused_at: string | null
  } | null
  usage: {
    customer_count: number
    subscription_count: number
  }
  plan_limits: {
    max_customers: number
    max_subscriptions: number
  } | null
  payment_summary: {
    last_paid_date: string | null
    last_paid_amount: number | null
    outstanding_balance: number
    total_paid_ever: number
  }
  payment_history: PaymentRecord[]
  activity_trail: ActivityEntry[]
}

type PlanStatus = 'active' | 'grace_period' | 'suspended' | 'paused' | 'no_plan'

function getStatusBadge(status: PlanStatus) {
  switch (status) {
    case 'active':
      return <Badge className="bg-green-100 text-green-800 border-green-200">Active</Badge>
    case 'grace_period':
      return <Badge variant="warning">Grace Period</Badge>
    case 'suspended':
      return <Badge variant="destructive">Suspended</Badge>
    case 'paused':
      return <Badge className="bg-blue-100 text-blue-800 border-blue-200">Paused</Badge>
    case 'no_plan':
      return <Badge variant="outline" className="text-gray-500">No Plan</Badge>
  }
}

function getDaysColor(days: number | null) {
  if (days === null) return 'text-gray-400'
  if (days > 7) return 'text-green-600 font-semibold'
  if (days >= 1) return 'text-amber-600 font-semibold'
  return 'text-red-600 font-semibold'
}

function getProgressBarColor(pct: number) {
  if (pct > 30) return '[&>div]:bg-green-600'
  if (pct > 10) return '[&>div]:bg-amber-500'
  return '[&>div]:bg-red-500'
}

function getActivityLabel(a: ActivityEntry): string {
  switch (a.action) {
    case 'initial_assignment': return `Plan assigned: ${a.to_plan || ''}`
    case 'upgrade': return `Plan changed to ${a.to_plan || ''}`
    case 'downgrade': return `Plan changed to ${a.to_plan || ''}`
    case 'paused': return 'Plan paused'
    case 'resumed': return 'Plan resumed'
    default: return a.action || 'Unknown action'
  }
}

// ─── Edit Profile Sheet ────────────────────────────────────────────────────

interface EditProfileForm {
  name: string
  mobile: string
  farm_name: string
  address_line: string
  city: string
  state: string
  zip: string
  gst_number: string
  new_pin: string
  confirm_pin: string
  is_active: boolean
}

interface EditProfileSheetProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  tenantId: number
  profile: TenantDetail['profile']
  onSuccess: () => void
}

function EditProfileSheet({ open, onOpenChange, tenantId, profile, onSuccess }: EditProfileSheetProps) {
  const [form, setForm] = useState<EditProfileForm>({
    name: profile.name ?? '',
    mobile: profile.phone ?? '',
    farm_name: profile.farm_name ?? '',
    address_line: profile.address_line ?? '',
    city: profile.city ?? '',
    state: profile.state ?? '',
    zip: profile.zip ?? '',
    gst_number: profile.gst_number ?? '',
    new_pin: '',
    confirm_pin: '',
    is_active: profile.is_active,
  })
  const [saving, setSaving] = useState(false)

  const set = (field: keyof EditProfileForm, value: string | boolean) =>
    setForm((prev) => ({ ...prev, [field]: value }))

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()

    if (form.new_pin && form.new_pin !== form.confirm_pin) {
      toast({ title: 'PIN mismatch', description: 'New PIN and confirm PIN do not match.', variant: 'destructive' })
      return
    }
    if (form.new_pin && !/^\d{6}$/.test(form.new_pin)) {
      toast({ title: 'Invalid PIN', description: 'PIN must be exactly 6 digits.', variant: 'destructive' })
      return
    }

    const payload: Record<string, unknown> = {
      name: form.name,
      mobile: form.mobile,
      farm_name: form.farm_name,
      address_line: form.address_line || null,
      city: form.city || null,
      state: form.state || null,
      zip: form.zip || null,
      gst_number: form.gst_number || null,
      is_active: form.is_active,
    }
    if (form.new_pin) {
      payload.new_pin = form.new_pin
    }

    try {
      setSaving(true)
      await apiClient.put(`/api/admin/v1/tenants/${tenantId}/profile`, payload)
      toast({ title: 'Profile updated', description: 'Tenant profile has been saved.' })
      onSuccess()
      onOpenChange(false)
    } catch (err: unknown) {
      const msg = (err as { response?: { data?: { message?: string } } })?.response?.data?.message
      toast({ title: 'Update failed', description: msg || 'Something went wrong.', variant: 'destructive' })
    } finally {
      setSaving(false)
    }
  }

  return (
    <Sheet open={open} onOpenChange={onOpenChange}>
      <SheetContent className="w-full sm:max-w-lg overflow-y-auto">
        <SheetHeader className="mb-6">
          <SheetTitle>Edit Tenant Profile</SheetTitle>
          <SheetDescription>Update owner details, farm info, and account settings.</SheetDescription>
        </SheetHeader>

        <form onSubmit={handleSubmit} className="space-y-6">
          {/* Owner details */}
          <div>
            <p className="text-xs font-semibold text-gray-500 uppercase tracking-wide mb-3">Owner Details</p>
            <div className="space-y-3">
              <div>
                <Label htmlFor="ep-name">Owner Name</Label>
                <Input id="ep-name" value={form.name} onChange={(e) => set('name', e.target.value)} required />
              </div>
              <div>
                <Label htmlFor="ep-mobile">Mobile</Label>
                <Input id="ep-mobile" value={form.mobile} onChange={(e) => set('mobile', e.target.value)} />
              </div>
            </div>
          </div>

          <Separator />

          {/* Farm details */}
          <div>
            <p className="text-xs font-semibold text-gray-500 uppercase tracking-wide mb-3">Farm Details</p>
            <div className="space-y-3">
              <div>
                <Label htmlFor="ep-farm-name">Farm Name</Label>
                <Input id="ep-farm-name" value={form.farm_name} onChange={(e) => set('farm_name', e.target.value)} />
              </div>
              <div>
                <Label htmlFor="ep-address">Address Line</Label>
                <Input id="ep-address" value={form.address_line} onChange={(e) => set('address_line', e.target.value)} />
              </div>
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <Label htmlFor="ep-city">City</Label>
                  <Input id="ep-city" value={form.city} onChange={(e) => set('city', e.target.value)} />
                </div>
                <div>
                  <Label htmlFor="ep-state">State</Label>
                  <Input id="ep-state" value={form.state} onChange={(e) => set('state', e.target.value)} />
                </div>
              </div>
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <Label htmlFor="ep-zip">ZIP / Pin Code</Label>
                  <Input id="ep-zip" value={form.zip} onChange={(e) => set('zip', e.target.value)} />
                </div>
                <div>
                  <Label htmlFor="ep-gst">GST Number</Label>
                  <Input id="ep-gst" value={form.gst_number} onChange={(e) => set('gst_number', e.target.value)} placeholder="Optional" />
                </div>
              </div>
            </div>
          </div>

          <Separator />

          {/* Account settings */}
          <div>
            <p className="text-xs font-semibold text-gray-500 uppercase tracking-wide mb-3">Account Settings</p>
            <div className="space-y-3">
              {/* Active toggle */}
              <div className="flex items-center justify-between rounded-lg border border-gray-200 px-4 py-3">
                <div>
                  <p className="text-sm font-medium text-gray-800">Account Active</p>
                  <p className="text-xs text-gray-400">Inactive owners cannot log in to the app.</p>
                </div>
                <button
                  type="button"
                  onClick={() => set('is_active', !form.is_active)}
                  className="focus:outline-none"
                >
                  {form.is_active
                    ? <ToggleRight className="w-8 h-8 text-green-600" />
                    : <ToggleLeft className="w-8 h-8 text-gray-400" />
                  }
                </button>
              </div>

              {/* PIN reset */}
              <div>
                <Label htmlFor="ep-pin">New PIN (leave blank to keep current)</Label>
                <Input
                  id="ep-pin"
                  type="password"
                  inputMode="numeric"
                  maxLength={6}
                  pattern="\d{6}"
                  value={form.new_pin}
                  onChange={(e) => set('new_pin', e.target.value)}
                  placeholder="6-digit PIN"
                  autoComplete="new-password"
                />
              </div>
              {form.new_pin && (
                <div>
                  <Label htmlFor="ep-confirm-pin">Confirm New PIN</Label>
                  <Input
                    id="ep-confirm-pin"
                    type="password"
                    inputMode="numeric"
                    maxLength={6}
                    pattern="\d{6}"
                    value={form.confirm_pin}
                    onChange={(e) => set('confirm_pin', e.target.value)}
                    placeholder="Repeat 6-digit PIN"
                    autoComplete="new-password"
                  />
                </div>
              )}
            </div>
          </div>

          <div className="flex justify-end gap-3 pt-2">
            <Button type="button" variant="outline" onClick={() => onOpenChange(false)}>
              Cancel
            </Button>
            <Button type="submit" className="bg-green-700 hover:bg-green-800 text-white" disabled={saving}>
              {saving ? 'Saving…' : 'Save Changes'}
            </Button>
          </div>
        </form>
      </SheetContent>
    </Sheet>
  )
}

// ─── Main page ─────────────────────────────────────────────────────────────

export default function TenantDetailPage() {
  const { id } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const queryClient = useQueryClient()

  const [paymentModalOpen, setPaymentModalOpen] = useState(false)
  const [editPayment, setEditPayment] = useState<PaymentRecord | null>(null)
  const [deletePayment, setDeletePayment] = useState<PaymentRecord | null>(null)
  const [planModalType, setPlanModalType] = useState<'assign' | 'change' | 'pause' | 'resume' | null>(null)
  const [editProfileOpen, setEditProfileOpen] = useState(false)
  const [savingModules, setSavingModules] = useState<string | null>(null)
  const [importingBootstrap, setImportingBootstrap] = useState(false)

  const { data: tenant, isLoading, isError, refetch } = useQuery<TenantDetail>({
    queryKey: ['tenant', id],
    queryFn: () => apiClient.get(`/api/admin/v1/tenants/${id}`).then((r) => r.data.data),
    enabled: !!id,
  })

  interface ModuleEntry { module_slug: string; is_enabled: boolean; has_override: boolean }
  const { data: modulesData, refetch: refetchModules } = useQuery<ModuleEntry[]>({
    queryKey: ['tenant-modules', id],
    queryFn: () => apiClient.get(`/api/admin/v1/tenants/${id}/modules`).then((r) => r.data.data),
    enabled: !!id,
  })

  const MODULE_LABELS: Record<string, string> = {
    route_delivery:         'Route-based Delivery',
    customer_app:           'Customer App',
    whatsapp_notifications: 'WhatsApp Notifications',
    billing_invoices:       'Billing & Invoices',
  }

  const handleModuleToggle = async (slug: string, currentEnabled: boolean) => {
    setSavingModules(slug)
    try {
      await apiClient.put(`/api/admin/v1/tenants/${id}/modules`, {
        modules: { [slug]: !currentEnabled },
      })
      refetchModules()
      toast({ title: `${MODULE_LABELS[slug] ?? slug} ${!currentEnabled ? 'enabled' : 'disabled'}.` })
    } catch {
      toast({ title: 'Failed to update module.', variant: 'destructive' })
    } finally {
      setSavingModules(null)
    }
  }

  const handleDeletePayment = async () => {
    if (!deletePayment) return
    try {
      await apiClient.delete(`/api/admin/v1/payments/${deletePayment.id}`)
      toast({ title: 'Payment deleted.' })
      refetch()
    } catch {
      toast({ title: 'Failed to delete payment.', variant: 'destructive' })
    } finally {
      setDeletePayment(null)
    }
  }

  const handleDownloadBootstrapTemplate = async () => {
    try {
      const response = await apiClient.get('/api/admin/v1/tenants/bootstrap-template', {
        responseType: 'blob',
      })
      const rawType = response.headers['content-type']
      const contentType = typeof rawType === 'string' ? rawType : ''
      if (contentType.includes('application/json')) {
        const text = await (response.data as Blob).text()
        const payload = JSON.parse(text) as { message?: string; error?: { message?: string } }
        throw new Error(payload.error?.message ?? payload.message ?? 'Download failed')
      }
      const blob = new Blob([response.data], {
        type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      })
      const url = window.URL.createObjectURL(blob)
      const link = document.createElement('a')
      link.href = url
      link.download = 'LactoSync_Tenant_Bootstrap_Template.xlsx'
      document.body.appendChild(link)
      link.click()
      link.remove()
      window.URL.revokeObjectURL(url)
      toast({ title: 'Template downloaded', description: 'Open the workbook and fill each sheet in order.' })
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : 'Could not download the bootstrap workbook template.'
      toast({
        title: 'Download failed',
        description: msg,
        variant: 'destructive',
      })
    }
  }

  const handleBootstrapImport = async (file: File) => {
    try {
      setImportingBootstrap(true)
      const formData = new FormData()
      formData.append('file', file)
      const response = await apiClient.post(`/api/admin/v1/tenants/${id}/bootstrap-import`, formData, {
        headers: { 'Content-Type': 'multipart/form-data' },
      })

      const data = response.data?.data as
        | {
            farm_updated?: boolean
            products_created?: number
            customers_created?: number
            subscriptions_created?: number
            subscription_lines_created?: number
            routes_created?: number
            route_customers_created?: number
            warnings?: string[]
          }
        | undefined

      const createdSummary = [
        `${data?.products_created ?? 0} products`,
        `${data?.customers_created ?? 0} customers`,
        `${data?.subscriptions_created ?? 0} subscriptions`,
        `${data?.subscription_lines_created ?? 0} lines`,
        `${data?.routes_created ?? 0} routes`,
      ].join(', ')

      toast({
        title: 'Bootstrap import completed',
        description: data?.warnings?.length
          ? `${createdSummary}. ${data.warnings.length} warning(s): ${data.warnings.slice(0, 2).join(' | ')}`
          : createdSummary,
      })

      queryClient.invalidateQueries({ queryKey: ['tenant', id] })
    } catch (err: unknown) {
      const msg = (err as { response?: { data?: { error?: { message?: string } } } })?.response?.data?.error?.message
      toast({
        title: 'Import failed',
        description: msg || 'Could not import template. Please check file format and try again.',
        variant: 'destructive',
      })
    } finally {
      setImportingBootstrap(false)
    }
  }

  if (isLoading) {
    return (
      <AdminShell title="Loading…">
        <div className="grid grid-cols-3 gap-6">
          <div className="col-span-2 space-y-4">
            <Skeleton className="h-48 w-full" />
            <Skeleton className="h-48 w-full" />
          </div>
          <div className="space-y-4">
            <Skeleton className="h-48 w-full" />
            <Skeleton className="h-32 w-full" />
          </div>
        </div>
      </AdminShell>
    )
  }

  if (isError || !tenant) {
    return (
      <AdminShell title="Tenant">
        {isError ? (
          <Alert variant="destructive">
            <AlertCircle className="h-4 w-4" />
            <AlertTitle>Failed to load tenant</AlertTitle>
            <AlertDescription>
              <Button variant="link" className="p-0 h-auto" onClick={() => refetch()}>
                Try again
              </Button>
            </AlertDescription>
          </Alert>
        ) : (
          <div className="flex flex-col items-center py-20 text-center">
            <AlertCircle className="w-12 h-12 text-gray-300 mb-3" />
            <h3 className="text-lg font-semibold text-gray-600">Tenant not found</h3>
            <Button variant="link" onClick={() => navigate('/tenants')}>
              Back to tenants
            </Button>
          </div>
        )}
      </AdminShell>
    )
  }

  const hasPlan = !!tenant.current_plan
  const planStatus: PlanStatus = tenant.current_plan?.status ?? 'no_plan'

  const planProgressPct = (() => {
    if (!tenant.current_plan?.start_date || !tenant.current_plan?.renewal_date || tenant.current_plan?.days_until_renewal === null) return 0
    const start = new Date(tenant.current_plan.start_date).getTime()
    const end = new Date(tenant.current_plan.renewal_date).getTime()
    const total = end - start
    const elapsed = Date.now() - start
    if (total <= 0) return 0
    return Math.min(100, Math.max(0, (elapsed / total) * 100))
  })()

  const remainingPct = 100 - planProgressPct

  const planModalTenant = {
    id: String(tenant.profile.id),
    name: tenant.profile.name,
    plan_name: tenant.current_plan?.plan_name ?? null,
    plan_price: null,
    status: planStatus,
  }

  const profile = tenant.profile

  return (
    <AdminShell title={profile.name}>
      {/* Breadcrumb */}
      <div className="text-sm text-gray-500 mb-4">
        <Link to="/tenants" className="text-green-700 hover:underline">Tenants</Link>
        <span className="mx-1">/</span>
        <span>{profile.name}</span>
      </div>

      <div className="grid grid-cols-3 gap-6">
        {/* Left column */}
        <div className="col-span-2">
          {/* Plan Status card */}
          <Card id="plan" className="p-5 mb-4">
            <div className="flex items-center justify-between mb-4">
              <div>
                <p className="text-xs text-gray-400 uppercase tracking-wide mb-0.5">Current Plan</p>
                <p className="text-lg font-semibold text-gray-900">{tenant.current_plan?.plan_name || 'No plan assigned'}</p>
              </div>
              {getStatusBadge(planStatus)}
            </div>

            {hasPlan && (
              <>
                <div className="grid grid-cols-3 gap-2 text-sm mb-4">
                  <div>
                    <p className="text-xs text-gray-400">Start date</p>
                    <p className="font-medium">{formatDate(tenant.current_plan!.start_date)}</p>
                  </div>
                  <div>
                    <p className="text-xs text-gray-400">Renewal date</p>
                    <p className="font-medium">{formatDate(tenant.current_plan!.renewal_date)}</p>
                  </div>
                  <div>
                    <p className="text-xs text-gray-400">Days remaining</p>
                    <p className={getDaysColor(tenant.current_plan!.days_until_renewal)}>
                      {tenant.current_plan!.days_until_renewal === null
                        ? '—'
                        : tenant.current_plan!.days_until_renewal < 0
                          ? 'Overdue'
                          : tenant.current_plan!.days_until_renewal}
                    </p>
                  </div>
                </div>

                <div className="mb-4">
                  <div className="flex justify-between text-xs text-gray-400 mb-1">
                    <span>{formatDate(tenant.current_plan!.start_date)}</span>
                    <span>{formatDate(tenant.current_plan!.renewal_date)}</span>
                  </div>
                  <Progress
                    value={planProgressPct}
                    className={`h-2 ${getProgressBarColor(remainingPct)}`}
                  />
                </div>
              </>
            )}

            <div className="flex gap-2">
              {!hasPlan && (
                <Button
                  size="sm"
                  className="bg-green-700 hover:bg-green-800 text-white"
                  onClick={() => setPlanModalType('assign')}
                >
                  Assign Plan
                </Button>
              )}
              {hasPlan && (
                <>
                  <Button size="sm" variant="outline" onClick={() => setPlanModalType('change')}>
                    Change Plan
                  </Button>
                  {planStatus !== 'paused' ? (
                    <Button size="sm" variant="outline" onClick={() => setPlanModalType('pause')}>
                      <PauseCircle className="w-4 h-4 mr-1" /> Pause
                    </Button>
                  ) : (
                    <Button size="sm" variant="outline" onClick={() => setPlanModalType('resume')}>
                      <PlayCircle className="w-4 h-4 mr-1" /> Resume
                    </Button>
                  )}
                </>
              )}
            </div>
          </Card>

          {/* Usage vs Limits */}
          <Card className="p-5 mb-4">
            <CardTitle className="text-sm font-semibold text-gray-700 mb-4">Usage vs Plan Limits</CardTitle>
            {!hasPlan ? (
              <p className="text-sm text-gray-400 italic">No plan — limits not applicable.</p>
            ) : (
              <>
                <div className="mb-3">
                  <div className="flex justify-between text-sm mb-1">
                    <span className="text-gray-600">Customers</span>
                    <span className={
                      tenant.plan_limits?.max_customers && (tenant.usage.customer_count / tenant.plan_limits.max_customers) > 0.9
                        ? 'text-red-600 font-semibold'
                        : 'text-gray-700'
                    }>
                      {tenant.usage.customer_count} / {tenant.plan_limits?.max_customers ?? '∞'}
                    </span>
                  </div>
                  {tenant.plan_limits?.max_customers && (
                    <Progress
                      value={(tenant.usage.customer_count / tenant.plan_limits.max_customers) * 100}
                      className={`h-2 ${getProgressBarColor(100 - (tenant.usage.customer_count / tenant.plan_limits.max_customers) * 100)}`}
                    />
                  )}
                </div>
                <div>
                  <div className="flex justify-between text-sm mb-1">
                    <span className="text-gray-600">Subscriptions</span>
                    <span className={
                      tenant.plan_limits?.max_subscriptions && (tenant.usage.subscription_count / tenant.plan_limits.max_subscriptions) > 0.9
                        ? 'text-red-600 font-semibold'
                        : 'text-gray-700'
                    }>
                      {tenant.usage.subscription_count} / {tenant.plan_limits?.max_subscriptions ?? '∞'}
                    </span>
                  </div>
                  {tenant.plan_limits?.max_subscriptions && (
                    <Progress
                      value={(tenant.usage.subscription_count / tenant.plan_limits.max_subscriptions) * 100}
                      className={`h-2 ${getProgressBarColor(100 - (tenant.usage.subscription_count / tenant.plan_limits.max_subscriptions) * 100)}`}
                    />
                  )}
                </div>
              </>
            )}
          </Card>

          {/* Payment History */}
          <div className="mb-6">
            <div className="flex items-center justify-between mb-3">
              <h3 className="text-base font-semibold text-gray-800">Payment History</h3>
              <Button
                size="sm"
                className="bg-green-700 hover:bg-green-800 text-white"
                onClick={() => setPaymentModalOpen(true)}
              >
                <Plus className="w-4 h-4 mr-1" /> Record Payment
              </Button>
            </div>

            <Card>
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Date</TableHead>
                    <TableHead>Amount</TableHead>
                    <TableHead>Method</TableHead>
                    <TableHead>Paid By</TableHead>
                    <TableHead>Reference</TableHead>
                    <TableHead className="w-16"></TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {tenant.payment_history.map((p) => (
                    <TableRow key={p.id}>
                      <TableCell>{formatDate(p.payment_date)}</TableCell>
                      <TableCell className="font-medium">{formatCurrency(p.amount)}</TableCell>
                      <TableCell>{p.payment_method}</TableCell>
                      <TableCell>{p.paid_by_name || '—'}</TableCell>
                      <TableCell className="text-gray-400 text-xs">{p.reference || '—'}</TableCell>
                      <TableCell>
                        <DropdownMenu>
                          <DropdownMenuTrigger asChild>
                            <Button variant="ghost" size="icon">
                              <MoreHorizontal className="w-4 h-4" />
                            </Button>
                          </DropdownMenuTrigger>
                          <DropdownMenuContent align="end">
                            <DropdownMenuItem onClick={() => setEditPayment(p)}>
                              <Pencil className="w-4 h-4 mr-2" /> Edit
                            </DropdownMenuItem>
                            <DropdownMenuSeparator />
                            <DropdownMenuItem
                              className="text-red-600"
                              onClick={() => setDeletePayment(p)}
                            >
                              <Trash2 className="w-4 h-4 mr-2" /> Delete
                            </DropdownMenuItem>
                          </DropdownMenuContent>
                        </DropdownMenu>
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
              {tenant.payment_history.length === 0 && (
                <p className="text-sm text-gray-400 text-center py-6">No payments recorded yet.</p>
              )}
            </Card>
          </div>

          {/* Activity Trail */}
          <div>
            <h3 className="text-base font-semibold text-gray-800 mb-3">Activity Trail</h3>
            {tenant.activity_trail.length === 0 ? (
              <p className="text-sm text-gray-400">No activity recorded yet.</p>
            ) : (
              <ol className="relative border-l border-gray-200 ml-3 space-y-4">
                {tenant.activity_trail.map((a, i) => (
                  <li key={i} className="ml-4">
                    <div className="absolute -left-1.5 w-3 h-3 rounded-full bg-green-500 border-2 border-white" />
                    <time className="text-xs text-gray-400">{a.changed_at ? formatDateTime(a.changed_at) : '—'}</time>
                    <p className="text-sm text-gray-700 mt-0.5">
                      <span className="font-medium">{getActivityLabel(a)}</span>
                      {a.reason && <span className="text-gray-400"> — {a.reason}</span>}
                    </p>
                  </li>
                ))}
              </ol>
            )}
          </div>
        </div>

        {/* Right column */}
        <div>
          {/* Tenant Profile card */}
          <Card className="p-5 mb-4">
            <div className="flex items-start justify-between mb-4">
              <div>
                <div className="flex items-center gap-2 mb-0.5">
                  <h2 className="text-base font-semibold text-gray-900">{profile.name}</h2>
                  {!profile.is_active && (
                    <Badge variant="destructive" className="text-[10px] px-1.5 py-0">Inactive</Badge>
                  )}
                </div>
                <p className="text-sm text-gray-500">{profile.phone || 'Farm owner'}</p>
              </div>
              <div className="flex items-center gap-2">
                {getStatusBadge(planStatus)}
                <Button
                  variant="outline"
                  size="sm"
                  onClick={() => setEditProfileOpen(true)}
                >
                  <Pencil className="w-3.5 h-3.5 mr-1" />
                  Edit
                </Button>
              </div>
            </div>
            <CardContent className="p-0 space-y-2 text-sm text-gray-600">
              <div className="flex gap-2">
                <Phone className="w-4 h-4 mt-0.5 text-gray-400 shrink-0" />
                <span>{profile.phone || '—'}</span>
              </div>
              <div className="flex gap-2">
                <Mail className="w-4 h-4 mt-0.5 text-gray-400 shrink-0" />
                <span>{profile.email || '—'}</span>
              </div>
              {profile.farm_name && (
                <div className="flex gap-2">
                  <Building2 className="w-4 h-4 mt-0.5 text-gray-400 shrink-0" />
                  <span>{profile.farm_name}</span>
                </div>
              )}
              {(profile.address_line || profile.city || profile.state) && (
                <div className="flex gap-2">
                  <MapPin className="w-4 h-4 mt-0.5 text-gray-400 shrink-0" />
                  <span>
                    {[profile.address_line, profile.city, profile.state, profile.zip].filter(Boolean).join(', ')}
                  </span>
                </div>
              )}
              {profile.gst_number && (
                <div className="flex gap-2">
                  <FileText className="w-4 h-4 mt-0.5 text-gray-400 shrink-0" />
                  <span>GST: {profile.gst_number}</span>
                </div>
              )}
              <div className="flex gap-2">
                <Calendar className="w-4 h-4 mt-0.5 text-gray-400 shrink-0" />
                <span className="text-gray-400">Since</span>
                <span>{formatDate(profile.created_at)}</span>
              </div>
            </CardContent>
          </Card>

          {/* Module Overrides card */}
          <Card className="p-5 mb-4">
            <div className="flex items-center gap-2 mb-3">
              <Layers className="w-4 h-4 text-green-700" />
              <CardTitle className="text-sm font-semibold text-gray-700">Module Access</CardTitle>
            </div>
            {!modulesData ? (
              <div className="space-y-2">
                {[1, 2, 3, 4].map((i) => (
                  <Skeleton key={i} className="h-8 w-full" />
                ))}
              </div>
            ) : (
              <div className="space-y-1">
                {modulesData.map((mod) => (
                  <div key={mod.module_slug} className="flex items-center justify-between py-1.5">
                    <div>
                      <p className="text-sm text-gray-700">{MODULE_LABELS[mod.module_slug] ?? mod.module_slug}</p>
                      {mod.has_override && (
                        <p className="text-[10px] text-amber-500">Override active</p>
                      )}
                    </div>
                    <button
                      onClick={() => handleModuleToggle(mod.module_slug, mod.is_enabled)}
                      disabled={savingModules === mod.module_slug}
                      className="disabled:opacity-40 transition-opacity"
                      title={mod.is_enabled ? 'Click to disable' : 'Click to enable'}
                    >
                      {mod.is_enabled
                        ? <ToggleRight className="w-7 h-7 text-green-600" />
                        : <ToggleLeft className="w-7 h-7 text-gray-300" />
                      }
                    </button>
                  </div>
                ))}
              </div>
            )}
          </Card>

          {/* Tenant Bootstrap Import */}
          <Card className="p-5 mb-4">
            <div className="flex items-center gap-2 mb-2">
              <Upload className="w-4 h-4 text-green-700" />
              <CardTitle className="text-sm font-semibold text-gray-700">Day-1 Data Bootstrap</CardTitle>
            </div>
            <p className="text-xs text-gray-500 mb-3">
              Download the guided multi-sheet Excel workbook, fill each tab in order, then upload to auto-setup this farm.
            </p>
            <div className="flex flex-col gap-2">
              <Button
                type="button"
                variant="outline"
                className="w-full justify-start"
                onClick={() => void handleDownloadBootstrapTemplate()}
              >
                <Download className="w-4 h-4 mr-2" />
                Download Excel workbook template
              </Button>
              <Label
                htmlFor="tenant-bootstrap-upload"
                className="inline-flex h-9 w-full cursor-pointer items-center justify-start rounded-md border border-input bg-background px-3 py-2 text-sm font-medium shadow-sm hover:bg-accent hover:text-accent-foreground"
              >
                <Upload className="w-4 h-4 mr-2" />
                {importingBootstrap ? 'Uploading and importing…' : 'Upload filled Excel workbook'}
              </Label>
              <Input
                id="tenant-bootstrap-upload"
                type="file"
                accept=".xlsx,application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
                disabled={importingBootstrap}
                className="hidden"
                onChange={(e) => {
                  const file = e.target.files?.[0]
                  if (file) {
                    void handleBootstrapImport(file)
                  }
                  e.currentTarget.value = ''
                }}
              />
            </div>
          </Card>

          {/* Payment Summary card */}
          <Card className="p-5">
            <CardTitle className="text-sm font-semibold text-gray-700 mb-3">Payment Summary</CardTitle>
            <div className="space-y-2 text-sm">
              <div className="flex justify-between">
                <span className="text-gray-500">Last paid</span>
                <span className="font-medium">
                  {tenant.payment_summary.last_paid_date
                    ? formatDate(tenant.payment_summary.last_paid_date)
                    : 'Never'}
                </span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-500">Last amount</span>
                <span className="font-medium">
                  {tenant.payment_summary.last_paid_amount
                    ? formatCurrency(tenant.payment_summary.last_paid_amount)
                    : '—'}
                </span>
              </div>
              <Separator className="my-2" />
              <div className="flex justify-between">
                <span className="text-gray-500 font-medium">Outstanding</span>
                <span className={tenant.payment_summary.outstanding_balance > 0 ? 'font-bold text-red-600' : 'font-medium text-gray-700'}>
                  {formatCurrency(tenant.payment_summary.outstanding_balance)}
                </span>
              </div>
            </div>
          </Card>
        </div>
      </div>

      {/* Edit Profile Sheet */}
      <EditProfileSheet
        open={editProfileOpen}
        onOpenChange={setEditProfileOpen}
        tenantId={profile.id}
        profile={profile}
        onSuccess={() => queryClient.invalidateQueries({ queryKey: ['tenant', id] })}
      />

      {/* Record Payment Modal */}
      <RecordPaymentModal
        open={paymentModalOpen || !!editPayment}
        onOpenChange={(open) => {
          if (!open) {
            setPaymentModalOpen(false)
            setEditPayment(null)
          }
        }}
        tenantId={String(profile.id)}
        tenantName={profile.name}
        existingPayment={editPayment ? {
          id: String(editPayment.id),
          payment_date: editPayment.payment_date || '',
          amount: editPayment.amount,
          method: editPayment.payment_method,
          paid_by: editPayment.paid_by_name || '',
          reference: editPayment.reference,
        } : undefined}
        onSuccess={() => {
          setPaymentModalOpen(false)
          setEditPayment(null)
          refetch()
        }}
      />

      {/* Plan Action Modals */}
      {planModalType && (
        <PlanActionModals
          tenant={planModalTenant}
          modalType={planModalType}
          onClose={() => setPlanModalType(null)}
          onSuccess={() => {
            setPlanModalType(null)
            queryClient.invalidateQueries({ queryKey: ['tenant', id] })
          }}
        />
      )}

      {/* Delete Payment AlertDialog */}
      <AlertDialog open={!!deletePayment} onOpenChange={(open) => !open && setDeletePayment(null)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Delete this payment record?</AlertDialogTitle>
            <AlertDialogDescription>
              This will remove the payment of <strong>{formatCurrency(deletePayment?.amount ?? 0)}</strong> recorded on{' '}
              <strong>{formatDate(deletePayment?.payment_date ?? null)}</strong>.
              <br /><br />
              The tenant's outstanding balance will increase accordingly.
              This action uses a soft delete — the record is archived in the audit trail.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Cancel</AlertDialogCancel>
            <AlertDialogAction
              className="bg-red-600 hover:bg-red-700 text-white"
              onClick={handleDeletePayment}
            >
              Delete
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </AdminShell>
  )
}
