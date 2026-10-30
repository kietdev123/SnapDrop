// Web không thể âm thầm kiểm tra clipboard như app native.
// Chỉ có 2 đường lấy ảnh, đều do người dùng chủ động:
//   1. Sự kiện `paste` (Ctrl/Cmd + V) – không cần xin quyền.
//   2. Nút "Dán ảnh" gọi navigator.clipboard.read() – trình duyệt có thể hỏi quyền.

export function imagesFromPaste(e: ClipboardEvent): File[] {
  const items = Array.from(e.clipboardData?.items ?? [])
  return items
    .filter((it) => it.kind === 'file' && it.type.startsWith('image/'))
    .map((it) => it.getAsFile())
    .filter((f): f is File => f !== null)
    .map(named)
}

export async function readClipboardImages(): Promise<File[]> {
  if (!navigator.clipboard?.read) {
    throw new Error('Trình duyệt không hỗ trợ đọc clipboard. Hãy nhấn Ctrl/Cmd + V.')
  }
  const items = await navigator.clipboard.read()
  const files: File[] = []
  for (const item of items) {
    const type = item.types.find((t) => t.startsWith('image/'))
    if (!type) continue
    const blob = await item.getType(type)
    files.push(named(new File([blob], '', { type })))
  }
  return files
}

function named(f: File): File {
  if (f.name && f.name !== 'image.png') return f
  const ext = f.type.split('/')[1] ?? 'png'
  const stamp = new Date().toTimeString().slice(0, 8).replaceAll(':', '')
  return new File([f], `clipboard-${stamp}.${ext}`, { type: f.type })
}
