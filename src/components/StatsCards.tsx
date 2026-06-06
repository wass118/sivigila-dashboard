import React from 'react'
import { BarChart3, Activity, AlertTriangle, TrendingUp } from 'lucide-react'
import { useSivigilaStore } from '../store/sivigilaStore'

const StatsCards: React.FC = () => {
  const { getTotalCases, getEventStats, getWeeklyData, getMunicipalityStats } = useSivigilaStore()
  const totalCases = getTotalCases()
  const events = getEventStats()
  const weeklyData = getWeeklyData()
  const municipalities = getMunicipalityStats()

  const stats = [
    {
      label: 'Casos Totales',
      value: totalCases.toLocaleString('es-CO'),
      icon: Activity,
      color: 'blue',
      bgColor: 'bg-blue-50',
    },
    {
      label: 'Eventos Reportados',
      value: events.length,
      icon: AlertTriangle,
      color: 'red',
      bgColor: 'bg-red-50',
    },
    {
      label: 'Municipios Afectados',
      value: municipalities.length,
      icon: BarChart3,
      color: 'green',
      bgColor: 'bg-green-50',
    },
    {
      label: 'Semanas Registradas',
      value: weeklyData.length,
      icon: TrendingUp,
      color: 'purple',
      bgColor: 'bg-purple-50',
    },
  ]

  const colorMap = {
    blue: 'text-blue-600',
    red: 'text-red-600',
    green: 'text-green-600',
    purple: 'text-purple-600',
  }

  return (
    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-6">
      {stats.map((stat, index) => (
        <div
          key={index}
          className="bg-white rounded-lg shadow-md p-6 hover:shadow-lg transition"
        >
          <div className={`${stat.bgColor} rounded-lg p-3 mb-4 w-fit`}>
            <stat.icon size={24} className={colorMap[stat.color as keyof typeof colorMap]} />
          </div>
          <h3 className="text-gray-600 text-sm font-medium mb-1">{stat.label}</h3>
          <p className="text-2xl font-bold text-gray-900">{stat.value}</p>
        </div>
      ))}
    </div>
  )
}

export default StatsCards
