import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Một ô đính kèm đang hiển thị.
class AttachTarget {
  AttachTarget({required this.label, required this.primary, required this.focusNode, required this.context, required this.add});
  final String label;
  final bool primary;
  final FocusNode focusNode;
  final BuildContext Function() context;
  final void Function(Uint8List bytes) add;

  /// Ô nằm trên route đang ở trên cùng (bottom sheet / modal / màn hình hiện tại).
  bool get onTopRoute {
    final ctx = context();
    return ctx.mounted && (ModalRoute.of(ctx)?.isCurrent ?? true);
  }
}

/// Các ô đính kèm tự đăng ký. Registry chọn ô nhận ảnh theo thứ tự:
///   1. Ô đang focus
///   2. Ô trong form / modal / bottom sheet đang mở (route trên cùng)
///   3. Ô chính của màn hình (`primary`)
class AttachRegistry extends ChangeNotifier {
  final _targets = <AttachTarget>[];

  void register(AttachTarget t) {
    _targets.add(t);
    t.focusNode.addListener(_changed);
    _changed();
  }

  void unregister(AttachTarget t) {
    _targets.remove(t);
    t.focusNode.removeListener(_changed);
    _changed();
  }

  AttachTarget? get target {
    final visible = _targets.where((t) => t.onTopRoute).toList();
    if (visible.isEmpty) return null;
    return visible.where((t) => t.focusNode.hasFocus).firstOrNull ??
        visible.where((t) => t.primary).firstOrNull ??
        visible.first;
  }

  // Đăng ký diễn ra trong initState/dispose → báo sau frame.
  void _changed() => SchedulerBinding.instance.addPostFrameCallback((_) => notifyListeners());
}

final attachRegistry = AttachRegistry();
