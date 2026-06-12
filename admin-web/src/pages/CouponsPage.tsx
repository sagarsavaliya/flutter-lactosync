import { useState } from 'react'
import { useQuery, useQueryClient } from '@tanstack/react-query'
import {
  Plus,
  Tag,
  ToggleLeft,
  ToggleRight,
  Gift,
  Copy,
  Check,
} from 'lucide-react'
import AdminShell from '../components/layout/AdminShell'
import { Card } from '../components/ui/card'
import { Badge } from '../components/ui/badge'
import { Button } from '../components/ui/button'
import { Input } from '../components/ui/input'
import { Label } from '../components/ui/label'
import { Separator } from '../components/ui/separator'
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
import { formatDate } from '../lib/utils'
import apiClient from '../api/client'
import { toast } from '../components/ui/use-toast'

interface Coupon {
  id: number
  code: string
  title: string
  type: string
  value: number
  max_redemptions: number | null
  redemption_count: number
  is_active: boolean
  is_redeemable: boolean
  expires_at: string | null
  notes: string | null
  created_by_email: string | null
  created_at: string
}

// ─── Copy-to-clipboard button ─────────────────────────────────────────────

function CopyButton({ text }: { text: string }) {
  const [copied, setCopied] = useState(false)
  const handleCopy = () => {
    navigator.clipboard.writeText(text)
    setCopied(true)
    setTimeout(() => setCopied(false), 1500)
  }
  return (
    <button
      onClick={handleCopy}
      className="ml-1 text-gray-400 hover:text-gray-600 transition-colors"
      title="Copy code"
    >
      {copied ? <Check className="w-3.5 h-3.5 text-green-600" /> : <Copy className="w-3.5 h-3.5" />}
    </button>
  )
}

// ─── Create Coupon Sheet ──────────────────────────────────────────────────

interface CreateCouponForm {
  title: string
  type: string
  value: string
  max_redemptions: string
  expires_at: string
  notes: string
}

const emptyForm: CreateCouponForm = {
  title: '',
  type: 'free_months',
  value: '1',
  max_redemptions: '',
  expires_at: '',
  notes: '',
}

interface CreateCouponSheetProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  onSuccess: () => void
}

function CreateCouponSheet({ open, onOpenChange, onSuccess }: CreateCouponSheetProps) {
  const [form, setForm] = useState<CreateCouponForm>(emptyForm)
  const [saving, setSaving] = useState(false)

  const set = (field: keyof CreateCouponForm, value: string) =>
    setForm((prev) => ({ ...prev, [field]: value }))

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()

    const valueNum = parseInt(form.value)
    if (isNaN(valueNum) || valueNum < 1 || valueNum > 12) {
      toast({ title: 'Invalid value', description: 'Value must be between 1 and 12 months.', variant: 'destructive' })
      return
    }

    const payload: Record<string, unknown> = {
      title: form.title,
      type: form.type,
      value: valueNum,
      notes: form.notes || null,
    }
    if (form.max_redemptions) payload.max_redemptions = parseInt(form.max_redemptions)
    if (form.expires_at) payload.expires_at = form.expires_at

    try {
      setSaving(true)
      await apiClient.post('/api/admin/v1/coupons', payload)
      toast({ title: 'Coupon created' })
      setForm(emptyForm)
      onSuccess()
      onOpenChange(false)
    } catch (err: unknown) {
      const msg = (err as { response?: { data?: { message?: string } } })?.response?.data?.message
      toast({ title: 'Failed to create coupon', description: msg || 'Something went wrong.', variant: 'destructive' })
    } finally {
      setSaving(false)
    }
  }

  return (
    <Sheet open={open} onOpenChange={onOpenChange}>
      <SheetContent className="w-full sm:max-w-md overflow-y-auto">
        <SheetHeader className="mb-6">
          <SheetTitle>Create Coupon</SheetTitle>
          <SheetDescription>
            The coupon code is auto-generated. Share it with the tenant owner.
          </SheetDescription>
        </SheetHeader>

        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <Label htmlFor="cc-title">Title / Description</Label>
            <Input
              id="cc-title"
              placeholder="e.g. Referral reward — 1 free month"
              value={form.title}
              onChange={(e) => set('title', e.target.value)}
              required
            />
          </div>

          <div>
            <Label htmlFor="cc-type">Coupon Type</Label>
            <select
              id="cc-type"
              value={form.type}
              onChange={(e) => set('type', e.target.value)}
              className="w-full h-9 rounded-md border border-input bg-background px-3 py-1 text-sm shadow-xs focus:outline-none focus:ring-1 focus:ring-ring"
            >
              <option value="free_months">Free Months</option>
            </select>
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <Label htmlFor="cc-value">Months to Credit</Label>
              <Input
                id="cc-value"
                type="number"
                min={1}
                max={12}
                value={form.value}
                onChange={(e) => set('value', e.target.value)}
                required
              />
            </div>
            <div>
              <Label htmlFor="cc-max">Max Redemptions</Label>
              <Input
                id="cc-max"
                type="number"
                min={1}
                placeholder="Unlimited"
                value={form.max_redemptions}
                onChange={(e) => set('max_redemptions', e.target.value)}
              />
            </div>
          </div>

          <div>
            <Label htmlFor="cc-expires">Expires On (optional)</Label>
            <Input
              id="cc-expires"
              type="date"
              value={form.expires_at}
              onChange={(e) => set('expires_at', e.target.value)}
            />
          </div>

          <div>
            <Label htmlFor="cc-notes">Notes (internal only)</Label>
            <Input
              id="cc-notes"
              placeholder="Optional internal notes"
              value={form.notes}
              onChange={(e) => set('notes', e.target.value)}
            />
          </div>

          <Separator />

          <div className="flex justify-end gap-3">
            <Button type="button" variant="outline" onClick={() => onOpenChange(false)}>Cancel</Button>
            <Button type="submit" className="bg-green-700 hover:bg-green-800 text-white" disabled={saving}>
              {saving ? 'Creating…' : 'Create Coupon'}
            </Button>
          </div>
        </form>
      </SheetContent>
    </Sheet>
  )
}

// ─── Apply Coupon Modal ───────────────────────────────────────────────────

interface ApplyCouponModalProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  coupon: Coupon
  onSuccess: () => void
}

function ApplyCouponModal({ open, onOpenChange, coupon, onSuccess }: ApplyCouponModalProps) {
  const [tenantId, setTenantId] = useState('')
  const [notes, setNotes] = useState('')
  const [saving, setSaving] = useState(false)

  const { data: tenantsData } = useQuery<{ items: { id: number; name: string }[] }>({
    queryKey: ['tenants-simple'],
    queryFn: () => apiClient.get('/api/admin/v1/tenants?page=1').then((r) => r.data.data),
    enabled: open,
  })

  const handleApply = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!tenantId) return

    try {
      setSaving(true)
      await apiClient.post(`/api/admin/v1/tenants/${tenantId}/apply-coupon`, {
        coupon_code: coupon.code,
        notes: notes || null,
      })
      toast({ title: 'Coupon applied', description: `${coupon.value} free month(s) credited to tenant.` })
      setTenantId('')
      setNotes('')
      onSuccess()
      onOpenChange(false)
    } catch (err: unknown) {
      const msg = (err as { response?: { data?: { error?: { message?: string } } } })?.response?.data?.error?.message
      toast({ title: 'Apply failed', description: msg || 'Something went wrong.', variant: 'destructive' })
    } finally {
      setSaving(false)
    }
  }

  return (
    <Sheet open={open} onOpenChange={onOpenChange}>
      <SheetContent className="w-full sm:max-w-md">
        <SheetHeader className="mb-6">
          <SheetTitle>Apply Coupon to Tenant</SheetTitle>
          <SheetDescription>
            Coupon <strong>{coupon.code}</strong> — {coupon.title}
          </SheetDescription>
        </SheetHeader>

        <form onSubmit={handleApply} className="space-y-4">
          <div className="rounded-lg bg-green-50 border border-green-200 px-4 py-3 flex items-center gap-3">
            <Gift className="w-5 h-5 text-green-600 shrink-0" />
            <div>
              <p className="text-sm font-semibold text-green-800">{coupon.value} free month(s)</p>
              <p className="text-xs text-green-600">Will extend tenant's renewal date by {coupon.value} month(s)</p>
            </div>
          </div>

          <div>
            <Label htmlFor="ac-tenant">Select Tenant</Label>
            <select
              id="ac-tenant"
              value={tenantId}
              onChange={(e) => setTenantId(e.target.value)}
              required
              className="w-full h-9 rounded-md border border-input bg-background px-3 py-1 text-sm shadow-xs focus:outline-none focus:ring-1 focus:ring-ring"
            >
              <option value="">— Choose tenant —</option>
              {(tenantsData?.items ?? []).map((t) => (
                <option key={t.id} value={String(t.id)}>{t.name}</option>
              ))}
            </select>
          </div>

          <div>
            <Label htmlFor="ac-notes">Notes (optional)</Label>
            <Input
              id="ac-notes"
              placeholder="e.g. Referral from Ramesh Farm"
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
            />
          </div>

          <div className="flex justify-end gap-3 pt-1">
            <Button type="button" variant="outline" onClick={() => onOpenChange(false)}>Cancel</Button>
            <Button type="submit" className="bg-green-700 hover:bg-green-800 text-white" disabled={saving || !tenantId}>
              {saving ? 'Applying…' : 'Apply Coupon'}
            </Button>
          </div>
        </form>
      </SheetContent>
    </Sheet>
  )
}

// ─── Main page ─────────────────────────────────────────────────────────────

function statusBadge(coupon: Coupon) {
  if (!coupon.is_active) return <Badge variant="outline" className="text-gray-400">Disabled</Badge>
  if (!coupon.is_redeemable) return <Badge variant="destructive">Exhausted</Badge>
  return <Badge className="bg-green-100 text-green-800 border-green-200">Active</Badge>
}

export default function CouponsPage() {
  const queryClient = useQueryClient()
  const [createOpen, setCreateOpen] = useState(false)
  const [applyTarget, setApplyTarget] = useState<Coupon | null>(null)

  const { data: coupons = [], isLoading } = useQuery<Coupon[]>({
    queryKey: ['coupons'],
    queryFn: () => apiClient.get('/api/admin/v1/coupons').then((r) => r.data.data),
  })

  const handleToggle = async (coupon: Coupon) => {
    try {
      await apiClient.patch(`/api/admin/v1/coupons/${coupon.id}/toggle-active`)
      queryClient.invalidateQueries({ queryKey: ['coupons'] })
      toast({ title: coupon.is_active ? 'Coupon disabled' : 'Coupon enabled' })
    } catch {
      toast({ title: 'Failed to update coupon.', variant: 'destructive' })
    }
  }

  const createButton = (
    <Button
      size="sm"
      className="bg-green-700 hover:bg-green-800 text-white"
      onClick={() => setCreateOpen(true)}
    >
      <Plus className="w-4 h-4 mr-1" /> New Coupon
    </Button>
  )

  return (
    <AdminShell title="Coupons & Offers" rightSlot={createButton}>

      {/* Info banner */}
      <div className="rounded-xl border border-blue-200 bg-blue-50 px-5 py-4 flex items-start gap-4 mb-6">
        <Gift className="w-5 h-5 text-blue-500 mt-0.5 shrink-0" />
        <div>
          <p className="text-sm font-semibold text-blue-800">Referral offer: 1 free month per referral</p>
          <p className="text-sm text-blue-600">
            Create a coupon with value = 1, max_redemptions = 12. Share the code with tenant owners.
            When they refer a paying tenant, apply the coupon to their account — it will extend their renewal date by 1 month automatically.
          </p>
        </div>
      </div>

      {isLoading ? (
        <div className="text-sm text-gray-400 py-10 text-center">Loading coupons…</div>
      ) : coupons.length === 0 ? (
        <div className="flex flex-col items-center py-20 text-center">
          <Tag className="w-10 h-10 text-gray-200 mb-3" />
          <p className="text-gray-500 font-medium">No coupons yet</p>
          <p className="text-sm text-gray-400 mb-4">Create your first coupon to get started.</p>
          <Button
            size="sm"
            className="bg-green-700 hover:bg-green-800 text-white"
            onClick={() => setCreateOpen(true)}
          >
            <Plus className="w-4 h-4 mr-1" /> New Coupon
          </Button>
        </div>
      ) : (
        <Card>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Code</TableHead>
                <TableHead>Title</TableHead>
                <TableHead>Benefit</TableHead>
                <TableHead>Redemptions</TableHead>
                <TableHead>Expires</TableHead>
                <TableHead>Status</TableHead>
                <TableHead className="w-44"></TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {coupons.map((c) => (
                <TableRow key={c.id}>
                  <TableCell>
                    <span className="font-mono text-sm font-semibold text-gray-800 bg-gray-100 px-2 py-0.5 rounded">
                      {c.code}
                    </span>
                    <CopyButton text={c.code} />
                  </TableCell>
                  <TableCell>
                    <p className="font-medium text-sm">{c.title}</p>
                    {c.notes && <p className="text-xs text-gray-400 mt-0.5">{c.notes}</p>}
                  </TableCell>
                  <TableCell>
                    <span className="text-sm">
                      {c.type === 'free_months' ? `${c.value} free month${c.value > 1 ? 's' : ''}` : c.type}
                    </span>
                  </TableCell>
                  <TableCell>
                    <span className={
                      c.max_redemptions !== null && c.redemption_count >= c.max_redemptions
                        ? 'text-red-600 font-semibold'
                        : 'text-gray-700'
                    }>
                      {c.redemption_count}
                      {c.max_redemptions !== null ? ` / ${c.max_redemptions}` : ''}
                    </span>
                  </TableCell>
                  <TableCell className="text-sm text-gray-500">
                    {c.expires_at ? formatDate(c.expires_at) : '—'}
                  </TableCell>
                  <TableCell>{statusBadge(c)}</TableCell>
                  <TableCell>
                    <div className="flex items-center gap-2">
                      <Button
                        size="sm"
                        variant="outline"
                        className="text-green-700 border-green-300 hover:bg-green-50"
                        disabled={!c.is_redeemable}
                        onClick={() => setApplyTarget(c)}
                      >
                        <Gift className="w-3.5 h-3.5 mr-1" /> Apply
                      </Button>
                      <button
                        onClick={() => handleToggle(c)}
                        className="text-gray-400 hover:text-gray-700 transition-colors"
                        title={c.is_active ? 'Disable coupon' : 'Enable coupon'}
                      >
                        {c.is_active
                          ? <ToggleRight className="w-7 h-7 text-green-600" />
                          : <ToggleLeft className="w-7 h-7 text-gray-400" />
                        }
                      </button>
                    </div>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </Card>
      )}

      <CreateCouponSheet
        open={createOpen}
        onOpenChange={setCreateOpen}
        onSuccess={() => queryClient.invalidateQueries({ queryKey: ['coupons'] })}
      />

      {applyTarget && (
        <ApplyCouponModal
          open={!!applyTarget}
          onOpenChange={(open) => !open && setApplyTarget(null)}
          coupon={applyTarget}
          onSuccess={() => queryClient.invalidateQueries({ queryKey: ['coupons'] })}
        />
      )}
    </AdminShell>
  )
}
