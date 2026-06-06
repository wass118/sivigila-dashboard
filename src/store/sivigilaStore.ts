import { create } from 'zustand'
import { ProcessedData, SivigilaEvent, CaseData } from '../types'

interface SivigilaState {
  data: ProcessedData | null
  loading: boolean
  error: string | null
  setData: (data: ProcessedData) => void
  setLoading: (loading: boolean) => void
  setError: (error: string | null) => void
  clearData: () => void
  getEventStats: () => SivigilaEvent[]
  getTotalCases: () => number
  getWeeklyData: () => any[]
  getMunicipalityStats: () => any[]
}

export const useSivigilaStore = create<SivigilaState>((set, get) => ({
  data: null,
  loading: false,
  error: null,
  
  setData: (data) => set({ data, error: null }),
  setLoading: (loading) => set({ loading }),
  setError: (error) => set({ error }),
  clearData: () => set({ data: null, error: null }),
  
  getEventStats: () => {
    const { data } = get()
    return data?.events || []
  },
  
  getTotalCases: () => {
    const { data } = get()
    return data?.totalCases || 0
  },
  
  getWeeklyData: () => {
    const { data } = get()
    return data?.weeklyData || []
  },
  
  getMunicipalityStats: () => {
    const { data } = get()
    if (!data?.cases) return []
    
    const stats = new Map<string, any>()
    data.cases.forEach((caseItem) => {
      if (!stats.has(caseItem.municipio)) {
        stats.set(caseItem.municipio, {
          municipio: caseItem.municipio,
          latitude: caseItem.latitude,
          longitude: caseItem.longitude,
          casos: 0,
          eventos: new Set<string>(),
        })
      }
      const mun = stats.get(caseItem.municipio)!
      mun.casos += caseItem.casos
      mun.eventos.add(caseItem.evento)
    })
    
    return Array.from(stats.values()).map((m) => ({
      ...m,
      eventos: Array.from(m.eventos),
    }))
  },
}))
