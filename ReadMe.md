# SnapDrop

Demo luồng **gợi ý đính kèm ảnh vừa copy** (chi tiết bài toán: [docs/user_flow.md](docs/user_flow.md), sơ đồ: [docs/goi_y_dinh_kem_anh_clipboard_flow.svg](docs/goi_y_dinh_kem_anh_clipboard_flow.svg)).

| Thư mục | Nền tảng | Công nghệ |
| --- | --- | --- |
| [`web/`](web) | Web | React 19 + Vite + TypeScript, deploy Netlify |
| [`moblie/`](moblie) | Android / iOS | Flutter 3.41.4 (quản lý bằng fvm) |

## Yêu cầu

- Node.js 22+ và npm
- [fvm](https://fvm.app) (phiên bản Flutter được ghim trong `moblie/.fvmrc`)
- Android SDK (build APK), Xcode (chạy iOS)

---

## Web

Hai ví dụ trong cùng một app:

- **Ví dụ 1 – Có ô đính kèm** (`/#vi-du-1`): nút "📋 Dán ảnh" + sự kiện `paste`, chọn ô theo thứ tự: ô đang focus → modal đang mở → ô chính.
- **Ví dụ 2 – Không có ô đính kèm** (`/#vi-du-2`): Ctrl/⌘ + V → banner "Đính kèm vào…" → chọn đích đến → form có ảnh sẵn.

### Chạy dev

```bash
cd web
npm install
npm run dev
```

Mở http://localhost:5173.

### Build web

```bash
cd web
npm install
npm run build
```

Kết quả nằm trong `web/dist/`. Xem thử bản build:

```bash
npm run preview
```

### Deploy Netlify

File `web/netlify.toml` đã cấu hình sẵn:

- Build command: `npm run build`
- Publish directory: `dist`
- Redirect SPA `/* → /index.html`

Khi tạo site trên Netlify (kết nối Git), đặt **Base directory = `web`**.

Hoặc deploy thủ công bằng Netlify CLI:

```bash
cd web
npm run build
npx netlify-cli deploy --prod --dir=dist
```

---

## Mobile (Flutter)

- Bước 1 (phát hiện ảnh mới) chạy native qua `MethodChannel('snapdrop/clipboard')`:
  - iOS: `UIPasteboard.hasImages` + `changeCount`
  - Android: `ClipDescription` (MIME `image/*`) + timestamp
- Trang có ô đính kèm: chip "📋 Dán ảnh vừa copy" cạnh nút đính kèm.
- Trang không có ô đính kèm: banner cuối màn hình → màn hình chọn đích đến.
- Nút 🧪 trên thanh tiêu đề: đưa một ảnh test vào clipboard để demo trên máy ảo.

### Cài SDK và thư viện

```bash
cd moblie
fvm install
fvm flutter pub get
```

### Chạy trên máy ảo / thiết bị

```bash
fvm flutter devices
```

```bash
fvm flutter run -d <device-id>
```

### Build APK release

```bash
cd moblie
fvm flutter build apk --release
```

File APK: `moblie/build/app/outputs/flutter-apk/app-release.apk` (~49 MB, chứa cả 3 kiến trúc).

Muốn APK nhỏ hơn, tách theo kiến trúc CPU:

```bash
fvm flutter build apk --release --split-per-abi
```

Sẽ ra `app-armeabi-v7a-release.apk`, `app-arm64-v8a-release.apk`, `app-x86_64-release.apk` (máy thật hiện nay hầu hết dùng `arm64-v8a`).

Cài APK lên máy đang kết nối:

```bash
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

> **Lưu ý ký app:** hiện bản release đang ký bằng **debug key** (cấu hình mặc định trong `android/app/build.gradle.kts`), chỉ dùng để cài thử / phát nội bộ. Trước khi đưa lên Google Play cần tạo keystore riêng và khai báo `signingConfigs` release (file `key.properties` và `*.jks` đã nằm trong `.gitignore`). Tham khảo: https://docs.flutter.dev/deployment/android#sign-the-app

Nếu cần build cho Google Play (App Bundle):

```bash
fvm flutter build appbundle --release
```

### Build iOS

```bash
cd moblie
fvm flutter build ios --release
```

Sau đó mở `moblie/ios/Runner.xcworkspace` bằng Xcode để ký (Signing & Capabilities) và Archive.

---

## Cấu trúc thư mục

```
docs/                     Mô tả bài toán và sơ đồ luồng
web/
  src/attach/             AttachHub (chọn ô nhận ảnh), AttachmentBox, đọc clipboard
  src/examples/           Ví dụ 1 (TaskDetail), Ví dụ 2 (TicketList), DestinationPicker
  netlify.toml
moblie/
  lib/clipboard/          ClipboardWatcher – phát hiện ảnh mới, độ tươi, ID đã xử lý
  lib/attach/             AttachRegistry (chọn ô nhận ảnh), AttachmentBox (chip dán ảnh)
  lib/screens/            Chi tiết YC, Danh sách, Chọn đích đến, Form đích
  android/.../MainActivity.kt   Native channel Android
  ios/Runner/AppDelegate.swift  Native channel iOS
```

## Chưa làm

- Nhận share ảnh từ Zalo (màn hình chọn đích đã hỗ trợ mục "Trang đang mở", chưa có phần native nhận share).
- Nút 📎 chọn ảnh từ thư viện, upload thật (hiện đang giả lập tiến trình).
- Đánh dấu ảnh đã xử lý khi người dùng tự nhấn giữ → Dán.
