import { useEffect, useState } from 'react'
import './App.css'

function App() {
  const [msg, setMsg] = useState('Cargando...')

  useEffect(() => {
    fetch('http://localhost:8000/api/hello')
      .then(r => r.json())
      .then(data => setMsg(data.message))
      .catch(() => setMsg('No se pudo conectar a la API'))
  }, [])

  return (
    <div style={{ padding: 20 }}>
      <h1>Frontend React</h1>
      <p>{msg}</p>
    </div>
  )
}

export default App
