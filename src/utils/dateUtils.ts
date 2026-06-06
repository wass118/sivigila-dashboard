export function getWeekRange(week: number, year: number): { start: Date; end: Date } {
  const jan1 = new Date(year, 0, 1)
  const dayOfWeek = jan1.getDay()
  const startDate = new Date(jan1)
  startDate.setDate(jan1.getDate() - dayOfWeek + (week - 1) * 7)
  
  const endDate = new Date(startDate)
  endDate.setDate(startDate.getDate() + 6)
  
  return { start: startDate, end: endDate }
}

export function formatDate(date: Date): string {
  return date.toLocaleDateString('es-CO', {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  })
}

export function getCurrentWeek(): number {
  const now = new Date()
  const start = new Date(now.getFullYear(), 0, 0)
  const diff = now.getTime() - start.getTime()
  const oneDay = 1000 * 60 * 60 * 24
  return Math.floor(diff / oneDay / 7) + 1
}
