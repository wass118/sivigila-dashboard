import React, { useRef } from 'react'
import { Upload, AlertCircle, CheckCircle } from 'lucide-react'
import { parseExcelFile } from '../utils/excelParser'
import { useSivigilaStore } from '../store/sivigilaStore'

const FileUpload: React.FC = () => {
  const fileInputRef = useRef<HTMLInputElement>(null)
  const { setData, setLoading, setError, loading, error } = useSivigilaStore()
  const [success, setSuccess] = React.useState(false)

  const handleFileSelect = async (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0]
    if (!file) return

    // Validate file type
    const validTypes = ['application/vnd.ms-excel', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet']
    if (!validTypes.includes(file.type)) {
      setError('Por favor, carga un archivo Excel válido')
      return
    }

    setLoading(true)
    setError(null)
    setSuccess(false)

    try {
      const processedData = await parseExcelFile(file)
      setData(processedData)
      setSuccess(true)
      setTimeout(() => setSuccess(false), 3000)
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Error al procesar el archivo'
      setError(errorMessage)
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="bg-white rounded-lg shadow-md p-6">
      <div className="flex items-center gap-2 mb-4">
        <Upload size={20} className="text-blue-600" />
        <h2 className="text-xl font-semibold text-gray-900">Importar Datos SIVIGILA</h2>
      </div>

      <div
        onClick={() => fileInputRef.current?.click()}
        className="border-2 border-dashed border-gray-300 rounded-lg p-8 text-center cursor-pointer hover:border-blue-500 hover:bg-blue-50 transition"
      >
        <input
          ref={fileInputRef}
          type="file"
          accept=".xlsx,.xls"
          onChange={handleFileSelect}
          disabled={loading}
          className="hidden"
        />
        <Upload size={32} className="mx-auto text-gray-400 mb-2" />
        <p className="text-gray-700 font-medium">Arrastra tu archivo Excel aquí</p>
        <p className="text-gray-500 text-sm">o haz clic para seleccionar</p>
        {loading && <p className="text-blue-600 text-sm mt-2">Procesando...</p>}
      </div>

      {error && (
        <div className="mt-4 p-4 bg-red-50 border border-red-200 rounded-lg flex items-start gap-3">
          <AlertCircle size={20} className="text-red-600 mt-0.5 flex-shrink-0" />
          <p className="text-red-700">{error}</p>
        </div>
      )}

      {success && (
        <div className="mt-4 p-4 bg-green-50 border border-green-200 rounded-lg flex items-start gap-3">
          <CheckCircle size={20} className="text-green-600 mt-0.5 flex-shrink-0" />
          <p className="text-green-700">¡Datos importados exitosamente!</p>
        </div>
      )}
    </div>
  )
}

export default FileUpload
