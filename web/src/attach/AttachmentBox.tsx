import { useEffect, useId, useRef, useState } from 'react'
import { useAttachHub, useLayer } from './AttachHub'
import { readClipboardImages } from './clipboard'

export type Attachment = { id: string; file: File; url: string; progress: number }

type Props = {
  label: string
  primary?: boolean
  placeholder?: string
  submitLabel?: string
  initialFiles?: File[]
  onSubmit?: (text: string, files: File[]) => void
}

let seq = 0

// Component đính kèm dùng chung: mỗi màn hình khai báo ô chính bằng `primary`.
export function AttachmentBox({ label, primary, placeholder, submitLabel = 'Gửi', initialFiles, onSubmit }: Props) {
  const id = useId()
  const layer = useLayer()
  const hub = useAttachHub()
  const rootRef = useRef<HTMLDivElement>(null)
  const fileRef = useRef<HTMLInputElement>(null)
  const [text, setText] = useState('')
  const [items, setItems] = useState<Attachment[]>([])
  const [error, setError] = useState<string | null>(null)
  const [flash, setFlash] = useState(false)

  const add = (files: File[]) => {
    setError(null)
    setFlash(true)
    setTimeout(() => setFlash(false), 600)
    const next = files.map((file) => ({ id: `a${++seq}`, file, url: URL.createObjectURL(file), progress: 0 }))
    setItems((prev) => [...prev, ...next])
    next.forEach((a) => fakeUpload(a.id))
    const ids = new Set(next.map((a) => a.id))
    return () => setItems((prev) => prev.filter((a) => !ids.has(a.id)))
  }

  // Upload nền ngay khi ảnh được thêm vào ô (giả lập).
  const fakeUpload = (attId: string) => {
    const timer = setInterval(() => {
      setItems((prev) =>
        prev.map((a) => (a.id === attId ? { ...a, progress: Math.min(100, a.progress + 8 + Math.random() * 18) } : a)),
      )
    }, 180)
    setTimeout(() => clearInterval(timer), 3000)
  }

  const addRef = useRef(add)
  addRef.current = add

  useEffect(
    () =>
      hub.register({
        id,
        label,
        primary,
        layer,
        element: () => rootRef.current,
        add: (files) => addRef.current(files),
      }),
    [hub.register, id, label, primary, layer],
  )

  const seeded = useRef(false)
  useEffect(() => {
    if (seeded.current || !initialFiles?.length) return
    seeded.current = true
    add(initialFiles)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  const pasteFromButton = async () => {
    try {
      const files = await readClipboardImages()
      if (files.length === 0) setError('Clipboard không có ảnh.')
      else add(files)
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Không đọc được clipboard.')
    }
  }

  const remove = (attId: string) => setItems((prev) => prev.filter((a) => a.id !== attId))

  const submit = () => {
    onSubmit?.(text, items.map((a) => a.file))
    setText('')
    setItems([])
  }

  // Re-render khi focus/số ô thay đổi để badge "ảnh dán sẽ vào đây" luôn đúng.
  void hub.focusedId
  void hub.boxCount
  const isTarget = hub.pickTarget()?.id === id
  const uploading = items.some((a) => a.progress < 100)

  return (
    <div ref={rootRef} className={`attach-box${isTarget ? ' is-target' : ''}${flash ? ' flash' : ''}`}>
      <div className="attach-head">
        <span className="attach-label">{label}</span>
        {isTarget && <span className="target-badge">Ctrl/⌘ + V sẽ dán vào đây</span>}
      </div>
      <textarea value={text} onChange={(e) => setText(e.target.value)} placeholder={placeholder} rows={3} />
      {items.length > 0 && (
        <ul className="thumbs">
          {items.map((a) => (
            <li key={a.id}>
              <img src={a.url} alt={a.file.name} />
              {a.progress < 100 ? (
                <span className="progress" style={{ width: `${a.progress}%` }} />
              ) : (
                <span className="done">✓</span>
              )}
              <button className="thumb-x" onClick={() => remove(a.id)} aria-label="Bỏ ảnh">
                ✕
              </button>
            </li>
          ))}
        </ul>
      )}
      {error && <p className="error">{error}</p>}
      <div className="attach-actions">
        <button className="icon-btn" onClick={() => fileRef.current?.click()} title="Đính kèm tệp">
          📎
        </button>
        <input
          ref={fileRef}
          type="file"
          accept="image/*"
          multiple
          hidden
          onChange={(e) => {
            add(Array.from(e.target.files ?? []))
            e.target.value = ''
          }}
        />
        <button className="chip" onClick={pasteFromButton}>
          📋 Dán ảnh
        </button>
        <span className="spacer" />
        <button className="primary-btn" disabled={uploading || (!text && items.length === 0)} onClick={submit}>
          {uploading ? 'Đang tải ảnh…' : submitLabel}
        </button>
      </div>
    </div>
  )
}
