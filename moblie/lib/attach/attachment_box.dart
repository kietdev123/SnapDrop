import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../clipboard/clipboard_watcher.dart';
import 'attach_registry.dart';

class _Attachment {
  _Attachment(this.bytes);
  final Uint8List bytes;
  double progress = 0;
}

/// Component đính kèm dùng chung. Mỗi màn hình khai báo ô chính bằng [primary].
///
/// Nhánh 2a: khi clipboard có ảnh mới và ô này là đích, hiện chip
/// "📋 Dán ảnh vừa copy" cạnh nút đính kèm (không thumbnail vì chưa đọc ảnh).
class AttachmentBox extends StatefulWidget {
  const AttachmentBox({
    super.key,
    required this.label,
    this.primary = false,
    this.hint = 'Viết bình luận…',
    this.submitLabel = 'Gửi',
    this.initialImages = const [],
    this.onSubmit,
  });

  final String label;
  final bool primary;
  final String hint;
  final String submitLabel;
  final List<Uint8List> initialImages;
  final void Function(String text, List<Uint8List> images)? onSubmit;

  @override
  State<AttachmentBox> createState() => _AttachmentBoxState();
}

class _AttachmentBoxState extends State<AttachmentBox> {
  final _focus = FocusNode();
  final _text = TextEditingController();
  final _items = <_Attachment>[];
  final _timers = <Timer>[];
  late final AttachTarget _target;
  bool _reading = false;

  @override
  void initState() {
    super.initState();
    _target = AttachTarget(
      label: widget.label,
      primary: widget.primary,
      focusNode: _focus,
      context: () => context,
      add: _add,
    );
    attachRegistry.register(_target);
    widget.initialImages.forEach(_add);
  }

  @override
  void dispose() {
    attachRegistry.unregister(_target);
    for (final t in _timers) {
      t.cancel();
    }
    _focus.dispose();
    _text.dispose();
    super.dispose();
  }

  void _add(Uint8List bytes) {
    final a = _Attachment(bytes);
    setState(() => _items.add(a));
    // Upload nền ngay khi ảnh vào ô (giả lập).
    final rnd = Random();
    _timers.add(Timer.periodic(const Duration(milliseconds: 180), (t) {
      if (!mounted) return t.cancel();
      setState(() => a.progress = min(1, a.progress + 0.08 + rnd.nextDouble() * 0.15));
      if (a.progress >= 1) t.cancel();
    }));
  }

  Future<void> _pasteSuggested(ClipSuggestion s) async {
    setState(() => _reading = true);
    try {
      final bytes = await clipboardWatcher.readImage();
      if (bytes == null) {
        _snack('Không đọc được ảnh (có thể bạn đã từ chối quyền dán).');
        return;
      }
      _add(bytes);
      clipboardWatcher.markHandled(s.id);
    } catch (e) {
      _snack('Lỗi đọc clipboard: $e');
    } finally {
      if (mounted) setState(() => _reading = false);
    }
  }

  void _submit() {
    widget.onSubmit?.call(_text.text, _items.map((a) => a.bytes).toList());
    setState(() {
      _text.clear();
      _items.clear();
    });
    _focus.unfocus();
  }

  void _snack(String msg) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final uploading = _items.any((a) => a.progress < 1);

    return ListenableBuilder(
      listenable: Listenable.merge([clipboardWatcher, attachRegistry, _focus]),
      builder: (context, _) {
        final suggestion = clipboardWatcher.suggestion;
        final isTarget = attachRegistry.target == _target;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isTarget && suggestion != null ? scheme.primary : scheme.outlineVariant, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.label, style: Theme.of(context).textTheme.labelLarge),
              TextField(
                focusNode: _focus,
                controller: _text,
                minLines: 1,
                maxLines: 4,
                decoration: InputDecoration(hintText: widget.hint, border: InputBorder.none, isDense: true),
              ),
              if (_items.isNotEmpty)
                SizedBox(
                  height: 76,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _items.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (_, i) => _Thumb(
                      item: _items[i],
                      onRemove: () => setState(() => _items.removeAt(i)),
                    ),
                  ),
                ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.attach_file),
                    tooltip: 'Đính kèm',
                    onPressed: () => _snack('Demo: chọn ảnh từ thư viện chưa làm – hãy thử chip dán ảnh.'),
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: isTarget && suggestion != null
                          ? _PasteChip(
                              loading: _reading,
                              onTap: () => _pasteSuggested(suggestion),
                              onClose: clipboardWatcher.dismiss,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: uploading ? null : _submit,
                    child: Text(uploading ? 'Đang tải…' : widget.submitLabel),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PasteChip extends StatelessWidget {
  const _PasteChip({required this.loading, required this.onTap, required this.onClose});
  final bool loading;
  final VoidCallback onTap;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return InputChip(
      avatar: loading
          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
          : const Text('📋'),
      label: const Text('Dán ảnh vừa copy', overflow: TextOverflow.ellipsis),
      onPressed: loading ? null : onTap,
      onDeleted: onClose,
      deleteButtonTooltipMessage: 'Không gợi ý ảnh này nữa',
      visualDensity: VisualDensity.compact,
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.item, required this.onRemove});
  final _Attachment item;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 76,
        height: 76,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.memory(item.bytes, fit: BoxFit.cover, gaplessPlayback: true),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: item.progress < 1
                  ? LinearProgressIndicator(value: item.progress, minHeight: 4)
                  : const Align(
                      alignment: Alignment.bottomLeft,
                      child: Padding(
                        padding: EdgeInsets.all(4),
                        child: CircleAvatar(radius: 9, backgroundColor: Colors.green, child: Icon(Icons.check, size: 12, color: Colors.white)),
                      ),
                    ),
            ),
            Positioned(
              top: 2,
              right: 2,
              child: GestureDetector(
                onTap: onRemove,
                child: const CircleAvatar(radius: 10, backgroundColor: Colors.black54, child: Icon(Icons.close, size: 12, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
