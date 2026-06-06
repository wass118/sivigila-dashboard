import React from 'react'
import { TrendingUp, TrendingDown, Minus } from 'lucide-react'
import { useSivigilaStore } from '../store/sivigilaStore'
import { SivigilaEvent } from '../types'

const EventsTable: React.FC = () => {
  const { getEventStats, getTotalCases } = useSivigilaStore()
  const events = getEventStats()
  const totalCases = getTotalCases()

  const getTrendIcon = (tendencia: string) => {
    switch (tendencia) {
      case 'aumento':
        return <TrendingUp size={18} className="text-red-600" />
      case 'disminucion':
        return <TrendingDown size={18} className="text-green-600" />
      default:
        return <Minus size={18} className="text-yellow-600" />
    }
  }

  const getTrendLabel = (tendencia: string) => {
    switch (tendencia) {
      case 'aumento':
        return 'Aumento'
      case 'disminucion':
        return 'Disminución'
      default:
        return 'Estable'
    }
  }

  if (!events.length) {
    return (
      <div className="bg-white rounded-lg shadow-md p-6 text-center text-gray-500">
        No hay datos disponibles. Importa un archivo Excel para comenzar.
      </div>
    )
  }

  return (
    <div className="bg-white rounded-lg shadow-md overflow-hidden">
      <div className="overflow-x-auto">
        <table className="w-full">
          <thead className="bg-gray-50 border-b border-gray-200">
            <tr>
              <th className="px-6 py-3 text-left text-sm font-semibold text-gray-900">Evento</th>
              <th className="px-6 py-3 text-right text-sm font-semibold text-gray-900">Casos</th>
              <th className="px-6 py-3 text-right text-sm font-semibold text-gray-900">% del Total</th>
              <th className="px-6 py-3 text-right text-sm font-semibold text-gray-900">Tasa Incidencia</th>
              <th className="px-6 py-3 text-center text-sm font-semibold text-gray-900">Tendencia</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-200">
            {events.map((event: SivigilaEvent) => (
              <tr key={event.id} className="hover:bg-gray-50 transition">
                <td className="px-6 py-4 text-sm font-medium text-gray-900">{event.evento}</td>
                <td className="px-6 py-4 text-sm text-right text-gray-700 font-semibold">{event.casos}</td>
                <td className="px-6 py-4 text-sm text-right text-gray-700">
                  {event.porcentaje.toFixed(2)}%
                </td>
                <td className="px-6 py-4 text-sm text-right text-gray-700">
                  {event.tasaIncidencia.toFixed(4)}
                </td>
                <td className="px-6 py-4 text-center">
                  <div className="flex items-center justify-center gap-2">
                    {getTrendIcon(event.tendencia)}
                    <span className="text-xs font-medium text-gray-600">
                      {getTrendLabel(event.tendencia)}
                    </span>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  )
}

export default EventsTable
