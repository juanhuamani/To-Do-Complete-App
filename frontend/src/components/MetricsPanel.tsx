import { useState, useEffect } from 'react'
import { Server, Activity, Clock, Globe, Database, Zap } from 'lucide-react'
import { apiService } from '../services/api'

interface MetricsData {
  environment: string
  apiHealth: 'healthy' | 'degraded' | 'down'
  responseTime: number
  timestamp: string
  region?: string
  cluster?: string
}

export default function MetricsPanel() {
  const [metrics, setMetrics] = useState<MetricsData>({
    environment: import.meta.env.VITE_APP_ENV || 'development',
    apiHealth: 'healthy',
    responseTime: 0,
    timestamp: new Date().toISOString(),
    region: import.meta.env.VITE_AWS_REGION || 'us-east-1',
    cluster: import.meta.env.VITE_CLUSTER_NAME || 'todo-cluster',
  })
  const [isExpanded, setIsExpanded] = useState(false)
  const [isLoading, setIsLoading] = useState(false)

  // Obtener métricas de salud de la API
  const checkApiHealth = async () => {
    setIsLoading(true)
    const startTime = performance.now()
    
    try {
      // Intentar hacer una petición simple para medir el tiempo de respuesta
      await apiService.getTasks()
      const responseTime = Math.round(performance.now() - startTime)
      
      setMetrics(prev => ({
        ...prev,
        apiHealth: responseTime < 500 ? 'healthy' : responseTime < 2000 ? 'degraded' : 'down',
        responseTime,
        timestamp: new Date().toISOString(),
      }))
    } catch (error) {
      setMetrics(prev => ({
        ...prev,
        apiHealth: 'down',
        responseTime: 0,
        timestamp: new Date().toISOString(),
      }))
    } finally {
      setIsLoading(false)
    }
  }

  // Verificar salud de la API cada 30 segundos
  useEffect(() => {
    checkApiHealth()
    const interval = setInterval(checkApiHealth, 30000)
    return () => clearInterval(interval)
  }, [])

  const getHealthColor = () => {
    switch (metrics.apiHealth) {
      case 'healthy':
        return 'text-green-400'
      case 'degraded':
        return 'text-yellow-400'
      case 'down':
        return 'text-red-400'
      default:
        return 'text-gray-400'
    }
  }

  const getHealthBg = () => {
    switch (metrics.apiHealth) {
      case 'healthy':
        return 'bg-green-500/10 border-green-400/30'
      case 'degraded':
        return 'bg-yellow-500/10 border-yellow-400/30'
      case 'down':
        return 'bg-red-500/10 border-red-400/30'
      default:
        return 'bg-gray-500/10 border-gray-400/30'
    }
  }

  const formatTime = (ms: number) => {
    if (ms === 0) return 'N/A'
    if (ms < 1000) return `${ms}ms`
    return `${(ms / 1000).toFixed(2)}s`
  }

  return (
    <div className="fixed bottom-4 right-4 z-50">
      {/* Botón para expandir/colapsar */}
      <button
        onClick={() => setIsExpanded(!isExpanded)}
        className={`mb-2 px-3 py-2 rounded-lg backdrop-blur-sm border transition-all duration-300 ${getHealthBg()} border-slate-600/50 text-white hover:scale-105`}
        title="Ver métricas del sistema"
      >
        <div className="flex items-center gap-2">
          <Activity className={`w-4 h-4 ${getHealthColor()}`} />
          <span className="text-sm font-medium">Métricas</span>
          {isLoading && (
            <div className="w-2 h-2 bg-cyan-400 rounded-full animate-pulse"></div>
          )}
        </div>
      </button>

      {/* Panel expandido */}
      {isExpanded && (
        <div className="bg-slate-900/95 backdrop-blur-md border border-slate-700/50 rounded-lg p-4 shadow-2xl min-w-[280px] space-y-3">
          <div className="flex items-center justify-between mb-3">
            <h3 className="text-sm font-semibold text-white flex items-center gap-2">
              <Zap className="w-4 h-4 text-cyan-400" />
              Información del Sistema
            </h3>
            <button
              onClick={() => setIsExpanded(false)}
              className="text-gray-400 hover:text-white transition-colors"
            >
              ✕
            </button>
          </div>

          {/* Estado de la API */}
          <div className={`p-3 rounded-lg border ${getHealthBg()}`}>
            <div className="flex items-center justify-between mb-2">
              <div className="flex items-center gap-2">
                <Server className={`w-4 h-4 ${getHealthColor()}`} />
                <span className="text-sm text-gray-300">API Status</span>
              </div>
              <span className={`text-xs font-medium capitalize ${getHealthColor()}`}>
                {metrics.apiHealth === 'healthy' ? 'Saludable' : 
                 metrics.apiHealth === 'degraded' ? 'Degradado' : 'Inactivo'}
              </span>
            </div>
            <div className="flex items-center gap-2 text-xs text-gray-400">
              <Clock className="w-3 h-3" />
              <span>Tiempo de respuesta: {formatTime(metrics.responseTime)}</span>
            </div>
          </div>

          {/* Información del entorno */}
          <div className="space-y-2">
            <div className="flex items-center justify-between text-sm">
              <div className="flex items-center gap-2 text-gray-400">
                <Globe className="w-4 h-4" />
                <span>Entorno</span>
              </div>
              <span className="text-white font-medium capitalize">
                {metrics.environment}
              </span>
            </div>

            {metrics.region && (
              <div className="flex items-center justify-between text-sm">
                <div className="flex items-center gap-2 text-gray-400">
                  <Globe className="w-4 h-4" />
                  <span>Región</span>
                </div>
                <span className="text-white font-medium">
                  {metrics.region}
                </span>
              </div>
            )}

            {metrics.cluster && (
              <div className="flex items-center justify-between text-sm">
                <div className="flex items-center gap-2 text-gray-400">
                  <Database className="w-4 h-4" />
                  <span>Cluster</span>
                </div>
                <span className="text-white font-medium truncate max-w-[150px]">
                  {metrics.cluster}
                </span>
              </div>
            )}
          </div>

          {/* Timestamp */}
          <div className="pt-2 border-t border-slate-700/50">
            <div className="text-xs text-gray-500 text-center">
              Última actualización: {new Date(metrics.timestamp).toLocaleTimeString()}
            </div>
          </div>

          {/* Botón para refrescar manualmente */}
          <button
            onClick={checkApiHealth}
            disabled={isLoading}
            className="w-full mt-2 px-3 py-2 bg-cyan-500/20 hover:bg-cyan-500/30 border border-cyan-400/30 rounded-lg text-cyan-400 text-sm font-medium transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
          >
            {isLoading ? 'Verificando...' : 'Refrescar'}
          </button>
        </div>
      )}
    </div>
  )
}

