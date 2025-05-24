import 'package:flutter/material.dart';

/// Base class for all jigsaw puzzle related errors
abstract class JigsawError implements Exception {
  final String message;
  final String? details;
  final dynamic originalError;

  JigsawError(this.message, {this.details, this.originalError});

  @override
  String toString() => 'JigsawError: $message${details != null ? ' - $details' : ''}';
}

/// Error thrown when image loading fails
class JigsawImageLoadError extends JigsawError {
  JigsawImageLoadError(String message, {String? details, dynamic originalError})
      : super(message, details: details, originalError: originalError);
}

/// Error thrown when puzzle initialization fails
class JigsawInitializationError extends JigsawError {
  JigsawInitializationError(String message, {String? details, dynamic originalError})
      : super(message, details: details, originalError: originalError);
}

/// Error thrown when piece operations fail
class JigsawPieceOperationError extends JigsawError {
  JigsawPieceOperationError(String message, {String? details, dynamic originalError})
      : super(message, details: details, originalError: originalError);
}

/// Error thrown when game state operations fail
class JigsawGameStateError extends JigsawError {
  JigsawGameStateError(String message, {String? details, dynamic originalError})
      : super(message, details: details, originalError: originalError);
}

/// Utility class for handling jigsaw errors
class JigsawErrorHandler {
  /// Shows an error dialog to the user
  static Future<void> showErrorDialog(BuildContext context, JigsawError error) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(error.message),
              if (error.details != null) ...[
                const SizedBox(height: 8),
                Text(
                  error.details!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  /// Logs the error with additional context
  static void logError(JigsawError error, {String? context}) {
    debugPrint('Jigsaw Error${context != null ? ' in $context' : ''}: ${error.toString()}');
    if (error.originalError != null) {
      debugPrint('Original error: ${error.originalError}');
    }
  }

  /// Attempts to recover from an error
  static Future<bool> attemptRecovery(BuildContext context, JigsawError error) async {
    switch (error.runtimeType) {
      case JigsawImageLoadError:
        return _handleImageLoadError(context, error as JigsawImageLoadError);
      case JigsawInitializationError:
        return _handleInitializationError(context, error as JigsawInitializationError);
      case JigsawPieceOperationError:
        return _handlePieceOperationError(context, error as JigsawPieceOperationError);
      case JigsawGameStateError:
        return _handleGameStateError(context, error as JigsawGameStateError);
      default:
        return false;
    }
  }

  static Future<bool> _handleImageLoadError(BuildContext context, JigsawImageLoadError error) async {
    // Show retry dialog
    final bool? retry = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Image Load Error'),
          content: Text('Failed to load image: ${error.message}'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text('Retry'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );
    return retry ?? false;
  }

  static Future<bool> _handleInitializationError(BuildContext context, JigsawInitializationError error) async {
    // Show retry dialog with more options
    final String? action = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Puzzle Initialization Error'),
          content: Text('Failed to initialize puzzle: ${error.message}'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop('cancel'),
            ),
            TextButton(
              child: const Text('Retry'),
              onPressed: () => Navigator.of(context).pop('retry'),
            ),
            TextButton(
              child: const Text('Try Different Image'),
              onPressed: () => Navigator.of(context).pop('new_image'),
            ),
          ],
        );
      },
    );
    return action == 'retry' || action == 'new_image';
  }

  static Future<bool> _handlePieceOperationError(BuildContext context, JigsawPieceOperationError error) async {
    // Show retry dialog
    final bool? retry = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Piece Operation Error'),
          content: Text('Failed to perform piece operation: ${error.message}'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text('Retry'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );
    return retry ?? false;
  }

  static Future<bool> _handleGameStateError(BuildContext context, JigsawGameStateError error) async {
    // Show retry dialog with state recovery options
    final String? action = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Game State Error'),
          content: Text('Failed to update game state: ${error.message}'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop('cancel'),
            ),
            TextButton(
              child: const Text('Retry'),
              onPressed: () => Navigator.of(context).pop('retry'),
            ),
            TextButton(
              child: const Text('Reset Game'),
              onPressed: () => Navigator.of(context).pop('reset'),
            ),
          ],
        );
      },
    );
    return action == 'retry' || action == 'reset';
  }
} 