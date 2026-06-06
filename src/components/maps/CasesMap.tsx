import React, { useMemo } from 'react'
import { MapContainer, TileLayer, CircleMarker, Popup } from 'react-leaflet'
import L from 'leaflet'
import { useSivigilaStore } from '../../store/sivigilaStore'

const CasesMap: React.FC = () => {
  const { getMunicipalityStats } = useSivigilaStore()
  const municipalities = getMunicipalityStats()

  const maxCases = useMemo(() => {
    return Math.max(...municipalities.map((m) => m.casos), 1)
  }, [municipalities])

  const getRadius = (casos: number) => {
    return Math.sqrt(casos / maxCases) * 30 + 5
  }

  const getColor = (casos: number) => {
    const ratio = casos / maxCases
    if (ratio > 0.75) return '#d33b27' // Red
    if (ratio > 0.5) return '#fbbc04' // Yellow
    if (ratio > 0.25) return '#34a853' // Green
    return '#1a73e8' // Blue
  }

  if (!municipalities.length) {
    return (
      <div className="bg-white rounded-lg shadow-md p-6 text-center text-gray-500">
        No hay datos geográficos disponibles
      </div>
    )
  }

  // Calculate center of map based on available points
  const center: [number, number] = [
    municipalities.reduce((sum, m) => sum + m.latitude, 0) / municipalities.length,
    municipalities.reduce((sum, m) => sum + m.longitude, 0) / municipalities.length,
  ]

  return (
    <div className="bg-white rounded-lg shadow-md overflow-hidden">
      <MapContainer
        center={center}
        zoom={6}
        style={{ height: '500px', width: '100%' }}
      >
        <TileLayer
          attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
          url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
        />
        {municipalities.map((mun) => (
          <CircleMarker
            key={`${mun.latitude}-${mun.longitude}`}
            center={[mun.latitude, mun.longitude]}
            radius={getRadius(mun.casos)}
            fillColor={getColor(mun.casos)}
            color={getColor(mun.casos)}
            weight={2}
            opacity={0.8}
            fillOpacity={0.6}
          >
            <Popup>
              <div className="text-center">
                <h3 className="font-semibold text-gray-900">{mun.municipio}</h3>
                <p className="text-sm text-gray-600">Casos: {mun.casos}</p>
                <p className="text-xs text-gray-500">Eventos: {mun.eventos.join(', ')}</p>
              </div>
            </Popup>
          </CircleMarker>
        ))}
      </MapContainer>
      <div className="p-4 border-t border-gray-200 bg-gray-50">
        <p className="text-sm text-gray-600 font-medium mb-2">Leyenda</p>
        <div className="grid grid-cols-2 gap-2 text-xs">
          <div className="flex items-center gap-2">
            <div className="w-3 h-3 rounded-full" style={{ backgroundColor: '#d33b27' }}></div>
            <span>Casos altos (&gt; 75%)</span>
          </div>
          <div className="flex items-center gap-2">
            <div className="w-3 h-3 rounded-full" style={{ backgroundColor: '#fbbc04' }}></div>
            <span>Casos moderados (50-75%)</span>
          </div>
          <div className="flex items-center gap-2">
            <div className="w-3 h-3 rounded-full" style={{ backgroundColor: '#34a853' }}></div>
            <span>Casos bajos (25-50%)</span>
          </div>
          <div className="flex items-center gap-2">
            <div className="w-3 h-3 rounded-full" style={{ backgroundColor: '#1a73e8' }}></div>
            <span>Casos muy bajos (&lt; 25%)</span>
          </div>
        </div>
      </div>
    </div>
  )
}

export default CasesMap
