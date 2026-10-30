import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(
    MaterialApp(
      title: 'Game',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.deepPurple),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.deepPurple,
      ),
      home: const GamePage(),
    ),
  );
}

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  static const _symbols = ['🐱', '🐶', '🦊', '🐼', '🐸', '🦁', '🐵', '🐯'];

  late List<String> _cards;
  late List<bool> _faceUp;
  late List<bool> _matched;

  int? _first; // бірінші ашылған карта нөмірі
  bool _busy = false; // екі карта салыстырылып жатқанда басуға болмайды
  int _moves = 0;
  int _pairs = 0;

  @override
  void initState() {
    super.initState();
    _newGame();
  }

  void _newGame() {
    _cards = [..._symbols, ..._symbols]..shuffle(Random());
    _faceUp = List.filled(_cards.length, false);
    _matched = List.filled(_cards.length, false);
    _first = null;
    _busy = false;
    _moves = 0;
    _pairs = 0;
  }

  Future<void> _onTap(int i) async {
    if (_busy || _faceUp[i] || _matched[i]) return;

    setState(() => _faceUp[i] = true);

    // Бірінші карта: тек есте сақтаймыз
    if (_first == null) {
      _first = i;
      return;
    }

    // Екінші карта: салыстырамыз
    final a = _first!;
    _first = null;
    setState(() => _moves++);

    if (_cards[a] == _cards[i]) {
      setState(() {
        _matched[a] = true;
        _matched[i] = true;
        _pairs++;
      });
      if (_pairs == _symbols.length) _showWin();
    } else {
      _busy = true;
      await Future.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      setState(() {
        _faceUp[a] = false;
        _faceUp[i] = false;
        _busy = false;
      });
    }
  }

  void _showWin() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Good job! 🎉'),
        content: Text('Found in $_moves moves'),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              setState(_newGame);
            },
            child: const Text('Again'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GAME'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'New game',
            onPressed: () => setState(_newGame),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _Stat(label: 'Movements', value: '$_moves'),
                  _Stat(label: 'Found', value: '$_pairs / ${_symbols.length}'),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 4,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    for (var i = 0; i < _cards.length; i++)
                      FlipCard(
                        symbol: _cards[i],
                        faceUp: _faceUp[i],
                        matched: _matched[i],
                        onTap: () => _onTap(i),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        Text(
          value,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

// Айналатын карта: 11-сабақтағы анимация идеясы
class FlipCard extends StatelessWidget {
  const FlipCard({
    super.key,
    required this.symbol,
    required this.faceUp,
    required this.matched,
    required this.onTap,
  });

  final String symbol;
  final bool faceUp;
  final bool matched;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final back = Container(
      decoration: BoxDecoration(
        color: cs.primary,
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: Icon(Icons.question_mark, color: cs.onPrimary, size: 32),
    );

    final front = Container(
      decoration: BoxDecoration(
        color: matched ? cs.tertiaryContainer : cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: matched ? Border.all(color: cs.tertiary, width: 2) : null,
      ),
      alignment: Alignment.center,
      child: Text(symbol, style: const TextStyle(fontSize: 32)),
    );

    return GestureDetector(
      onTap: onTap,
      child: TweenAnimationBuilder<double>(
        // faceUp өзгергенде 0-ден 1-ге (не кері) жұмсақ ауысады
        tween: Tween<double>(end: faceUp ? 1 : 0),
        duration: const Duration(milliseconds: 350),
        builder: (context, value, child) {
          final angle = value * pi; // 0..180 градус
          final showFront = value > 0.5;

          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001) // перспектива
              ..rotateY(angle),
            // Артқы жағы айна сияқты шағылыспауы үшін қосымша бұрамыз
            child: showFront
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.rotationY(pi),
                    child: front,
                  )
                : back,
          );
        },
      ),
    );
  }
}
