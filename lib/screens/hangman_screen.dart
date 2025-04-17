import 'package:flutter/material.dart';
import '../models/word_list.dart';
import '../models/word_hints.dart';
import '../widgets/difficulty_dialog.dart';
import '../widgets/hangman_figure.dart';

class HangmanScreen extends StatefulWidget {
  const HangmanScreen({super.key});

  @override
  State<HangmanScreen> createState() => _HangmanScreenState();
}

class _HangmanScreenState extends State<HangmanScreen> {
  String? _word;
  List<String> _guessedLetters = [];
  int _remainingAttempts = 7;
  bool _gameOver = false;
  bool _gameWon = false;
  bool _dialogShown = false;
  String _currentDifficulty = 'easy';

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
      builder: (context) => const DifficultyDialog(),
    );

    if (difficulty != null) {
      setState(() {
        _currentDifficulty = difficulty;
        _word = WordList.getRandomWord(difficulty);
        _guessedLetters = [];
        _remainingAttempts = 7;
        _gameOver = false;
        _gameWon = false;
      });
    } else {
      Navigator.pop(context);
    }
  }

  void _guessLetter(String letter) {
    if (_gameOver || _gameWon) return;

    setState(() {
      if (!_guessedLetters.contains(letter)) {
        _guessedLetters.add(letter);
        if (!_word!.contains(letter)) {
          _remainingAttempts--;
        }
      }

      _gameOver = _remainingAttempts <= 0;
      _gameWon = _word!.split('').every((char) => _guessedLetters.contains(char));
    });
  }

  String _getDisplayWord() {
    return _word!.split('').map((char) {
      return _guessedLetters.contains(char) ? char : '_';
    }).join(' ');
  }

  Color _getStatusColor() {
    if (_gameWon) return Colors.green;
    if (_gameOver) return Colors.red;
    if (_remainingAttempts <= 2) return Colors.orange;
    return Colors.blue;
  }

  @override
  Widget build(BuildContext context) {
    if (_word == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final statusColor = _getStatusColor();
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Hangman'),
        backgroundColor: statusColor,
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              statusColor.withValues(alpha: 0.1),
              Colors.grey[100]!,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Container(
                height: 50,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getStatusColor().withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    _gameOver || _gameWon
                        ? _gameWon
                            ? '🎉 Congratulations! You won! 🎉'
                            : 'Game Over!'
                        : 'Attempts remaining: $_remainingAttempts',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: 0),
              SizedBox(
                height: screenHeight * 0.25,
                child: Center(
                  child: HangmanFigure(
                    remainingAttempts: _remainingAttempts,
                    color: statusColor,
                  ),
                ),
              ),
              const SizedBox(height: 0),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: statusColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        WordHints.getHint(_word!),
                        style: TextStyle(
                          fontSize: 16,
                          color: statusColor,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.1),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  _getDisplayWord(),
                  style: const TextStyle(
                    fontSize: 28,
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (_gameOver || _gameWon) ...[
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _gameWon ? 'Congratulations!' : 'The word was:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _word!,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _word = WordList.getRandomWord(_currentDifficulty);
                      _guessedLetters = [];
                      _remainingAttempts = 7;
                      _gameOver = false;
                      _gameWon = false;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: statusColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'New Game (${_currentDifficulty[0].toUpperCase()}${_currentDifficulty.substring(1).toLowerCase()})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.1),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Wrap(
                  spacing: 0.8,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: [
                    // First row: Q W E R T Y U I O P
                    ...'qwertyuiop'.split('').map((letter) => _buildLetterButton(letter)),
                    const SizedBox(width: double.infinity), // Force new line
                    // Second row: A S D F G H J K L
                    ...'asdfghjkl'.split('').map((letter) => _buildLetterButton(letter)),
                    const SizedBox(width: double.infinity), // Force new line
                    // Third row: Z X C V B N M
                    ...'zxcvbnm'.split('').map((letter) => _buildLetterButton(letter)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLetterButton(String letter) {
    final isGuessed = _guessedLetters.contains(letter);
    final isCorrect = _word!.contains(letter);
    
    return SizedBox(
      width: 38,
      height: 38,
      child: ElevatedButton(
        onPressed: isGuessed ? null : () => _guessLetter(letter),
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: isGuessed
              ? (isCorrect ? Colors.green : Colors.red)
              : _getStatusColor().withValues(alpha: 0.1),
          foregroundColor: isGuessed
              ? Colors.white
              : _getStatusColor(),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          letter.toUpperCase(),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
} 