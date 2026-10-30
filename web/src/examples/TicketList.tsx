import { TICKETS } from '../data'

type Props = { pending: { id: string; url: string }[]; onAttachPending: (id: string) => void; onDropPending: (id: string) => void }

// Ví dụ 2 – Trang KHÔNG có ô đính kèm (nhánh 2b).
// Web không thể chủ động phát hiện ảnh, nên ở đây gợi ý chỉ bật khi người dùng nhấn Ctrl/⌘ + V:
// ảnh không có ô nào nhận → hiện banner "Đính kèm vào…" → màn hình chọn đích đến.
export function TicketList({ pending, onAttachPending, onDropPending }: Props) {
  return (
    <div className="page">
      <h1>Yêu cầu của tôi</h1>
      <section className="hint">
        <b>Thử:</b> copy một ảnh rồi nhấn <kbd>Ctrl/⌘ + V</kbd> trên trang này. Trang không có ô đính kèm nên sẽ hiện
        banner ở cuối màn hình để chọn nơi đính kèm.
      </section>

      {pending.length > 0 && (
        <section className="pending">
          <h3>🗂️ Ảnh chờ ({pending.length})</h3>
          <ul>
            {pending.map((p) => (
              <li key={p.id}>
                <img src={p.url} alt="" />
                <div>
                  <button className="link" onClick={() => onAttachPending(p.id)}>
                    Đính kèm vào…
                  </button>
                  <button className="link danger" onClick={() => onDropPending(p.id)}>
                    Xoá
                  </button>
                </div>
              </li>
            ))}
          </ul>
        </section>
      )}

      <ul className="tickets">
        {TICKETS.map((t) => (
          <li key={t.code}>
            <div>
              <span className="code">{t.code}</span>
              <b>{t.title}</b>
              <small className="muted">{t.customer}</small>
            </div>
            <span className="status">{t.status}</span>
          </li>
        ))}
      </ul>
    </div>
  )
}
