import 'dart:io';

import 'package:flutter/services.dart';

/// Nhận ảnh share từ app khác (Zalo, Ảnh, Files…). Hiện chỉ có Android.
///
/// Native đọc sẵn bytes ảnh (quyền đọc URI chỉ đi kèm intent share),
/// Dart nhận qua:
///   - `takeInitialShare`: app được mở nguội từ share
///   - `onShare`: app đang chạy thì nhận thêm share
class ShareReceiver {
  static const _channel = MethodChannel('snapdrop/share');

  static Future<void> start(void Function(List<Uint8List> images) onImages) async {
    if (!Platform.isAndroid) return;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onShare') {
        final images = (call.arguments as List).cast<Uint8List>();
        if (images.isNotEmpty) onImages(images);
      }
    });
    final initial = await _channel.invokeListMethod<Uint8List>('takeInitialShare');
    if (initial != null && initial.isNotEmpty) onImages(initial);
  }
}
