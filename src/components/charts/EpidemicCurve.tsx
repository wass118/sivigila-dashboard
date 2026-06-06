import React from 'react'
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  Title,
  Tooltip,
  Legend,
  Filler,
} from 'chart.js'
import { Line } from 'react-chartjs-2'
import { useSivigilaStore } from '../../store/sivigilaStore'

ChartJS.register(
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  Title,
  Tooltip,
  Legend,
  Filler
)

const EpidemicCurve: React.FC = () => {
  const { getWeeklyData } = useSivigilaStore()
  const weeklyData = getWeeklyData()

  if (!weeklyData.length) {
    return (
      <div className="bg-white rounded-lg shadow-md p-6 text-center text-gray-500">
        No hay datos disponibles para la curva epidémica
      </div>
    )
  }

  const data = {
    labels: weeklyData.map((w) => `Semana ${w.semana}`),
    datasets: [
      {
        label: 'Casos por Semana',
        data: weeklyData.map((w) => w.casos),
        borderColor: '#d33b27',
        backgroundColor: 'rgba(211, 59, 39, 0.1)',
        borderWidth: 2,
        fill: true,
        tension: 0.4,
        pointRadius: 5,
        pointHoverRadius: 7,
        pointBackgroundColor: '#d33b27',
        pointBorderColor: '#fff',
        pointBorderWidth: 2,
      },
    ],
  }

  const options = {
    responsive: true,
    maintainAspectRatio: true,
    plugins: {
      legend: {
        position: 'top' as const,
      },
      title: {
        display: true,
        text: 'Curva Epidémica - Casos por Semana',
        font: { size: 16, weight: 'bold' },
      },
    },
    scales: {
      y: {
        beginAtZero: true,
        ticks: {
          stepSize: 1,
        },
      },
    },
  }

  return (
    <div className="bg-white rounded-lg shadow-md p-6">
      <div className="h-96">
        <Line data={data} options={options} />
      </div>
    </div>
  )
}

export default EpidemicCurve
