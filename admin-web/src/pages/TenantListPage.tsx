import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useQuery, useQueryClient } from '@tanstack/react-query'
import {
  Building2,
  Search,
  MoreHorizontal,
  Eye,
  CreditCard,
  PauseCircle,
  PlayCircle,
  Banknote,
  AlertCircle,
} from 'lucide-react'
import AdminShell from '../components/layout/AdminShell'
import { Button } from '../components/ui/button'
import { Input } from '../components/ui/input'
import { Badge } from '../components/ui/badge'
import { Skeleton } from '../components/ui/skeleton'
import { Alert, AlertTitle, AlertDescription } from '../components/ui/alert'
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
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '../components/ui/table'
import { Card } from '../components/ui/card'
import { formatCurrency, formatDate } from '../lib/utils'
import apiClient from '../api/client'
import RecordPaymentModal from '../components/modals/RecordPaymentModal'
import PlanActionModals from '../components/modals/PlanActionModals'

interface Tenant {
  id: number
  name: string
  phone: string
  plan_name: string | null
  plan_status: 'active' | 'grace_period' | 'suspended' | 'paused' | 'no_plan'
  renewal_date: string | null
  days_until_renewal: number | null
  outstanding_balance: number
}

function getStatusBadge(status: Tenant['plan_status'], daysLeft?: number | null) {
  switch (status) {
    case 'active':
      return <Badge className="bg-green-100 text-green-800 border-green-200">Active</Badge>
    case 'grace_period':
      return <Badge variant="warning">{`Grace — ${daysLeft ?? 0} days`}</Badge>
    case 'suspended':
      return <Badge variant="destructive">Suspended</Badge>
    case 'paused':
      return <Badge className="bg-blue-100 text-blue-800 border-blue-200">Paused</Badge>
    case 'no_plan':
      return <Badge variant="outline" className="text-gray-500">No Plan</Badge>
    default:
      return <Badge variant="outline">{status}</Badge>
  }
}

export default function TenantListPage() {
  const navigate = useNavigate()
  const queryClient = useQueryClient()

  const [search, setSearch] = useState('')
  const [statusFilter, setStatusFilter] = useState('all')
  const [recordPaymentTenant, setRecordPaymentTenant] = useState<{ id: string; name: string } | null>(null)
  const [paymentModalOpen, setPaymentModalOpen] = useState(false)
  const [planModalTenant, setPlanModalTenant] = useState<{ id: string; name: string; plan_name: string | null; plan_status: string } | null>(null)
  const [planModalType, setPlanModalType] = useState<'assign' | 'change' | 'pause' | 'resume' | null>(null)

  const { data: tenants = [], isLoading, isError, refetch } = useQuery<Tenant[]>({
    queryKey: ['tenants'],
    queryFn: () => apiClient.get('/api/admin/v1/tenants').then((r) => r.data.data.items),
  })

  const filtered = tenants.filter((t) => {
    const matchSearch =
      !search ||
      t.name.toLowerCase().includes(search.toLowerCase()) ||
      t.phone.includes(search)
    const matchStatus = statusFilter === 'all' || t.plan_status === statusFilter
    return matchSearch && matchStatus
  })

  const openPlanModal = (tenant: Tenant, type: 'assign' | 'change' | 'pause' | 'resume') => {
    setPlanModalTenant({ id: String(tenant.id), name: tenant.name, plan_name: tenant.plan_name, plan_status: tenant.plan_status })
    setPlanModalType(type)
  }

  const closePlanModal = () => {
    setPlanModalTenant(null)
    setPlanModalType(null)
  }

  return (
    <AdminShell title="Tenants">
      {/* Toolbar */}
      <div className="flex items-center gap-3 mb-4">
        <div className="relative flex-1 max-w-sm">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
          <Input
            placeholder="Search tenants…"
            className="pl-9"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
          />
        </div>

        <Select value={statusFilter} onValueChange={setStatusFilter}>
          <SelectTrigger className="w-44">
            <SelectValue placeholder="All Statuses" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">All Statuses</SelectItem>
            <SelectItem value="active">Active</SelectItem>
            <SelectItem value="grace_period">Grace Period</SelectItem>
            <SelectItem value="suspended">Suspended</SelectItem>
            <SelectItem value="no_plan">No Plan</SelectItem>
            <SelectItem value="paused">Paused</SelectItem>
          </SelectContent>
        </Select>
      </div>

      {isError && (
        <Alert variant="destructive" className="mb-4">
          <AlertCircle className="h-4 w-4" />
          <AlertTitle>Failed to load tenants</AlertTitle>
          <AlertDescription>
            <Button variant="link" className="p-0 h-auto ml-1" onClick={() => refetch()}>
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
        ) : filtered.length === 0 ? (
          <div className="flex flex-col items-center py-16 text-center">
            <Building2 className="w-12 h-12 text-gray-200 mb-3" />
            <p className="text-sm font-medium text-gray-500">No tenants found</p>
            <p className="text-xs text-gray-400 mt-1">Try adjusting your search or filter.</p>
          </div>
        ) : (
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Tenant Name</TableHead>
                <TableHead>Phone</TableHead>
                <TableHead>Plan</TableHead>
                <TableHead>Status</TableHead>
                <TableHead>Renewal Date</TableHead>
                <TableHead>Outstanding</TableHead>
                <TableHead className="w-16"></TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {filtered.map((tenant) => (
                <TableRow
                  key={tenant.id}
                  className={tenant.plan_status === 'suspended' ? 'bg-red-50' : ''}
                >
                  <TableCell>
                    <button
                      onClick={() => navigate(`/tenants/${tenant.id}`)}
                      className="text-green-700 font-medium cursor-pointer hover:underline text-left"
                    >
                      {tenant.name}
                    </button>
                  </TableCell>
                  <TableCell>{tenant.phone}</TableCell>
                  <TableCell>
                    {tenant.plan_name || (
                      <span className="text-gray-400 italic">No plan</span>
                    )}
                  </TableCell>
                  <TableCell>{getStatusBadge(tenant.plan_status)}</TableCell>
                  <TableCell>{formatDate(tenant.renewal_date)}</TableCell>
                  <TableCell>
                    <span className={tenant.outstanding_balance > 0 ? 'text-red-600' : 'text-gray-500'}>
                      {formatCurrency(tenant.outstanding_balance)}
                    </span>
                  </TableCell>
                  <TableCell>
                    <DropdownMenu>
                      <DropdownMenuTrigger asChild>
                        <Button variant="ghost" size="icon">
                          <MoreHorizontal className="w-4 h-4" />
                        </Button>
                      </DropdownMenuTrigger>
                      <DropdownMenuContent align="end">
                        <DropdownMenuItem onClick={() => navigate(`/tenants/${tenant.id}`)}>
                          <Eye className="w-4 h-4 mr-2" /> View Details
                        </DropdownMenuItem>

                        {tenant.plan_status === 'no_plan' && (
                          <DropdownMenuItem onClick={() => openPlanModal(tenant, 'assign')}>
                            <CreditCard className="w-4 h-4 mr-2" /> Assign Plan
                          </DropdownMenuItem>
                        )}

                        {['active', 'grace_period', 'suspended'].includes(tenant.plan_status) && (
                          <DropdownMenuItem onClick={() => openPlanModal(tenant, 'change')}>
                            <CreditCard className="w-4 h-4 mr-2" /> Change Plan
                          </DropdownMenuItem>
                        )}

                        {tenant.plan_status === 'active' && (
                          <DropdownMenuItem onClick={() => openPlanModal(tenant, 'pause')}>
                            <PauseCircle className="w-4 h-4 mr-2" /> Pause Plan
                          </DropdownMenuItem>
                        )}

                        {tenant.plan_status === 'paused' && (
                          <DropdownMenuItem onClick={() => openPlanModal(tenant, 'resume')}>
                            <PlayCircle className="w-4 h-4 mr-2" /> Resume Plan
                          </DropdownMenuItem>
                        )}

                        {tenant.plan_status !== 'no_plan' && (
                          <>
                            <DropdownMenuSeparator />
                            <DropdownMenuItem
                              onClick={() => {
                                setRecordPaymentTenant({ id: String(tenant.id), name: tenant.name })
                                setPaymentModalOpen(true)
                              }}
                            >
                              <Banknote className="w-4 h-4 mr-2" /> Record Payment
                            </DropdownMenuItem>
                          </>
                        )}
                      </DropdownMenuContent>
                    </DropdownMenu>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        )}
      </Card>

      {/* Record Payment Modal */}
      <RecordPaymentModal
        open={paymentModalOpen}
        onOpenChange={setPaymentModalOpen}
        tenantId={recordPaymentTenant?.id}
        tenantName={recordPaymentTenant?.name}
        onSuccess={() => {
          queryClient.invalidateQueries({ queryKey: ['tenants'] })
        }}
      />

      {/* Plan Action Modals */}
      {planModalTenant && planModalType && (
        <PlanActionModals
          tenant={planModalTenant}
          modalType={planModalType}
          onClose={closePlanModal}
          onSuccess={() => {
            closePlanModal()
            queryClient.invalidateQueries({ queryKey: ['tenants'] })
          }}
        />
      )}
    </AdminShell>
  )
}
