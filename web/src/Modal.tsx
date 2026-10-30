import { useEffect, type ReactNode } from 'react'
import { Layer } from './attach/AttachHub'

type Props = { title: string; onClose: () => void; children: ReactNode; wide?: boolean }

export function Modal({ title, onClose, children, wide }: Props) {
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => e.key === 'Escape' && onClose()
    document.addEventListener('keydown', onKey)
    return () => document.removeEventListener('keydown', onKey)
  }, [onClose])

  return (
    <div className="backdrop" onMouseDown={(e) => e.target === e.currentTarget && onClose()}>
      <div className={`modal${wide ? ' wide' : ''}`} role="dialog" aria-label={title}>
        <header>
          <h2>{title}</h2>
          <button className="icon-btn" onClick={onClose} aria-label="Đóng">
            ✕
          </button>
        </header>
        <Layer>{children}</Layer>
      </div>
    </div>
  )
}
