import { useState } from 'react'
import { AttachmentBox } from '../attach/AttachmentBox'
import { Modal } from '../Modal'
import { TICKETS } from '../data'

type Post = { who: string; text: string; images: string[]; tag?: string }

// Ví dụ 1 – Trang CÓ ô đính kèm (nhánh 2a trên web):
// nút "📋 Dán ảnh" cố định + sự kiện paste. Trang có 2 ô (bình luận và báo cáo hoàn thành)
// để minh hoạ thứ tự ưu tiên: ô đang focus → modal đang mở → ô chính.
export function TaskDetail() {
  const ticket = TICKETS[0]
  const [posts, setPosts] = useState<Post[]>([
    { who: 'Anh Tuấn (Kỹ thuật)', text: 'Đã khảo sát, cần thêm ảnh vị trí đặt máy.', images: [] },
  ])
  const [reportOpen, setReportOpen] = useState(false)

  const post = (text: string, files: File[], tag?: string) =>
    setPosts((p) => [...p, { who: 'Bạn', text, images: files.map((f) => URL.createObjectURL(f)), tag }])

  return (
    <div className="page">
      <div className="ticket-card">
        <div className="ticket-top">
          <span className="code">{ticket.code}</span>
          <span className="status">{ticket.status}</span>
        </div>
        <h1>{ticket.title}</h1>
        <p className="muted">{ticket.customer}</p>
        <button className="secondary-btn" onClick={() => setReportOpen(true)}>
          ✅ Báo cáo hoàn thành
        </button>
      </div>

      <section className="hint">
        <b>Thử:</b> copy một ảnh (ví dụ chụp màn hình vào clipboard) rồi nhấn <kbd>Ctrl/⌘ + V</kbd> ở bất kỳ đâu trên
        trang. Viền xanh cho biết ảnh sẽ vào ô nào. Mở “Báo cáo hoàn thành” rồi dán lại để thấy ảnh đi vào modal.
      </section>

      <h3>Bình luận</h3>
      <ul className="posts">
        {posts.map((p, i) => (
          <li key={i}>
            <div className="who">
              {p.who} {p.tag && <span className="tag">{p.tag}</span>}
            </div>
            {p.text && <p>{p.text}</p>}
            {p.images.length > 0 && (
              <div className="post-imgs">
                {p.images.map((src) => (
                  <img key={src} src={src} alt="" />
                ))}
              </div>
            )}
          </li>
        ))}
      </ul>

      <AttachmentBox label="Bình luận" primary placeholder="Viết bình luận…" onSubmit={(t, f) => post(t, f)} />

      {reportOpen && (
        <Modal title={`Báo cáo hoàn thành – ${ticket.code}`} onClose={() => setReportOpen(false)}>
          <AttachmentBox
            label="Ảnh nghiệm thu"
            primary
            placeholder="Mô tả kết quả, ảnh nghiệm thu…"
            submitLabel="Gửi báo cáo"
            onSubmit={(t, f) => {
              post(t, f, 'Báo cáo hoàn thành')
              setReportOpen(false)
            }}
          />
        </Modal>
      )}
    </div>
  )
}
