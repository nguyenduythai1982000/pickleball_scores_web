import 'package:flutter/material.dart';

void main() {
  runApp(const PickleballScorerApp());
}

// Widget chính của ứng dụng
class PickleballScorerApp extends StatelessWidget {
  const PickleballScorerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tính Điểm Pickleball',
      theme: ThemeData(
        // Thiết lập theme cơ bản
        primarySwatch: Colors.indigo,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
        fontFamily: 'Inter',
      ),
      home: const ScoreKeeperScreen(),
    );
  }
}

// Màn hình giữ trạng thái của ứng dụng
class ScoreKeeperScreen extends StatefulWidget {
  const ScoreKeeperScreen({super.key});

  @override
  State<ScoreKeeperScreen> createState() => _ScoreKeeperScreenState();
}

class _ScoreKeeperScreenState extends State<ScoreKeeperScreen> {
  // Các hằng số
  static const int MAX_SCORE = 11;

  // --- Trạng thái Game ---
  String _mode = 'singles'; // 'singles' hoặc 'doubles'
  int _score1 = 0;
  int _score2 = 0;
  int _servingTeam = 1; // 1 hoặc 2
  int _serverPosition = 1; // 1 hoặc 2 (người giao bóng 1 hoặc 2)
  bool _isInitialServer = true; // Lượt giao bóng đầu tiên của Đội 1 (đôi)
  int? _gameWinner; // null, 1 hoặc 2

  // --- Logic cốt lõi ---

  // Đặt lại trò chơi về trạng thái ban đầu
  void _resetGame() {
    setState(() {
      _score1 = 0;
      _score2 = 0;
      _servingTeam = 1;
      _serverPosition = 1;
      _isInitialServer = true;
      _gameWinner = null;
    });
  }

  // Chuyển chế độ chơi và reset game
  void _switchMode(String mode) {
    if (_mode != mode) {
      setState(() {
        _mode = mode;
      });
      _resetGame();
    }
  }

  // Kiểm tra điều kiện thắng (11 điểm, cách biệt 2)
  int? _checkWinner(int s1, int s2) {
    if (s1 >= MAX_SCORE && s1 >= s2 + 2) return 1;
    if (s2 >= MAX_SCORE && s2 >= s1 + 2) return 2;
    return null;
  }

  // Xử lý khi đội đang giao bóng phạm lỗi (Side Out)
  void _handleFault() {
    if (_gameWinner != null) return;

    setState(() {
      int newServingTeam = _servingTeam;
      int newServerPosition = _serverPosition;
      bool newIsInitialServer = _isInitialServer;

      if (_mode == 'singles') {
        // Đánh đơn: Đổi bên giao bóng ngay lập tức
        newServingTeam = _servingTeam == 1 ? 2 : 1;
      } else {
        // Đánh đôi: Logic luân chuyển giao bóng (Side Out)
        if (newIsInitialServer) {
          // Lỗi đầu tiên của Server 1 đội xuất phát, chuyển sang Server 2 của cùng đội
          newIsInitialServer = false;
          newServerPosition = 2;
        } else {
          // Luân chuyển tiêu chuẩn
          if (_serverPosition == 1) {
            // Server 1 lỗi, chuyển sang Server 2 của cùng đội
            newServerPosition = 2;
          } else {
            // Server 2 lỗi, Side Out (chuyển sang đội khác)
            newServingTeam = _servingTeam == 1 ? 2 : 1;
            newServerPosition = 1; // Đội mới luôn bắt đầu bằng Server 1
          }
        }
      }

      _servingTeam = newServingTeam;
      _serverPosition = newServerPosition;
      _isInitialServer = newIsInitialServer;
      _gameWinner = _checkWinner(_score1, _score2);
    });
  }

  // Xử lý khi đội đang giao bóng ghi điểm
  void _handlePoint(int team) {
    if (_gameWinner != null) return;

    if (team == _servingTeam) {
      setState(() {
        if (team == 1) {
          _score1++;
        } else {
          _score2++;
        }
        _gameWinner = _checkWinner(_score1, _score2);
      });
    } else {
      // Nếu đội không giao bóng cố gắng ghi điểm, coi như đội giao bóng phạm lỗi (Side Out)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chỉ đội đang giao bóng mới có thể ghi điểm. Tự động chuyển giao bóng (Fault).'),
          duration: Duration(milliseconds: 1500),
        ),
      );
      _handleFault();
    }
  }

  // Định dạng chuỗi gọi điểm theo chuẩn Pickleball
  String _getScoreCallout() {
    if (_mode == 'singles') {
      return '$_score1 - $_score2';
    }

    final serverScore = _servingTeam == 1 ? _score1 : _score2;
    final receiverScore = _servingTeam == 1 ? _score2 : _score1;
    
    // Số giao bóng hiển thị là 2 chỉ khi ở lượt giao bóng đầu tiên (chế độ đôi)
    final displayServerPosition = _isInitialServer && _serverPosition == 1 ? 2 : _serverPosition;

    return '$serverScore - $receiverScore - $displayServerPosition';
  }

  // --- Xây dựng Giao diện người dùng (UI) ---

  @override
  Widget build(BuildContext context) {
    final bool isGameEnded = _gameWinner != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tính Điểm Pickleball', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.indigo.shade700,
        elevation: 8,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Chọn Chế Độ Chơi
            _buildModeSelector(),
            const SizedBox(height: 20),

            // Bảng Điểm
            _buildScoreBoard(isGameEnded),
            const SizedBox(height: 24),

            // Điều khiển Đội 1
            _buildTeamControls(1, 'Đội 1', Colors.indigo),
            // Điều khiển Đội 2
            _buildTeamControls(2, 'Đội 2', Colors.red),
            const SizedBox(height: 16),

            // Nút Lỗi và Đặt Lại
            _buildActionButtons(isGameEnded),

            const SizedBox(height: 16),
            Text(
              'Trò chơi đến $MAX_SCORE điểm, thắng cách biệt 2 điểm.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  // Widget chọn chế độ chơi
  Widget _buildModeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Chọn Chế Độ:',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => _switchMode('singles'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _mode == 'singles' ? Colors.indigo.shade500 : Colors.grey.shade200,
                  foregroundColor: _mode == 'singles' ? Colors.white : Colors.black87,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 4,
                ),
                child: const Text('Đánh Đơn', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _switchMode('doubles'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _mode == 'doubles' ? Colors.indigo.shade500 : Colors.grey.shade200,
                  foregroundColor: _mode == 'doubles' ? Colors.white : Colors.black87,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 4,
                ),
                child: const Text('Đánh Đôi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Widget hiển thị bảng điểm
  Widget _buildScoreBoard(bool isGameEnded) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text(
              'Điểm Hiện Tại',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            Text(
              '$_score1 - $_score2',
              style: TextStyle(
                fontSize: 72,
                fontWeight: FontWeight.w900,
                color: Colors.indigo.shade800,
                // Sử dụng font mono để điểm số rõ ràng hơn
                fontFamily: 'RobotoMono', 
              ),
            ),
            const SizedBox(height: 10),
            if (isGameEnded)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '🎉 ĐỘI $_gameWinner THẮNG! 🎉',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.green.shade700,
                  ),
                ),
              )
            else
              Column(
                children: [
                  Text(
                    'Đội giao bóng: Đội $_servingTeam (${_mode == 'doubles' ? 'Server $_serverPosition' : 'Singles'})',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.indigo.shade200),
                    ),
                    child: Text(
                      'Cách gọi điểm: ${_getScoreCallout()}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo.shade700,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // Widget điều khiển điểm cho từng đội
  Widget _buildTeamControls(int team, String name, MaterialColor color) {
    final bool isServing = team == _servingTeam;

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
        border: Border(
          left: BorderSide(
            color: isServing ? Colors.yellow.shade600 : color.shade400,
            width: isServing ? 8.0 : 4.0,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                name,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color.shade800),
              ),
              if (isServing)
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Text(
                    '⚡', // Icon Giao bóng
                    style: TextStyle(fontSize: 24),
                  ),
                ),
            ],
          ),
          ElevatedButton(
            onPressed: _gameWinner == null ? () => _handlePoint(team) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade500,
              foregroundColor: Colors.white,
              minimumSize: const Size(80, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 4,
            ),
            child: const Text('+', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  // Widget Nút Lỗi và Đặt Lại
  Widget _buildActionButtons(bool isGameEnded) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: isGameEnded ? null : _handleFault,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.yellow.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 4,
            ),
            child: const Text(
              'Lỗi (Side Out)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton(
            onPressed: _resetGame,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade500,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 4,
            ),
            child: const Text(
              'Đặt Lại',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}