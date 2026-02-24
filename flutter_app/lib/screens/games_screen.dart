import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: GamesScreen(),
  ));
}

// --- CONSTANTS & THEME ---
class AppColors {
  static const primaryBlue = Color(0xFF385399);
  static const accentBlue = Color(0xFF5C7BC0);
  static const bgWhite = Color(0xFFF3F6F8);
  static const cardBg = Colors.white;
  static const textDark = Color(0xFF2D3142);
  static const success = Color(0xFF4CAF50);
  static const error = Color(0xFFE57373);
}

// --- MAIN MENU SCREEN ---
class GamesScreen extends StatelessWidget {
  const GamesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgWhite,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Brain Training",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primaryBlue,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 20),
            child: Text(
              "Select a Challenge",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          _GameCard(
            title: "Sequence Memory",
            subtitle: "Watch the pattern and repeat pattern.",
            icon: Icons.grid_view_rounded,
            color: Colors.orangeAccent,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SequenceGame())),
          ),
          _GameCard(
            title: "Card Match",
            subtitle: "Find pairs of matching symbols.",
            icon: Icons.style,
            color: Colors.purpleAccent,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MatchGame())),
          ),
          _GameCard(
            title: "Digit Span",
            subtitle: "Memorize the number, then type it.",
            icon: Icons.dialpad,
            color: Colors.tealAccent.shade700,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NumberSpanGame())),
          ),
        ],
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _GameCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 30),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey[400]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- GAME 1: SEQUENCE MEMORY ---
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
  String _statusMessage = "Press Start";

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

    int speed = max(300, 600 - (_sequence.length * 20));

    await Future.delayed(const Duration(milliseconds: 500));

    for (int index in _sequence) {
      if (!mounted) return;
      setState(() => _activeTile = index);
      await Future.delayed(Duration(milliseconds: (speed * 0.7).round()));
      if (!mounted) return;
      setState(() => _activeTile = null);
      await Future.delayed(Duration(milliseconds: (speed * 0.3).round()));
    }

    if (mounted) {
      setState(() {
        _isPlayingSequence = false;
        _statusMessage = "Your Turn!";
      });
    }
  }

  void _handleTap(int index) {
    if (_isPlayingSequence || _sequence.isEmpty) return;

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
      setState(() => _statusMessage = "Perfect! Next Level...");
      Future.delayed(const Duration(milliseconds: 1000), _nextRound);
    }
  }

  void _showResult(bool win) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(win ? "Good job!" : "Game Over"),
        content: Text("You reached Level ${_sequence.length}"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _sequence.clear();
                _statusMessage = "Press Start";
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
      backgroundColor: AppColors.bgWhite,
      appBar: AppBar(
        title: const Text("Sequence", style: TextStyle(color: Colors.white)), 
        backgroundColor: Colors.orangeAccent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0,2))],
                ),
                child: Column(
                  children: [
                    Text("Level ${_sequence.isEmpty ? 0 : _sequence.length}", 
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                    Text(_statusMessage, style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30.0),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Wrap(
                    spacing: 15,
                    runSpacing: 15,
                    alignment: WrapAlignment.center,
                    children: List.generate(4, (i) {
                      bool isLit = _activeTile == i || _playerTappedTile == i;
                      final colors = [const Color(0xFFE57373), const Color(0xFF64B5F6), const Color(0xFF81C784), const Color(0xFFFFD54F)];
                      final baseColor = colors[i];
                      
                      return GestureDetector(
                        onTapDown: (_) => _handleTap(i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 100),
                          width: 120, // 🔹 Reduced size to prevent overflow
                          height: 120, // 🔹 Reduced size to prevent overflow
                          decoration: BoxDecoration(
                            color: isLit ? baseColor : baseColor.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: baseColor, width: 2),
                            boxShadow: isLit 
                              ? [BoxShadow(color: baseColor.withOpacity(0.6), blurRadius: 20, spreadRadius: 2)] 
                              : [],
                          ),
                          child: isLit 
                            ? const Icon(Icons.touch_app, color: Colors.white, size: 40)
                            : null,
                        ),
                      );
                    }),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              if (_sequence.isEmpty) 
                SizedBox(
                  width: 200,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orangeAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      elevation: 5
                    ),
                    onPressed: _nextRound, 
                    child: const Text("START GAME", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))
                  ),
                ),
            ],
          ),
        ),
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
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _setup();
  }

  void _setup() {
    final icons = ["🍎", "🚀", "⚽", "🐶", "🍕", "🎸"];
    _cards = [...icons, ...icons]..shuffle();
    _revealed = List.filled(_cards.length, false);
    _pairsFound = 0;
    _firstIndex = null;
    _isProcessing = false;
  }

  void _handleTap(int i) {
    if (_revealed[i] || _firstIndex == i || _isProcessing) return;

    setState(() => _revealed[i] = true);

    if (_firstIndex == null) {
      _firstIndex = i;
    } else {
      if (_cards[_firstIndex!] == _cards[i]) {
        _pairsFound++;
        _firstIndex = null;
        if (_pairsFound == _cards.length ~/ 2) _showWin();
      } else {
        _isProcessing = true;
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) {
            setState(() {
              _revealed[_firstIndex!] = false;
              _revealed[i] = false;
              _firstIndex = null;
              _isProcessing = false;
            });
          }
        });
      }
    }
  }

  void _showWin() {
    showDialog(
      context: context, 
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Column(
          children: [
            Icon(Icons.emoji_events, size: 50, color: Colors.amber),
            SizedBox(height: 10),
            Text("Match Complete!"),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purpleAccent),
            onPressed: () { Navigator.pop(context); setState(() => _setup()); }, 
            child: const Text("Play Again", style: TextStyle(color: Colors.white)),
          )
        ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgWhite,
      appBar: AppBar(
        title: const Text("Memory Match", style: TextStyle(color: Colors.white)), 
        backgroundColor: Colors.purpleAccent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20.0),
            child: Text("Find all the pairs!", style: TextStyle(fontSize: 18, color: Colors.grey)),
          ),
          Expanded(
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(), // 🔹 Stops it from scrolling
              padding: const EdgeInsets.symmetric(horizontal: 20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, 
                mainAxisSpacing: 12, // 🔹 Reduced spacing slightly
                crossAxisSpacing: 12, 
                childAspectRatio: 1.0, // 🔹 Made cards square instead of tall
              ),
              itemCount: _cards.length,
              itemBuilder: (_, i) {
                bool isRevealed = _revealed[i];
                return GestureDetector(
                  onTap: () => _handleTap(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOutBack,
                    decoration: BoxDecoration(
                      color: isRevealed ? Colors.white : Colors.purpleAccent.shade100,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))
                      ],
                      border: isRevealed ? Border.all(color: Colors.purpleAccent, width: 2) : null,
                    ),
                    child: Center(
                      child: isRevealed 
                        ? Text(_cards[i], style: const TextStyle(fontSize: 32)) // 🔹 Font size adjusted for square
                        : const Icon(Icons.question_mark, color: Colors.white, size: 30),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
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
  int _digits = 4;

  void _start() {
    FocusScope.of(context).unfocus(); // Hide keyboard
    _controller.clear();
    
    // Generate number based on digits
    int min = pow(10, _digits - 1).toInt();
    int maxVal = pow(10, _digits).toInt() - 1;
    _target = (min + Random().nextInt(maxVal - min)).toString();

    setState(() => _isShowing = true);
    
    // Show for 2.5 seconds
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) setState(() => _isShowing = false);
    });
  }

  void _submit() {
    bool win = _controller.text == _target;
    showDialog(
      context: context, 
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(win ? Icons.check_circle : Icons.error, 
              color: win ? AppColors.success : AppColors.error, size: 60),
            const SizedBox(height: 16),
            Text(win ? "Correct!" : "Incorrect", 
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("Target: $_target", style: const TextStyle(color: Colors.grey)),
            if (!win) Text("You typed: ${_controller.text}", style: const TextStyle(color: Colors.red)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (win) {
                setState(() => _digits++); // Increase difficulty
              } else {
                setState(() => _digits = 4); // Reset
              }
              _start();
            }, 
            child: Text(win ? "Next Level" : "Try Again"),
          )
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgWhite,
      appBar: AppBar(
        title: const Text("Digit Span", style: TextStyle(color: Colors.white)), 
        backgroundColor: Colors.teal,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0,4))],
                ),
                child: Column(
                  children: [
                    Text("Memorize $_digits Digits", 
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal)),
                    const SizedBox(height: 30),
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: _isShowing ? 1.0 : 0.0,
                      child: Text(
                        _isShowing ? _target : "? " * _digits, 
                        style: const TextStyle(fontSize: 42, fontWeight: FontWeight.bold, letterSpacing: 8, color: AppColors.textDark),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              
              if (!_isShowing && _target.isNotEmpty) ...[
                TextField(
                  controller: _controller, 
                  keyboardType: TextInputType.number, 
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24, letterSpacing: 4),
                  decoration: InputDecoration(
                    hintText: "Enter digits here",
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _submit,
                    child: const Text("SUBMIT", style: TextStyle(color: Colors.white, fontSize: 18)),
                  ),
                )
              ],

              if (_target.isEmpty) 
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _start, 
                    child: const Text("START ROUND", style: TextStyle(color: Colors.white, fontSize: 18)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}