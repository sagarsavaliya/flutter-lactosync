import { useState } from 'react'
import { useQuery, useQueryClient } from '@tanstack/react-query'
import { useNavigate } from 'react-router-dom'
import { format } from 'date-fns'
import {
  AlertCircle,
  CheckCircle2,
  Banknote,
  MoreHorizontal,
  Pencil,
  Trash2,
  Plus,
  X,
  Loader2,
} from 'lucide-react'
import AdminShell from '../components/layout/AdminShell'
import RecordPaymentModal from '../components/modals/RecordPaymentModal'
import { Button } from '../components/ui/button'
import { Card } from '../components/ui/card'
import { Badge } from '../components/ui/badge'
import { Skeleton } from '../components/ui/skeleton'
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '../components/ui/select'
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from '../components/ui/dropdown-menu'
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
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '../components/ui/table'
import { Alert, AlertDescription } from '../components/ui/alert'
import apiClient from '../api/client'
import { toast } from '../components/ui/use-toast'
import { cn, formatCurrency } from '../lib/utils'

interface Payment {
  id: string
  owner_id: string
  tenant_name: string
  amount: string
  payment_date: string
  due_date: string
  payment_method: string
  paid_by_name: string
  reference: string | null
  notes: string | null
  created_at: string
}

interface PaymentsResponse {
  data: Payment[]
  total_outstanding: string
  meta?: { current_page: number; last_page: number; total: number }
}

interface TenantOption {
  id: string | number
  name: string
}

const METHOD_LABELS: Record<string, string> = {
  upi: 'UPI',
  cash: 'Cash',
  credit_card: 'Credit Card',
}

function formatDate(d: string) {
  try { return format(new Date(d), 'dd MMM yyyy') } catch { return d }
}

export default function PaymentsPage() {
  const navigate = useNavigate()
  const queryClient = useQueryClient()

  const [tenantFilter, setTenantFilter] = useState('all')
  const [sortBy, setSortBy] = useState('date_desc')
  const [fromDate, setFromDate] = useState('')
  const [toDate, setToDate] = useState('')
  const [page, setPage] = useState(1)

  const [recordModalOpen, setRecordModalOpen] = useState(false)
  const [editPayment, setEditPayment] = useState<Payment | null>(null)
  const [deleteTarget, setDeleteTarget] = useState<Payment | null>(null)
  const [deleting, setDeleting] = useState(false)

  const hasFilters = tenantFilter !== 'all' || !!fromDate || !!toDate

  const sortByApiMap: Record<string, string> = {
    date_desc: 'date',
    date_asc: 'date',
    amount_desc: 'amount',
    amount_asc: 'amount',
    tenant_asc: 'tenant',
  }

  const paymentsQuery = useQuery<PaymentsResponse>({
    queryKey: ['payments', tenantFilter, sortBy, fromDate, toDate, page],
    queryFn: () =>
      apiClient.get('/api/admin/v1/payments', {
        params: {
          ...(tenantFilter !== 'all' && { tenant_id: tenantFilter }),
          ...(fromDate && { from: fromDate }),
          ...(toDate && { to: toDate }),
          sort_by: sortByApiMap[sortBy] ?? 'date',
          page,
        },
      }).then((r) => r.data),
  })

  const tenantsQuery = useQuery<{ items: TenantOption[] }>({
    queryKey: ['tenants-list-payments'],
    queryFn: () => apiClient.get('/api/admin/v1/tenants?per_page=100').then((r) => r.data.data),
  })

  const tenants: TenantOption[] = tenantsQuery.data?.items ?? []
  const payments: Payment[] = paymentsQuery.data?.data ?? []
  const totalOutstanding = paymentsQuery.data?.total_outstanding ?? '0.00'
  const meta = paymentsQuery.data?.meta

  function clearFilters() {
    setTenantFilter('all')
    setFromDate('')
    setToDate('')
    setPage(1)
  }

  function invalidate() {
    queryClient.invalidateQueries({ queryKey: ['payments'] })
    queryClient.invalidateQueries({ queryKey: ['dashboard'] })
  }

  async function confirmDelete() {
    if (!deleteTarget) return
    setDeleting(true)
    try {
      await apiClient.delete(`/api/admin/v1/payments/${deleteTarget.id}`)
      toast.success('Payment deleted.')
      setDeleteTarget(null)
      invalidate()
    } catch {
      toast.error('Failed to delete payment.')
    } finally {
      setDeleting(false)
    }
  }

  const outstanding = parseFloat(totalOutstanding)

  return (
    <AdminShell title="Payments">
      <div className="p-6 space-y-5">

        {/* Outstanding summary card */}
        {paymentsQuery.isLoading ? (
          <Card className="p-4">
            <Skeleton className="h-8 w-48" />
          </Card>
        ) : outstanding > 0 ? (
          <Card className="p-4 flex items-center justify-between bg-red-50 border-red-200">
            <div className="flex items-center gap-3">
              <AlertCircle className="w-5 h-5 text-red-500 shrink-0" />
              <div>
                <p className="text-xs text-red-600 font-medium uppercase tracking-wide">
                  Total Outstanding
                </p>
                <p className="text-2xl font-bold text-red-700">{formatCurrency(totalOutstanding)}</p>
              </div>
            </div>
            <p className="text-xs text-red-400">Across all tenants</p>
          </Card>
        ) : (
          <Card className="p-4 flex items-center gap-3 bg-green-50 border-green-200">
            <CheckCircle2 className="w-5 h-5 text-green-600 shrink-0" />
            <p className="text-sm font-medium text-green-700">
              All accounts are settled. No outstanding dues.
            </p>
          </Card>
        )}

        {/* Toolbar */}
        <div className="flex flex-wrap items-center gap-3">
          {/* Date range (simple inputs — react-day-picker not needed for functionality) */}
          <div className="flex items-center gap-2">
            <input
              type="date"
              value={fromDate}
              onChange={(e) => { setFromDate(e.target.value); setPage(1) }}
              className="h-9 rounded-md border border-gray-300 px-3 text-sm focus:outline-none focus:ring-2 focus:ring-green-500"
              placeholder="From"
            />
            <span className="text-gray-400 text-sm">–</span>
            <input
              type="date"
              value={toDate}
              onChange={(e) => { setToDate(e.target.value); setPage(1) }}
              className="h-9 rounded-md border border-gray-300 px-3 text-sm focus:outline-none focus:ring-2 focus:ring-green-500"
              placeholder="To"
            />
          </div>

          {/* Tenant filter */}
          <Select value={tenantFilter} onValueChange={(v) => { setTenantFilter(v); setPage(1) }}>
            <SelectTrigger className="w-48">
              <SelectValue placeholder="All Tenants" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">All Tenants</SelectItem>
              {tenants.map((t) => (
                <SelectItem key={String(t.id)} value={String(t.id)}>{t.name}</SelectItem>
              ))}
            </SelectContent>
          </Select>

          {/* Sort */}
          <Select value={sortBy} onValueChange={setSortBy}>
            <SelectTrigger className="w-44">
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="date_desc">Date (Newest)</SelectItem>
              <SelectItem value="date_asc">Date (Oldest)</SelectItem>
              <SelectItem value="amount_desc">Amount (High–Low)</SelectItem>
              <SelectItem value="amount_asc">Amount (Low–High)</SelectItem>
              <SelectItem value="tenant_asc">Tenant (A–Z)</SelectItem>
            </SelectContent>
          </Select>

          {hasFilters && (
            <Button variant="ghost" size="sm" onClick={clearFilters} className="text-gray-400 hover:text-gray-600">
              <X className="w-4 h-4 mr-1" /> Clear
            </Button>
          )}

          <Button
            className="ml-auto bg-green-700 hover:bg-green-800 text-white"
            onClick={() => { setEditPayment(null); setRecordModalOpen(true) }}
          >
            <Plus className="w-4 h-4 mr-1.5" /> Record Payment
          </Button>
        </div>

        {/* Error state */}
        {paymentsQuery.isError && (
          <Alert variant="destructive">
            <AlertCircle className="h-4 w-4" />
            <AlertDescription>Failed to load payments. Try again.</AlertDescription>
          </Alert>
        )}

        {/* Table */}
        <Card className="overflow-hidden">
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Date</TableHead>
                <TableHead>Tenant</TableHead>
                <TableHead>Amount</TableHead>
                <TableHead>Method</TableHead>
                <TableHead>Paid By</TableHead>
                <TableHead>Reference</TableHead>
                <TableHead className="w-14" />
              </TableRow>
            </TableHeader>
            <TableBody>
              {paymentsQuery.isLoading ? (
                Array.from({ length: 8 }).map((_, i) => (
                  <TableRow key={i}>
                    {Array.from({ length: 7 }).map((_, j) => (
                      <TableCell key={j}><Skeleton className="h-4 w-full" /></TableCell>
                    ))}
                  </TableRow>
                ))
              ) : payments.length === 0 ? (
                <TableRow>
                  <TableCell colSpan={7}>
                    <div className="flex flex-col items-center py-16 text-center">
                      <Banknote className="w-12 h-12 text-gray-200 mb-3" />
                      <p className="text-sm font-medium text-gray-500">No payments found</p>
                      <p className="text-xs text-gray-400 mt-1">
                        {hasFilters ? 'Try adjusting your filters.' : 'Record the first payment to get started.'}
                      </p>
                    </div>
                  </TableCell>
                </TableRow>
              ) : (
                payments.map((p) => (
                  <TableRow key={p.id}>
                    <TableCell className="text-sm">{formatDate(p.payment_date)}</TableCell>
                    <TableCell>
                      <button
                        className="text-green-700 font-medium hover:underline text-sm"
                        onClick={() => navigate(`/tenants/${p.owner_id}`)}
                      >
                        {p.tenant_name}
                      </button>
                    </TableCell>
                    <TableCell className="font-medium text-sm">{formatCurrency(p.amount)}</TableCell>
                    <TableCell>
                      <Badge variant="outline" className="text-xs">
                        {METHOD_LABELS[p.payment_method] ?? p.payment_method}
                      </Badge>
                    </TableCell>
                    <TableCell className="text-sm">{p.paid_by_name}</TableCell>
                    <TableCell className={cn('text-xs max-w-[140px] truncate', p.reference ? 'text-gray-500' : 'text-gray-300')}>
                      {p.reference ?? '—'}
                    </TableCell>
                    <TableCell>
                      <DropdownMenu>
                        <DropdownMenuTrigger asChild>
                          <Button variant="ghost" size="icon">
                            <MoreHorizontal className="w-4 h-4" />
                          </Button>
                        </DropdownMenuTrigger>
                        <DropdownMenuContent align="end">
                          <DropdownMenuItem onClick={() => { setEditPayment(p); setRecordModalOpen(true) }}>
                            <Pencil className="w-4 h-4 mr-2" /> Edit
                          </DropdownMenuItem>
                          <DropdownMenuSeparator />
                          <DropdownMenuItem
                            className="text-red-600 focus:text-red-600"
                            onClick={() => setDeleteTarget(p)}
                          >
                            <Trash2 className="w-4 h-4 mr-2" /> Delete
                          </DropdownMenuItem>
                        </DropdownMenuContent>
                      </DropdownMenu>
                    </TableCell>
                  </TableRow>
                ))
              )}
            </TableBody>
          </Table>
        </Card>

        {/* Pagination */}
        {meta && meta.last_page > 1 && (
          <div className="flex items-center justify-between text-sm text-gray-500">
            <span>Page {meta.current_page} of {meta.last_page} ({meta.total} total)</span>
            <div className="flex gap-2">
              <Button
                variant="outline"
                size="sm"
                disabled={meta.current_page <= 1}
                onClick={() => setPage((p) => p - 1)}
              >
                Previous
              </Button>
              <Button
                variant="outline"
                size="sm"
                disabled={meta.current_page >= meta.last_page}
                onClick={() => setPage((p) => p + 1)}
              >
                Next
              </Button>
            </div>
          </div>
        )}
      </div>

      {/* Record / Edit modal */}
      <RecordPaymentModal
        open={recordModalOpen}
        onOpenChange={(open) => {
          setRecordModalOpen(open)
          if (!open) setEditPayment(null)
        }}
        existingPayment={editPayment ? {
          id: editPayment.id,
          payment_date: editPayment.payment_date,
          amount: parseFloat(editPayment.amount),
          method: editPayment.payment_method,
          paid_by: editPayment.paid_by_name,
          reference: editPayment.reference,
          due_date: editPayment.due_date,
          tenant_id: editPayment.owner_id,
          tenant_name: editPayment.tenant_name,
        } : undefined}
        onSuccess={invalidate}
      />

      {/* Delete confirmation */}
      <AlertDialog open={!!deleteTarget} onOpenChange={(o) => !o && setDeleteTarget(null)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Delete this payment record?</AlertDialogTitle>
            <AlertDialogDescription>
              This will remove the payment of{' '}
              <strong>{deleteTarget ? formatCurrency(deleteTarget.amount) : ''}</strong> recorded on{' '}
              <strong>{deleteTarget ? formatDate(deleteTarget.payment_date) : ''}</strong> for{' '}
              <strong>{deleteTarget?.tenant_name}</strong>.
              <br /><br />
              The tenant's outstanding balance will increase accordingly.
              This action uses a soft delete — the record is archived in the audit trail.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel disabled={deleting}>Cancel</AlertDialogCancel>
            <AlertDialogAction
              className="bg-red-600 hover:bg-red-700 text-white"
              onClick={confirmDelete}
              disabled={deleting}
            >
              {deleting ? <><Loader2 className="w-4 h-4 mr-1.5 animate-spin" />Deleting…</> : 'Delete'}
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </AdminShell>
  )
}
