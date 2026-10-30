import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Vẽ một ảnh PNG ngẫu nhiên để đưa vào clipboard khi demo trên máy ảo.
Future<Uint8List> makeTestImage() async {
  final rnd = Random();
  final color = HSVColor.fromAHSV(1, rnd.nextDouble() * 360, 0.55, 0.85).toColor();
  const w = 480.0, h = 320.0;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(const Rect.fromLTWH(0, 0, w, h), Paint()..color = color);
  final now = TimeOfDay.now();
  final tp = TextPainter(
    text: TextSpan(
      text: 'Ảnh test\n${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
      style: const TextStyle(color: Colors.white, fontSize: 56, fontWeight: FontWeight.bold),
    ),
    textAlign: TextAlign.center,
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: w);
  tp.paint(canvas, Offset((w - tp.width) / 2, (h - tp.height) / 2));
  final img = await recorder.endRecording().toImage(w.toInt(), h.toInt());
  final data = await img.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}
