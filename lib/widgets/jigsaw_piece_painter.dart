import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class JigsawPiecePainter extends CustomPainter {
  final ui.Image imageChunk;
  final double rotationAngle; // in radians
  final Color? borderColor;
  final double borderWidth;
  final bool isSelected;

  JigsawPiecePainter({
    required this.imageChunk,
    required this.rotationAngle,
    this.borderColor,
    this.borderWidth = 1.0,
    this.isSelected = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // size is the size of the CustomPaint widget itself

    final Paint paint = Paint();

    // Center the image chunk within the painter's canvas
    final double pieceWidth = imageChunk.width.toDouble();
    final double pieceHeight = imageChunk.height.toDouble();

    // Translate to the center of the piece for rotation
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(rotationAngle);
    canvas.translate(-pieceWidth / 2, -pieceHeight / 2);

    // Draw the image chunk
    // Assuming the imageChunk is already the correct display size.
    // If not, scaling would be needed here or before creating the imageChunk.
    // For simplicity, we draw it at its native resolution centered.
    final Rect srcRect = Rect.fromLTWH(0, 0, pieceWidth, pieceHeight);
    final Rect dstRect = Rect.fromLTWH(0, 0, pieceWidth, pieceHeight);
    canvas.drawImageRect(imageChunk, srcRect, dstRect, paint);

    // Optionally draw a border
    if (borderColor != null) {
      final Paint borderPaint = Paint()
        ..color = isSelected ? Colors.blue.withAlpha((255 * 0.7).round()) : borderColor!
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? borderWidth * 2.5 : borderWidth;
      canvas.drawRect(dstRect, borderPaint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant JigsawPiecePainter oldDelegate) {
    return oldDelegate.imageChunk != imageChunk ||
        oldDelegate.rotationAngle != rotationAngle ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.borderWidth != borderWidth ||
        oldDelegate.isSelected != isSelected;
  }
}
