import { useAttachHub } from './AttachHub'
import type { ClipSuggestion } from './useClipboardWatcher'

type Props = {
  suggestion: ClipSuggestion
  onDismiss: () => void
  // Trang không có ô đính kèm → mở màn hình chọn đích (nhánh 2b).
  onChooseDestination: (file: File) => void
  onUsed: () => void
}

// Popup gợi ý khi clipboard có ảnh mới. Web đã đọc được ảnh nên hiện luôn thumbnail.
//   - Trang có ô đính kèm (2a): "Dán vào <ô>" – ô được chọn theo focus → modal → ô chính.
//   - Trang không có ô (2b): "Đính kèm vào…" → màn hình chọn đích đến.
// Không tự biến mất: chỉ ẩn khi người dùng ✕ hoặc clipboard đổi sang thứ khác.
export function SuggestionPopup({ suggestion, onDismiss, onChooseDestination, onUsed }: Props) {
  const hub = useAttachHub()
  void hub.focusedId
  void hub.boxCount
  const target = hub.pickTarget()

  return (
    <div className="suggest" role="dialog" aria-label="Gợi ý dán ảnh vừa copy">
      <img src={suggestion.url} alt="Ảnh vừa copy" />
      <div className="suggest-body">
        <b>Bạn vừa copy 1 ảnh</b>
        <small>{target ? `Dán vào ô “${target.label}”?` : 'Đính kèm vào yêu cầu, báo giá…?'}</small>
        <div className="suggest-actions">
          {target ? (
            <button
              className="primary-btn"
              onClick={() => {
                target.add([suggestion.file])
                onUsed()
              }}
            >
              📋 Dán vào {target.label}
            </button>
          ) : (
            <button
              className="primary-btn"
              onClick={() => {
                onChooseDestination(suggestion.file)
                onUsed()
              }}
            >
              Đính kèm vào…
            </button>
          )}
          <button className="link" onClick={onDismiss}>
            Bỏ qua
          </button>
        </div>
      </div>
      <button className="icon-btn suggest-x" onClick={onDismiss} aria-label="Không gợi ý ảnh này nữa">
        ✕
      </button>
    </div>
  )
}
