import 'package:flutter/material.dart';

class HangmanFigure extends StatelessWidget {
  final int remainingAttempts;
  final Color color;

  const HangmanFigure({
    super.key,
    required this.remainingAttempts,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(200, 200),
      painter: HangmanPainter(
        remainingAttempts: remainingAttempts,
        color: color,
      ),
    );
  }
}

class HangmanPainter extends CustomPainter {
  final int remainingAttempts;
  final Color color;

  HangmanPainter({
    required this.remainingAttempts,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    // Draw the gallows
    if (remainingAttempts < 7) {
      // Base
      canvas.drawLine(
        const Offset(50, 180),
        const Offset(150, 180),
        paint,
      );
      // Pole
      canvas.drawLine(
        const Offset(100, 180),
        const Offset(100, 50),
        paint,
      );
      // Top
      canvas.drawLine(
        const Offset(100, 50),
        const Offset(150, 50),
        paint,
      );
      // Rope
      canvas.drawLine(
        const Offset(150, 50),
        const Offset(150, 80),
        paint,
      );
    }

    // Draw the head
    if (remainingAttempts < 6) {
      canvas.drawCircle(
        const Offset(150, 90),
        10,
        paint,
      );
    }

    // Draw the body
    if (remainingAttempts < 5) {
      canvas.drawLine(
        const Offset(150, 100),
        const Offset(150, 140),
        paint,
      );
    }

    // Draw the left arm
    if (remainingAttempts < 4) {
      canvas.drawLine(
        const Offset(150, 110),
        const Offset(130, 130),
        paint,
      );
    }

    // Draw the right arm
    if (remainingAttempts < 3) {
      canvas.drawLine(
        const Offset(150, 110),
        const Offset(170, 130),
        paint,
      );
    }

    // Draw the left leg
    if (remainingAttempts < 2) {
      canvas.drawLine(
        const Offset(150, 140),
        const Offset(130, 170),
        paint,
      );
    }

    // Draw the right leg
    if (remainingAttempts < 1) {
      canvas.drawLine(
        const Offset(150, 140),
        const Offset(170, 170),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
} 