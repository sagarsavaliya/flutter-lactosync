import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useQuery, useQueryClient } from '@tanstack/react-query'
import {
  Plus,
  Pencil,
  Archive,
  ArchiveRestore,
  CreditCard,
  AlertCircle,
  Lock,
  Loader2,
} from 'lucide-react'
import AdminShell from '../components/layout/AdminShell'
import { Button } from '../components/ui/button'
import { Input } from '../components/ui/input'
import { Label } from '../components/ui/label'
import { Badge } from '../components/ui/badge'
import { Skeleton } from '../components/ui/skeleton'
import { Alert, AlertTitle, AlertDescription } from '../components/ui/alert'
import { Card } from '../components/ui/card'
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '../components/ui/table'
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from '../components/ui/alert-dialog'
import {
  Sheet,
  SheetContent,
  SheetHeader,
  SheetTitle,
  SheetDescription,
  SheetFooter,
} from '../components/ui/sheet'
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '../components/ui/select'
import { Textarea } from '../components/ui/textarea'
import { Tooltip, TooltipContent, TooltipProvider, TooltipTrigger } from '../components/ui/tooltip'
import apiClient from '../api/client'
import { toast } from '../components/ui/use-toast'

const ALL_MODULES: { slug: string; label: string }[] = [
  { slug: 'route_delivery',         label: 'Route-based Delivery' },
  { slug: 'customer_app',           label: 'Customer App' },
  { slug: 'whatsapp_notifications', label: 'WhatsApp Notifications' },
  { slug: 'billing_invoices',       label: 'Billing & Invoices' },
]

interface Plan {
  id: string
  name: string
  description: string | null
  price: number
  billing_cycle: string
  billing_cycle_label: string
  max_customers: number
  max_subscriptions: number
  is_archived: boolean
  active_tenant_count: number
  modules: string[]
}

function LockedHint() {
  return (
    <p className="text-xs text-amber-600 mt-1 flex items-center gap-1">
      <Lock className="w-3 h-3" />
      Cannot change while this plan has active tenants
    </p>
  )
}

interface PlanFormData {
  name: string
  description: string
  price: string
  billing_cycle: string
  max_customers: string
  modules: string[]
}

const emptyForm: PlanFormData = {
  name: '',
  description: '',
  price: '',
  billing_cycle: 'monthly',
  max_customers: '',
  modules: [],
}

export default function PlanListPage() {
  const navigate = useNavigate()
  const queryClient = useQueryClient()

  const [sheetOpen, setSheetOpen] = useState(false)
  const [sheetMode, setSheetMode] = useState<'create' | 'edit'>('create')
  const [editingPlan, setEditingPlan] = useState<Plan | null>(null)
  const [formData, setFormData] = useState<PlanFormData>(emptyForm)
  const [formErrors, setFormErrors] = useState<Partial<PlanFormData>>({})
  const [submitting, setSubmitting] = useState(false)
  const [formError, setFormError] = useState<string | null>(null)

  const [archiveTarget, setArchiveTarget] = useState<Plan | null>(null)

  const { data: plans = [], isLoading, isError, refetch } = useQuery<Plan[]>({
    queryKey: ['plans'],
    queryFn: () => apiClient.get('/api/admin/v1/plans').then((r) => r.data.data),
  })

  const activePlanCount = plans.filter((p) => !p.is_archived).length
  const archivedPlanCount = plans.filter((p) => p.is_archived).length

  const openCreateSheet = () => {
    setSheetMode('create')
    setEditingPlan(null)
    setFormData(emptyForm)
    setFormErrors({})
    setFormError(null)
    setSheetOpen(true)
  }

  const openEditSheet = (plan: Plan) => {
    setSheetMode('edit')
    setEditingPlan(plan)
    setFormData({
      name: plan.name,
      description: plan.description || '',
      price: plan.price.toString(),
      billing_cycle: plan.billing_cycle,
      max_customers: plan.max_customers.toString(),
      modules: plan.modules ?? [],
    })
    setFormErrors({})
    setFormError(null)
    setSheetOpen(true)
  }

  const toggleModule = (slug: string) => {
    setFormData((prev) => ({
      ...prev,
      modules: prev.modules.includes(slug)
        ? prev.modules.filter((m) => m !== slug)
        : [...prev.modules, slug],
    }))
  }

  const isLocked = sheetMode === 'edit' && editingPlan && (editingPlan.active_tenant_count > 0 || editingPlan.is_archived)

  const validateForm = () => {
    const errors: Partial<PlanFormData> = {}
    if (!formData.name.trim()) errors.name = 'This field is required.'
    if (!formData.price || parseFloat(formData.price) <= 0) errors.price = 'Price must be greater than 0.'
    if (!formData.max_customers || parseInt(formData.max_customers) < 1) errors.max_customers = 'Must be at least 1.'
    setFormErrors(errors)
    return Object.keys(errors).length === 0
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!validateForm()) return

    setSubmitting(true)
    setFormError(null)

    try {
      const payload = {
        name: formData.name.trim(),
        description: formData.description || null,
        price: parseFloat(formData.price),
        billing_cycle: formData.billing_cycle,
        max_customers: parseInt(formData.max_customers),
        max_subscriptions: 9999,
        modules: formData.modules,
      }

      if (sheetMode === 'create') {
        await apiClient.post('/api/admin/v1/plans', payload)
        toast.success('Plan created.')
      } else if (editingPlan) {
        await apiClient.put(`/api/admin/v1/plans/${editingPlan.id}`, payload)
        toast.success('Plan updated.')
      }
      setSheetOpen(false)
      queryClient.invalidateQueries({ queryKey: ['plans'] })
    } catch (err: unknown) {
      const axiosErr = err as { response?: { status: number } }
      if (axiosErr.response?.status === 422) {
        toast.error('A plan with this name already exists.')
      } else {
        setFormError('Failed to save plan. Please try again.')
      }
    } finally {
      setSubmitting(false)
    }
  }

  const handleArchive = async () => {
    if (!archiveTarget) return
    try {
      await apiClient.post(`/api/admin/v1/plans/${archiveTarget.id}/archive`)
      toast.success('Plan archived.')
      queryClient.invalidateQueries({ queryKey: ['plans'] })
    } catch {
      toast.error('Failed to archive plan.')
    } finally {
      setArchiveTarget(null)
    }
  }

  const handleUnarchive = async (plan: Plan) => {
    try {
      await apiClient.post(`/api/admin/v1/plans/${plan.id}/unarchive`)
      toast.success('Plan unarchived.')
      queryClient.invalidateQueries({ queryKey: ['plans'] })
    } catch {
      toast.error('Failed to unarchive plan.')
    }
  }

  const billingCycleLabel = (cycle: string) => {
    const map: Record<string, string> = {
      monthly: 'Monthly',
      quarterly: 'Quarterly',
      half_yearly: 'Half-Yearly',
      yearly: 'Yearly',
    }
    return map[cycle] || cycle
  }

  return (
    <AdminShell title="Plans">
      {/* Header row */}
      <div className="flex items-center justify-between mb-4">
        <div>
          <h2 className="text-base font-semibold text-gray-800">Subscription Plans</h2>
          <p className="text-xs text-gray-400 mt-0.5">
            {activePlanCount} active · {archivedPlanCount} archived
          </p>
        </div>
        <Button className="bg-green-700 hover:bg-green-800 text-white" onClick={openCreateSheet}>
          <Plus className="w-4 h-4 mr-1.5" /> New Plan
        </Button>
      </div>

      {isError && (
        <Alert variant="destructive" className="mb-4">
          <AlertCircle className="h-4 w-4" />
          <AlertTitle>Failed to load plans</AlertTitle>
          <AlertDescription>
            <Button variant="link" className="p-0 h-auto" onClick={() => refetch()}>
              Try again
            </Button>
          </AlertDescription>
        </Alert>
      )}

      <Card>
        {isLoading ? (
          <div className="p-4 space-y-3">
            {Array.from({ length: 5 }).map((_, i) => (
              <Skeleton key={i} className="h-10 w-full" />
            ))}
          </div>
        ) : plans.length === 0 ? (
          <div className="flex flex-col items-center py-16 text-center">
            <CreditCard className="w-12 h-12 text-gray-200 mb-3" />
            <p className="text-sm font-medium text-gray-500">No plans yet</p>
            <p className="text-xs text-gray-400 mt-1">Create your first plan to start assigning it to tenants.</p>
            <Button size="sm" className="mt-4 bg-green-700 hover:bg-green-800 text-white" onClick={openCreateSheet}>
              <Plus className="w-4 h-4 mr-1" /> New Plan
            </Button>
          </div>
        ) : (
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Name</TableHead>
                <TableHead>Price</TableHead>
                <TableHead>Billing Cycle</TableHead>
                <TableHead className="text-right">Max Customers</TableHead>
                <TableHead>Modules</TableHead>
                <TableHead>Status</TableHead>
                <TableHead>Tenants</TableHead>
                <TableHead className="w-20">Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {plans.map((plan) => (
                <TableRow
                  key={plan.id}
                  className={plan.is_archived ? 'opacity-50' : ''}
                  title={plan.is_archived ? 'This plan is archived and cannot be assigned to new tenants.' : undefined}
                >
                  <TableCell>
                    <div className="font-medium text-gray-800">{plan.name}</div>
                    {plan.description && (
                      <div className="text-xs text-gray-400 truncate max-w-[160px]">{plan.description}</div>
                    )}
                  </TableCell>
                  <TableCell>₹{plan.price}</TableCell>
                  <TableCell>{billingCycleLabel(plan.billing_cycle)}</TableCell>
                  <TableCell className="text-right">{plan.max_customers}</TableCell>
                  <TableCell>
                    <div className="flex flex-wrap gap-1">
                      {(plan.modules ?? []).length === 0 ? (
                        <span className="text-xs text-gray-400">None</span>
                      ) : (plan.modules ?? []).map((slug) => {
                        const mod = ALL_MODULES.find((m) => m.slug === slug)
                        return (
                          <Badge key={slug} className="bg-emerald-50 text-emerald-700 border-emerald-200 text-[10px] px-1.5 py-0">
                            {mod?.label ?? slug}
                          </Badge>
                        )
                      })}
                    </div>
                  </TableCell>
                  <TableCell>
                    {!plan.is_archived ? (
                      <Badge className="bg-green-100 text-green-800 border-green-200">Active</Badge>
                    ) : (
                      <Badge className="bg-gray-100 text-gray-500 border-gray-200">Archived</Badge>
                    )}
                  </TableCell>
                  <TableCell>
                    <button
                      onClick={() => navigate(`/tenants?plan=${plan.id}`)}
                      className="text-green-700 hover:underline text-sm"
                    >
                      {plan.active_tenant_count}
                    </button>
                  </TableCell>
                  <TableCell>
                    {!plan.is_archived ? (
                      <div className="flex items-center gap-1">
                        <TooltipProvider>
                          <Tooltip>
                            <TooltipTrigger asChild>
                              <Button variant="ghost" size="icon" onClick={() => openEditSheet(plan)}>
                                <Pencil className="w-4 h-4" />
                              </Button>
                            </TooltipTrigger>
                            <TooltipContent>Edit plan</TooltipContent>
                          </Tooltip>
                        </TooltipProvider>
                        <TooltipProvider>
                          <Tooltip>
                            <TooltipTrigger asChild>
                              <Button
                                variant="ghost"
                                size="icon"
                                className="text-red-400 hover:text-red-600 hover:bg-red-50"
                                onClick={() => setArchiveTarget(plan)}
                              >
                                <Archive className="w-4 h-4" />
                              </Button>
                            </TooltipTrigger>
                            <TooltipContent>Archive plan</TooltipContent>
                          </Tooltip>
                        </TooltipProvider>
                      </div>
                    ) : (
                      <TooltipProvider>
                        <Tooltip>
                          <TooltipTrigger asChild>
                            <Button
                              variant="ghost"
                              size="icon"
                              className="text-gray-400 hover:text-gray-700"
                              onClick={() => handleUnarchive(plan)}
                            >
                              <ArchiveRestore className="w-4 h-4" />
                            </Button>
                          </TooltipTrigger>
                          <TooltipContent>Unarchive plan</TooltipContent>
                        </Tooltip>
                      </TooltipProvider>
                    )}
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        )}
      </Card>

      {/* Plan Form Sheet */}
      <Sheet open={sheetOpen} onOpenChange={setSheetOpen}>
        <SheetContent className="w-[480px] sm:max-w-[480px] overflow-y-auto pt-12">
          <SheetHeader className="mb-0">
            <SheetTitle>{sheetMode === 'create' ? 'New Plan' : 'Edit Plan'}</SheetTitle>
            <SheetDescription>
              {sheetMode === 'create' ? 'Define a new subscription plan.' : "Update this plan's details."}
            </SheetDescription>
          </SheetHeader>

          <form onSubmit={handleSubmit} className="space-y-5 mt-6 px-6">
            {/* Plan Name */}
            <div>
              <Label htmlFor="plan-name">Plan Name <span className="text-red-500">*</span></Label>
              <Input
                id="plan-name"
                placeholder="e.g. Starter, Growth, Pro"
                value={formData.name}
                onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                required
              />
              {formErrors.name && <p className="text-xs text-red-500 mt-1">{formErrors.name}</p>}
            </div>

            {/* Description */}
            <div>
              <Label htmlFor="plan-description">Description</Label>
              <Textarea
                id="plan-description"
                placeholder="Brief description of this plan"
                rows={2}
                className="resize-none"
                value={formData.description}
                onChange={(e) => setFormData({ ...formData, description: e.target.value })}
              />
            </div>

            {/* Price */}
            <div>
              <Label htmlFor="plan-price">Price <span className="text-red-500">*</span></Label>
              <div className="relative">
                <span className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400 text-sm">₹</span>
                <Input
                  id="plan-price"
                  type="number"
                  min="0"
                  step="1"
                  placeholder="0"
                  className="pl-7"
                  disabled={!!isLocked}
                  value={formData.price}
                  onChange={(e) => setFormData({ ...formData, price: e.target.value })}
                  required
                />
              </div>
              {isLocked && <LockedHint />}
              {formErrors.price && <p className="text-xs text-red-500 mt-1">{formErrors.price}</p>}
            </div>

            {/* Billing Cycle */}
            <div>
              <Label>Billing Cycle <span className="text-red-500">*</span></Label>
              <Select
                value={formData.billing_cycle}
                onValueChange={(v) => setFormData({ ...formData, billing_cycle: v })}
              >
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="monthly">Monthly</SelectItem>
                  <SelectItem value="quarterly">Quarterly (3 months)</SelectItem>
                  <SelectItem value="half_yearly">Half-Yearly (6 months)</SelectItem>
                  <SelectItem value="yearly">Yearly (12 months)</SelectItem>
                </SelectContent>
              </Select>
            </div>

            {/* Max Customers */}
            <div>
              <Label htmlFor="plan-max-customers">Max Customers <span className="text-red-500">*</span></Label>
              <Input
                id="plan-max-customers"
                type="number"
                min="1"
                placeholder="e.g. 50"
                disabled={!!isLocked}
                value={formData.max_customers}
                onChange={(e) => setFormData({ ...formData, max_customers: e.target.value })}
                required
              />
              {isLocked && <LockedHint />}
              {formErrors.max_customers && <p className="text-xs text-red-500 mt-1">{formErrors.max_customers}</p>}
            </div>

            {/* Modules */}
            <div>
              <Label className="block mb-2">Included Modules</Label>
              <div className="rounded-lg border border-gray-200 divide-y divide-gray-100 overflow-hidden">
                {ALL_MODULES.map(({ slug, label }) => {
                  const checked = formData.modules.includes(slug)
                  return (
                    <label
                      key={slug}
                      className="flex items-center justify-between px-4 py-3 cursor-pointer hover:bg-gray-50 transition-colors"
                    >
                      <span className="text-sm text-gray-700">{label}</span>
                      <input
                        type="checkbox"
                        checked={checked}
                        onChange={() => toggleModule(slug)}
                        className="w-4 h-4 rounded accent-green-700"
                      />
                    </label>
                  )
                })}
              </div>
              <p className="text-xs text-gray-400 mt-1.5">
                Modules not checked here can still be enabled per-tenant via overrides.
              </p>
            </div>

            {formError && (
              <Alert variant="destructive">
                <AlertCircle className="h-4 w-4" />
                <AlertDescription>{formError}</AlertDescription>
              </Alert>
            )}

            <SheetFooter className="mt-6 flex gap-2 justify-end pb-6">
              <Button type="button" variant="outline" onClick={() => setSheetOpen(false)}>Cancel</Button>
              <Button type="submit" className="bg-green-700 hover:bg-green-800 text-white" disabled={submitting}>
                {submitting
                  ? <><Loader2 className="w-4 h-4 mr-1 animate-spin" /> Saving…</>
                  : sheetMode === 'create' ? 'Create Plan' : 'Save Changes'
                }
              </Button>
            </SheetFooter>
          </form>
        </SheetContent>
      </Sheet>

      {/* Archive AlertDialog */}
      <AlertDialog open={archiveTarget !== null} onOpenChange={(open) => !open && setArchiveTarget(null)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Archive this plan?</AlertDialogTitle>
            <AlertDialogDescription>
              <strong>{archiveTarget?.name}</strong> will be archived.
              Tenants currently on this plan keep their assignment until renewal.
              No new tenants can be assigned this plan after archiving.
            </AlertDialogDescription>
          </AlertDialogHeader>

          {archiveTarget && (archiveTarget.active_tenant_count ?? 0) > 0 && (
            <Alert className="border-amber-300 bg-amber-50 my-2">
              <AlertCircle className="h-4 w-4 text-amber-600" />
              <AlertDescription className="text-amber-800 text-sm">
                {archiveTarget.active_tenant_count} tenant(s) are currently on this plan.
                They will remain unaffected until their renewal date.
              </AlertDescription>
            </Alert>
          )}

          <AlertDialogFooter>
            <AlertDialogCancel>Cancel</AlertDialogCancel>
            <AlertDialogAction
              className="bg-red-600 hover:bg-red-700 text-white"
              onClick={handleArchive}
            >
              Archive Plan
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </AdminShell>
  )
}
