import { create } from 'zustand'
import { persist, createJSONStorage } from 'zustand/middleware'
import axios from 'axios'

interface AuthState {
  token: string | null
  adminEmail: string | null
  setAuth: (token: string, email: string) => void
  clearAuth: () => void
  logout: () => Promise<void>
}

export const useAuthStore = create<AuthState>()(
  persist(
    (set, get) => ({
      token: null,
      adminEmail: null,

      setAuth: (token: string, email: string) => {
        set({ token, adminEmail: email })
      },

      clearAuth: () => {
        set({ token: null, adminEmail: null })
      },

      logout: async () => {
        try {
          const { token } = get()
          if (token) {
            await axios.post(
              `${import.meta.env.VITE_API_BASE_URL || ''}/api/admin/v1/auth/logout`,
              {},
              { headers: { Authorization: `Bearer ${token}` } }
            )
          }
        } catch {
          // Ignore errors on logout
        } finally {
          get().clearAuth()
        }
      },
    }),
    {
      name: 'lactosync-admin-auth',
      storage: createJSONStorage(() => localStorage),
      partialize: (state) => ({
        token: state.token,
        adminEmail: state.adminEmail,
      }),
    },
  ),
)
