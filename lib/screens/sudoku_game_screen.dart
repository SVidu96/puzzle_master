import 'package:flutter/material.dart';
import '../widgets/sudoku_difficulty_dialog.dart';
// import '../widgets/banner_ad_widget.dart';

class SudokuGameScreen extends StatefulWidget {
  const SudokuGameScreen({super.key});

  @override
  State<SudokuGameScreen> createState() => _SudokuGameScreenState();
}

class _SudokuGameScreenState extends State<SudokuGameScreen> {
  List<List<int>> _board = List.generate(9, (_) => List.filled(9, 0));
  List<List<bool>> _fixedNumbers = List.generate(9, (_) => List.filled(9, false));
  int _selectedRow = -1;
  int _selectedCol = -1;
  bool _dialogShown = false;
  String _currentDifficulty = 'easy';
  bool _showCongratulations = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_dialogShown) {
      _dialogShown = true;
      Future.microtask(() => _showDifficultyDialog());
    }
  }

  Future<void> _showDifficultyDialog() async {
    final difficulty = await showDialog<String>(
      context: context,
      builder: (context) => const SudokuDifficultyDialog(),
    );

    if (difficulty != null) {
      setState(() {
        _currentDifficulty = difficulty;
        _generatePuzzle(difficulty);
      });
    } else {
      Navigator.pop(context);
    }
  }

  void _generatePuzzle(String difficulty) {
    // Reset the board
    _board = List.generate(9, (_) => List.filled(9, 0));
    _fixedNumbers = List.generate(9, (_) => List.filled(9, false));

    // Generate a solved Sudoku board
    bool success = _generateSolvedBoard();
    if (!success) {
      // If generation failed, try again
      _generatePuzzle(difficulty);
      return;
    }

    // Remove numbers based on difficulty
    int cellsToRemove;
    switch (difficulty) {
      case 'easy':
        cellsToRemove = 41; // 40 filled cells
        break;
      case 'medium':
        cellsToRemove = 51; // 30 filled cells
        break;
      case 'hard':
        cellsToRemove = 61; // 20 filled cells
        break;
      default:
        cellsToRemove = 41;
    }

    // Remove numbers while ensuring the puzzle remains solvable
    final random = List.generate(81, (index) => index)..shuffle();
    for (int i = 0; i < cellsToRemove; i++) {
      final row = random[i] ~/ 9;
      final col = random[i] % 9;
      _board[row][col] = 0;
    }

    // Mark remaining numbers as fixed
    for (int i = 0; i < 9; i++) {
      for (int j = 0; j < 9; j++) {
        _fixedNumbers[i][j] = _board[i][j] != 0;
      }
    }
  }

  bool _generateSolvedBoard() {
    // This is a simple implementation that might not always generate a valid board
    // In a real app, you'd want to use a more robust algorithm
    final random = List.generate(9, (index) => index + 1)..shuffle();
    for (int i = 0; i < 9; i++) {
      for (int j = 0; j < 9; j++) {
        if (_board[i][j] == 0) {
          for (int num in random) {
            if (_isValidPlacement(i, j, num)) {
              _board[i][j] = num;
              if (_generateSolvedBoard()) {
                return true;
              }
              _board[i][j] = 0;
            }
          }
          return false;
        }
      }
    }
    return true;
  }

  bool _isValidPlacement(int row, int col, int num) {
    // Check row
    for (int i = 0; i < 9; i++) {
      if (_board[row][i] == num) return false;
    }

    // Check column
    for (int i = 0; i < 9; i++) {
      if (_board[i][col] == num) return false;
    }

    // Check 3x3 box
    final boxRow = (row ~/ 3) * 3;
    final boxCol = (col ~/ 3) * 3;
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        if (_board[boxRow + i][boxCol + j] == num) return false;
      }
    }

    return true;
  }

  void _selectCell(int row, int col) {
    if (!_fixedNumbers[row][col]) {
      setState(() {
        _selectedRow = row;
        _selectedCol = col;
      });
    }
  }

  void _placeNumber(int number) {
    if (_selectedRow != -1 && _selectedCol != -1 && !_fixedNumbers[_selectedRow][_selectedCol]) {
      setState(() {
        _board[_selectedRow][_selectedCol] = number;
        if (_isPuzzleComplete()) {
          _showCongratulations = true;
        }
      });
    }
  }

  bool _isNumberValidInPosition(int row, int col) {
    if (_board[row][col] == 0) return true;
    
    final num = _board[row][col];
    
    // Check row
    for (int i = 0; i < 9; i++) {
      if (i != col && _board[row][i] == num) return false;
    }
    
    // Check column
    for (int i = 0; i < 9; i++) {
      if (i != row && _board[i][col] == num) return false;
    }
    
    // Check 3x3 box
    final boxRow = (row ~/ 3) * 3;
    final boxCol = (col ~/ 3) * 3;
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        if (boxRow + i != row && boxCol + j != col && 
            _board[boxRow + i][boxCol + j] == num) {
          return false;
        }
      }
    }
    
    return true;
  }

  bool _isPuzzleComplete() {
    // Check if all cells are filled
    for (int i = 0; i < 9; i++) {
      for (int j = 0; j < 9; j++) {
        if (_board[i][j] == 0 || !_isNumberValidInPosition(i, j)) {
          return false;
        }
      }
    }
    return true;
  }

  void _startNewGame() {
    setState(() {
      _showCongratulations = false;
      _generatePuzzle(_currentDifficulty);
      _selectedRow = -1;
      _selectedCol = -1;
    });
  }

  Color _getCellColor(int row, int col) {
    if (_fixedNumbers[row][col]) {
      return Colors.grey[200]!;
    }
    if (row == _selectedRow && col == _selectedCol) {
      return Colors.blue.withOpacity(0.3);
    }
    if (_board[row][col] != 0) {
      if (!_isNumberValidInPosition(row, col)) {
        return Colors.red.withOpacity(0.3);
      }
      return Colors.green.withOpacity(0.1);
    }
    return Colors.white;
  }

  TextStyle _getNumberStyle(int row, int col) {
    if (_fixedNumbers[row][col]) {
      return const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      );
    }
    if (!_isNumberValidInPosition(row, col)) {
      return const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.normal,
        color: Colors.red,
      );
    }
    return const TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.normal,
      color: Colors.green,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Sudoku'),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _dialogShown = false;
              Future.microtask(() => _showDifficultyDialog());
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.green.withOpacity(0.1),
                  Colors.grey[100]!,
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Container(
                    height: 50,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        'Difficulty: ${_currentDifficulty[0].toUpperCase()}${_currentDifficulty.substring(1)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final size = constraints.maxWidth - 20;
                        return Center(
                          child: Container(
                            width: size,
                            height: size,
                            padding: const EdgeInsets.all(10),
                            child: GridView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 9,
                                childAspectRatio: 1.0,
                                crossAxisSpacing: 1,
                                mainAxisSpacing: 1,
                              ),
                              itemCount: 81,
                              itemBuilder: (context, index) {
                                final row = index ~/ 9;
                                final col = index % 9;
                                
                                return GestureDetector(
                                  onTap: () => _selectCell(row, col),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: _getCellColor(row, col),
                                      border: Border(
                                        top: const BorderSide(
                                          color: Colors.black,
                                          width: 1.0,
                                        ),
                                        left: const BorderSide(
                                          color: Colors.black,
                                          width: 1.0,
                                        ),
                                        right: BorderSide(
                                          color: Colors.black,
                                          width: (col + 1) % 3 == 0 ? 1.0 : 0.0,
                                        ),
                                        bottom: BorderSide(
                                          color: Colors.black,
                                          width: (row + 1) % 3 == 0 ? 1.0 : 0.0,
                                        ),
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        _board[row][col] == 0 ? '' : _board[row][col].toString(),
                                        style: _getNumberStyle(row, col),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(9, (index) {
                        return GestureDetector(
                          onTap: () => _placeNumber(index + 1),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.green,
                                width: 1,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                (index + 1).toString(),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_showCongratulations)
            Container(
              color: Colors.black54,
              child: Center(
                child: Container(
                  margin: const EdgeInsets.all(32),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.celebration,
                        color: Colors.green,
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Congratulations!',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You completed the ${_currentDifficulty.toLowerCase()} puzzle!',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _startNewGame,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Start New Game',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
} 