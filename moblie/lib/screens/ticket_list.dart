import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../clipboard/clipboard_watcher.dart';
import '../data.dart';
import 'destination_picker.dart';

/// Ví dụ 2 – Trang KHÔNG có ô đính kèm (nhánh 2b).
/// Clipboard có ảnh mới → banner cuối màn hình "Bạn vừa copy 1 ảnh — Đính kèm vào…".
class TicketListScreen extends StatelessWidget {
  const TicketListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      children: [
        ListenableBuilder(
          listenable: appState,
          builder: (context, _) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              if (appState.pending.isNotEmpty) ...[
                Text('🗂️ Ảnh chờ (${appState.pending.length})', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                SizedBox(
                  height: 110,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [for (final img in appState.pending) _PendingTile(img)],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              for (final t in tickets)
                Card.outlined(
                  child: ListTile(
                    title: Text(t.title),
                    subtitle: Text('${t.code} · ${t.customer}'),
                    trailing: Text(t.status, style: TextStyle(color: scheme.outline, fontSize: 12)),
                  ),
                ),
            ],
          ),
        ),
        const Positioned(left: 12, right: 12, bottom: 12, child: SafeArea(top: false, child: ClipBanner())),
      ],
    );
  }
}

/// Banner không tự biến mất: chỉ ẩn khi người dùng ✕ hoặc clipboard đổi sang ảnh khác.
class ClipBanner extends StatelessWidget {
  const ClipBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: clipboardWatcher,
      builder: (context, _) {
        final s = clipboardWatcher.suggestion;
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, a) => SlideTransition(
            position: Tween(begin: const Offset(0, 1), end: Offset.zero).animate(a),
            child: FadeTransition(opacity: a, child: child),
          ),
          child: s == null
              ? const SizedBox.shrink()
              : Material(
                  key: ValueKey(s.id),
                  color: scheme.primary,
                  elevation: 6,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => runDestinationFlow(
                      context,
                      loadImage: clipboardWatcher.readImage,
                      onUsed: () => clipboardWatcher.markHandled(s.id),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 6, 4, 6),
                      child: Row(
                        children: [
                          Text.rich(
                            TextSpan(children: [
                              const TextSpan(text: '📋  Bạn vừa copy 1 ảnh — '),
                              const TextSpan(text: 'Đính kèm vào…', style: TextStyle(fontWeight: FontWeight.bold)),
                            ]),
                            style: TextStyle(color: scheme.onPrimary),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: Icon(Icons.close, color: scheme.onPrimary),
                            tooltip: 'Không gợi ý ảnh này nữa',
                            onPressed: clipboardWatcher.dismiss,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }
}

class _PendingTile extends StatelessWidget {
  const _PendingTile(this.bytes);
  final Uint8List bytes;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => runDestinationFlow(
          context,
          allowSavePending: false,
          loadImage: () async => bytes,
          onUsed: () => appState.removePending(bytes),
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.memory(bytes, width: 120, height: 110, fit: BoxFit.cover),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(10)),
                ),
                child: const Text('Đính kèm vào…', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
