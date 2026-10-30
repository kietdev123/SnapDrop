Dưới đây là flow theo hướng gợi ý, tách thành hai nhánh chính: trang có ô đính kèm và trang không có.

## Bước 1: Phát hiện ảnh mới (chạy mỗi khi app vào foreground)

Ở bước này chỉ kiểm tra "clipboard có ảnh hay không", chưa đọc nội dung ảnh. Nhờ vậy không làm phiền người dùng bằng hộp thoại xin quyền.

**Kiểm tra có ảnh:**
- iOS: `UIPasteboard.general.hasImages`. Chỉ đọc nội dung thật khi người dùng bấm.
- Android: `getPrimaryClipDescription()` rồi kiểm tra MIME `image/*`.

**Nhận biết ảnh "mới":**
- iOS: so `changeCount` với giá trị lần trước.
- Android: so `ClipDescription.getTimestamp()`.
- Lưu lại ID của ảnh đã dùng hoặc đã bị tắt gợi ý, để không gợi ý lặp lại.

**Giới hạn độ tươi:** chỉ gợi ý nếu ảnh xuất hiện trong khoảng vài phút gần đây (tự ghi lại lúc phát hiện lần đầu). Ảnh copy từ hôm qua không nên bật gợi ý.

## Bước 2a: Trang có ô đính kèm (nhánh tím)

Chip nhỏ xuất hiện ngay cạnh nút đính kèm, ví dụ "📋 Dán ảnh vừa copy". Chip không có thumbnail, vì muốn hiện thumbnail thì phải đọc ảnh trước. Bấm chip thì app mới đọc ảnh, thêm vào ô ở trạng thái chờ gửi kèm preview, và bắt đầu upload nền.

Nếu một trang có nhiều ô đính kèm (ví dụ chi tiết công việc có cả ô bình luận lẫn "Báo cáo hoàn thành"), chọn ô theo thứ tự ưu tiên:
1. Ô đang focus.
2. Form, modal hoặc bottom sheet đang mở.
3. Ô chính của trang (mặc định là ô bình luận).

Mỗi màn hình tự khai báo ô chính của nó trong component đính kèm dùng chung.

## Bước 2b: Trang không có ô đính kèm (nhánh xanh)

Hiện một banner ở cuối màn hình: "Bạn vừa copy 1 ảnh — **Đính kèm vào…**", kèm nút ✕ để tắt. Banner không tự biến mất sau vài giây, vì sales có thể cần thời gian đọc. Banner chỉ biến mất khi người dùng tắt hoặc khi clipboard đổi sang ảnh khác.

Bấm vào banner sẽ mở màn hình chọn đích đến:
- **Tạo mới:** sắp theo vai trò người dùng.
- **Gần đây:** các mục người dùng vừa xem hoặc vừa bình luận.
- **Tìm kiếm:** theo mã hoặc tên.
- **Lưu vào Ảnh chờ:** để quyết định sau.

Chọn xong thì mở form đích với ảnh đã đính kèm sẵn.

## Share từ Zalo dùng chung màn hình chọn đích đến

Khi nhận share, app mở thẳng màn hình chọn đích đến, bỏ qua các bước kiểm tra clipboard. Nếu trước đó app đang mở một trang có ô đính kèm, đưa "**Trang đang mở: YC-1023…**" lên đầu danh sách. Như vậy cả ba cách vào (copy, share, mở app) đều dẫn về cùng một màn hình, sales chỉ phải học một kiểu thao tác.

## Hành vi khi tắt gợi ý và khi gửi xong

- Bấm ✕ trên chip hoặc banner: ghi nhớ ID ảnh đó, không gợi ý lại.
- Gửi xong: đánh dấu ảnh đã xử lý.
- Người dùng tự dán bằng tay (nhấn giữ → Dán): cũng đánh dấu đã xử lý, để chip không hiện thừa.

## Bản web

Web không thể kiểm tra clipboard một cách âm thầm như app native. Vì vậy trên web, nhánh 2a được thay bằng nút "Dán ảnh" cố định cộng với sự kiện `paste`, như đã nói ở đầu. Nhánh 2b không làm được trên web. Gợi ý chủ động là lợi thế riêng của app.

Bạn có thể bấm vào từng ô trong sơ đồ để mình đi sâu vào phần đó, ví dụ thiết kế màn hình chọn đích đến hoặc code phát hiện clipboard.