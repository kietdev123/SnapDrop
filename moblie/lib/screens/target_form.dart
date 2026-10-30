import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../attach/attachment_box.dart';
import '../data.dart';

/// Form đích, mở ra với ảnh đã đính kèm sẵn. Trả về câu thông báo khi gửi xong.
class TargetForm extends StatelessWidget {
  const TargetForm({super.key, required this.destination, required this.images});
  final Destination destination;
  final List<Uint8List> images;

  @override
  Widget build(BuildContext context) {
    final d = destination;
    final title = switch (d) {
      TicketDestination(:final ticket) => 'Bình luận vào ${ticket.code}',
      CreateDestination(:final kind) => kind.label,
      SavePendingDestination() => 'Ảnh chờ',
    };
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (d is TicketDestination) ...[
            Text(d.ticket.title, style: Theme.of(context).textTheme.titleMedium),
            Text(d.ticket.customer, style: TextStyle(color: Theme.of(context).colorScheme.outline)),
            const SizedBox(height: 16),
          ],
          if (d is CreateDestination) ...[
            const TextField(decoration: InputDecoration(labelText: 'Tiêu đề / tên', border: OutlineInputBorder())),
            const SizedBox(height: 16),
          ],
          AttachmentBox(
            label: d is TicketDestination ? 'Bình luận' : 'Nội dung',
            primary: true,
            hint: 'Ảnh đã đính kèm sẵn, thêm mô tả nếu cần…',
            submitLabel: d is TicketDestination ? 'Gửi' : 'Tạo',
            initialImages: images,
            onSubmit: (_, imgs) {
              if (d is TicketDestination) appState.touchRecent(d.ticket.code);
              Navigator.pop(context, 'Đã gửi ${imgs.length} ảnh → $title');
            },
          ),
        ],
      ),
    );
  }
}
