// ignore_for_file: prefer_const_constructors, unnecessary_new, sort_child_properties_last, non_constant_identifier_names, use_key_in_widget_constructors, prefer_const_constructors_in_immutables

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';

enum TileState { covered, blown, open, flagged, revealed }

void main() => runApp(MineSweeper());

class MineSweeper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Mine Sweeper",
      home: Board(),
    );
  }
}

class Board extends StatefulWidget {
  @override
  BoardState createState() => BoardState();
}

class BoardState extends State<Board> {
  final int rows = 9;
  final int cols = 9;
  final int numOfMines = 11;

  List<List<TileState>> uiState = [];
  List<List<bool>> tiles = [];

  bool alive = true;
  bool wonGame = false;
  int minesFound = 0;
  late Timer timer = Timer.periodic(Duration(seconds: 1), (Timer timer) {
    setState(() {});
  });
  Stopwatch stopwatch = Stopwatch();

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  void resetBoard() {
    alive = true;
    wonGame = false;
    minesFound = 0;
    stopwatch.reset();

    timer.cancel();
    timer = Timer.periodic(Duration(seconds: 1), (Timer timer) {
      setState(() {});
    });

    uiState = new List<List<TileState>>.generate(rows, (row) {
      return new List<TileState>.filled(cols, TileState.covered);
    });

    tiles = new List<List<bool>>.generate(rows, (row) {
      return new List<bool>.filled(cols, false);
    });

    Random random = Random();

    int remainingMines = numOfMines;
    while (remainingMines > 0) {
      int pos = random.nextInt(rows * cols);
      int row = pos ~/ rows;
      int col = pos % cols;

      if (!tiles[row][col]) {
        tiles[row][col] = true;
        remainingMines--;
      }
    }
  }

  @override
  void initState() {
    resetBoard();
    super.initState();
  }

  Widget buildBoard() {
    bool hasCoveredCell = false;
    List<Row> boardRow = <Row>[];
    for (int i = 0; i < rows; i++) {
      List<Widget> rowChildren = <Widget>[];
      for (int j = 0; j < cols; j++) {
        TileState state = uiState[i][j];
        int count = mineCount(i, j);

        if (!alive) {
          if (state != TileState.blown) {
            state = tiles[i][j] ? TileState.revealed : state;
          }
        }

        if (state == TileState.covered || state == TileState.flagged) {
          rowChildren.add(GestureDetector(
            onLongPress: () {
              flag(i, j);
            },
            onTap: () {
              if (state == TileState.covered) probe(i, j);
            },
            child: Listener(
                child: CoveredMineTile(
              flagged: state == TileState.flagged,
              posX: i,
              posY: j,
            )),
          ));
          if (state == TileState.covered) {
            hasCoveredCell = true;
          }
        } else {
          rowChildren.add(OpenMIneTile(
            state: state,
            count: count,
          ));
        }
      }
      boardRow.add(Row(
        children: rowChildren,
        mainAxisAlignment: MainAxisAlignment.center,
        key: ValueKey<int>(i),
      ));
    }
    if (!hasCoveredCell) {
      if ((minesFound == numOfMines) && alive) {
        wonGame = true;
        stopwatch.stop();
      }
    }
    return Container(
      color: Colors.grey[700],
      padding: EdgeInsets.all(10.0),
      child: Column(
        children: boardRow,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int timeelapsed = stopwatch.elapsedMilliseconds ~/ 1000;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        centerTitle: true,
        title: Text('Mine Sweeper'),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(45.0),
          child: Row(children: <Widget>[
            FloatingActionButton(
              child: Text(
                'Reset Board',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () => resetBoard(),
              hoverColor: Colors.green,
              splashColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  color: Colors.blue,
                ),
              ),
              focusColor: Colors.blueAccent[100],
            ),
            Container(
              height: 40.0,
              alignment: Alignment.center,
              child: RichText(
                text: TextSpan(
                    text: wonGame
                        ? 'You have Won! $timeelapsed seconds.'
                        : alive
                            ? '[Mines Found: $minesFound] [Total Mines: $numOfMines] [$timeelapsed seconds]'
                            : 'You have lost! $timeelapsed seconds.'),
              ),
            ),
          ]),
        ),
      ),
      body: Container(
        color: Colors.grey[50],
        child: Center(
          child: buildBoard(),
        ),
      ),
    );
  }

  void probe(int i, int j) {
    if (!alive) return;
    if (uiState[i][j] == TileState.flagged) return;
    setState(() {
      if (tiles[i][j]) {
        uiState[i][j] = TileState.blown;
        alive = false;
        timer.cancel();
        stopwatch.stop();
      } else {
        if (!stopwatch.isRunning) stopwatch.start();
      }
    });
  }

  void open(int i, int j) {
    if (!inBoard(i, j)) return;
    if (uiState[i][j] == TileState.open) return;
    uiState[i][j] = TileState.open;

    if (mineCount(i, j) > 0) return;
    open(i - 1, j);
    open(i + 1, j);
    open(i, j - 1);
    open(i, j + 1);
    open(i - 1, j - 1);
    open(i + 1, j + 1);
    open(i - 1, j + 1);
    open(i + 1, j - 1);
  }

  void flag(int x, int y) {
    if (!alive) return;
    setState(() {
      if (uiState[x][y] == TileState.flagged) {
        uiState[x][y] == TileState.covered;
        --minesFound;
      } else {
        uiState[y][x] = TileState.flagged;
        ++minesFound;
      }
    });
  }

  int mineCount(int x, int y) {
    int count = 0;
    count += bombs(x - 1, y);
    count += bombs(x + 1, y);
    count += bombs(x, y - 1);
    count += bombs(x, y + 1);
    count += bombs(x - 1, y - 1);
    count += bombs(x + 1, y + 1);
    count += bombs(x + 1, y - 1);
    count += bombs(x - 1, y + 1);
    return count;
  }

  int bombs(int x, int y) => inBoard(x, y) && tiles[y][x] ? 1 : 0;
  bool inBoard(int x, int y) => x >= 0 && x < cols && y >= 0 && y < rows;
}

Widget buildTile(Widget child) {
  return Container(
    padding: EdgeInsets.all(1.0),
    height: 30.0,
    width: 30.0,
    color: Colors.grey[400],
    margin: EdgeInsets.all(2.0),
    child: child,
  );
}

Widget buildInnerTile(Widget child) {
  return Container(
    padding: EdgeInsets.all(1.0),
    margin: EdgeInsets.all(2.0),
    height: 20.0,
    width: 20.0,
    child: child,
  );
}

class CoveredMineTile extends StatelessWidget {
  final bool flagged;
  final int posX;
  final int posY;

  CoveredMineTile(
      {required this.flagged, required this.posX, required this.posY});

  @override
  Widget build(BuildContext context) {
    Widget text = '' as Widget;
    if (flagged) {
      text = buildInnerTile(RichText(
        text: TextSpan(
          text: "\u2691",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        textAlign: TextAlign.center,
      ));
    }
    Widget innerTile = Container(
      padding: EdgeInsets.all(1.0),
      margin: EdgeInsets.all(2.0),
      height: 20.0,
      width: 20.0,
      color: Colors.grey[350],
      child: text,
    );
    return buildTile(innerTile);
  }
}

class OpenMIneTile extends StatelessWidget {
  final TileState state;
  final int count;
  OpenMIneTile({required this.state, required this.count});

  final List textColor = [
    Colors.blue,
    Colors.green,
    Colors.red,
    Colors.purple,
    Colors.cyan,
    Colors.amber,
    Colors.brown,
    Colors.black,
  ];

  @override
  Widget build(BuildContext context) {
    late Widget text;
    if (state == TileState.open) {
      if (count != 0) {
        text = RichText(
          text: TextSpan(
            text: '$count',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: textColor[count - 1],
            ),
          ),
          textAlign: TextAlign.center,
        );
      }
    } else {
      text = RichText(
        text: TextSpan(
          text: '\u2739',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        textAlign: TextAlign.center,
      );
    }
    return buildTile(buildInnerTile(text));
  }
}
