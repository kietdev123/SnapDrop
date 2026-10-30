import { useCallback, useEffect, useRef, useState } from 'react'

// Tự phát hiện ảnh trong clipboard (giống Bước 1 trên mobile).
//
// Chỉ làm được trên Chrome / Edge: sau khi người dùng cho phép quyền "clipboard-read"
// MỘT lần, trang được đọc clipboard khi tab đang focus mà không cần thao tác.
// Firefox / Safari bắt buộc mỗi lần đọc phải có thao tác người dùng → 'unsupported',
// vẫn dùng nút "Dán ảnh" + Ctrl/⌘ + V như cũ.

export type ClipStatus = 'checking' | 'unsupported' | 'prompt' | 'granted' | 'denied'
export type ClipSuggestion = { id: string; file: File; url: string }

const FRESH_MS = 5 * 60_000 // chỉ gợi ý ảnh copy trong 5 phút gần đây
const POLL_MS = 2_000 // copy ngay trong trang (chuột phải → Sao chép ảnh) cũng bắt được
const LS_HANDLED = 'snapdrop.clip.handled'
const LS_SEEN = 'snapdrop.clip.firstSeen'

function load<T>(key: string, fallback: T): T {
  try {
    const raw = localStorage.getItem(key)
    return raw ? (JSON.parse(raw) as T) : fallback
  } catch {
    return fallback
  }
}

function save(key: string, value: unknown) {
  try {
    localStorage.setItem(key, JSON.stringify(value))
  } catch {
    // private mode / bị chặn storage: chỉ mất phần ghi nhớ, gợi ý vẫn chạy
  }
}

export async function imageId(blob: Blob): Promise<string> {
  const hash = await crypto.subtle.digest('SHA-256', await blob.arrayBuffer())
  return Array.from(new Uint8Array(hash).slice(0, 12), (b) => b.toString(16).padStart(2, '0')).join('')
}

async function readClipboardImage(): Promise<Blob | null> {
  const items = await navigator.clipboard.read()
  for (const item of items) {
    const type = item.types.find((t) => t.startsWith('image/'))
    if (type) return item.getType(type)
  }
  return null
}

export function useClipboardWatcher() {
  const [status, setStatus] = useState<ClipStatus>('checking')
  const [suggestion, setSuggestion] = useState<ClipSuggestion | null>(null)
  const handled = useRef<string[]>(load(LS_HANDLED, []))
  const firstSeen = useRef<Record<string, number>>(load(LS_SEEN, {}))
  const busy = useRef(false)

  const show = useCallback((next: ClipSuggestion | null) => {
    setSuggestion((prev) => {
      if (prev?.id === next?.id) return prev
      if (prev) URL.revokeObjectURL(prev.url)
      return next
    })
  }, [])

  const check = useCallback(async () => {
    if (busy.current || document.visibilityState !== 'visible' || !document.hasFocus()) return
    busy.current = true
    try {
      const blob = await readClipboardImage()
      // Clipboard đổi sang thứ khác (chữ, rỗng) → gợi ý cũ biến mất.
      if (!blob) return show(null)
      const id = await imageId(blob)
      if (handled.current.includes(id)) return show(null)

      const now = Date.now()
      const seen = (firstSeen.current[id] ??= now)
      const ids = Object.keys(firstSeen.current)
      if (ids.length > 50) ids.slice(0, ids.length - 50).forEach((k) => delete firstSeen.current[k])
      save(LS_SEEN, firstSeen.current)
      if (now - seen > FRESH_MS) return show(null)

      const ext = blob.type.split('/')[1] ?? 'png'
      const file = new File([blob], `clipboard-${id.slice(0, 6)}.${ext}`, { type: blob.type })
      show({ id, file, url: URL.createObjectURL(file) })
    } catch {
      // Mất focus giữa chừng / quyền bị thu hồi: bỏ qua lần này.
    } finally {
      busy.current = false
    }
  }, [show])

  // Theo dõi trạng thái quyền.
  useEffect(() => {
    if (!navigator.clipboard?.read || !navigator.permissions?.query) {
      setStatus('unsupported')
      return
    }
    let perm: PermissionStatus | undefined
    const sync = () => perm && setStatus(perm.state)
    navigator.permissions
      .query({ name: 'clipboard-read' as PermissionName })
      .then((p) => {
        perm = p
        sync()
        p.addEventListener('change', sync)
      })
      .catch(() => setStatus('unsupported'))
    return () => perm?.removeEventListener('change', sync)
  }, [])

  // Kiểm tra mỗi khi quay lại tab + định kỳ khi tab đang focus.
  useEffect(() => {
    if (status !== 'granted') return
    const onVisible = () => document.visibilityState === 'visible' && check()
    window.addEventListener('focus', check)
    document.addEventListener('visibilitychange', onVisible)
    const timer = setInterval(check, POLL_MS)
    check()
    return () => {
      window.removeEventListener('focus', check)
      document.removeEventListener('visibilitychange', onVisible)
      clearInterval(timer)
    }
  }, [status, check])

  // Bấm nút "Bật gợi ý": lần đọc đầu tiên có thao tác người dùng → trình duyệt hỏi quyền.
  const enable = useCallback(async () => {
    try {
      await navigator.clipboard.read()
      setStatus('granted')
    } catch {
      const p = await navigator.permissions.query({ name: 'clipboard-read' as PermissionName }).catch(() => null)
      setStatus(p?.state ?? 'denied')
    }
  }, [])

  // Trình duyệt chỉ hỏi quyền khi có thao tác người dùng → tự xin ở lần bấm / gõ phím
  // đầu tiên bất kỳ đâu trên trang, không cần nút riêng.
  useEffect(() => {
    if (status !== 'prompt') return
    let asked = false
    const ask = () => {
      if (asked) return
      asked = true
      void enable()
    }
    const events = ['pointerdown', 'pointerup', 'keydown'] as const
    events.forEach((e) => window.addEventListener(e, ask, true))
    return () => events.forEach((e) => window.removeEventListener(e, ask, true))
  }, [status, enable])

  // Đã dùng / đã tắt gợi ý / người dùng tự dán → không gợi ý lại ảnh này.
  const markHandled = useCallback(
    (id: string) => {
      handled.current = [...handled.current.filter((x) => x !== id), id].slice(-50)
      save(LS_HANDLED, handled.current)
      setSuggestion((prev) => {
        if (prev?.id !== id) return prev
        URL.revokeObjectURL(prev.url)
        return null
      })
    },
    [],
  )

  const markFilesHandled = useCallback(
    async (files: File[]) => {
      for (const f of files) markHandled(await imageId(f))
    },
    [markHandled],
  )

  return { status, suggestion, enable, markHandled, markFilesHandled }
}
