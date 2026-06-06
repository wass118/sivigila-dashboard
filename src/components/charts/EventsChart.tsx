import React from 'react'
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  BarElement,
  Title,
  Tooltip,
  Legend,
} from 'chart.js'
import { Bar } from 'react-chartjs-2'
import { useSivigilaStore } from '../../store/sivigilaStore'

ChartJS.register(
  CategoryScale,
  LinearScale,
  BarElement,
  Title,
  Tooltip,
  Legend
)

const EventsChart: React.FC = () => {
  const { getEventStats } = useSivigilaStore()
  const events = getEventStats()

  if (!events.length) {
    return (
      <div className="bg-white rounded-lg shadow-md p-6 text-center text-gray-500">
        No hay datos disponibles para el gráfico de eventos
      </div>
    )
  }

  // Sort events by number of cases and take top 10
  const topEvents = [...events].sort((a, b) => b.casos - a.casos).slice(0, 10)

  const data = {
    labels: topEvents.map((e) => e.evento),
    datasets: [
      {
        label: 'Número de Casos',
        data: topEvents.map((e) => e.casos),
        backgroundColor: [
          '#1a73e8',
          '#34a853',
          '#fbbc04',
          '#d33b27',
          '#4285f4',
          '#ea4335',
          '#7b68ee',
          '#20b2aa',
          '#ff6347',
          '#ffa500',
        ],
        borderRadius: 4,
      },
    ],
  }

  const options = {
    indexAxis: 'y' as const,
    responsive: true,
    maintainAspectRatio: true,
    plugins: {
      legend: {
        position: 'top' as const,
      },
      title: {
        display: true,
        text: 'Top 10 Eventos - Número de Casos',
        font: { size: 16, weight: 'bold' },
      },
    },
    scales: {
      x: {
        beginAtZero: true,
      },
    },
  }

  return (
    <div className="bg-white rounded-lg shadow-md p-6">
      <div className="h-96">
        <Bar data={data} options={options} />
      </div>
    </div>
  )
}

export default EventsChart
