import 'package:flutter/material.dart';
// import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:puzzle_master/screens/hangman_game_screen.dart';
import 'package:puzzle_master/screens/sudoku_game_screen.dart';
import 'package:puzzle_master/screens/jigsaw_puzzle_screen.dart';
import 'package:puzzle_master/widgets/about_dialog.dart';
import 'package:puzzle_master/widgets/game_card.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth;
          final isSmallScreen = maxWidth < 392;
          final isMediumScreen = maxWidth < 768;
          
          // Responsive values
          final titleFontSize = isSmallScreen ? 28.0 : 36.0;
          final subtitleFontSize = isSmallScreen ? 18.0 : 24.0;
          final horizontalPadding = isSmallScreen ? 12.0 : 16.0;
          final verticalSpacing = isSmallScreen ? 8.0 : 10.0;
          final gridSpacing = isSmallScreen ? 12.0 : 20.0;
          final gridPadding = isSmallScreen ? 12.0 : 20.0;
          final iconSize = isSmallScreen ? 24.0 : 28.0;
          final topPadding = isSmallScreen ? 20.0 : 40.0;
          
          // Calculate maximum container width for game cards
          final maxContainerWidth = isMediumScreen ? maxWidth : 768.0;
          
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.purple.shade300,
                  Colors.blue.shade300,
                  Colors.green.shade300,
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox(width: isSmallScreen ? 32 : 40), // For balance
                        Column(
                          children: [
                            SizedBox(height: topPadding),
                            Text(
                              'Puzzle Master',
                              style: TextStyle(
                                fontSize: titleFontSize,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    blurRadius: 10.0,
                                    color: Colors.black26,
                                    offset: const Offset(2.0, 2.0),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.info_outline),
                          iconSize: iconSize,
                          color: Colors.white,
                          onPressed: () => showDialog(
                            context: context,
                            builder: (context) => const AppAboutDialog(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: verticalSpacing),
                  Text(
                    'Choose Your Game',
                    style: TextStyle(
                      fontSize: subtitleFontSize,
                      color: Colors.white70,
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 20 : 30),
                  Expanded(
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: maxContainerWidth,
                      ),
                      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                      child: GridView.count(
                        padding: EdgeInsets.zero,
                        crossAxisCount: isSmallScreen ? 1 : 2,
                        mainAxisSpacing: gridSpacing,
                        crossAxisSpacing: gridSpacing,
                        childAspectRatio: isSmallScreen ? 1.5 : 1.0,
                        shrinkWrap: true,
                        children: [
                          GameCard(
                            title: 'Hangman',
                            description: 'Guess the word before the hangman is complete!',
                            icon: Icons.person,
                            color: const Color(0xFFFF6B6B),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const HangmanScreen(),
                                ),
                              );
                            },
                          ),
                          GameCard(
                            title: 'Sudoku',
                            description: 'Fill the grid with numbers following the rules!',
                            icon: Icons.grid_on,
                            color: const Color(0xFF4ECDC4),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SudokuGameScreen(),
                                ),
                              );
                            },
                          ),
                          GameCard(
                            title: 'Jigsaw Puzzle',
                            description: 'Arrange the pieces to complete the picture!',
                            icon: Icons.extension,
                            color: const Color(0xFFFF9F1C),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const JigsawPuzzleScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
