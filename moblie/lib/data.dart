import 'package:flutter/foundation.dart';

enum Role { sales, kyThuat }

extension RoleLabel on Role {
  String get label => switch (this) {
        Role.sales => 'Sales',
        Role.kyThuat => 'Kỹ thuật',
      };
}

class Ticket {
  const Ticket(this.code, this.title, this.customer, this.status);
  final String code;
  final String title;
  final String customer;
  final String status;
}

const tickets = [
  Ticket('YC-1023', 'Lắp đặt máy lọc nước tầng 3', 'Trường THCS Nguyễn Du', 'Đang xử lý'),
  Ticket('YC-1019', 'Báo giá 20 bộ bàn ghế học sinh', 'Trường TH Lê Lợi', 'Chờ duyệt'),
  Ticket('YC-1011', 'Bảo trì máy chiếu phòng 204', 'Trường THPT Trần Phú', 'Mới'),
  Ticket('YC-1004', 'Khảo sát hệ thống camera', 'Trường MN Hoa Sen', 'Hoàn thành'),
  Ticket('KH-0231', 'Khách hàng: Trường TH Kim Đồng', 'Trường TH Kim Đồng', 'Khách hàng'),
];

class CreateKind {
  const CreateKind(this.label, this.icon);
  final String label;
  final String icon;
}

const _baoGia = CreateKind('Báo giá', '💰');
const _khachHang = CreateKind('Khách hàng mới', '👤');
const _yeuCau = CreateKind('Yêu cầu mới', '📝');
const _baoCao = CreateKind('Báo cáo hiện trường', '🛠️');

/// "Tạo mới" sắp theo vai trò người dùng.
const createByRole = {
  Role.sales: [_baoGia, _khachHang, _yeuCau, _baoCao],
  Role.kyThuat: [_baoCao, _yeuCau, _baoGia, _khachHang],
};

sealed class Destination {}

class CreateDestination extends Destination {
  CreateDestination(this.kind);
  final CreateKind kind;
}

class TicketDestination extends Destination {
  TicketDestination(this.ticket);
  final Ticket ticket;
}

class SavePendingDestination extends Destination {}

class AppState extends ChangeNotifier {
  Role role = Role.sales;
  final recent = <String>['YC-1023', 'YC-1019'];

  /// Ảnh chờ: lưu lại để quyết định đính kèm vào đâu sau.
  final pending = <Uint8List>[];

  void setRole(Role r) {
    role = r;
    notifyListeners();
  }

  void touchRecent(String code) {
    recent
      ..remove(code)
      ..insert(0, code);
    if (recent.length > 4) recent.removeLast();
    notifyListeners();
  }

  void addPending(Uint8List bytes) {
    pending.add(bytes);
    notifyListeners();
  }

  void removePending(Uint8List bytes) {
    pending.remove(bytes);
    notifyListeners();
  }
}

final appState = AppState();
