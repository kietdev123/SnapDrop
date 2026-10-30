import { createContext, useCallback, useContext, useEffect, useRef, useState, type ReactNode } from 'react'
import { imagesFromPaste } from './clipboard'

// Mỗi ô đính kèm tự đăng ký với hub. Hub quyết định ảnh dán vào ô nào theo thứ tự:
//   1. Ô đang focus
//   2. Ô nằm trong form / modal / bottom sheet đang mở (layer cao nhất)
//   3. Ô chính của trang (primary)
export type BoxRegistration = {
  id: string
  label: string
  primary?: boolean
  layer: number
  element: () => HTMLElement | null
  add: (files: File[]) => void
}

type Hub = {
  register: (box: BoxRegistration) => () => void
  pickTarget: () => BoxRegistration | undefined
  focusedId: string | null
  boxCount: number
}

const HubContext = createContext<Hub | null>(null)

export function useAttachHub() {
  const hub = useContext(HubContext)
  if (!hub) throw new Error('useAttachHub phải nằm trong <AttachHubProvider>')
  return hub
}

type Props = {
  children: ReactNode
  // Nhánh 2b: trang không có ô đính kèm nào nhận ảnh.
  onOrphanImages: (files: File[]) => void
}

export function AttachHubProvider({ children, onOrphanImages }: Props) {
  const boxes = useRef(new Map<string, BoxRegistration>())
  const [focusedId, setFocusedId] = useState<string | null>(null)
  const [boxCount, setBoxCount] = useState(0)

  const register = useCallback((box: BoxRegistration) => {
    boxes.current.set(box.id, box)
    setBoxCount(boxes.current.size)
    return () => {
      boxes.current.delete(box.id)
      setBoxCount(boxes.current.size)
    }
  }, [])

  const pickTarget = useCallback(() => {
    const all = [...boxes.current.values()]
    if (all.length === 0) return undefined
    const active = document.activeElement
    const focused = all.find((b) => active && b.element()?.contains(active))
    if (focused) return focused
    const topLayer = Math.max(...all.map((b) => b.layer))
    const onTop = all.filter((b) => b.layer === topLayer)
    return onTop.find((b) => b.primary) ?? onTop[0]
  }, [])

  useEffect(() => {
    const onFocus = () => {
      const active = document.activeElement
      const box = [...boxes.current.values()].find((b) => active && b.element()?.contains(active))
      setFocusedId(box?.id ?? null)
    }
    const onBlur = () => setTimeout(onFocus)
    document.addEventListener('focusin', onFocus)
    document.addEventListener('focusout', onBlur)
    return () => {
      document.removeEventListener('focusin', onFocus)
      document.removeEventListener('focusout', onBlur)
    }
  }, [])

  useEffect(() => {
    const onPaste = (e: ClipboardEvent) => {
      const files = imagesFromPaste(e)
      if (files.length === 0) return // dán chữ: để trình duyệt xử lý bình thường
      e.preventDefault()
      const target = pickTarget()
      if (target) target.add(files)
      else onOrphanImages(files)
    }
    document.addEventListener('paste', onPaste)
    return () => document.removeEventListener('paste', onPaste)
  }, [pickTarget, onOrphanImages])

  return (
    <HubContext.Provider value={{ register, pickTarget, focusedId, boxCount }}>{children}</HubContext.Provider>
  )
}

// Layer giúp hub biết ô nào nằm trong modal đang mở.
const LayerContext = createContext(0)
export const useLayer = () => useContext(LayerContext)
export function Layer({ children }: { children: ReactNode }) {
  const parent = useLayer()
  return <LayerContext.Provider value={parent + 1}>{children}</LayerContext.Provider>
}
