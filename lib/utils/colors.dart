import 'package:flutter/material.dart';

String colorToHexs(Color color) {
  final int argb = color.toARGB32();
  return '#${argb.toRadixString(16).padLeft(8, '0').substring(2)}';
}

Color? hexToColors(String? hex) {
  if (hex == null || hex.isEmpty) return null;

  final buffer = StringBuffer();
  if (hex.length == 6 || hex.length == 7) buffer.write('ff');
  buffer.write(hex.replaceFirst('#', ''));

  return Color(int.parse(buffer.toString(), radix: 16));
}
