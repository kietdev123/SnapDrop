import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../data.dart';
import 'target_form.dart';

/// Màn hình chọn đích đến – dùng chung cho banner, share từ Zalo và "Ảnh chờ".
class DestinationPicker extends StatefulWidget {
  const DestinationPicker({super.key, this.currentPage, this.allowSavePending = true});

  /// Khi vào từ share: trang có ô đính kèm đang mở được đưa lên đầu.
  final Ticket? currentPage;
  final bool allowSavePending;

  @override
  State<DestinationPicker> createState() => _DestinationPickerState();
}

class _DestinationPickerState extends State<DestinationPicker> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final q = _q.trim().toLowerCase();
    final results = q.isEmpty
        ? const <Ticket>[]
        : tickets.where((t) => '${t.code} ${t.title} ${t.customer}'.toLowerCase().contains(q)).toList();
    final recent = appState.recent.map((c) => tickets.firstWhere((t) => t.code == c)).toList();
    void pick(Destination d) => Navigator.pop(context, d);

    return Scaffold(
      appBar: AppBar(title: const Text('Đính kèm vào…')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: SearchBar(
              hintText: 'Tìm theo mã hoặc tên',
              leading: const Icon(Icons.search),
              elevation: const WidgetStatePropertyAll(0),
              onChanged: (v) => setState(() => _q = v),
            ),
          ),
          if (q.isNotEmpty) ...[
            const _Header('Kết quả tìm kiếm'),
            if (results.isEmpty) const ListTile(title: Text('Không tìm thấy.')),
            for (final t in results) _ticketTile(t, Icons.description_outlined, pick),
          ] else ...[
            if (widget.currentPage != null) ...[
              const _Header('Trang đang mở'),
              _ticketTile(widget.currentPage!, Icons.push_pin_outlined, pick),
            ],
            const _Header('Tạo mới'),
            for (final k in createByRole[appState.role]!)
              ListTile(
                leading: Text(k.icon, style: const TextStyle(fontSize: 22)),
                title: Text(k.label),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => pick(CreateDestination(k)),
              ),
            const _Header('Gần đây'),
            for (final t in recent) _ticketTile(t, Icons.history, pick),
            if (widget.allowSavePending) ...[
              const _Header('Để sau'),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Lưu vào Ảnh chờ'),
                subtitle: const Text('Quyết định đính kèm vào đâu sau'),
                onTap: () => pick(SavePendingDestination()),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _ticketTile(Ticket t, IconData icon, void Function(Destination) pick) => ListTile(
        leading: Icon(icon),
        title: Text('${t.code} · ${t.title}', maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(t.customer),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => pick(TicketDestination(t)),
      );
}

class _Header extends StatelessWidget {
  const _Header(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Text(text.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.outline, letterSpacing: 0.6)),
      );
}

/// Luồng đầy đủ: chọn đích → đọc ảnh → mở form đích với ảnh đã đính kèm sẵn.
/// [loadImage] chỉ được gọi sau khi người dùng đã chọn (lúc này mới đọc clipboard).
Future<void> runDestinationFlow(
  BuildContext context, {
  required Future<Uint8List?> Function() loadImage,
  VoidCallback? onUsed,
  bool allowSavePending = true,
}) async {
  final dest = await Navigator.push<Destination>(
    context,
    MaterialPageRoute(builder: (_) => DestinationPicker(allowSavePending: allowSavePending)),
  );
  if (dest == null || !context.mounted) return;

  final bytes = await loadImage();
  if (!context.mounted) return;
  if (bytes == null) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không đọc được ảnh từ clipboard.')));
    return;
  }
  onUsed?.call();

  if (dest is SavePendingDestination) {
    appState.addPending(bytes);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã lưu vào Ảnh chờ')));
    return;
  }
  final sent = await Navigator.push<String>(
    context,
    MaterialPageRoute(builder: (_) => TargetForm(destination: dest, images: [bytes])),
  );
  if (sent != null && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(sent)));
  }
}
