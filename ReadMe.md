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

**Tự dán ảnh vừa copy (Chrome / Edge):** lần đầu bấm hoặc gõ phím bất kỳ đâu trên trang,
Chrome hỏi quyền đọc clipboard (bắt buộc, trình duyệt không cho bỏ qua) – chọn **Cho phép** một lần.
Từ đó, mỗi khi quay lại tab (hoặc copy ảnh ngay trong trang):
- Trang có ô đính kèm → ảnh được **tự dán thẳng vào ô** (ô đang focus → modal đang mở → ô chính),
  hiện thông báo kèm nút **Hoàn tác** trong 6 giây.
- Trang không có ô → popup có thumbnail **"Đính kèm vào…"** → màn hình chọn đích đến.

Giống mobile: chỉ gợi ý ảnh copy trong 5 phút gần đây; ảnh đã dán / đã bấm ✕ / đã tự Ctrl+V
được ghi nhớ (theo SHA-256, lưu `localStorage`) để không gợi ý lại; clipboard đổi sang chữ thì popup ẩn.
Firefox / Safari không cho đọc clipboard nếu người dùng không thao tác → chỉ có nút "Dán ảnh" + Ctrl/⌘ + V.
Cần HTTPS (Netlify đã có) hoặc `localhost`. Code: `web/src/attach/useClipboardWatcher.ts`, `AutoPaste.tsx`, `SuggestionPopup.tsx`.
Quyền cấp theo từng domain: mỗi URL ngrok mới sẽ phải cho phép lại.

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

### Chia sẻ tạm qua ngrok

`vite.config.ts` đã cho phép các domain `*.ngrok-free.app`, `*.ngrok.app`, `*.ngrok.io`.
Nên chạy bản build (tải nhanh hơn nhiều so với dev server qua ngrok):

```bash
cd web
npm run build && npm run preview -- --port 4173
```

```bash
ngrok http 4173
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
- **Nhận share ảnh (Android):** SnapDrop có trong bảng Share của Zalo, Ảnh, Files… (1 hoặc nhiều ảnh).
  App mở thẳng màn hình chọn đích, bỏ qua kiểm tra clipboard. Nếu đang mở trang có ô đính kèm,
  mục "Trang đang mở: YC-1023…" được đưa lên đầu; chọn mục đó thì ảnh vào thẳng ô đính kèm của trang.
  Code: `intent-filter` SEND/SEND_MULTIPLE trong `AndroidManifest.xml`, xử lý trong `MainActivity.kt`
  (channel `snapdrop/share`), phía Dart ở `lib/share/share_receiver.dart`.

#### Thử share trên máy ảo Android

Mở app Ảnh (Google Photos) → chọn ảnh → **Share** → **SnapDrop**.
Lưu ý: không dùng được `adb shell am start -a SEND` với URI `content://media/...`,
vì shell không có quyền cấp quyền đọc ảnh cho app.

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
  lib/share/              ShareReceiver – nhận ảnh share (Android)
  android/.../MainActivity.kt   Native channel Android
  ios/Runner/AppDelegate.swift  Native channel iOS
```

## Chưa làm

- Nhận share ảnh trên **iOS** (cần Share Extension + App Group). Android đã làm.
- Nút 📎 chọn ảnh từ thư viện, upload thật (hiện đang giả lập tiến trình).
- Đánh dấu ảnh đã xử lý khi người dùng tự nhấn giữ → Dán.
