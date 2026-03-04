import 'package:flutter/material.dart';
import '../services/game_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({Key? key}) : super(key: key);

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  late Future<List<dynamic>> _leaderboardFuture;
  String _selectedGame = "all";

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  void _loadLeaderboard() {
    _leaderboardFuture = GameService.getHighScores(
      gameType: _selectedGame == "all" ? null : _selectedGame,
      limit: 50,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Leaderboard"),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Game Filter
          SizedBox(
            height: 60,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(8.0),
              children: [
                _buildFilterChip("All Games", "all"),
                _buildFilterChip("Sequence", "sequence"),
                _buildFilterChip("Match", "match"),
                _buildFilterChip("Number Span", "digit_span"),
              ],
            ),
          ),
          // Leaderboard List
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _leaderboardFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }

                final scores = snapshot.data ?? [];

                if (scores.isEmpty) {
                  return const Center(child: Text("No scores yet"));
                }

                return ListView.builder(
                  itemCount: scores.length,
                  itemBuilder: (context, index) {
                    final score = scores[index];
                    final rank = index + 1;
                    final isTopThree = rank <= 3;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 6.0,
                      ),
                      color: isTopThree ? _getRankColor(rank) : Colors.grey[50],
                      child: ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _getRankColor(rank),
                          ),
                          child: Center(
                            child: Text(
                              "$rank",
                              style: TextStyle(
                                color: isTopThree
                                    ? Colors.white
                                    : Colors.black87,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        title: Text(
                          score['username'] ?? 'Player',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          "Game: ${score['gameType'] ?? 'N/A'} | Level: ${score['level'] ?? 1}",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "${score['score'] ?? 0}",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple,
                              ),
                            ),
                            Text(
                              "${score['duration'] ?? 0}s",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedGame == value;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedGame = value;
            _loadLeaderboard();
          });
        },
        backgroundColor: Colors.grey[200],
        selectedColor: Colors.deepPurple,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber; // Gold
      case 2:
        return Colors.grey[400] ?? Colors.grey; // Silver
      case 3:
        return Colors.orange[700] ?? Colors.orange; // Bronze
      default:
        return Colors.deepPurple;
    }
  }
}
