# SnapDrop – Web (React + Vite)

Bản web của luồng "gợi ý đính kèm ảnh vừa copy" (xem `../docs/user_flow.md`).

- **Ví dụ 1 – Có ô đính kèm** (`#vi-du-1`): nút "📋 Dán ảnh" cố định + sự kiện `paste`.
  Trang có 2 ô (Bình luận và Báo cáo hoàn thành trong modal) để minh hoạ thứ tự ưu tiên:
  ô đang focus → modal đang mở → ô chính.
- **Ví dụ 2 – Không có ô đính kèm** (`#vi-du-2`): Ctrl/⌘ + V → banner "Đính kèm vào…" →
  màn hình chọn đích (Tạo mới theo vai trò, Gần đây, Tìm kiếm, Lưu vào Ảnh chờ) → form đích có ảnh sẵn.
  Web không thể âm thầm kiểm tra clipboard, nên banner chỉ hiện khi người dùng tự dán.

```bash
npm install
npm run dev     # http://localhost:5173
npm run build   # ra thư mục dist/
```

## Deploy Netlify

`netlify.toml` đã cấu hình sẵn (build `npm run build`, publish `dist`).
Khi tạo site trên Netlify, chọn **Base directory = `web`**.
