import React from 'react'
import FileUpload from '../components/FileUpload'
import StatsCards from '../components/StatsCards'
import EventsTable from '../components/EventsTable'
import EpidemicCurve from '../components/charts/EpidemicCurve'
import EventsChart from '../components/charts/EventsChart'
import EventsDistributionPie from '../components/charts/EventsDistributionPie'
import CasesMap from '../components/maps/CasesMap'

const Dashboard: React.FC = () => {
  return (
    <div className="space-y-6">
      {/* File Upload */}
      <FileUpload />

      {/* Stats Cards */}
      <StatsCards />

      {/* Charts Row 1 */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <EpidemicCurve />
        <EventsDistributionPie />
      </div>

      {/* Charts Row 2 */}
      <div className="grid grid-cols-1 gap-6">
        <EventsChart />
      </div>

      {/* Map */}
      <div className="grid grid-cols-1 gap-6">
        <CasesMap />
      </div>

      {/* Events Table */}
      <div className="grid grid-cols-1 gap-6">
        <div>
          <h2 className="text-xl font-semibold text-gray-900 mb-4">Tablero de Eventos</h2>
          <EventsTable />
        </div>
      </div>
    </div>
  )
}

export default Dashboard
