import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show ByteData, Uint8List, rootBundle;
import '../models/jigsaw_piece.dart';
import '../models/jigsaw_puzzle.dart';
import 'package:puzzle_master/utils/jigsaw_utils.dart';
import 'package:puzzle_master/utils/jigsaw_errors.dart';
import '../widgets/jigsaw_image_selection_dialog.dart';
import '../widgets/jigsaw_piece_widget.dart';

class JigsawPuzzleScreen extends StatefulWidget {
  const JigsawPuzzleScreen({super.key});

  @override
  State<JigsawPuzzleScreen> createState() => _JigsawPuzzleScreenState();
}

class _JigsawPuzzleScreenState extends State<JigsawPuzzleScreen> {
  JigsawPuzzle? _puzzle;
  JigsawPiece? _selectedPiece;
  Offset? _dragOffset;
  bool _isLoading = false;
  String? _currentImagePath;
  ui.Image? _backgroundImage;
  final GlobalKey _boardKey = GlobalKey();
  Size _boardSize = Size.zero;

  @override
  void initState() {
    super.initState();
    _showNewGameDialog();
  }

  Future<ui.Image> _loadImage(String assetPath) async {
    try {
      final ByteData data = await rootBundle.load(assetPath);
      final Completer<ui.Image> completer = Completer();
      ui.decodeImageFromList(Uint8List.view(data.buffer), completer.complete);
      return completer.future;
    } catch (e) {
      debugPrint('Error loading image: $e');
      rethrow;
    }
  }

  Future<void> _initializePuzzle(String imagePath, String difficulty) async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _currentImagePath = imagePath;
    });

    try {
      final image = await _loadImage(imagePath);
      if (!mounted) return;

      // Wait for the board size to be available
      await _waitForBoardSize();

      final puzzle = await JigsawPuzzle.create(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        image: image,
        difficulty: difficulty,
        boardSize: _boardSize,
      );

      puzzle.shufflePieces();

      if (mounted) {
        setState(() {
          _puzzle = puzzle;
          _backgroundImage = image;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Failed to initialize puzzle', e.toString());
      }
    }
  }

  Future<void> _waitForBoardSize() async {
    int attempts = 0;
    const maxAttempts = 10;

    while (attempts < maxAttempts) {
      final context = _boardKey.currentContext;
      if (context != null) {
        final box = context.findRenderObject() as RenderBox?;
        if (box != null) {
          final size = box.size;
          if (size.width > 0 && size.height > 0) {
            setState(() => _boardSize = size);
            return;
          }
        }
      }
      await Future.delayed(const Duration(milliseconds: 100));
      attempts++;
    }
    throw Exception('Could not determine board size');
  }

  void _showNewGameDialog() async {
    final result = await showJigsawImageSelectionDialog(context);
    if (result != null && mounted) {
      await _initializePuzzle(result.imagePath, result.difficulty);
    }
  }

  void _onPiecePanStart(JigsawPiece piece, Offset position) {
    if (piece.isAssembled) return;

    setState(() {
      _selectedPiece = piece;
      _dragOffset = position - piece.position;
    });
  }

  void _onPiecePanUpdate(Offset position) {
    if (_selectedPiece == null || _dragOffset == null) return;

    setState(() {
      _selectedPiece!.position = position - _dragOffset!;
    });
  }

  void _onPiecePanEnd() {
    if (_selectedPiece == null) return;

    // Check if the piece is close to its correct position
    if (_selectedPiece!.isCorrectlyPlaced()) {
      setState(() {
        _selectedPiece!.position = _selectedPiece!.correctPosition;
        _selectedPiece!.rotation = 0;
        _selectedPiece!.isAssembled = true;
      });

      // Check if the puzzle is complete
      _puzzle?.checkCompletion();
      if (_puzzle?.isComplete ?? false) {
        _showCompletionDialog();
      }
    }

    setState(() {
      _selectedPiece = null;
      _dragOffset = null;
    });
  }

  void _onPieceTap(JigsawPiece piece) {
    if (piece.isAssembled) return;

    setState(() {
      piece.rotate();
    });
  }

  void _showError(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Congratulations!'),
        content: const Text('You have completed the puzzle!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showNewGameDialog();
            },
            child: const Text('New Game'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jigsaw Puzzle'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _showNewGameDialog,
            tooltip: 'New Game',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _puzzle == null
              ? const Center(child: Text('Select an image to start'))
              : LayoutBuilder(
                  builder: (context, constraints) {
                    return Row(
                      children: [
                        // Game Board
                        Expanded(
                          flex: 3,
                          child: Container(
                            key: _boardKey,
                            color: Colors.grey[200],
                            child: Stack(
                              children: [
                                // Background image preview
                                if (_backgroundImage != null)
                                  Opacity(
                                    opacity: 0.2,
                                    child: RawImage(
                                      image: _backgroundImage,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                // Puzzle pieces
                                ..._puzzle!.pieces.map((piece) {
                                  if (piece.isAssembled) return const SizedBox.shrink();
                                  return Positioned(
                                    left: piece.position.dx,
                                    top: piece.position.dy,
                                    child: GestureDetector(
                                      onPanStart: (details) => _onPiecePanStart(
                                        piece,
                                        details.globalPosition,
                                      ),
                                      onPanUpdate: (details) => _onPiecePanUpdate(
                                        details.globalPosition,
                                      ),
                                      onPanEnd: (_) => _onPiecePanEnd(),
                                      onTap: () => _onPieceTap(piece),
                                      child: JigsawPieceWidget(
                                        piece: piece,
                                        isSelected: _selectedPiece?.id == piece.id,
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ),
                        // Piece Tray
                        Expanded(
                          flex: 1,
                          child: Container(
                            color: Colors.grey[100],
                            padding: const EdgeInsets.all(8),
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _puzzle!.pieces.length,
                              itemBuilder: (context, index) {
                                final piece = _puzzle!.pieces[index];
                                if (!piece.isAssembled) return const SizedBox.shrink();
                                return Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: JigsawPieceWidget(
                                    piece: piece,
                                    isSelected: _selectedPiece?.id == piece.id,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
    );
  }
}
