export type Role = 'sales' | 'ky_thuat'

export const ROLES: Record<Role, string> = { sales: 'Sales', ky_thuat: 'Kỹ thuật' }

export type Ticket = { code: string; title: string; customer: string; status: string }

export const TICKETS: Ticket[] = [
  { code: 'YC-1023', title: 'Lắp đặt máy lọc nước tầng 3', customer: 'Trường THCS Nguyễn Du', status: 'Đang xử lý' },
  { code: 'YC-1019', title: 'Báo giá 20 bộ bàn ghế học sinh', customer: 'Trường TH Lê Lợi', status: 'Chờ duyệt' },
  { code: 'YC-1011', title: 'Bảo trì máy chiếu phòng 204', customer: 'Trường THPT Trần Phú', status: 'Mới' },
  { code: 'YC-1004', title: 'Khảo sát hệ thống camera', customer: 'Trường MN Hoa Sen', status: 'Hoàn thành' },
  { code: 'KH-0231', title: 'Khách hàng: Trường TH Kim Đồng', customer: 'Trường TH Kim Đồng', status: 'Khách hàng' },
]

export type CreateKind = { key: string; label: string; icon: string }

const CREATE: Record<string, CreateKind> = {
  yeu_cau: { key: 'yeu_cau', label: 'Yêu cầu mới', icon: '📝' },
  bao_gia: { key: 'bao_gia', label: 'Báo giá', icon: '💰' },
  khach_hang: { key: 'khach_hang', label: 'Khách hàng mới', icon: '👤' },
  bao_cao: { key: 'bao_cao', label: 'Báo cáo hiện trường', icon: '🛠️' },
}

// "Tạo mới" sắp theo vai trò người dùng.
export const CREATE_BY_ROLE: Record<Role, CreateKind[]> = {
  sales: [CREATE.bao_gia, CREATE.khach_hang, CREATE.yeu_cau, CREATE.bao_cao],
  ky_thuat: [CREATE.bao_cao, CREATE.yeu_cau, CREATE.bao_gia, CREATE.khach_hang],
}

export type Destination = { kind: 'create'; create: CreateKind } | { kind: 'ticket'; ticket: Ticket }
