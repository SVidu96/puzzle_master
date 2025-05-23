import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show ByteData, Uint8List, rootBundle;
import 'package:puzzle_master/models/jigsaw_piece_model.dart';
import 'package:puzzle_master/models/jigsaw_puzzle_model.dart';
import 'package:puzzle_master/utils/jigsaw_utils.dart';
import 'package:puzzle_master/widgets/jigsaw_image_selection_dialog.dart';
import 'package:puzzle_master/widgets/jigsaw_piece_widget.dart';

class JigsawPuzzleScreen extends StatefulWidget {
  const JigsawPuzzleScreen({super.key});

  @override
  State<JigsawPuzzleScreen> createState() => _JigsawPuzzleScreenState();
}

class _JigsawPuzzleScreenState extends State<JigsawPuzzleScreen> {
  JigsawPuzzle? _currentPuzzle;
  List<JigsawPiece> _displayedPieces = []; // Pieces in the tray
  List<JigsawPiece> _boardPieces = []; // Pieces on the game board
  JigsawPiece? _selectedPiece;
  Offset? _dragOffset; // Offset of pointer from piece's top-left
  bool _isLoading = false;
  String? _currentPuzzleImageKey; // To help identify the current puzzle image

  // Game board properties - will be determined after layout
  Size _gameBoardSize = Size.zero;
  Offset _gameBoardOffset = Offset.zero;
  final GlobalKey _gameBoardKey = GlobalKey();

  // Helper to load ui.Image from asset path
  Future<ui.Image> _loadUiImage(String assetPath) async {
    final ByteData data = await rootBundle.load(assetPath);
    final Completer<ui.Image> completer = Completer();
    ui.decodeImageFromList(Uint8List.view(data.buffer), (ui.Image img) {
      completer.complete(img);
    });
    return completer.future;
  }

  @override
  void initState() {
    super.initState();
    // Use WidgetsBinding.instance.addPostFrameCallback to safely access layout info
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showNewGameDialog();
      _determineGameBoardSizeAndOffset();
    });
  }

  void _determineGameBoardSizeAndOffset() {
    if (_gameBoardKey.currentContext != null) {
      final RenderBox renderBox =
          _gameBoardKey.currentContext!.findRenderObject() as RenderBox;
      setState(() {
        _gameBoardSize = renderBox.size;
        _gameBoardOffset = renderBox.localToGlobal(Offset.zero);
      });
      debugPrint("Game board size: $_gameBoardSize, Offset: $_gameBoardOffset");
       // If a puzzle exists, re-initialize with correct board size
      if (_currentPuzzle != null && _currentPuzzleImageKey != null) {
        _initializePuzzle(_currentPuzzleImageKey!, _currentPuzzle!.difficulty);
      }
    } else {
       debugPrint("Game board context not available yet.");
    }
  }

  Future<void> _initializePuzzle(String imagePath, String difficulty) async {
    setState(() {
      _isLoading = true;
      _currentPuzzleImageKey = imagePath; // Store for potential re-initialization
    });

    try {
      final ui.Image originalImage = await _loadUiImage(imagePath);

      // Determine grid size based on difficulty
      Size gridSize;
      if (difficulty == 'Easy') {
        gridSize = const Size(3, 2); // 6 pieces
      } else if (difficulty == 'Medium') {
        gridSize = const Size(4, 3); // 12 pieces
      } else {
        // Hard
        gridSize = const Size(5, 4); // 20 pieces
      }

      // Ensure gameBoardSize is available, otherwise pieces will have 0 dimensions
      if (_gameBoardSize == Size.zero) {
        // This can happen if _initializePuzzle is called before layout is complete.
        // Schedule a re-call after layout.
        WidgetsBinding.instance.addPostFrameCallback((_) {
           _determineGameBoardSizeAndOffset(); // try to get it again
           if (_gameBoardSize != Size.zero) {
            _initializePuzzle(imagePath, difficulty);
           } else {
            debugPrint("Error: Game board size not determined. Cannot initialize puzzle.");
            // Show an error to the user or retry logic
             setState(() => _isLoading = false);
           }
        });
        return;
      }
      
      final JigsawPuzzle puzzle = await JigsawUtils.sliceImageIntoPieces(
        puzzleId: DateTime.now().millisecondsSinceEpoch.toString(),
        image: originalImage,
        gridSize: gridSize,
        difficulty: difficulty,
        boardSize: _gameBoardSize, // Use the determined game board size
      );

      puzzle.shufflePieces(_gameBoardSize); // Shuffle based on available board area for tray (for now)

      setState(() {
        _currentPuzzle = puzzle;
        _displayedPieces = List.from(puzzle.pieces);
        _boardPieces = [];
        _selectedPiece = null;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error initializing puzzle: $e");
      setState(() {
        _isLoading = false;
      });
      // Show error dialog
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading puzzle: ${e.toString()}')),
        );
      }
    }
  }

  void _showNewGameDialog() async {
    final JigsawSelectionResult? result =
        await showJigsawImageSelectionDialog(context);
    if (result != null && mounted) {
      _initializePuzzle(result.imagePath, result.difficulty);
    }
  }

  void _restartPuzzle() {
    if (_currentPuzzle != null) {
      // Re-shuffle and reset positions
      _currentPuzzle!.shufflePieces(_gameBoardSize); // Or tray area if different
      setState(() {
        _displayedPieces = List.from(_currentPuzzle!.pieces);
        _boardPieces = [];
        _selectedPiece = null;
        // Reset assembled state for all pieces
        for (var piece in _currentPuzzle!.pieces) {
          piece.isAssembled = false;
          piece.connectedTo.clear();
        }
      });
    } else {
      _showNewGameDialog(); // Or handle as an error / prompt to start a new game
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine game board size post-layout if not already done
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_gameBoardSize == Size.zero && _gameBoardKey.currentContext != null) {
        _determineGameBoardSizeAndOffset();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Jigsaw Puzzle'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Restart Puzzle',
            onPressed: _restartPuzzle,
          ),
          IconButton(
            icon: const Icon(Icons.add_photo_alternate),
            tooltip: 'New Game',
            onPressed: _showNewGameDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentPuzzle == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('No puzzle loaded.'),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _showNewGameDialog,
                        child: const Text('Start New Game'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Game Board Area
                    Expanded(
                      key: const Key('jigsaw_game_board_area'), // Added Key
                      flex: 3, // Takes 3/4 of the vertical space
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          // Use LayoutBuilder to get dimensions for the game board area
                          // This is a more reliable spot to set _gameBoardSize if not already set
                          // However, _determineGameBoardSizeAndOffset uses a GlobalKey which is also fine.
                          // Ensure this doesn't cause rapid setState calls during build.
                          final availableWidth = constraints.maxWidth;
                          final availableHeight = constraints.maxHeight;

                          // Calculate aspect ratio of the original image
                          final originalImageAspectRatio = _currentPuzzle!.originalImage.width / _currentPuzzle!.originalImage.height;
                          
                          double boardDisplayWidth = availableWidth;
                          double boardDisplayHeight = availableWidth / originalImageAspectRatio;

                          if (boardDisplayHeight > availableHeight) {
                            boardDisplayHeight = availableHeight;
                            boardDisplayWidth = availableHeight * originalImageAspectRatio;
                          }
                          
                          // Update gameBoardSize if it changed significantly or not set
                          // This needs to be done carefully to avoid build loops
                          if (_gameBoardSize.width.round() != boardDisplayWidth.round() || 
                              _gameBoardSize.height.round() != boardDisplayHeight.round()) {
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                   // Check if mounted because this is in a callback
                                  if(mounted && (_gameBoardSize.width.round() != boardDisplayWidth.round() || 
                                      _gameBoardSize.height.round() != boardDisplayHeight.round())) {
                                    debugPrint("GameBoard size updated by LayoutBuilder: W$boardDisplayWidth H$boardDisplayHeight");
                                    setState(() {
                                      _gameBoardSize = Size(boardDisplayWidth, boardDisplayHeight);
                                    });
                                    // Potentially re-initialize puzzle if board size is critical for piece scaling
                                    // and has changed substantially. This can be complex.
                                    // For now, we assume initial _determineGameBoardSizeAndOffset is sufficient
                                    // or that pieces can adapt. The current JigsawUtils.sliceImageIntoPieces
                                    // uses the boardSize passed at initialization.
                                  }
                                });
                          }


                          return Stack(
                            key: _gameBoardKey, // GlobalKey to get offset and size
                            alignment: Alignment.center, // Center the board in the available space
                            children: [
                              // Faint Preview of Original Image (scaled)
                              if (_currentPuzzle != null && _gameBoardSize != Size.zero)
                                Opacity(
                                  opacity: 0.2,
                                  child: Container(
                                    width: _gameBoardSize.width,
                                    height: _gameBoardSize.height,
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      image: DecorationImage(
                                        image: // We need a provider for ui.Image
                                            // For now, using a trick: draw it with CustomPaint
                                            // This is inefficient for just a preview.
                                            // A better way would be to convert ui.Image to MemoryImage if possible
                                            // or save the original asset path to use Image.asset here.
                                            // Let's assume we have the original asset path for preview
                                            AssetImage(_currentPuzzleImageKey!),
                                        fit: BoxFit.contain, // or BoxFit.fill based on how boardSize is calculated
                                      ),
                                    ),
                                  ),
                                ),
                              
                              // Placed Pieces on Board
                              ..._boardPieces.map((piece) => Positioned(
                                    left: piece.currentPosition.dx,
                                    top: piece.currentPosition.dy,
                                    child: GestureDetector(
                                      onPanStart: (details) => _onPiecePanStart(piece, details.globalPosition),
                                      onPanUpdate: (details) => _onPiecePanUpdate(piece, details.globalPosition),
                                      onPanEnd: (details) => _onPiecePanEnd(piece),
                                      onTap: () => _onPieceTap(piece),
                                      child: JigsawPieceWidget(
                                        piece: piece,
                                        isSelected: _selectedPiece?.id == piece.id,
                                      ),
                                    ),
                                  )),
                               // Dragging Piece (if any) - rendered on top
                              if (_selectedPiece != null && _dragOffset != null)
                                Positioned(
                                  left: _selectedPiece!.currentPosition.dx,
                                  top: _selectedPiece!.currentPosition.dy,
                                  child: Opacity(
                                    opacity: 0.7, // Make dragged piece slightly transparent
                                    child: JigsawPieceWidget(
                                      piece: _selectedPiece!,
                                      isSelected: true,
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                    // Piece Tray Area
                    Expanded(
                      key: const Key('jigsaw_piece_tray_area'), // Added Key
                      flex: 1, // Takes 1/4 of the vertical space
                      child: Container(
                        color: Colors.blueGrey[100],
                        padding: const EdgeInsets.all(8.0),
                        child: _displayedPieces.isEmpty
                            ? const Center(child: Text('Tray is empty or all pieces on board.'))
                            : ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _displayedPieces.length,
                                itemBuilder: (context, index) {
                                  final piece = _displayedPieces[index];
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                    child: GestureDetector(
                                      onPanStart: (details) => _onPiecePanStart(piece, details.globalPosition, isFromTray: true),
                                      onPanUpdate: (details) => _onPiecePanUpdate(piece, details.globalPosition),
                                      onPanEnd: (details) => _onPiecePanEnd(piece),
                                      onTap: () => _onPieceTap(piece, isFromTray: true),
                                      child: JigsawPieceWidget(
                                        piece: piece,
                                        isSelected: _selectedPiece?.id == piece.id,
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ),
                  ],
                ),
    );
  }

  // --- Interaction Handlers ---

  void _onPiecePanStart(JigsawPiece piece, Offset globalPosition, {bool isFromTray = false}) {
    if (piece.isAssembled) {
      // Potentially drag assembled group - more complex, handle later
      // For now, prevent dragging of already assembled individual pieces
      // unless we implement group dragging.
      // If we want to allow detaching, that's another logic path.
      debugPrint("Piece ${piece.id} is assembled. Dragging locked/group drag TBD.");
      return;
    }

    setState(() {
      _selectedPiece = piece;
      if (isFromTray) {
        // Calculate offset relative to the piece's own top-left.
        // Tray pieces are drawn at 0,0 within their JigsawPieceWidget.
        // Their global position needs to be mapped to local.
        // For simplicity, let's assume drag starts from piece center if from tray for now.
        // This is tricky because the piece in tray is not yet using global board coordinates.
         _dragOffset = Offset(piece.width / 2, piece.height / 2);

        // Move from tray to board conceptually at drag start
        if (_displayedPieces.remove(piece)) {
          // Initial position on board when dragged from tray:
          // Convert global pointer to local board coordinates
          final RenderBox boardBox = _gameBoardKey.currentContext!.findRenderObject() as RenderBox;
          final Offset boardTapPosition = boardBox.globalToLocal(globalPosition);
          
          piece.currentPosition = boardTapPosition - _dragOffset!;
          _boardPieces.add(piece);
        }
      } else {
         // Piece is already on the board.
        // The globalPosition is the pointer's position on the screen.
        // We need the offset of the pointer *from the piece's top-left corner*.
        // piece.currentPosition is relative to the board's top-left.
        // So, global position of piece's top-left is _gameBoardOffset + piece.currentPosition.
        final Offset pieceGlobalTopLeft = _gameBoardOffset + piece.currentPosition;
        _dragOffset = globalPosition - pieceGlobalTopLeft;
      }
    });
  }

  void _onPiecePanUpdate(JigsawPiece piece, Offset globalPosition) {
    if (_selectedPiece == null || _selectedPiece!.id != piece.id || _dragOffset == null) return;
    if (_selectedPiece!.isAssembled) return; // Should not happen if panStart checks

    setState(() {
      // Convert global pointer position to local board coordinates
      final RenderBox boardBox = _gameBoardKey.currentContext!.findRenderObject() as RenderBox;
      final Offset boardTapPosition = boardBox.globalToLocal(globalPosition);
      _selectedPiece!.currentPosition = boardTapPosition - _dragOffset!;
    });
  }

  void _onPiecePanEnd(JigsawPiece piece) {
    if (_selectedPiece == null || _selectedPiece!.id != piece.id) return;
    if (_selectedPiece!.isAssembled && !_selectedPiece!.connectedTo.isNotEmpty) {
        // If it was marked assembled but not connected (e.g. placed correctly by itself)
        // Allow it to be moved unless it's truly locked.
        // For now, if isAssembled is true, it's considered locked or part of a group.
    }


    bool snapped = false;
    if (!_selectedPiece!.isAssembled) { // Only try to snap if not already part of a larger assembly
        // Check for snapping with other pieces on the board
        for (var boardPiece in _boardPieces) {
          if (boardPiece.id == _selectedPiece!.id) continue;

          // Check if pieces are candidates for snapping (e.g., one is assembled, other is not, or both are not)
          // More advanced: If boardPiece is part of an assembly, selectedPiece snaps to the whole group.
          // For now, basic piece-to-piece snapping.
          
          // Dynamic snap tolerance based on piece size.
          // Ensure _currentPuzzle and its pieces are available.
          double dynamicSnapTolerance = 20.0; // Default fallback
          if (_currentPuzzle != null && _currentPuzzle!.pieces.isNotEmpty) {
            // Use the width of the piece being dragged (_selectedPiece)
            // as it's directly relevant to the interaction.
            dynamicSnapTolerance = _selectedPiece!.width * 0.25; // 25% of the piece width
          }

          if (JigsawUtils.shouldSnap(
            piece1: boardPiece, // The piece already on the board (potentially an anchor)
            piece2: _selectedPiece!, // The piece being dragged
            snapTolerance: dynamicSnapTolerance,
            pieceGridSize: _currentPuzzle!.pieceGridSize,
            boardSize: _currentPuzzle!.boardSize,
          )) {
            JigsawUtils.snapPieces(boardPiece, _selectedPiece!);
            // If boardPiece was not assembled, but selectedPiece was, and they snapped,
            // boardPiece should now also be considered assembled as part of the new group.
            // The snapPieces logic handles setting both to isAssembled.

            // Transitive connections: if _selectedPiece was already connected to others,
            // and boardPiece was connected to others, all these should now be one group.
            // JigsawUtils.snapPieces handles direct connection. For group merging:
            _mergeConnectedPieces(_selectedPiece!);
            _mergeConnectedPieces(boardPiece); // Ensure both sides propagate assembly

            snapped = true;
            debugPrint("Piece ${_selectedPiece!.id} snapped with ${boardPiece.id}");
            break; 
          }
        }
    }


    // If not snapped, check if it's correctly placed by itself
    if (!snapped && _selectedPiece!.isCorrectlyPlaced()) {
        _selectedPiece!.isAssembled = true; // Mark as assembled
        // currentPosition should already be very close to correctPosition
        _selectedPiece!.currentPosition = _selectedPiece!.correctPosition;
        _selectedPiece!.currentRotation = _selectedPiece!.correctRotation;
        debugPrint("Piece ${_selectedPiece!.id} placed in correct solo position.");
        snapped = true; // Treat as "snapped" for completion check purposes
    }


    // If not snapped and dropped outside board, return to tray
    // For now, let's assume if not snapped, it stays on board if dropped on board,
    // or if it was from tray and not snapped, it just stays where it is on board.
    // A more refined logic would check if it's within board bounds.
    final RenderBox boardBox = _gameBoardKey.currentContext!.findRenderObject() as RenderBox;
    final Rect boardRect = Rect.fromLTWH(0, 0, boardBox.size.width, boardBox.size.height);

    if (!snapped && !boardRect.overlaps(_selectedPiece!.currentPosition & Size(_selectedPiece!.width, _selectedPiece!.height))) {
       // If piece is entirely outside the board and not snapped, move back to tray
      if (_boardPieces.remove(_selectedPiece!)) {
        _displayedPieces.add(_selectedPiece!);
         debugPrint("Piece ${_selectedPiece!.id} returned to tray.");
      }
    }


    // Check for game completion
    if (_currentPuzzle!.isComplete()) {
      _showCompletionDialog();
    }

    setState(() {
      _selectedPiece = null;
      _dragOffset = null;
    });
  }

  void _onPieceTap(JigsawPiece piece, {bool isFromTray = false}) {
     if (piece.isAssembled) {
      debugPrint("Piece ${piece.id} is assembled. Rotation locked/group rotation TBD.");
      // Potentially allow selecting an entire assembled group later.
      return;
    }
    setState(() {
      JigsawUtils.rotatePiece(piece);
      // If the piece is in the tray, its widget will just rebuild.
      // If the piece is on the board, its JigsawPieceWidget will rebuild.
      // If it was the _selectedPiece, ensure the _selectedPiece reference is updated (though it should be the same object)
      if (_selectedPiece?.id == piece.id) {
        _selectedPiece = piece; 
      }
    });
    debugPrint("Piece ${piece.id} rotated. New rotation: ${piece.currentRotation}");
  }

  void _mergeConnectedPieces(JigsawPiece startingPiece) {
    if (!startingPiece.isAssembled) return;

    Set<int> groupToMerge = {startingPiece.id, ...startingPiece.connectedTo};
    List<JigsawPiece> allPuzzlePieces = _currentPuzzle!.pieces; // Use _currentPuzzle safely
    bool changedInLoop;

    do {
      changedInLoop = false;
      Set<int> newConnections = Set<int>.from(groupToMerge);
      for (int pieceIdInGroup in groupToMerge) {
        // Since groupToMerge contains IDs from _currentPuzzle.pieces,
        // firstWhere will find a non-null piece.
        JigsawPiece pieceInGroup = allPuzzlePieces.firstWhere((p) => p.id == pieceIdInGroup);
        for (int connectedId in pieceInGroup.connectedTo) {
          if (newConnections.add(connectedId)) {
            changedInLoop = true;
          }
        }
      }
      groupToMerge = newConnections;
    } while (changedInLoop);

    // Now, ensure all pieces in this group share the same connection set and assembled status
    for (int pieceIdInGroup in groupToMerge) {
       // pieceToUpdate will be non-null for the same reason as pieceInGroup
       JigsawPiece pieceToUpdate = allPuzzlePieces.firstWhere((p) => p.id == pieceIdInGroup);
        pieceToUpdate.isAssembled = true;
        // The '!' was on pieceToUpdate.id, which is fine if pieceToUpdate is non-nullable.
        pieceToUpdate.connectedTo.addAll(groupToMerge.where((id) => id != pieceToUpdate.id)); 
    }

    // Update the positions of all pieces in the group relative to the startingPiece's new snapped position
    // This assumes startingPiece is the one that just got snapped and its position is now "correct" for the group.
    // This is a crucial part for group dragging and snapping.
    // When piece A snaps to piece B, and A is part of group G_A, B part of G_B.
    // All pieces in G_A and G_B must now move relative to the new snap.
    // Let's assume `snapPieces` correctly positioned `startingPiece`.
    // We need to update all other pieces in `groupToMerge`.

    // Find the "anchor" of the group. This could be the piece with the lowest ID, or the startingPiece.
    // For simplicity, let's use startingPiece as the piece whose position is now "leading".
    final Offset anchorCurrentPos = startingPiece.currentPosition;
    final Offset anchorCorrectPos = startingPiece.correctPosition;

    for (int pieceIdInGroup in groupToMerge) {
      if (pieceIdInGroup == startingPiece.id) continue;
      // memberPiece will be non-null
      JigsawPiece memberPiece = allPuzzlePieces.firstWhere((p) => p.id == pieceIdInGroup);
      
      final Offset correctOffsetFromAnchor = memberPiece.correctPosition - anchorCorrectPos;
      memberPiece.currentPosition = anchorCurrentPos + correctOffsetFromAnchor;
      memberPiece.currentRotation = memberPiece.correctRotation; // Ensure all pieces in group are correctly oriented
      memberPiece.isAssembled = true; // Ensure
    }
     // After merging, update _boardPieces to reflect any changes (e.g. if a piece was in displayedPieces but now assembled)
    setState(() {
      // Ensure _currentPuzzle is not null here before accessing its pieces
      // Adding a null check for safety, though _mergeConnectedPieces is called when _currentPuzzle should be non-null.
      if (_currentPuzzle != null) {
        _boardPieces = _currentPuzzle!.pieces.where((p) => _boardPieces.any((bp) => bp.id == p.id) || groupToMerge.contains(p.id)).toList();
        _displayedPieces.removeWhere((p) => groupToMerge.contains(p.id));
      }
    });
  }

  void _showCompletionDialog() {
    // Ensure context is valid and mounted before showing dialog
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) { // Renamed to avoid confusion with widget's context
        return AlertDialog(
          title: const Text('Congratulations!'),
          content: const Text('You have completed the puzzle!'),
          actions: <Widget>[
            TextButton(
              child: const Text('Play Again'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Use dialogContext
                _restartPuzzle();
              },
            ),
            TextButton(
              child: const Text('New Game'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Use dialogContext
                _showNewGameDialog();
              },
            ),
          ],
        );
      },
    );
  }
}
