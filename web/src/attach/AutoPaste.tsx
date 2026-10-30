import { useEffect, useRef, useState } from 'react'
import { useAttachHub } from './AttachHub'
import { SuggestionPopup } from './SuggestionPopup'
import type { ClipSuggestion } from './useClipboardWatcher'

type Props = {
  suggestion: ClipSuggestion | null
  hidden: boolean
  onHandled: (id: string) => void
  onChooseDestination: (file: File) => void
}

type Undo = { text: string; undo: () => void }

// Tự dán ảnh vừa copy:
//   - Trang có ô đính kèm → dán thẳng vào ô (focus → modal → ô chính), kèm "Hoàn tác".
//   - Trang không có ô → không biết đính kèm vào đâu, nên hiện popup "Đính kèm vào…".
export function AutoPaste({ suggestion, hidden, onHandled, onChooseDestination }: Props) {
  const hub = useAttachHub()
  const [undo, setUndo] = useState<Undo | null>(null)
  const timer = useRef<number | undefined>(undefined)
  const target = hub.pickTarget()

  useEffect(() => {
    if (!suggestion || hidden || !target) return
    const revert = target.add([suggestion.file])
    onHandled(suggestion.id)
    setUndo({ text: `Đã tự dán ảnh vừa copy vào “${target.label}”`, undo: revert })
    clearTimeout(timer.current)
    timer.current = window.setTimeout(() => setUndo(null), 6000)
    // Chỉ chạy khi có ảnh mới hoặc trang vừa có ô đính kèm.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [suggestion?.id, hidden, target?.id])

  useEffect(() => () => clearTimeout(timer.current), [])

  return (
    <>
      {suggestion && !hidden && !target && (
        <SuggestionPopup
          suggestion={suggestion}
          onDismiss={() => onHandled(suggestion.id)}
          onUsed={() => onHandled(suggestion.id)}
          onChooseDestination={onChooseDestination}
        />
      )}
      {undo && (
        <div className="toast undo-toast" role="status">
          <span>📋 {undo.text}</span>
          <button
            className="link strong"
            onClick={() => {
              undo.undo()
              setUndo(null)
            }}
          >
            Hoàn tác
          </button>
        </div>
      )}
    </>
  )
}
