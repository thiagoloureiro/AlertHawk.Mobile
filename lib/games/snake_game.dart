import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SnakeGame extends StatefulWidget {
  const SnakeGame({super.key});

  @override
  State<SnakeGame> createState() => _SnakeGameState();
}

class _SnakeGameState extends State<SnakeGame> {
  static List<Color> colors = [
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.yellow,
    Colors.purple,
    Colors.orange,
  ];

  final int squaresPerRow = 20;
  final int squaresPerCol = 40;
  final fontStyle = GoogleFonts.robotoMono(color: Colors.white, fontSize: 20.0);
  final randomGen = Random();

  var snake = [
    [0, 0],
  ];
  var food = [0, 2];
  var direction = 'up';
  var isPlaying = false;
  var score = 0;
  Timer? timer;

  void startGame() {
    const duration = Duration(milliseconds: 200);
    snake = [
      [(squaresPerRow / 2).floor(), (squaresPerCol / 2).floor()]
    ];
    snake.add([snake.first[0], snake.first[1] + 1]);
    createFood();
    isPlaying = true;
    timer = Timer.periodic(duration, (Timer timer) {
      moveSnake();
      if (checkGameOver()) {
        timer.cancel();
        endGame();
      }
    });
  }

  void moveSnake() {
    setState(() {
      switch (direction) {
        case 'up':
          snake.insert(0, [snake.first[0], snake.first[1] - 1]);
          break;
        case 'down':
          snake.insert(0, [snake.first[0], snake.first[1] + 1]);
          break;
        case 'left':
          snake.insert(0, [snake.first[0] - 1, snake.first[1]]);
          break;
        case 'right':
          snake.insert(0, [snake.first[0] + 1, snake.first[1]]);
          break;
      }

      if (snake.first[0] == food[0] && snake.first[1] == food[1]) {
        createFood();
        score += 5;
      } else {
        snake.removeLast();
      }
    });
  }

  void createFood() {
    food = [
      randomGen.nextInt(squaresPerRow),
      randomGen.nextInt(squaresPerCol),
    ];
  }

  bool checkGameOver() {
    if (!isPlaying ||
        snake.first[1] < 0 ||
        snake.first[1] >= squaresPerCol ||
        snake.first[0] < 0 ||
        snake.first[0] >= squaresPerRow) {
      return true;
    }

    for (var i = 1; i < snake.length; i++) {
      if (snake[i][0] == snake.first[0] && snake[i][1] == snake.first[1]) {
        return true;
      }
    }
    return false;
  }

  void endGame() {
    isPlaying = false;
    score = 0;
  }

  Widget buildGameView() {
    return AspectRatio(
      aspectRatio: squaresPerRow / (squaresPerCol + 5),
      child: GestureDetector(
        onVerticalDragUpdate: (details) {
          if (direction != 'up' && details.delta.dy > 0) {
            direction = 'down';
          }
          if (direction != 'down' && details.delta.dy < 0) {
            direction = 'up';
          }
        },
        onHorizontalDragUpdate: (details) {
          if (direction != 'left' && details.delta.dx > 0) {
            direction = 'right';
          }
          if (direction != 'right' && details.delta.dx < 0) {
            direction = 'left';
          }
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black,
            border: Border.all(
              color: Colors.white,
              width: 2.0,
            ),
          ),
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: squaresPerRow,
            ),
            itemCount: squaresPerRow * squaresPerCol,
            itemBuilder: (BuildContext context, int index) {
              var color = Colors.transparent;
              var x = (index % squaresPerRow);
              var y = (index / squaresPerRow).floor();

              if (snake.any((pos) => pos[0] == x && pos[1] == y)) {
                color = colors[snake.length % colors.length];
              } else if (food[0] == x && food[1] == y) {
                color = Colors.red;
              }

              return Container(
                margin: const EdgeInsets.all(1),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          'Snake Game',
          style: GoogleFonts.robotoMono(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: buildGameView(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text(
                  'Score: $score',
                  style: fontStyle,
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                  ),
                  onPressed: isPlaying ? null : startGame,
                  child: Text(
                    isPlaying ? 'Playing' : 'Start',
                    style: fontStyle,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }
}
