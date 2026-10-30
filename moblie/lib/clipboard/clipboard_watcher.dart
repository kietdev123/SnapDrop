import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Một gợi ý "bạn vừa copy ảnh". Chưa có nội dung ảnh – chỉ có ID.
class ClipSuggestion {
  const ClipSuggestion(this.id, this.copiedAt);
  final String id;
  final DateTime copiedAt;
}

/// Bước 1: phát hiện ảnh mới mỗi khi app vào foreground.
///
/// Chỉ hỏi native "clipboard có ảnh không" (iOS `hasImages` + `changeCount`,
/// Android `ClipDescription` + timestamp). Nội dung ảnh chỉ được đọc qua
/// [readImage] khi người dùng bấm chip / banner.
class ClipboardWatcher extends ChangeNotifier with WidgetsBindingObserver {
  static const _channel = MethodChannel('snapdrop/clipboard');
  static const _prefsHandled = 'clip.handled';
  static const _prefsFirstSeen = 'clip.firstSeen';

  /// Chỉ gợi ý ảnh copy trong khoảng thời gian này.
  static const freshness = Duration(minutes: 5);

  ClipSuggestion? _suggestion;
  ClipSuggestion? get suggestion => _suggestion;

  late SharedPreferences _prefs;
  final _handled = <String>{};
  final _firstSeen = <String, int>{};

  Future<void> start() async {
    _prefs = await SharedPreferences.getInstance();
    _handled.addAll(_prefs.getStringList(_prefsHandled) ?? const []);
    final seen = _prefs.getString(_prefsFirstSeen);
    if (seen != null) _firstSeen.addAll(Map<String, int>.from(jsonDecode(seen) as Map));
    WidgetsBinding.instance.addObserver(this);
    await check();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Android chỉ cho đọc clipboard khi app đã có focus → chờ một nhịp.
    if (state == AppLifecycleState.resumed) {
      Future.delayed(const Duration(milliseconds: 300), check);
    }
  }

  Future<void> check() async {
    Map<String, dynamic>? r;
    try {
      r = await _channel.invokeMapMethod<String, dynamic>('peek');
    } on PlatformException catch (e) {
      debugPrint('peek lỗi: $e');
    }
    if (r == null || r['hasImage'] != true) return _set(null);

    final id = r['id'] as String;
    if (_handled.contains(id)) return _set(null);

    final now = DateTime.now();
    final ageMs = r['ageMs'] as int?;
    final DateTime copiedAt;
    if (ageMs != null) {
      copiedAt = now.subtract(Duration(milliseconds: ageMs));
    } else {
      // iOS không có timestamp: tự ghi lại lúc phát hiện lần đầu.
      final first = _firstSeen.putIfAbsent(id, () => now.millisecondsSinceEpoch);
      copiedAt = DateTime.fromMillisecondsSinceEpoch(first);
      _saveFirstSeen();
    }
    if (now.difference(copiedAt) > freshness) return _set(null);
    _set(ClipSuggestion(id, copiedAt));
  }

  /// Đọc nội dung ảnh thật. Chỉ gọi khi người dùng chủ động bấm.
  /// iOS 16+ có thể hiện hộp thoại "Cho phép dán".
  Future<Uint8List?> readImage() => _channel.invokeMethod<Uint8List>('readImage');

  /// Đã dùng / đã gửi / người dùng tắt gợi ý → không gợi ý lại ảnh này.
  void markHandled(String id) {
    _handled.add(id);
    final list = _handled.toList();
    _prefs.setStringList(_prefsHandled, list.length > 50 ? list.sublist(list.length - 50) : list);
    if (_suggestion?.id == id) _set(null);
  }

  void dismiss() {
    final s = _suggestion;
    if (s != null) markHandled(s.id);
  }

  /// Chỉ dùng để demo trên máy ảo: đưa một ảnh vào clipboard.
  Future<void> writeTestImage(Uint8List png) async {
    await _channel.invokeMethod('writeTestImage', png);
    await check();
  }

  void _set(ClipSuggestion? s) {
    if (s?.id == _suggestion?.id) return;
    _suggestion = s;
    notifyListeners();
  }

  void _saveFirstSeen() {
    if (_firstSeen.length > 50) {
      final keys = _firstSeen.keys.toList()..sort((a, b) => _firstSeen[a]!.compareTo(_firstSeen[b]!));
      for (final k in keys.take(_firstSeen.length - 50)) {
        _firstSeen.remove(k);
      }
    }
    _prefs.setString(_prefsFirstSeen, jsonEncode(_firstSeen));
  }
}

final clipboardWatcher = ClipboardWatcher();
