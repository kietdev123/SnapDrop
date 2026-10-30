import react from '@vitejs/plugin-react'
import { defineConfig } from 'vite'

// https://vite.dev/config/
export default defineConfig({
  plugins: [react()],
  // Cho phép mở dev server / preview qua ngrok (URL đổi mỗi lần chạy).
  server: { allowedHosts: ['.ngrok-free.app', '.ngrok.app', '.ngrok.io'] },
  preview: { allowedHosts: ['.ngrok-free.app', '.ngrok.app', '.ngrok.io'] },
})
