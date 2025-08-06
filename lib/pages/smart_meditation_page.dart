import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:provider/provider.dart';
import '../pages/dream_style_selection_page.dart';
import '../services/deepseek_service.dart';
import '../services/language_service.dart';


class SmartMeditationPage extends StatefulWidget {
  final int duration; // 冥想时长（分钟）
  final DreamStyle dreamStyle; // 选择的风格

  const SmartMeditationPage({
    Key? key,
    required this.duration,
    required this.dreamStyle,
  }) : super(key: key);

  @override
  State<SmartMeditationPage> createState() => _SmartMeditationPageState();
}

class _SmartMeditationPageState extends State<SmartMeditationPage>
    with TickerProviderStateMixin {
  // 动画控制器
  late AnimationController _breathingController;
  late AnimationController _rippleController;
  
  // 冥想状态
  bool _isPlaying = false;
  int _remainingTime = 0;
  Timer? _countdownTimer;
  
  // 场景相关
  int _currentSceneIndex = 0;
  List<Map<String, dynamic>> _scenes = [];
  bool _isLoadingScene = false;
  
  // 音频播放器
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isMusicPlaying = false;
  
  // 名言列表
  List<String> get _quotes {
    final localizations = AppLocalizations.of(context)!;
    return [
      localizations.meditationQuote1,
      localizations.meditationQuote2,
      localizations.meditationQuote3,
      localizations.meditationQuote4,
      localizations.meditationQuote5,
      localizations.meditationQuote6,
      localizations.meditationQuote7,
      localizations.meditationQuote8,
      localizations.meditationQuote9,
      localizations.meditationQuote10
    ];
  }
  
  int _currentQuoteIndex = 0;
  Timer? _quoteTimer;
  Timer? _sceneTimer;
  
  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initAudioPlayer();
    _startMeditation();
  }
  
  void _initializeControllers() {
    _breathingController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );
    
    _rippleController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
  }
  

  
  Future<void> _initAudioPlayer() async {
    try {
      await _audioPlayer.setSource(AssetSource('audio/dream_music.mp3'));
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      setState(() {
        _isMusicPlaying = true;
      });
      await _audioPlayer.resume();
    } catch (e) {
      print('Audio initialization failed: $e');
    }
  }
  
  void _startMeditation() async {
    setState(() {
      _isPlaying = true;
      _remainingTime = widget.duration * 60;
    });
    
    _breathingController.repeat(reverse: true);
    _rippleController.repeat();
    
    // 启动本地计时器
    _startCountdown();
    
    // 开始生成场景
    _generateFirstScene();
    
    // 启动名言轮换
    _startQuoteRotation();
  }
  

  
  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPlaying || _remainingTime <= 0) {
        timer.cancel();
        if (_remainingTime <= 0) {
          _stopMeditation();
          _showCompletionDialog();
        }
        return;
      }
      
      if (mounted) {
        setState(() {
          _remainingTime--;
        });
      }
    });
  }
  
  void _generateFirstScene() async {
    setState(() {
      _isLoadingScene = true;
    });
    
    try {
      final scene = await _generateScene();
      if (mounted) {
        setState(() {
          _scenes.add(scene);
          _isLoadingScene = false;
        });
        
        // 启动场景轮换定时器
        _startSceneRotation();
      }
    } catch (e) {
      print('Scene generation failed: $e');
      if (mounted) {
        setState(() {
          _isLoadingScene = false;
        });
      }
    }
  }
  
  void _startSceneRotation() {
    _sceneTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!_isPlaying) {
        timer.cancel();
        return;
      }
      
      _generateNextScene();
    });
  }
  
  void _generateNextScene() async {
    try {
      final scene = await _generateScene();
      if (mounted) {
        setState(() {
          _scenes.add(scene);
          _currentSceneIndex = _scenes.length - 1;
        });
      }
    } catch (e) {
      print('Next scene generation failed: $e');
    }
  }
  
  Future<Map<String, dynamic>> _generateScene() async {
    try {
      String fullContent = '';
      
      // 使用deepseek服务生成冥想场景内容
      await for (final chunk in _generateMeditationSceneStream()) {
        fullContent += chunk;
      }
      
      final sceneData = _parseStreamResponse(fullContent);
      
      // 生成图片
      final imageUrl = await _generateImage(sceneData['image_prompt']);
      sceneData['image_url'] = imageUrl;
      
      return sceneData;
    } catch (e) {
      print('Scene generation failed: $e');
      return _getDefaultScene();
    }
  }
  
  // 生成冥想场景的流式方法
  Stream<String> _generateMeditationSceneStream() async* {
    try {
      final languageService = Provider.of<LanguageService>(context, listen: false);
      final stream = DeepSeekService.generateMeditationSceneStream(
        styleKeywords: widget.dreamStyle.keywords,
        styleName: widget.dreamStyle.name,
        styleDescription: widget.dreamStyle.description,
        languageService: languageService,
      );
      
      await for (final chunk in stream) {
        yield chunk;
      }
    } catch (e) {
      print('Meditation scene stream generation failed: $e');
      // 如果流式生成失败，返回空字符串，让上层方法使用默认场景
      yield '';
    }
  }
  
  Future<String> _generateImage(String prompt) async {
    // 这里应该调用图片生成API，暂时返回占位图
    await Future.delayed(const Duration(seconds: 2)); // 模拟API调用
    return 'https://picsum.photos/800/600?random=${DateTime.now().millisecondsSinceEpoch}';
  }
  
  Map<String, dynamic> _parseStreamResponse(String content) {
    try {
      return jsonDecode(content);
    } catch (e) {
      // 如果解析失败，返回默认内容
      return _getDefaultScene();
    }
  }
  
  Map<String, dynamic> _getDefaultScene() {
    final localizations = AppLocalizations.of(context)!;
    final defaultTexts = [
      localizations.defaultMeditationText1,
      localizations.defaultMeditationText2,
      localizations.defaultMeditationText3,
      localizations.defaultMeditationText4,
      localizations.defaultMeditationText5
    ];
    
    final random = Random();
    return {
      'text': defaultTexts[random.nextInt(defaultTexts.length)],
      'image_prompt': '${widget.dreamStyle.description}${localizations.meditationSceneSuffix}',
      'image_url': 'https://picsum.photos/800/600?random=${random.nextInt(1000)}'
    };
  }
  
  void _startQuoteRotation() {
    _quoteTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (!_isPlaying) {
        timer.cancel();
        return;
      }
      
      setState(() {
        _currentQuoteIndex = (_currentQuoteIndex + 1) % _quotes.length;
      });
    });
  }
  
  void _stopMeditation() async {
    setState(() {
      _isPlaying = false;
    });
    
    _breathingController.stop();
    _rippleController.stop();
    _quoteTimer?.cancel();
    _sceneTimer?.cancel();
    
    _countdownTimer?.cancel();
    await _audioPlayer.pause();
  }
  
  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1c2e),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          '🧘‍♀️ ${AppLocalizations.of(context)!.meditationCompleted}',
          style: const TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
        content: Text(
          AppLocalizations.of(context)!.meditationCompletedMessage,
          style: const TextStyle(color: Colors.white70),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: Text(
              AppLocalizations.of(context)!.confirm,
              style: const TextStyle(color: Color(0xFF8B9AFF)),
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
  void dispose() {
    _breathingController.dispose();
    _rippleController.dispose();
    _countdownTimer?.cancel();
    _quoteTimer?.cancel();
    _sceneTimer?.cancel();
    _audioPlayer.dispose();

    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 背景图片或默认背景
          if (_scenes.isNotEmpty && !_isLoadingScene)
            _buildBackgroundImage()
          else
            _buildDefaultBackground(),
          
          // 前景内容
          SafeArea(
            child: Column(
              children: [
                // 顶部信息栏
                _buildTopBar(),
                
                Expanded(
                  child: _scenes.isEmpty || _isLoadingScene
                      ? _buildLoadingView()
                      : _buildMeditationView(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBackgroundImage() {
    return AnimatedSwitcher(
      duration: const Duration(seconds: 2),
      child: Container(
        key: ValueKey(_currentSceneIndex),
        decoration: BoxDecoration(
          image: DecorationImage(
            image: CachedNetworkImageProvider(
              _scenes[_currentSceneIndex]['image_url'],
            ),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.3),
                Colors.black.withOpacity(0.1),
                Colors.black.withOpacity(0.3),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildDefaultBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1a1c2e),
            Color(0xFF16213e),
            Color(0xFF0f3460),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          
          // 倒计时（小字体，左上角）
          if (_scenes.isNotEmpty && !_isLoadingScene) ...[
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                _formatTime(_remainingTime),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
          
          const Spacer(),
          
          // 音乐控制按钮
          IconButton(
            icon: Icon(
              _isMusicPlaying ? Icons.volume_up : Icons.volume_off,
              color: Colors.white,
            ),
            onPressed: () async {
              if (_isMusicPlaying) {
                await _audioPlayer.pause();
              } else {
                await _audioPlayer.resume();
              }
              setState(() {
                _isMusicPlaying = !_isMusicPlaying;
              });
            },
          ),
          
          // 停止按钮
          IconButton(
            icon: const Icon(Icons.stop, color: Colors.white),
            onPressed: () {
              _stopMeditation();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 大倒计时
          Text(
            _formatTime(_remainingTime),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 64,
              fontWeight: FontWeight.w300,
              letterSpacing: 2,
            ),
          ),
          
          const SizedBox(height: 40),
          
          // 呼吸动画
          _buildBreathingAnimation(),
          
          const SizedBox(height: 40),
          
          // 加载提示
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
          
          const SizedBox(height: 20),
          
          Text(
            AppLocalizations.of(context)!.generatingMeditationScene,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMeditationView() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const Spacer(),
          
          // 呼吸动画
          _buildBreathingAnimation(),
          
          const SizedBox(height: 40),
          
          // 冥想文字
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Text(
                  _scenes[_currentSceneIndex]['text'] ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    height: 1.6,
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 20),
                
                // 名言
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    _quotes[_currentQuoteIndex],
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          
          const Spacer(),
        ],
      ),
    );
  }
  
  Widget _buildBreathingAnimation() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // 外层涟漪效果
        AnimatedBuilder(
          animation: _rippleController,
          builder: (context, child) {
            return Container(
              width: 280 + (_rippleController.value * 80),
              height: 280 + (_rippleController.value * 80),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF8B9AFF).withOpacity(0.2 - (_rippleController.value * 0.2)),
                  width: 1.5,
                ),
              ),
            );
          },
        ),
        
        // 中层涟漪效果
        AnimatedBuilder(
          animation: _rippleController,
          builder: (context, child) {
            return Container(
              width: 220 + (_rippleController.value * 60),
              height: 220 + (_rippleController.value * 60),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF6C7CE7).withOpacity(0.3 - (_rippleController.value * 0.3)),
                  width: 2,
                ),
              ),
            );
          },
        ),
        
        // 主呼吸圆圈
        AnimatedBuilder(
          animation: _breathingController,
          builder: (context, child) {
            final breathingSize = 160 + (_breathingController.value * 60);
            return Container(
              width: breathingSize,
              height: breathingSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF8B9AFF).withOpacity(0.4),
                    const Color(0xFF6C7CE7).withOpacity(0.2),
                    const Color(0xFF4A5FE7).withOpacity(0.1),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.4, 0.7, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8B9AFF).withOpacity(0.3),
                    blurRadius: 20 + (_breathingController.value * 10),
                    spreadRadius: 5,
                  ),
                ],
              ),
            );
          },
        ),
        
        // 内层装饰圆圈
        AnimatedBuilder(
          animation: _breathingController,
          builder: (context, child) {
            return Container(
              width: 80 + (_breathingController.value * 20),
              height: 80 + (_breathingController.value * 20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
            );
          },
        ),
        
        // 中心呼吸提示
        AnimatedBuilder(
          animation: _breathingController,
          builder: (context, child) {
            final isInhaling = _breathingController.value > 0.5;
            final progress = _breathingController.value;
            
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 主要文字
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    isInhaling ? AppLocalizations.of(context)!.inhale : AppLocalizations.of(context)!.exhale,
                    key: ValueKey(isInhaling),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2,
                      shadows: [
                        Shadow(
                          color: const Color(0xFF8B9AFF).withOpacity(0.5),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // 进度指示器
                Container(
                  width: 60,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: 60 * progress,
                      height: 4,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF8B9AFF),
                            Color(0xFF6C7CE7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF8B9AFF).withOpacity(0.5),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 6),
                
                // 辅助提示文字
                Text(
                  isInhaling ? AppLocalizations.of(context)!.feelEnergyFlow : AppLocalizations.of(context)!.releaseTension,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 1,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
  

}