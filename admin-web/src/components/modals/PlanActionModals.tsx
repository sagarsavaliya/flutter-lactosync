import { useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import { PauseCircle, PlayCircle, Loader2, AlertCircle } from 'lucide-react'
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
  DialogFooter,
} from '../ui/dialog'
import { Button } from '../ui/button'
import { Label } from '../ui/label'
import { Alert, AlertDescription } from '../ui/alert'
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '../ui/select'
import { Textarea } from '../ui/textarea'
import { Input } from '../ui/input'
import { format } from 'date-fns'
import apiClient from '../../api/client'
import { toast } from '../ui/use-toast'

interface Plan {
  id: string
  name: string
  price: number
  billing_cycle: string
  billing_cycle_label?: string
  active_tenant_count?: number
}

interface Tenant {
  id: string | number
  name: string
  plan_id?: string | null
  plan_name?: string | null
  plan_price?: number | null
  status?: string
}

interface PlanActionModalsProps {
  tenant: Tenant
  modalType: 'assign' | 'change' | 'pause' | 'resume'
  onClose: () => void
  onSuccess: () => void
}

export default function PlanActionModals({
  tenant,
  modalType,
  onClose,
  onSuccess,
}: PlanActionModalsProps) {
  const [selectedPlan, setSelectedPlan] = useState('')
  const [startDate, setStartDate] = useState(format(new Date(), 'yyyy-MM-dd'))
  const [reason, setReason] = useState('')
  const [submitting, setSubmitting] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const { data: plans = [] } = useQuery<Plan[]>({
    queryKey: ['plans-active'],
    queryFn: () =>
      apiClient.get('/api/admin/v1/plans').then((r) =>
        (r.data.data as (Plan & { is_archived?: boolean; status?: string })[])
          .filter((p) => !p.is_archived && p.status !== 'archived')
      ),
    enabled: modalType === 'assign' || modalType === 'change',
  })

  const selectedPlanData = plans.find((p) => p.id === selectedPlan)

  const handleSubmit = async () => {
    setError(null)
    setSubmitting(true)

    try {
      if (modalType === 'assign') {
        if (!selectedPlan) { setError('Please select a plan.'); setSubmitting(false); return }
        await apiClient.post(`/api/admin/v1/tenants/${tenant.id}/plan-assign`, {
          plan_id: parseInt(selectedPlan),
          start_date: startDate,
        })
        toast.success('Plan assigned successfully.')
      } else if (modalType === 'change') {
        if (!selectedPlan || !reason) { setError('Please fill all required fields.'); setSubmitting(false); return }
        await apiClient.post(`/api/admin/v1/tenants/${tenant.id}/plan-change`, {
          plan_id: parseInt(selectedPlan),
          reason,
        })
        toast.success('Plan updated.')
      } else if (modalType === 'pause') {
        await apiClient.post(`/api/admin/v1/tenants/${tenant.id}/plan-pause`)
        toast.success('Plan paused.')
      } else if (modalType === 'resume') {
        await apiClient.post(`/api/admin/v1/tenants/${tenant.id}/plan-resume`)
        toast.success('Plan resumed.')
      }
      onSuccess()
    } catch {
      setError('Action failed. Please try again.')
    } finally {
      setSubmitting(false)
    }
  }

  const open = true

  // Assign Plan Modal
  if (modalType === 'assign') {
    return (
      <Dialog open={open} onOpenChange={(o) => !o && onClose()}>
        <DialogContent className="max-w-md">
          <DialogHeader>
            <DialogTitle>Assign Plan</DialogTitle>
            <DialogDescription>Select a plan and start date for {tenant.name}.</DialogDescription>
          </DialogHeader>
          <div className="space-y-4 py-2">
            <div>
              <Label>Plan</Label>
              <Select value={selectedPlan} onValueChange={setSelectedPlan}>
                <SelectTrigger><SelectValue placeholder="Choose a plan" /></SelectTrigger>
                <SelectContent>
                  {plans.map((p) => (
                    <SelectItem key={p.id} value={p.id}>
                      {p.name} — ₹{p.price}/{p.billing_cycle_label || p.billing_cycle}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            <div>
              <Label>Start Date</Label>
              <Input
                type="date"
                value={startDate}
                onChange={(e) => setStartDate(e.target.value)}
              />
            </div>
            {error && (
              <Alert variant="destructive">
                <AlertCircle className="h-4 w-4" />
                <AlertDescription>{error}</AlertDescription>
              </Alert>
            )}
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={onClose}>Cancel</Button>
            <Button
              className="bg-green-700 hover:bg-green-800 text-white"
              onClick={handleSubmit}
              disabled={!selectedPlan || submitting}
            >
              {submitting ? <><Loader2 className="w-4 h-4 mr-1 animate-spin" /> Assigning…</> : 'Assign Plan'}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    )
  }

  // Change Plan Modal
  if (modalType === 'change') {
    const isUpgrade = selectedPlanData && tenant.plan_price && selectedPlanData.price > tenant.plan_price
    const isDowngrade = selectedPlanData && tenant.plan_price && selectedPlanData.price < tenant.plan_price
    return (
      <Dialog open={open} onOpenChange={(o) => !o && onClose()}>
        <DialogContent className="max-w-md">
          <DialogHeader>
            <DialogTitle>Change Plan</DialogTitle>
          </DialogHeader>
          <div className="space-y-4 py-2">
            <div className="rounded-md bg-gray-50 border border-gray-200 px-3 py-2 text-sm">
              <span className="text-gray-400 text-xs block mb-0.5">Current plan</span>
              <span className="font-medium">{tenant.plan_name || 'None'}</span>
            </div>
            <div>
              <Label>New Plan</Label>
              <Select value={selectedPlan} onValueChange={setSelectedPlan}>
                <SelectTrigger><SelectValue placeholder="Choose a plan" /></SelectTrigger>
                <SelectContent>
                  {plans
                    .filter((p) => !tenant.plan_id || p.id !== tenant.plan_id)
                    .map((p) => (
                      <SelectItem key={p.id} value={p.id}>
                        {p.name} — ₹{p.price}/{p.billing_cycle_label || p.billing_cycle}
                      </SelectItem>
                    ))}
                </SelectContent>
              </Select>
            </div>
            {selectedPlanData && (isUpgrade !== undefined || isDowngrade !== undefined) && (
              <div className={`text-sm font-medium px-3 py-1.5 rounded-md ${
                isUpgrade
                  ? 'bg-green-50 text-green-700'
                  : 'bg-amber-50 text-amber-700'
              }`}>
                {isUpgrade ? '↑ Upgrade' : '↓ Downgrade'}
              </div>
            )}
            <div>
              <Label>Reason <span className="text-red-500">*</span></Label>
              <Textarea
                placeholder="e.g. Tenant requested upgrade to accommodate more customers"
                rows={2}
                value={reason}
                onChange={(e) => setReason(e.target.value)}
                required
              />
            </div>
            {error && (
              <Alert variant="destructive">
                <AlertCircle className="h-4 w-4" />
                <AlertDescription>{error}</AlertDescription>
              </Alert>
            )}
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={onClose}>Cancel</Button>
            <Button
              className="bg-green-700 hover:bg-green-800 text-white"
              onClick={handleSubmit}
              disabled={!selectedPlan || !reason || submitting}
            >
              {submitting ? <><Loader2 className="w-4 h-4 mr-1 animate-spin" /> Saving…</> : 'Confirm Change'}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    )
  }

  // Pause Plan Modal
  if (modalType === 'pause') {
    return (
      <Dialog open={open} onOpenChange={(o) => !o && onClose()}>
        <DialogContent className="max-w-sm">
          <DialogHeader>
            <DialogTitle>Pause Plan</DialogTitle>
          </DialogHeader>
          <div className="py-2">
            <Alert className="border-amber-300 bg-amber-50">
              <PauseCircle className="h-4 w-4 text-amber-600" />
              <AlertDescription className="text-amber-800">
                The renewal clock will stop. The tenant's renewal date is frozen until
                the plan is resumed. Active tenant access continues during the pause.
              </AlertDescription>
            </Alert>
          </div>
          {error && (
            <Alert variant="destructive">
              <AlertCircle className="h-4 w-4" />
              <AlertDescription>{error}</AlertDescription>
            </Alert>
          )}
          <DialogFooter>
            <Button variant="outline" onClick={onClose}>Cancel</Button>
            <Button variant="destructive" onClick={handleSubmit} disabled={submitting}>
              {submitting ? <><Loader2 className="w-4 h-4 mr-1 animate-spin" /> Pausing…</> : 'Pause Plan'}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    )
  }

  // Resume Plan Modal
  if (modalType === 'resume') {
    return (
      <Dialog open={open} onOpenChange={(o) => !o && onClose()}>
        <DialogContent className="max-w-sm">
          <DialogHeader>
            <DialogTitle>Resume Plan</DialogTitle>
          </DialogHeader>
          <div className="py-2">
            <p className="text-sm text-gray-600">
              The renewal clock will restart from today. The tenant's remaining days
              are preserved from the point the plan was paused.
            </p>
          </div>
          {error && (
            <Alert variant="destructive">
              <AlertCircle className="h-4 w-4" />
              <AlertDescription>{error}</AlertDescription>
            </Alert>
          )}
          <DialogFooter>
            <Button variant="outline" onClick={onClose}>Cancel</Button>
            <Button
              className="bg-green-700 hover:bg-green-800 text-white"
              onClick={handleSubmit}
              disabled={submitting}
            >
              {submitting ? <><Loader2 className="w-4 h-4 mr-1 animate-spin" /> Resuming…</> : <><PlayCircle className="w-4 h-4 mr-1" /> Resume Plan</>}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    )
  }

  return null
}
