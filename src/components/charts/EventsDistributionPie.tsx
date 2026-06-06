import React from 'react'
import { Chart as ChartJS, ArcElement, Tooltip, Legend, Title } from 'chart.js'
import { Pie } from 'react-chartjs-2'
import { useSivigilaStore } from '../../store/sivigilaStore'

ChartJS.register(ArcElement, Tooltip, Legend, Title)

const EventsDistributionPie: React.FC = () => {
  const { getEventStats } = useSivigilaStore()
  const events = getEventStats()

  if (!events.length) {
    return (
      <div className="bg-white rounded-lg shadow-md p-6 text-center text-gray-500">
        No hay datos disponibles para el gráfico de distribución
      </div>
    )
  }

  // Take top 8 events, rest as "Otros"
  const sortedEvents = [...events].sort((a, b) => b.casos - a.casos)
  const topEvents = sortedEvents.slice(0, 8)
  const otherCases = sortedEvents.slice(8).reduce((sum, e) => sum + e.casos, 0)

  const labels = topEvents.map((e) => e.evento)
  const values = topEvents.map((e) => e.casos)

  if (otherCases > 0) {
    labels.push('Otros')
    values.push(otherCases)
  }

  const colors = [
    '#1a73e8',
    '#34a853',
    '#fbbc04',
    '#d33b27',
    '#4285f4',
    '#ea4335',
    '#7b68ee',
    '#20b2aa',
    '#ff6347',
  ]

  const data = {
    labels,
    datasets: [
      {
        data: values,
        backgroundColor: colors.slice(0, labels.length),
        borderColor: '#fff',
        borderWidth: 2,
      },
    ],
  }

  const options = {
    responsive: true,
    maintainAspectRatio: true,
    plugins: {
      legend: {
        position: 'bottom' as const,
        labels: {
          padding: 15,
          font: { size: 12 },
        },
      },
      title: {
        display: true,
        text: 'Distribución de Eventos',
        font: { size: 16, weight: 'bold' },
      },
    },
  }

  return (
    <div className="bg-white rounded-lg shadow-md p-6">
      <div className="h-96">
        <Pie data={data} options={options} />
      </div>
    </div>
  )
}

export default EventsDistributionPie
