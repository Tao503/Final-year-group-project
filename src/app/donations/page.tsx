import { 
  Heart, 
  Trash2, 
  CheckCircle2, 
  Search,
  Filter,
  User 
} from 'lucide-react'
import { supabase } from '@/lib/supabase'

async function getDonations() {
  const { data } = await supabase
    .from('donations')
    .select('*, user_profiles(full_name)')
    .order('created_at', { ascending: false })
  return data || []
}

export default async function DonationsPage() {
  const donations = await getDonations()

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-slate-900 dark:text-white tracking-tight">Donation Management</h1>
          <p className="mt-1 text-sm text-slate-500 dark:text-slate-400">
            Review and manage items put up for donation in the community.
          </p>
        </div>
      </div>

      <div className="flex items-center gap-x-4">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-400" />
          <input 
            type="text" 
            placeholder="Search donations..." 
            className="w-full rounded-lg border border-slate-200 bg-white py-2 pl-10 pr-4 text-sm outline-none focus:ring-2 focus:ring-blue-500 dark:border-slate-800 dark:bg-slate-950 dark:text-white"
          />
        </div>
        <button className="flex items-center gap-x-2 rounded-lg border border-slate-200 bg-white px-4 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50 dark:border-slate-800 dark:bg-slate-950 dark:text-slate-300 dark:hover:bg-slate-900">
          <Filter className="h-4 w-4" />
          Filter
        </button>
      </div>

      <div className="overflow-hidden rounded-xl border border-slate-200 bg-white shadow-sm dark:border-slate-800 dark:bg-slate-950">
        <table className="w-full text-left text-sm">
          <thead className="border-b border-slate-200 bg-slate-50/50 dark:border-slate-800 dark:bg-slate-900/50">
            <tr>
              <th className="px-6 py-4 font-semibold text-slate-900 dark:text-white">Donation Item</th>
              <th className="px-6 py-4 font-semibold text-slate-900 dark:text-white">Recommended To</th>
              <th className="px-6 py-4 font-semibold text-slate-900 dark:text-white">Date Posted</th>
              <th className="px-6 py-4 font-semibold text-slate-900 dark:text-white">Actions</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-100 dark:divide-slate-900">
            {donations.map((donation) => (
              <tr key={donation.id} className="hover:bg-slate-50/50 dark:hover:bg-slate-900/50">
                <td className="px-6 py-4">
                  <div className="flex flex-col">
                    <span className="font-medium text-slate-900 dark:text-white truncate max-w-[240px]">
                      {donation.title}
                    </span>
                    <span className="text-xs text-slate-500 flex items-center gap-x-1">
                      <User className="h-3 w-3" />
                      {donation.user_profiles?.full_name || 'Anonymous Donor'}
                    </span>
                  </div>
                </td>
                <td className="px-6 py-4">
                  <span className="inline-flex items-center rounded-full bg-emerald-50 px-2 py-0.5 text-xs font-medium text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-400">
                    {donation.recommended_category || 'General'}
                  </span>
                </td>
                <td className="px-6 py-4 text-slate-500 dark:text-slate-400">
                  {new Date(donation.created_at).toLocaleDateString()}
                </td>
                <td className="px-6 py-4">
                  <div className="flex items-center gap-x-3">
                    <button className="text-slate-400 hover:text-green-600 dark:hover:text-green-400 transition-colors">
                      <CheckCircle2 className="h-5 w-5" />
                    </button>
                    <button className="text-slate-400 hover:text-red-600 dark:hover:text-red-400 transition-colors">
                      <Trash2 className="h-5 w-5" />
                    </button>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
        {donations.length === 0 && (
          <div className="px-6 py-12 text-center text-slate-500 dark:text-slate-400">
            No donations found.
          </div>
        )}
      </div>
    </div>
  )
}
