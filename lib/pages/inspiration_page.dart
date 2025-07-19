import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/deepseek_service.dart';

class InspirationPage extends StatefulWidget {
  const InspirationPage({super.key});

  @override
  State<InspirationPage> createState() => _InspirationPageState();
}

class _InspirationPageState extends State<InspirationPage>
    with TickerProviderStateMixin {
  late AnimationController _floatingController;
  late AnimationController _cardController;
  late PageController _pageController;
  
  List<String> _inspirations = [];
  int _currentIndex = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    
    _floatingController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    _cardController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _pageController = PageController();
    _floatingController.repeat();
    
    // 移除自动生成灵感，改为用户主动触发
    // _generateNewInspiration();
  }

  @override
  void dispose() {
    _floatingController.dispose();
    _cardController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _generateNewInspiration() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      String fullInspiration = '';
      await for (String chunk in DeepSeekService.generateInspiration()) {
        fullInspiration += chunk;
      }
      
      setState(() {
        _inspirations.add(fullInspiration.trim());
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
    
    // 当滑动到最后一张卡片时，生成新的灵感
    if (index == _inspirations.length - 1) {
      _generateNewInspiration();
    }
  }

  void _nextCard() {
    if (_currentIndex < _inspirations.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // 如果是最后一张卡片，生成新的灵感后跳转
      _generateNewInspiration().then((_) {
        if (_inspirations.isNotEmpty) {
          _pageController.nextPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.purple.shade900.withOpacity(0.8),
              Colors.blue.shade900.withOpacity(0.8),
              Colors.indigo.shade900.withOpacity(0.9),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 顶部标题
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: Colors.white,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '灵感',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Spacer(),
                    if (_inspirations.isNotEmpty)
                      Text(
                        '${_currentIndex + 1}/${_inspirations.length}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                  ],
                ),
              ),
              
              // 卡片区域
              Expanded(
                child: _inspirations.isEmpty && !_isLoading
                    ? _buildEmptyState()
                    : _buildCardView(),
              ),
              
              // 底部提示
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.swipe,
                      color: Colors.white.withOpacity(0.6),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '左右滑动翻页，点击卡片获取新灵感',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.6),
                      ),
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



  Widget _buildEmptyState() {
    return Center(
      child: AnimatedBuilder(
        animation: _floatingController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(
              0,
              10 * (0.5 - (_floatingController.value - 0.5).abs()),
            ),
            child: GestureDetector(
              onTap: _generateNewInspiration,
              child: Container(
                padding: const EdgeInsets.all(40),
                margin: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      size: 60,
                      color: Colors.white.withOpacity(0.8),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '点击获取灵感',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '让创意的火花点亮你的思维',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCardView() {
    if (_isLoading && _inspirations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            const SizedBox(height: 20),
            Text(
              '正在生成灵感...',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return PageView.builder(
      controller: _pageController,
      onPageChanged: _onPageChanged,
      itemCount: _inspirations.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _inspirations.length) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          );
        }

        return Container(
          margin: const EdgeInsets.all(20),
          child: GestureDetector(
            onTap: _nextCard,
            child: Card(
              elevation: 8,
              color: Colors.white.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Container(
                padding: const EdgeInsets.all(30),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.format_quote,
                      size: 40,
                      color: Colors.white.withOpacity(0.8),
                    ),
                    const SizedBox(height: 30),
                    Text(
                      _inspirations[index],
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white.withOpacity(0.9),
                        height: 1.6,
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '点击获取新灵感',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}