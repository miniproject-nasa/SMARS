import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: GamesScreen(),
  ));
}

class GamesScreen extends StatelessWidget {
  const GamesScreen({super.key});

  static const primaryBlue = Color.fromARGB(255, 56, 83, 153);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Memory Games", style: TextStyle(color: Colors.white)),
        backgroundColor: primaryBlue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _gameButton(context, "Remember the Sequence", Icons.extension, const SequenceGame()),
            const SizedBox(height: 16),
            _gameButton(context, "Match the Cards", Icons.grid_view, const MatchGame()),
            const SizedBox(height: 16),
            _gameButton(context, "Quick Digit Span", Icons.onetwothree, const NumberSpanGame()),
          ],
        ),
      ),
    );
  }

  static Widget _gameButton(BuildContext context, String text, IconData icon, Widget page) {
    return SizedBox(
      width: double.infinity,
      height: 70,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
        icon: Icon(icon, color: Colors.white),
        label: Text(text, style: const TextStyle(fontSize: 16, color: Colors.white)),
      ),
    );
  }
}

// --- IMPROVED GAME 1: SEQUENCE MEMORY ---
class SequenceGame extends StatefulWidget {
  const SequenceGame({super.key});
  @override
  State<SequenceGame> createState() => _SequenceGameState();
}

class _SequenceGameState extends State<SequenceGame> {
  final List<int> _sequence = [];
  final List<int> _playerInput = [];
  int? _activeTile;
  int? _playerTappedTile;
  bool _isPlayingSequence = false;
  String _statusMessage = "Press Start to Begin";

  void _nextRound() async {
    _playerInput.clear();
    _sequence.add(Random().nextInt(4));
    _playSequence();
  }

  void _playSequence() async {
    setState(() {
      _isPlayingSequence = true;
      _statusMessage = "Watch Closely...";
    });

    // Speed up slightly as levels increase
    int speed = max(250, 500 - (_sequence.length * 25));

    for (int index in _sequence) {
      await Future.delayed(Duration(milliseconds: speed));
      if (!mounted) return;
      setState(() => _activeTile = index);
      await Future.delayed(Duration(milliseconds: speed));
      if (!mounted) return;
      setState(() => _activeTile = null);
    }

    setState(() {
      _isPlayingSequence = false;
      _statusMessage = "Your Turn!";
    });
  }

  void _handleTap(int index) {
    if (_isPlayingSequence || _sequence.isEmpty) return;

    // Immediate visual feedback for the tap
    setState(() => _playerTappedTile = index);
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) setState(() => _playerTappedTile = null);
    });

    _playerInput.add(index);

    if (_playerInput.last != _sequence[_playerInput.length - 1]) {
      _showResult(false);
      return;
    }

    if (_playerInput.length == _sequence.length) {
      setState(() => _statusMessage = "Perfect!");
      Future.delayed(const Duration(milliseconds: 800), _nextRound);
    }
  }

  void _showResult(bool win) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(win ? "Good job!" : "Game Over"),
        content: Text("You reached level ${_sequence.length}"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _sequence.clear();
                _statusMessage = "Press Start to Begin";
              });
            },
            child: const Text("Try Again"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sequence Game"), backgroundColor: GamesScreen.primaryBlue),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Level: ${_sequence.isEmpty ? 0 : _sequence.length}", 
               style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(_statusMessage, 
               style: TextStyle(fontSize: 16, color: _isPlayingSequence ? Colors.red : Colors.green[700])),
          const SizedBox(height: 30),
          Wrap(
            spacing: 20,
            runSpacing: 20,
            alignment: WrapAlignment.center,
            children: List.generate(4, (i) {
              bool isLit = _activeTile == i || _playerTappedTile == i;
              final colors = [Colors.red, Colors.blue, Colors.green, Colors.yellow];
              return GestureDetector(
                onTapDown: (_) => _handleTap(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 100),
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: colors[i],
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: isLit ? [BoxShadow(color: colors[i].withOpacity(0.5), blurRadius: 15, spreadRadius: 2)] : [],
                  ),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 100),
                    opacity: isLit ? 1.0 : 0.4,
                    child: Container(decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(16))),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 40),
          if (_sequence.isEmpty) 
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: GamesScreen.primaryBlue),
              onPressed: _nextRound, 
              child: const Text("Start", style: TextStyle(color: Colors.white))
            ),
        ],
      ),
    );
  }
}

// --- GAME 2: MATCH PAIRS ---
class MatchGame extends StatefulWidget {
  const MatchGame({super.key});
  @override
  State<MatchGame> createState() => _MatchGameState();
}

class _MatchGameState extends State<MatchGame> {
  late List<String> _cards;
  late List<bool> _revealed;
  int? _firstIndex;
  int _pairsFound = 0;

  @override
  void initState() {
    super.initState();
    _setup();
  }

  void _setup() {
    final icons = ["🍎", "🍌", "🍇", "🍒", "🍓", "🍍"];
    _cards = [...icons, ...icons]..shuffle();
    _revealed = List.filled(_cards.length, false);
    _pairsFound = 0;
    _firstIndex = null;
  }

  void _handleTap(int i) {
    if (_revealed[i] || _firstIndex == i) return;
    setState(() => _revealed[i] = true);
    if (_firstIndex == null) {
      _firstIndex = i;
    } else {
      if (_cards[_firstIndex!] == _cards[i]) {
        _pairsFound++;
        _firstIndex = null;
        if (_pairsFound == _cards.length ~/ 2) _showWin();
      } else {
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) {
            setState(() {
              _revealed[_firstIndex!] = false;
              _revealed[i] = false;
              _firstIndex = null;
            });
          }
        });
      }
    }
  }

  void _showWin() {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text("Match Complete!"),
      actions: [TextButton(onPressed: () { Navigator.pop(context); setState(() => _setup()); }, child: const Text("Restart"))],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Match Game"), backgroundColor: GamesScreen.primaryBlue),
      body: GridView.builder(
        padding: const EdgeInsets.all(20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 12, crossAxisSpacing: 12),
        itemCount: _cards.length,
        itemBuilder: (_, i) => GestureDetector(
          onTap: () => _handleTap(i),
          child: Container(
            decoration: BoxDecoration(color: Colors.blueGrey, borderRadius: BorderRadius.circular(12)),
            child: Center(child: Text(_revealed[i] ? _cards[i] : "?", style: const TextStyle(fontSize: 32, color: Colors.white))),
          ),
        ),
      ),
    );
  }
}

// --- GAME 3: NUMBER SPAN ---
class NumberSpanGame extends StatefulWidget {
  const NumberSpanGame({super.key});
  @override
  State<NumberSpanGame> createState() => _NumberSpanGameState();
}

class _NumberSpanGameState extends State<NumberSpanGame> {
  String _target = "";
  bool _isShowing = false;
  final TextEditingController _controller = TextEditingController();

  void _start() {
    _controller.clear();
    _target = (1000 + Random().nextInt(8999)).toString();
    setState(() => _isShowing = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isShowing = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Quick Digit"), backgroundColor: GamesScreen.primaryBlue),
      body: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          children: [
            const Text("Remember the digits:", style: TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            Text(_isShowing ? _target : "****", 
                 style: const TextStyle(fontSize: 50, fontWeight: FontWeight.bold, letterSpacing: 10)),
            const SizedBox(height: 30),
            if (!_isShowing && _target.isNotEmpty) ...[
              TextField(controller: _controller, keyboardType: TextInputType.number, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: GamesScreen.primaryBlue),
                onPressed: () {
                  bool win = _controller.text == _target;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(win ? "Correct!" : "Wrong, it was $_target")));
                  _start();
                },
                child: const Text("Submit", style: TextStyle(color: Colors.white)),
              )
            ],
            if (_target.isEmpty) 
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: GamesScreen.primaryBlue),
                onPressed: _start, 
                child: const Text("Start Round", style: TextStyle(color: Colors.white))
              ),
          ],
        ),
      ),
    );
  }
}