export interface SivigilaEvent {
  id: string
  evento: string
  casos: number
  porcentaje: number
  tasaIncidencia: number
  tendencia: 'aumento' | 'disminucion' | 'estable'
  semana: number
  año: number
}

export interface CaseData {
  municipio: string
  latitude: number
  longitude: number
  evento: string
  casos: number
  fecha: string
  semana: number
  año: number
}

export interface ProcessedData {
  events: SivigilaEvent[]
  cases: CaseData[]
  totalCases: number
  weeklyData: WeeklyData[]
}

export interface WeeklyData {
  semana: number
  casos: number
  fechaInicio: string
  fechaFin: string
}

export interface MunicipalityStats {
  municipio: string
  latitude: number
  longitude: number
  casos: number
  eventos: string[]
}
