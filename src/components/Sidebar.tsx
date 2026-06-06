import React from 'react'
import { BarChart3, Map, Activity, FileText } from 'lucide-react'

interface SidebarProps {
  open: boolean
}

const Sidebar: React.FC<SidebarProps> = ({ open }) => {
  const menuItems = [
    { icon: Activity, label: 'Dashboard', href: '#' },
    { icon: BarChart3, label: 'Gráficas', href: '#' },
    { icon: Map, label: 'Mapa', href: '#' },
    { icon: FileText, label: 'Reportes', href: '#' },
  ]

  return (
    <aside
      className={`${
        open ? 'w-64' : 'w-20'
      } bg-gradient-to-b from-blue-600 to-blue-800 text-white transition-all duration-300 hidden md:block`}
    >
      <div className="p-4 border-b border-blue-500">
        <div className={`text-lg font-bold ${open ? '' : 'text-center'}`}>
          {open ? 'SIVIGILA' : 'S'}
        </div>
      </div>
      <nav className="mt-6">
        {menuItems.map((item) => (
          <a
            key={item.label}
            href={item.href}
            className="flex items-center gap-3 px-4 py-3 hover:bg-blue-700 transition text-sm"
          >
            <item.icon size={20} />
            {open && <span>{item.label}</span>}
          </a>
        ))}
      </nav>
    </aside>
  )
}

export default Sidebar
