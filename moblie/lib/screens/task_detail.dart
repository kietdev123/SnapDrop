import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../attach/attachment_box.dart';
import '../data.dart';

class _Post {
  _Post(this.who, this.text, this.images, {this.tag});
  final String who;
  final String text;
  final List<Uint8List> images;
  final String? tag;
}

/// Ví dụ 1 – Trang CÓ ô đính kèm (nhánh 2a).
/// Có 2 ô: "Bình luận" (ô chính) và "Báo cáo hoàn thành" (trong bottom sheet)
/// để minh hoạ thứ tự ưu tiên: ô đang focus → sheet đang mở → ô chính.
class TaskDetailScreen extends StatefulWidget {
  const TaskDetailScreen({super.key});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final ticket = tickets.first;
  @override
  void initState() {
    super.initState();
    appState.currentPage = ticket;
  }

  @override
  void dispose() {
    if (appState.currentPage == ticket) appState.currentPage = null;
    super.dispose();
  }

  final _posts = [_Post('Anh Tuấn (Kỹ thuật)', 'Đã khảo sát, cần thêm ảnh vị trí đặt máy.', const [])];

  void _post(String text, List<Uint8List> images, {String? tag}) =>
      setState(() => _posts.add(_Post('Bạn', text, images, tag: tag)));

  void _openReport() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + MediaQuery.viewInsetsOf(ctx).bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Báo cáo hoàn thành – ${ticket.code}', style: Theme.of(ctx).textTheme.titleMedium),
            const SizedBox(height: 12),
            AttachmentBox(
              label: 'Ảnh nghiệm thu',
              primary: true,
              hint: 'Mô tả kết quả…',
              submitLabel: 'Gửi báo cáo',
              onSubmit: (t, imgs) {
                _post(t, imgs, tag: 'Báo cáo hoàn thành');
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card.outlined(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Text(ticket.code, style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w600)),
                        const Spacer(),
                        Chip(label: Text(ticket.status), visualDensity: VisualDensity.compact),
                      ]),
                      Text(ticket.title, style: Theme.of(context).textTheme.titleLarge),
                      Text(ticket.customer, style: TextStyle(color: scheme.outline)),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _openReport,
                        icon: const Icon(Icons.task_alt),
                        label: const Text('Báo cáo hoàn thành'),
                      ),
                    ],
                  ),
                ),
              ),
              const _Hint(
                'Copy 1 ảnh (hoặc bấm 🧪 trên thanh tiêu đề), rời app rồi quay lại: chip “📋 Dán ảnh vừa copy” '
                'hiện cạnh nút đính kèm của ô đang được chọn. Mở “Báo cáo hoàn thành” để thấy chip chuyển vào sheet.',
              ),
              Text('Bình luận', style: Theme.of(context).textTheme.titleSmall),
              for (final p in _posts) _PostTile(p),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: AttachmentBox(label: 'Bình luận', primary: true, onSubmit: _post),
          ),
        ),
      ],
    );
  }
}

class _PostTile extends StatelessWidget {
  const _PostTile(this.p);
  final _Post p;

  @override
  Widget build(BuildContext context) {
    return Card.outlined(
      margin: const EdgeInsets.only(top: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text(p.who, style: const TextStyle(fontWeight: FontWeight.w600)),
              if (p.tag != null) ...[
                const SizedBox(width: 6),
                Text(p.tag!, style: const TextStyle(color: Colors.green, fontSize: 12)),
              ],
            ]),
            if (p.text.isNotEmpty) Text(p.text),
            if (p.images.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Wrap(spacing: 6, runSpacing: 6, children: [
                  for (final img in p.images)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(img, width: 96, height: 96, fit: BoxFit.cover),
                    ),
                ]),
              ),
          ],
        ),
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(text, style: const TextStyle(fontSize: 13, height: 1.4)),
      );
}
