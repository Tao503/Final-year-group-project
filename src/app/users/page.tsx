import { 
  Users, 
  Trash2, 
  Shield, 
  Search,
  MoreVertical,
  Mail,
  User 
} from 'lucide-react'
import { supabase } from '@/lib/supabase'

async function getUsers() {
  const { data } = await supabase
    .from('user_profiles')
    .select('*')
    .order('created_at', { ascending: false })
  return data || []
}

export default async function UsersPage() {
  const users = await getUsers()

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-slate-900 dark:text-white tracking-tight">User Management</h1>
          <p className="mt-1 text-sm text-slate-500 dark:text-slate-400">
            Monitor and manage registered users in the Ummu community.
          </p>
        </div>
      </div>

      <div className="flex items-center gap-x-4">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-400" />
          <input 
            type="text" 
            placeholder="Search users by name or email..." 
            className="w-full rounded-lg border border-slate-200 bg-white py-2 pl-10 pr-4 text-sm outline-none focus:ring-2 focus:ring-blue-500 dark:border-slate-800 dark:bg-slate-950 dark:text-white"
          />
        </div>
      </div>

      <div className="overflow-hidden rounded-xl border border-slate-200 bg-white shadow-sm dark:border-slate-800 dark:bg-slate-950">
        <table className="w-full text-left text-sm">
          <thead className="border-b border-slate-200 bg-slate-50/50 dark:border-slate-800 dark:bg-slate-900/50">
            <tr>
              <th className="px-6 py-4 font-semibold text-slate-900 dark:text-white">User</th>
              <th className="px-6 py-4 font-semibold text-slate-900 dark:text-white">Joined Date</th>
              <th className="px-6 py-4 font-semibold text-slate-900 dark:text-white">Actions</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-100 dark:divide-slate-900">
            {users.map((user) => (
              <tr key={user.id} className="hover:bg-slate-50/50 dark:hover:bg-slate-900/50">
                <td className="px-6 py-4">
                  <div className="flex items-center gap-x-3">
                    <div className="h-10 w-10 overflow-hidden rounded-full bg-slate-100 dark:bg-slate-900 flex items-center justify-center">
                      {user.avatar_url ? (
                        <img src={user.avatar_url} alt={user.full_name} className="h-full w-full object-cover" />
                      ) : (
                        <User className="h-5 w-5 text-slate-400" />
                      )}
                    </div>
                    <div>
                      <div className="font-medium text-slate-900 dark:text-white">
                        {user.full_name || 'Anonymous'}
                      </div>
                      <div className="text-xs text-slate-500 flex items-center gap-x-1">
                        <Mail className="h-3 w-3" />
                        {user.email || 'No email provided'}
                      </div>
                    </div>
                  </div>
                </td>
                <td className="px-6 py-4 text-slate-500 dark:text-slate-400">
                  {new Date(user.created_at).toLocaleDateString()}
                </td>
                <td className="px-6 py-4">
                  <div className="flex items-center gap-x-3 text-slate-400">
                    <button className="hover:text-blue-600 dark:hover:text-blue-400 transition-colors">
                      <Shield className="h-5 w-5" />
                    </button>
                    <button className="hover:text-red-600 dark:hover:text-red-400 transition-colors">
                      <Trash2 className="h-5 w-5" />
                    </button>
                    <button className="hover:text-slate-900 dark:hover:text-white transition-colors">
                      <MoreVertical className="h-5 w-5" />
                    </button>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
        {users.length === 0 && (
          <div className="px-6 py-12 text-center text-slate-500 dark:text-slate-400">
            No users found.
          </div>
        )}
      </div>
    </div>
  )
}
