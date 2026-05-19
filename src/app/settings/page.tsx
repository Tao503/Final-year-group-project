'use client'

import { useState } from 'react'
import { Save, Shield, Bell, Database, Key } from 'lucide-react'

export default function SettingsPage() {
  const [loading, setLoading] = useState(false)

  const handleSave = async (e: React.FormEvent) => {
    e.preventDefault()
    setLoading(true)
    // Simulate saving
    await new Promise(resolve => setTimeout(resolve, 1000))
    setLoading(false)
    alert('Settings saved successfully!')
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-3xl font-bold tracking-tight text-slate-900 dark:text-white">Settings</h1>
      </div>

      <form onSubmit={handleSave} className="space-y-6">
        {/* API Configuration */}
        <div className="rounded-xl border border-slate-200 bg-white p-6 dark:border-slate-800 dark:bg-slate-950">
          <div className="flex items-center gap-x-3 border-b border-slate-100 pb-4 dark:border-slate-900">
            <Key className="h-5 w-5 text-blue-600" />
            <h2 className="text-lg font-semibold text-slate-900 dark:text-white">API Configuration</h2>
          </div>
          <div className="mt-6 space-y-4">
            <div>
              <label className="block text-sm font-medium text-slate-700 dark:text-slate-300">Gemini API Key</label>
              <input
                type="password"
                placeholder="Enter Gemini API Key..."
                className="mt-1 block w-full rounded-lg border border-slate-300 px-4 py-2 text-slate-900 focus:border-blue-500 focus:ring-blue-500 dark:border-slate-700 dark:bg-slate-900 dark:text-white"
              />
              <p className="mt-1 text-xs text-slate-500">Used for image recognition in the community app.</p>
            </div>
          </div>
        </div>

        {/* Database Settings */}
        <div className="rounded-xl border border-slate-200 bg-white p-6 dark:border-slate-800 dark:bg-slate-950">
          <div className="flex items-center gap-x-3 border-b border-slate-100 pb-4 dark:border-slate-900">
            <Database className="h-5 w-5 text-blue-600" />
            <h2 className="text-lg font-semibold text-slate-900 dark:text-white">Database Synchronization</h2>
          </div>
          <div className="mt-6 space-y-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-slate-900 dark:text-white">Auto-sync with Supabase</p>
                <p className="text-xs text-slate-500">Keep dashboard data updated in real-time.</p>
              </div>
              <button
                type="button"
                className="relative inline-flex h-6 w-11 shrink-0 cursor-pointer rounded-full border-2 border-transparent bg-slate-200 transition-colors duration-200 ease-in-out focus:outline-none focus:ring-2 focus:ring-blue-600 focus:ring-offset-2 dark:bg-slate-800"
              >
                <span className="translate-x-0 pointer-events-none inline-block h-5 w-5 transform rounded-full bg-white shadow ring-0 transition duration-200 ease-in-out"></span>
              </button>
            </div>
          </div>
        </div>

        {/* Security Settings */}
        <div className="rounded-xl border border-slate-200 bg-white p-6 dark:border-slate-800 dark:bg-slate-950">
          <div className="flex items-center gap-x-3 border-b border-slate-100 pb-4 dark:border-slate-900">
            <Shield className="h-5 w-5 text-blue-600" />
            <h2 className="text-lg font-semibold text-slate-900 dark:text-white">Security & Access</h2>
          </div>
          <div className="mt-6 space-y-4">
            <div>
              <label className="block text-sm font-medium text-slate-700 dark:text-slate-300">Admin Email</label>
              <input
                type="email"
                defaultValue="admin@nileuniversity.edu.ng"
                className="mt-1 block w-full rounded-lg border border-slate-300 px-4 py-2 text-slate-900 focus:border-blue-500 focus:ring-blue-500 dark:border-slate-700 dark:bg-slate-900 dark:text-white"
              />
            </div>
          </div>
        </div>

        <div className="flex justify-end">
          <button
            type="submit"
            disabled={loading}
            className="flex items-center gap-x-2 rounded-lg bg-blue-600 px-6 py-2.5 text-sm font-semibold text-white shadow-sm hover:bg-blue-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-blue-600 disabled:opacity-50"
          >
            <Save className="h-4 w-4" />
            {loading ? 'Saving...' : 'Save Settings'}
          </button>
        </div>
      </form>
    </div>
  )
}
