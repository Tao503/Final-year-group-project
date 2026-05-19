'use client'

import Link from 'next/link'
import { usePathname } from 'next/navigation'
import { 
  BarChart3, 
  MapPin, 
  Heart, 
  Calendar, 
  Users, 
  Settings, 
  LogOut,
  ShieldCheck
} from 'lucide-react'

const navigation = [
  { name: 'Dashboard', href: '/', icon: BarChart3 },
  { name: 'Lost & Found', href: '/items', icon: MapPin },
  { name: 'Donations', href: '/donations', icon: Heart },
  { name: 'Events', href: '/events', icon: Calendar },
  { name: 'Users', href: '/users', icon: Users },
  { name: 'Settings', href: '/settings', icon: Settings },
]

export default function Sidebar() {
  const pathname = usePathname()

  return (
    <div className="flex grow flex-col gap-y-5 overflow-y-auto border-r border-slate-200 bg-white px-6 pb-4 dark:border-slate-800 dark:bg-slate-950">
      <div className="flex h-16 shrink-0 items-center gap-x-2">
        <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-blue-600 text-white">
          <ShieldCheck className="h-5 w-5" />
        </div>
        <span className="text-xl font-bold tracking-tight text-slate-900 dark:text-white">Ummu Admin</span>
      </div>
      <nav className="flex flex-1 flex-col">
        <ul role="list" className="flex flex-1 flex-col gap-y-7">
          <li>
            <ul role="list" className="-mx-2 space-y-1">
              {navigation.map((item) => (
                <li key={item.name}>
                  <Link
                    href={item.href}
                    className={`
                      group flex gap-x-3 rounded-md p-2 text-sm font-semibold leading-6
                      ${pathname === item.href 
                        ? 'bg-slate-50 text-blue-600 dark:bg-slate-900 dark:text-blue-400' 
                        : 'text-slate-700 hover:bg-slate-50 hover:text-blue-600 dark:text-slate-400 dark:hover:bg-slate-900 dark:hover:text-blue-400'}
                    `}
                  >
                    <item.icon className="h-6 w-6 shrink-0" aria-hidden="true" />
                    {item.name}
                  </Link>
                </li>
              ))}
            </ul>
          </li>
          <li className="mt-auto">
            <button
              className="group -mx-2 flex w-full gap-x-3 rounded-md p-2 text-sm font-semibold leading-6 text-slate-700 hover:bg-slate-50 hover:text-red-600 dark:text-slate-400 dark:hover:bg-slate-900 dark:hover:text-red-400"
            >
              <LogOut className="h-6 w-6 shrink-0" aria-hidden="true" />
              Sign out
            </button>
          </li>
        </ul>
      </nav>
    </div>
  )
}
