import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MeditationPage extends StatefulWidget {
  const MeditationPage({super.key});

  @override
  State<MeditationPage> createState() => _MeditationPageState();
}

class _MeditationPageState extends State<MeditationPage>
    with TickerProviderStateMixin {
  late AnimationController _breathingController;
  late AnimationController _rippleController;
  late Animation<double> _breathingAnimation;
  late Animation<double> _rippleAnimation;
  
  bool _isPlaying = false;
  int _duration = 5; // 默认5分钟
  int _remainingTime = 0;
  
  final List<int> _durations = [1, 3, 5, 10, 15, 30]; // 冥想时长选项（分钟）
  
  @override
  void initState() {
    super.initState();
    
    _breathingController = AnimationController(
      duration: const Duration(seconds: 8), // 呼吸周期8秒
      vsync: this,
    );
    
    _rippleController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _breathingAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _breathingController,
      curve: Curves.easeInOut,
    ));
    
    _rippleAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _rippleController,
      curve: Curves.easeOut,
    ));
  }
  
  @override
  void dispose() {
    _breathingController.dispose();
    _rippleController.dispose();
    super.dispose();
  }
  
  void _startMeditation() {
    setState(() {
      _isPlaying = true;
      _remainingTime = _duration * 60; // 转换为秒
    });
    
    _breathingController.repeat(reverse: true);
    _rippleController.repeat();
    
    // 倒计时
    _startCountdown();
  }
  
  void _stopMeditation() {
    setState(() {
      _isPlaying = false;
      _remainingTime = 0;
    });
    
    _breathingController.stop();
    _rippleController.stop();
  }
  
  void _startCountdown() {
    if (_remainingTime > 0 && _isPlaying) {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted && _isPlaying) {
          setState(() {
            _remainingTime--;
          });
          if (_remainingTime > 0) {
            _startCountdown();
          } else {
            _stopMeditation();
            _showCompletionDialog();
          }
        }
      });
    }
  }
  
  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1c2e),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          '🧘‍♀️ 冥想完成',
          style: TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
        content: const Text(
          '恭喜你完成了这次冥想练习！\n愿你内心平静，身心愉悦。',
          style: TextStyle(color: Colors.white70),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              '确定',
              style: TextStyle(color: Color(0xFF8B9AFF)),
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
  
  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1a1c2e),
              Color(0xFF2d1b69),
              Color(0xFF11001a),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // 顶部导航
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        '冥想',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48), // 平衡布局
                  ],
                ),
                
                const SizedBox(height: 40),
                
                // 主要内容区域
                Expanded(
                  child: _isPlaying ? _buildMeditationView() : _buildSetupView(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildSetupView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 冥想图标
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                const Color(0xFF8B9AFF).withOpacity(0.3),
                const Color(0xFF6B73FF).withOpacity(0.1),
              ],
            ),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: const Icon(
            Icons.self_improvement,
            size: 60,
            color: Colors.white,
          ),
        ),
        
        const SizedBox(height: 40),
        
        // 标题和描述
        const Text(
          '开始冥想',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        
        const SizedBox(height: 16),
        
        Text(
          '选择冥想时长，让心灵得到宁静',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 60),
        
        // 时长选择
        const Text(
          '选择时长',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        
        const SizedBox(height: 20),
        
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _durations.map((duration) {
            final isSelected = _duration == duration;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _duration = duration;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF8B9AFF)
                      : Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF8B9AFF)
                        : Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  '${duration}分钟',
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white.withOpacity(0.8),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        
        const SizedBox(height: 60),
        
        // 开始按钮
        GestureDetector(
          onTap: _startMeditation,
          child: Container(
            width: 200,
            height: 60,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8B9AFF), Color(0xFF6B73FF)],
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B9AFF).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Center(
              child: Text(
                '开始冥想',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildMeditationView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 倒计时显示
        Text(
          _formatTime(_remainingTime),
          style: const TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        
        const SizedBox(height: 60),
        
        // 呼吸引导圆圈
        AnimatedBuilder(
          animation: _breathingAnimation,
          builder: (context, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                // 外层涟漪效果
                AnimatedBuilder(
                  animation: _rippleAnimation,
                  builder: (context, child) {
                    return Container(
                      width: 300 * _rippleAnimation.value,
                      height: 300 * _rippleAnimation.value,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3 * (1 - _rippleAnimation.value)),
                          width: 2,
                        ),
                      ),
                    );
                  },
                ),
                
                // 主呼吸圆圈
                Container(
                  width: 200 * _breathingAnimation.value,
                  height: 200 * _breathingAnimation.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF8B9AFF).withOpacity(0.6),
                        const Color(0xFF6B73FF).withOpacity(0.2),
                        Colors.transparent,
                      ],
                    ),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                ),
                
                // 中心图标
                const Icon(
                  Icons.self_improvement,
                  size: 40,
                  color: Colors.white,
                ),
              ],
            );
          },
        ),
        
        const SizedBox(height: 60),
        
        // 呼吸指导文字
        AnimatedBuilder(
          animation: _breathingController,
          builder: (context, child) {
            final isInhaling = _breathingController.value < 0.5;
            return Text(
              isInhaling ? '深呼吸...' : '慢慢呼出...',
              style: TextStyle(
                fontSize: 20,
                color: Colors.white.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
            );
          },
        ),
        
        const SizedBox(height: 80),
        
        // 停止按钮
        GestureDetector(
          onTap: _stopMeditation,
          child: Container(
            width: 120,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: const Center(
              child: Text(
                '停止',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}