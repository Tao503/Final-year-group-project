import { 
  BarChart3, 
  MapPin, 
  Heart, 
  Clock,
  ArrowUpRight 
} from 'lucide-react'
import { supabase } from '@/lib/supabase'

async function getStats() {
  // Use a simpler select to get counts
  const { count: usersCount } = await supabase.from('user_profiles').select('id', { count: 'exact', head: true })
  const { count: itemsCount } = await supabase.from('items').select('id', { count: 'exact', head: true })
  const { count: donationsCount } = await supabase.from('donations').select('id', { count: 'exact', head: true })

  return {
    users: usersCount || 0,
    items: itemsCount || 0,
    donations: donationsCount || 0,
  }
}

async function getRecentActivity() {
  const { data: items } = await supabase
    .from('items')
    .select('*')
    .order('created_at', { ascending: false })
    .limit(5)
    
  const { data: donations } = await supabase
    .from('donations')
    .select('*')
    .order('created_at', { ascending: false })
    .limit(5)

  // Merge and sort
  const activity = [
    ...(items || []).map(i => ({ ...i, activityType: 'Lost & Found' })),
    ...(donations || []).map(d => ({ ...d, activityType: 'Donation', type: 'Donation' }))
  ].sort((a, b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime())
  
  return activity.slice(0, 5)
}

export default async function Dashboard() {
  const stats = await getStats()
  const recentActivity = await getRecentActivity()

  const statCards = [
    { name: 'Total Users', value: stats.users, icon: BarChart3, color: 'text-blue-600', bg: 'bg-blue-50 dark:bg-blue-900/20' },
    { name: 'Lost & Found', value: stats.items, icon: MapPin, color: 'text-orange-600', bg: 'bg-orange-50 dark:bg-orange-900/20' },
    { name: 'Donations', value: stats.donations, icon: Heart, color: 'text-red-600', bg: 'bg-red-50 dark:bg-red-900/20' },
  ]

  return (
    <div className="space-y-8">
      <div>
        <h1 className="text-2xl font-bold text-slate-900 dark:text-white">Dashboard Overview</h1>
        <p className="mt-1 text-sm text-slate-500 dark:text-slate-400">
          Welcome back, Admin. Here is what's happening today.
        </p>
      </div>

      <div className="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3">
        {statCards.map((card) => (
          <div key={card.name} className="overflow-hidden rounded-xl border border-slate-200 bg-white p-6 shadow-sm dark:border-slate-800 dark:bg-slate-950">
            <div className="flex items-center gap-x-4">
              <div className={`p-2 rounded-lg ${card.bg}`}>
                <card.icon className={`h-6 w-6 ${card.color}`} />
              </div>
              <div>
                <p className="text-sm font-medium text-slate-500 dark:text-slate-400">{card.name}</p>
                <p className="text-2xl font-bold text-slate-900 dark:text-white">{card.value}</p>
              </div>
            </div>
          </div>
        ))}
      </div>

      <div className="rounded-xl border border-slate-200 bg-white shadow-sm dark:border-slate-800 dark:bg-slate-950">
        <div className="flex items-center justify-between border-b border-slate-200 px-6 py-4 dark:border-slate-800">
          <h2 className="text-lg font-semibold text-slate-900 dark:text-white">Recent Activity</h2>
          <button className="flex items-center gap-x-1 text-sm font-medium text-blue-600 hover:text-blue-500 dark:text-blue-400">
            View all
            <ArrowUpRight className="h-4 w-4" />
          </button>
        </div>
        <div className="divide-y divide-slate-100 dark:divide-slate-900">
          {recentActivity.length > 0 ? (
            recentActivity.map((item) => (
              <div key={item.id} className="flex items-center space-x-4 px-6 py-4">
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-medium text-slate-900 truncate dark:text-white">
                    {item.title}
                  </p>
                  <p className="text-xs text-slate-500 dark:text-slate-400">
                    {item.activityType} • {item.category || item.recommended_category || 'General'}
                  </p>
                </div>
                <div className="flex flex-col items-end gap-y-1">
                  <span className={`inline-flex items-center rounded-full px-2 py-0.5 text-xs font-medium ${
                    item.status === 'open' ? 'bg-green-100 text-green-700 dark:bg-green-900/30' : 'bg-slate-100 text-slate-700 dark:bg-slate-900/30'
                  }`}>
                    {item.status}
                  </span>
                  <div className="flex items-center gap-x-1 text-xs text-slate-400">
                    <Clock className="h-3 w-3" />
                    {new Date(item.created_at).toLocaleDateString()}
                  </div>
                </div>
              </div>
            ))
          ) : (
            <div className="px-6 py-10 text-center text-slate-500 dark:text-slate-400">
              No recent items found.
            </div>
          )}
        </div>
      </div>
    </div>
  )
}
