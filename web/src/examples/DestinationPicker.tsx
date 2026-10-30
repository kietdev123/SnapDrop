import { useMemo, useState } from 'react'
import { Modal } from '../Modal'
import { CREATE_BY_ROLE, TICKETS, type Destination, type Role } from '../data'

type Props = {
  role: Role
  count: number
  recent: string[]
  onPick: (d: Destination) => void
  onSavePending: () => void
  onClose: () => void
}

// Màn hình chọn đích đến – dùng chung cho banner, share và "Ảnh chờ".
export function DestinationPicker({ role, count, recent, onPick, onSavePending, onClose }: Props) {
  const [q, setQ] = useState('')
  const results = useMemo(() => {
    const s = q.trim().toLowerCase()
    if (!s) return []
    return TICKETS.filter((t) => `${t.code} ${t.title} ${t.customer}`.toLowerCase().includes(s))
  }, [q])
  const recentTickets = recent.map((c) => TICKETS.find((t) => t.code === c)!).filter(Boolean)

  return (
    <Modal title={`Đính kèm ${count} ảnh vào…`} onClose={onClose} wide>
      <input
        className="search"
        autoFocus
        placeholder="🔍 Tìm theo mã hoặc tên (YC-1011, máy chiếu…)"
        value={q}
        onChange={(e) => setQ(e.target.value)}
      />
      {q ? (
        <List title="Kết quả tìm kiếm" empty="Không tìm thấy.">
          {results.map((t) => (
            <Row key={t.code} icon="📄" main={`${t.code} · ${t.title}`} sub={t.customer} onClick={() => onPick({ kind: 'ticket', ticket: t })} />
          ))}
        </List>
      ) : (
        <>
          <List title="Tạo mới">
            {CREATE_BY_ROLE[role].map((c) => (
              <Row key={c.key} icon={c.icon} main={c.label} onClick={() => onPick({ kind: 'create', create: c })} />
            ))}
          </List>
          <List title="Gần đây">
            {recentTickets.map((t) => (
              <Row key={t.code} icon="🕘" main={`${t.code} · ${t.title}`} sub={t.customer} onClick={() => onPick({ kind: 'ticket', ticket: t })} />
            ))}
          </List>
          <List title="Để sau">
            <Row icon="🗂️" main="Lưu vào Ảnh chờ" sub="Quyết định đính kèm vào đâu sau" onClick={onSavePending} />
          </List>
        </>
      )}
    </Modal>
  )
}

function List({ title, children, empty }: { title: string; children: React.ReactNode; empty?: string }) {
  const has = Array.isArray(children) ? children.length > 0 : !!children
  return (
    <section className="dest-list">
      <h4>{title}</h4>
      {has ? <ul>{children}</ul> : <p className="muted">{empty}</p>}
    </section>
  )
}

function Row({ icon, main, sub, onClick }: { icon: string; main: string; sub?: string; onClick: () => void }) {
  return (
    <li>
      <button onClick={onClick}>
        <span className="row-icon">{icon}</span>
        <span className="row-text">
          <span>{main}</span>
          {sub && <small>{sub}</small>}
        </span>
        <span className="chev">›</span>
      </button>
    </li>
  )
}
