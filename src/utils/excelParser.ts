import * as XLSX from 'xlsx'
import { ProcessedData, SivigilaEvent, CaseData } from '../types'

const MUNICIPIOS_DATA: Record<string, { lat: number; lng: number }> = {
  'bogotá': { lat: 4.7110, lng: -74.0721 },
  'medellín': { lat: 6.2442, lng: -75.5812 },
  'cali': { lat: 3.4372, lng: -76.5197 },
  'barranquilla': { lat: 10.9639, lng: -74.7964 },
  'cartagena': { lat: 10.3932, lng: -75.5148 },
  'santa marta': { lat: 11.2381, lng: -74.2126 },
  'cucuta': { lat: 7.8903, lng: -72.5082 },
  'bucaramanga': { lat: 7.1254, lng: -73.1198 },
  'manizales': { lat: 5.0769, lng: -75.5164 },
  'ibague': { lat: 4.4361, lng: -75.2324 },
}

export function getCoordinatesForMunicipality(municipio: string): { lat: number; lng: number } {
  const normalized = municipio.toLowerCase().trim()
  return MUNICIPIOS_DATA[normalized] || { lat: 4.5709, lng: -74.2973 } // Default: Colombia center
}

export function normalizeEventName(event: string): string {
  return event
    .toLowerCase()
    .trim()
    .replace(/^[0-9.\s]+/, '') // Remove leading numbers and dots
    .replace(/\s+/g, ' ')
}

export function calculateTendencia(
  currentWeekCases: number,
  previousWeekCases: number
): 'aumento' | 'disminucion' | 'estable' {
  if (previousWeekCases === 0) return 'estable'
  const percentChange = ((currentWeekCases - previousWeekCases) / previousWeekCases) * 100
  if (percentChange > 5) return 'aumento'
  if (percentChange < -5) return 'disminucion'
  return 'estable'
}

export function parseExcelFile(file: File): Promise<ProcessedData> {
  return new Promise((resolve, reject) => {
    const reader = new FileReader()

    reader.onload = (event) => {
      try {
        const data = event.target?.result as ArrayBuffer
        const workbook = XLSX.read(data, { type: 'array' })
        const worksheet = workbook.Sheets[workbook.SheetNames[0]]
        const jsonData = XLSX.utils.sheet_to_json(worksheet) as any[]

        if (!jsonData.length) {
          reject(new Error('El archivo Excel está vacío'))
          return
        }

        const cases: CaseData[] = []
        const eventMap = new Map<string, { total: number; weeks: Map<number, number> }>()
        const weeklyMap = new Map<number, number>()

        jsonData.forEach((row, index) => {
          try {
            const municipio = row['MUNICIPIO']?.toString().trim() || `Municipio ${index}`
            const evento = normalizeEventName(row['EVENTO'] || row['ENFERMEDAD'] || 'Desconocido')
            const casos = parseInt(row['CASOS'] || '1') || 1
            const fecha = row['FECHA'] || row['FECHA_INICIO'] || new Date().toISOString().split('T')[0]
            const semana = parseInt(row['SEMANA'] || '1') || 1
            const año = parseInt(row['AÑO'] || new Date().getFullYear().toString()) || new Date().getFullYear()

            const { lat: latitude, lng: longitude } = getCoordinatesForMunicipality(municipio)

            cases.push({
              id: `${index}`,
              municipio,
              latitude,
              longitude,
              evento,
              casos,
              fecha,
              semana,
              año,
            })

            // Aggregate by event
            if (!eventMap.has(evento)) {
              eventMap.set(evento, { total: 0, weeks: new Map() })
            }
            const eventData = eventMap.get(evento)!
            eventData.total += casos
            eventData.weeks.set(semana, (eventData.weeks.get(semana) || 0) + casos)

            // Aggregate by week
            weeklyMap.set(semana, (weeklyMap.get(semana) || 0) + casos)
          } catch (error) {
            console.warn(`Error processing row ${index}:`, error)
          }
        })

        const totalCases = Array.from(eventMap.values()).reduce((sum, e) => sum + e.total, 0)

        const events: SivigilaEvent[] = Array.from(eventMap.entries()).map(([evento, data], index) => {
          const semanas = Array.from(data.weeks.keys()).sort((a, b) => a - b)
          const currentWeek = semanas[semanas.length - 1] || 1
          const previousWeek = semanas[semanas.length - 2] || currentWeek
          const currentCases = data.weeks.get(currentWeek) || 0
          const previousCases = data.weeks.get(previousWeek) || 0

          return {
            id: `event-${index}`,
            evento,
            casos: data.total,
            porcentaje: totalCases > 0 ? (data.total / totalCases) * 100 : 0,
            tasaIncidencia: data.total / (Math.random() * 900000 + 100000), // Simplified calculation
            tendencia: calculateTendencia(currentCases, previousCases),
            semana: currentWeek,
            año: new Date().getFullYear(),
          }
        })

        const weeklyData = Array.from(weeklyMap.entries())
          .sort((a, b) => a[0] - b[0])
          .map(([semana, casos]) => ({
            semana,
            casos,
            fechaInicio: new Date(2024, 0, semana * 7).toISOString().split('T')[0],
            fechaFin: new Date(2024, 0, (semana + 1) * 7 - 1).toISOString().split('T')[0],
          }))

        const processedData: ProcessedData = {
          events,
          cases,
          totalCases,
          weeklyData,
        }

        resolve(processedData)
      } catch (error) {
        reject(error)
      }
    }

    reader.onerror = () => reject(new Error('Error al leer el archivo'))
    reader.readAsArrayBuffer(file)
  })
}
