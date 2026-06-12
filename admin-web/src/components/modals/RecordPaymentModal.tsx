import { useState, useEffect } from 'react'
import { useQuery } from '@tanstack/react-query'
import { Loader2, AlertCircle } from 'lucide-react'
import { format } from 'date-fns'
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
  DialogFooter,
} from '../ui/dialog'
import { Button } from '../ui/button'
import { Input } from '../ui/input'
import { Label } from '../ui/label'
import { Alert, AlertDescription } from '../ui/alert'
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '../ui/select'
import apiClient from '../../api/client'
import { toast } from '../ui/use-toast'

interface Payment {
  id: string
  payment_date: string
  amount: number
  method: string
  paid_by: string
  reference: string | null
  tenant_id?: string
  tenant_name?: string
  due_date?: string
}

interface Tenant {
  id: string | number
  name: string
}

interface RecordPaymentModalProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  tenantId?: string
  tenantName?: string
  existingPayment?: Payment
  onSuccess: () => void
}

export default function RecordPaymentModal({
  open,
  onOpenChange,
  tenantId,
  tenantName,
  existingPayment,
  onSuccess,
}: RecordPaymentModalProps) {
  const isEdit = !!existingPayment

  const [selectedTenant, setSelectedTenant] = useState(tenantId || '')
  const [amount, setAmount] = useState('')
  const [paymentDate, setPaymentDate] = useState(format(new Date(), 'yyyy-MM-dd'))
  const [dueDate, setDueDate] = useState('')
  const [method, setMethod] = useState('')
  const [paidBy, setPaidBy] = useState('')
  const [reference, setReference] = useState('')
  const [submitting, setSubmitting] = useState(false)
  const [error, setError] = useState<string | null>(null)

  // Load tenants list when opened globally (no tenantId)
  const { data: tenants = [] } = useQuery<Tenant[]>({
    queryKey: ['tenants-list'],
    queryFn: () => apiClient.get('/api/admin/v1/tenants').then((r) => r.data.data.items),
    enabled: open && !tenantId,
  })

  // Pre-fill form when editing
  useEffect(() => {
    if (existingPayment) {
      setAmount(existingPayment.amount.toString())
      setPaymentDate(existingPayment.payment_date?.split('T')[0] || format(new Date(), 'yyyy-MM-dd'))
      setDueDate(existingPayment.due_date?.split('T')[0] || '')
      setMethod(existingPayment.method || '')
      setPaidBy(existingPayment.paid_by || '')
      setReference(existingPayment.reference || '')
    } else {
      // Reset form
      setAmount('')
      setPaymentDate(format(new Date(), 'yyyy-MM-dd'))
      setDueDate('')
      setMethod('')
      setPaidBy('')
      setReference('')
      setSelectedTenant(tenantId || '')
    }
    setError(null)
  }, [existingPayment, open, tenantId])

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setError(null)

    const tid = tenantId || selectedTenant
    if (!tid || !amount || !paymentDate || !dueDate || !method || !paidBy) {
      setError('Please fill in all required fields.')
      return
    }

    setSubmitting(true)
    try {
      const payload = {
        amount: parseFloat(amount),
        payment_date: paymentDate,
        due_date: dueDate || null,
        payment_method: method,
        paid_by_name: paidBy || null,
        reference: reference || null,
      }

      if (isEdit && existingPayment) {
        await apiClient.put(`/api/admin/v1/payments/${existingPayment.id}`, payload)
        toast.success('Payment updated.')
      } else {
        await apiClient.post(`/api/admin/v1/tenants/${tid}/payments`, payload)
        toast.success('Payment recorded successfully.')
      }
      onSuccess()
      onOpenChange(false)
    } catch {
      setError('Failed to record payment. Please try again.')
    } finally {
      setSubmitting(false)
    }
  }

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-lg">
        <DialogHeader>
          <DialogTitle>{isEdit ? 'Edit Payment' : 'Record Payment'}</DialogTitle>
          <DialogDescription>
            Record a SaaS subscription payment for a tenant.
          </DialogDescription>
        </DialogHeader>

        <form onSubmit={handleSubmit} className="space-y-4 py-2">
          {/* Tenant field */}
          {tenantId ? (
            <div>
              <Label>Tenant</Label>
              <div className="rounded-md border border-gray-200 bg-gray-50 px-3 py-2 text-sm font-medium">
                {tenantName}
              </div>
            </div>
          ) : (
            <div>
              <Label>Tenant <span className="text-red-500">*</span></Label>
              <Select
                value={selectedTenant}
                onValueChange={setSelectedTenant}
                disabled={isEdit}
              >
                <SelectTrigger>
                  <SelectValue placeholder="Choose a tenant" />
                </SelectTrigger>
                <SelectContent>
                  {tenants.map((t) => (
                    <SelectItem key={String(t.id)} value={String(t.id)}>{t.name}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
          )}

          {/* Amount */}
          <div>
            <Label htmlFor="amount">Amount <span className="text-red-500">*</span></Label>
            <div className="relative">
              <span className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400 text-sm">₹</span>
              <Input
                id="amount"
                type="number"
                min="1"
                step="1"
                placeholder="0"
                className="pl-7"
                value={amount}
                onChange={(e) => setAmount(e.target.value)}
                required
              />
            </div>
          </div>

          {/* Payment Date */}
          <div>
            <Label htmlFor="payment_date">Payment Date <span className="text-red-500">*</span></Label>
            <Input
              id="payment_date"
              type="date"
              value={paymentDate}
              onChange={(e) => setPaymentDate(e.target.value)}
              required
            />
          </div>

          {/* Due Date */}
          <div>
            <Label htmlFor="due_date">Due Date <span className="text-red-500">*</span></Label>
            <Input
              id="due_date"
              type="date"
              value={dueDate}
              onChange={(e) => setDueDate(e.target.value)}
              required
            />
            <p className="text-xs text-gray-400 mt-1">The billing due date this payment is covering.</p>
          </div>

          {/* Payment Method */}
          <div>
            <Label>Payment Method <span className="text-red-500">*</span></Label>
            <Select value={method} onValueChange={setMethod}>
              <SelectTrigger>
                <SelectValue placeholder="Select method" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="upi">UPI</SelectItem>
                <SelectItem value="cash">Cash</SelectItem>
                <SelectItem value="credit">Credit Card</SelectItem>
              </SelectContent>
            </Select>
          </div>

          {/* Paid By */}
          <div>
            <Label htmlFor="paid_by">Paid By <span className="text-red-500">*</span></Label>
            <Input
              id="paid_by"
              placeholder="e.g. Farm owner name"
              value={paidBy}
              onChange={(e) => setPaidBy(e.target.value)}
              required
            />
          </div>

          {/* Reference */}
          <div>
            <Label htmlFor="reference">Reference / Notes</Label>
            <Input
              id="reference"
              placeholder="e.g. UPI transaction ID, bank ref, note"
              maxLength={255}
              value={reference}
              onChange={(e) => setReference(e.target.value)}
            />
          </div>

          {error && (
            <Alert variant="destructive">
              <AlertCircle className="h-4 w-4" />
              <AlertDescription>{error}</AlertDescription>
            </Alert>
          )}
        </form>

        <DialogFooter>
          <Button variant="outline" onClick={() => onOpenChange(false)} type="button">
            Cancel
          </Button>
          <Button
            type="submit"
            className="bg-green-700 hover:bg-green-800 text-white"
            disabled={submitting}
            onClick={handleSubmit}
          >
            {submitting ? (
              <>
                <Loader2 className="w-4 h-4 mr-1.5 animate-spin" />
                {isEdit ? 'Saving…' : 'Recording…'}
              </>
            ) : (
              isEdit ? 'Update Payment' : 'Record Payment'
            )}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}
