import { 
  Calendar, 
  Trash2, 
  Edit3, 
  Plus,
  Clock,
  MapPin 
} from 'lucide-react'
import { supabase } from '@/lib/supabase'

async function getEvents() {
  const { data } = await supabase
    .from('events')
    .select('*')
    .order('event_date', { ascending: true })
  return data || []
}

export default async function EventsPage() {
  const events = await getEvents()

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-slate-900 dark:text-white tracking-tight">Community Events</h1>
          <p className="mt-1 text-sm text-slate-500 dark:text-slate-400">
            Create and manage upcoming events for the community.
          </p>
        </div>
        <button className="flex items-center gap-x-2 rounded-lg bg-blue-600 px-4 py-2 text-sm font-semibold text-white hover:bg-blue-500 transition-colors shadow-sm">
          <Plus className="h-4 w-4" />
          Add Event
        </button>
      </div>

      <div className="grid grid-cols-1 gap-6 md:grid-cols-2 lg:grid-cols-3">
        {events.map((event) => (
          <div key={event.id} className="group overflow-hidden rounded-xl border border-slate-200 bg-white shadow-sm transition-all hover:shadow-md dark:border-slate-800 dark:bg-slate-950">
            <div className="relative h-40 w-full overflow-hidden bg-slate-100 dark:bg-slate-900">
              {event.image_url ? (
                <img 
                  src={event.image_url} 
                  alt={event.title} 
                  className="h-full w-full object-cover transition-transform duration-300 group-hover:scale-105"
                />
              ) : (
                <div className="flex h-full w-full items-center justify-center text-slate-300">
                  <Calendar className="h-12 w-12" />
                </div>
              )}
              <div className="absolute top-3 right-3 flex gap-x-2">
                <button className="rounded-full bg-white/90 p-1.5 text-slate-700 shadow-sm transition-colors hover:bg-white hover:text-blue-600 dark:bg-slate-950/90 dark:text-slate-300 dark:hover:text-blue-400">
                  <Edit3 className="h-4 w-4" />
                </button>
                <button className="rounded-full bg-white/90 p-1.5 text-slate-700 shadow-sm transition-colors hover:bg-white hover:text-red-600 dark:bg-slate-950/90 dark:text-slate-300 dark:hover:text-red-400">
                  <Trash2 className="h-4 w-4" />
                </button>
              </div>
            </div>
            <div className="p-5">
              <h3 className="text-lg font-bold text-slate-900 dark:text-white truncate">
                {event.title}
              </h3>
              <div className="mt-3 space-y-2">
                <div className="flex items-center gap-x-2 text-sm text-slate-500 dark:text-slate-400">
                  <Calendar className="h-4 w-4 text-blue-500" />
                  {new Date(event.event_date).toLocaleDateString(undefined, { dateStyle: 'medium' })}
                </div>
                <div className="flex items-center gap-x-2 text-sm text-slate-500 dark:text-slate-400">
                  <Clock className="h-4 w-4 text-blue-500" />
                  {event.event_time || 'Check description'}
                </div>
                <div className="flex items-center gap-x-2 text-sm text-slate-500 dark:text-slate-400">
                  <MapPin className="h-4 w-4 text-blue-500" />
                  <span className="truncate">{event.location || 'N/A'}</span>
                </div>
              </div>
            </div>
          </div>
        ))}
      </div>

      {events.length === 0 && (
        <div className="rounded-xl border-2 border-dashed border-slate-200 py-20 text-center dark:border-slate-800">
          <Calendar className="mx-auto h-12 w-12 text-slate-300" />
          <h3 className="mt-4 text-lg font-medium text-slate-900 dark:text-white">No events scheduled</h3>
          <p className="mt-1 text-slate-500 dark:text-slate-400">Get started by creating a new event for the community.</p>
        </div>
      )}
    </div>
  )
}
