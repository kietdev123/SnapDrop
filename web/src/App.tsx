import { useCallback, useEffect, useMemo, useState } from 'react'
import { AttachHubProvider } from './attach/AttachHub'
import { AttachmentBox } from './attach/AttachmentBox'
import { Modal } from './Modal'
import { ROLES, type Destination, type Role } from './data'
import { DestinationPicker } from './examples/DestinationPicker'
import { TaskDetail } from './examples/TaskDetail'
import { TicketList } from './examples/TicketList'

type Tab = 'vi-du-1' | 'vi-du-2'
type Pending = { id: string; file: File; url: string }

const readTab = (): Tab => (location.hash === '#vi-du-2' ? 'vi-du-2' : 'vi-du-1')

export default function App() {
  const [tab, setTab] = useState<Tab>(readTab)
  const [role, setRole] = useState<Role>('sales')
  // Ảnh vừa dán nhưng chưa có nơi nhận (nhánh 2b).
  const [orphan, setOrphan] = useState<File[] | null>(null)
  const [pickerOpen, setPickerOpen] = useState(false)
  const [target, setTarget] = useState<{ dest: Destination; files: File[] } | null>(null)
  const [pending, setPending] = useState<Pending[]>([])
  const [recent, setRecent] = useState(['YC-1023', 'YC-1019'])
  const [toast, setToast] = useState<string | null>(null)

  const bannerThumb = useMemo(() => (orphan ? URL.createObjectURL(orphan[0]) : ''), [orphan])

  useEffect(() => {
    const onHash = () => setTab(readTab())
    window.addEventListener('hashchange', onHash)
    return () => window.removeEventListener('hashchange', onHash)
  }, [])

  // Banner chỉ biến mất khi người dùng tắt hoặc khi có ảnh khác thay thế.
  const onOrphanImages = useCallback((files: File[]) => setOrphan(files), [])

  const notify = (msg: string) => {
    setToast(msg)
    setTimeout(() => setToast(null), 2500)
  }

  const pick = (dest: Destination) => {
    if (!orphan) return
    setTarget({ dest, files: orphan })
    setOrphan(null)
    setPickerOpen(false)
  }

  const savePending = () => {
    if (!orphan) return
    setPending((p) => [...p, ...orphan.map((file) => ({ id: crypto.randomUUID(), file, url: URL.createObjectURL(file) }))])
    setOrphan(null)
    setPickerOpen(false)
    notify(`Đã lưu ${orphan.length} ảnh vào Ảnh chờ`)
  }

  const attachPending = (id: string) => {
    const item = pending.find((p) => p.id === id)
    if (!item) return
    setPending((p) => p.filter((x) => x.id !== id))
    setOrphan([item.file])
    setPickerOpen(true)
  }

  const targetTitle = (d: Destination) => (d.kind === 'ticket' ? `Bình luận vào ${d.ticket.code}` : d.create.label)

  return (
    <AttachHubProvider onOrphanImages={onOrphanImages}>
      <header className="topbar">
        <span className="brand">📋 SnapDrop</span>
        <nav>
          <a href="#vi-du-1" className={tab === 'vi-du-1' ? 'active' : ''}>
            Ví dụ 1 · Có ô đính kèm
          </a>
          <a href="#vi-du-2" className={tab === 'vi-du-2' ? 'active' : ''}>
            Ví dụ 2 · Không có ô đính kèm
          </a>
        </nav>
        <label className="role">
          Vai trò
          <select value={role} onChange={(e) => setRole(e.target.value as Role)}>
            {Object.entries(ROLES).map(([k, v]) => (
              <option key={k} value={k}>
                {v}
              </option>
            ))}
          </select>
        </label>
      </header>

      <main>
        {tab === 'vi-du-1' ? (
          <TaskDetail />
        ) : (
          <TicketList
            pending={pending}
            onAttachPending={attachPending}
            onDropPending={(id) => setPending((p) => p.filter((x) => x.id !== id))}
          />
        )}
      </main>

      {orphan && !pickerOpen && (
        <div className="banner" role="status">
          <img src={bannerThumb} alt="" />
          <span>
            Bạn vừa dán {orphan.length} ảnh —{' '}
            <button className="link strong" onClick={() => setPickerOpen(true)}>
              Đính kèm vào…
            </button>
          </span>
          <button className="icon-btn" onClick={() => setOrphan(null)} aria-label="Tắt gợi ý">
            ✕
          </button>
        </div>
      )}

      {pickerOpen && orphan && (
        <DestinationPicker
          role={role}
          count={orphan.length}
          recent={recent}
          onPick={pick}
          onSavePending={savePending}
          onClose={() => setPickerOpen(false)}
        />
      )}

      {target && (
        <Modal title={targetTitle(target.dest)} onClose={() => setTarget(null)}>
          {target.dest.kind === 'create' && <input className="search" placeholder="Tiêu đề / tên…" autoFocus />}
          <AttachmentBox
            label={target.dest.kind === 'ticket' ? 'Bình luận' : 'Nội dung'}
            primary
            initialFiles={target.files}
            placeholder="Ảnh đã được đính kèm sẵn, thêm mô tả nếu cần…"
            submitLabel={target.dest.kind === 'ticket' ? 'Gửi' : 'Tạo'}
            onSubmit={(_t, files) => {
              const d = target.dest
              if (d.kind === 'ticket') setRecent((r) => [d.ticket.code, ...r.filter((c) => c !== d.ticket.code)].slice(0, 4))
              notify(`Đã gửi ${files.length} ảnh → ${targetTitle(d)}`)
              setTarget(null)
            }}
          />
        </Modal>
      )}

      {toast && <div className="toast">{toast}</div>}
    </AttachHubProvider>
  )
}
