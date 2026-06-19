import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom'
import { useEffect, useState } from 'react'
import { useAuthStore } from '../stores/authStore'

import LoginPage from '../pages/LoginPage'
import DashboardPage from '../pages/DashboardPage'
import TenantListPage from '../pages/TenantListPage'
import TenantDetailPage from '../pages/TenantDetailPage'
import PlanListPage from '../pages/PlanListPage'
import PaymentsPage from '../pages/PaymentsPage'
import CouponsPage from '../pages/CouponsPage'

function ProtectedRoute({ children }: { children: React.ReactNode }) {
  const token = useAuthStore((s) => s.token)
  const [hydrated, setHydrated] = useState(useAuthStore.persist.hasHydrated())

  useEffect(() => {
    if (hydrated) return
    const unsub = useAuthStore.persist.onFinishHydration(() => setHydrated(true))
    setHydrated(useAuthStore.persist.hasHydrated())
    return unsub
  }, [hydrated])

  if (!hydrated) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-[#F4F7F5] text-sm text-gray-500">
        Loading…
      </div>
    )
  }

  if (!token) return <Navigate to="/login" replace />
  return <>{children}</>
}

export default function AppRouter() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/login" element={<LoginPage />} />
        <Route path="/" element={<Navigate to="/dashboard" replace />} />
        <Route
          path="/dashboard"
          element={
            <ProtectedRoute>
              <DashboardPage />
            </ProtectedRoute>
          }
        />
        <Route
          path="/tenants"
          element={
            <ProtectedRoute>
              <TenantListPage />
            </ProtectedRoute>
          }
        />
        <Route
          path="/tenants/:id"
          element={
            <ProtectedRoute>
              <TenantDetailPage />
            </ProtectedRoute>
          }
        />
        <Route
          path="/plans"
          element={
            <ProtectedRoute>
              <PlanListPage />
            </ProtectedRoute>
          }
        />
        <Route
          path="/payments"
          element={
            <ProtectedRoute>
              <PaymentsPage />
            </ProtectedRoute>
          }
        />
        <Route
          path="/coupons"
          element={
            <ProtectedRoute>
              <CouponsPage />
            </ProtectedRoute>
          }
        />
      </Routes>
    </BrowserRouter>
  )
}
