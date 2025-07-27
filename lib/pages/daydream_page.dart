import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/deepseek_service.dart';
import '../services/jimeng_service.dart';
import 'dream_style_selection_page.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';
import 'package:flutter/services.dart';

// 加载期间显示的名言列表
const List<String> _quotes = [
  '梦是心灵的翅膀',
  '每一个不曾起舞的日子，都是对生命的辜负',
  '梦里能到达的地方，总有一天脚步也能到达',
  '心有多大，梦就有多远',
  '梦，是灵魂的低语',
  '敢于梦想，才能成就非凡',
  '梦是现实的种子',
  '让梦想照亮现实',
  '梦境，是灵感的源泉',
  '追梦的路上，星光不问赶路人',
];

// 竖排多列分组函数
List<String> splitToColumns(String text, int colLen) {
  List<String> columns = [];
  for (int i = 0; i < text.length; i += colLen) {
    columns.add(text.substring(i, (i + colLen > text.length) ? text.length : i + colLen));
  }
  return columns;
}

class DaydreamPage extends StatefulWidget {
  final DreamStyle? dreamStyle;
  
  const DaydreamPage({super.key, this.dreamStyle});

  @override
  State<DaydreamPage> createState() => _DaydreamPageState();
}

class _DaydreamPageState extends State<DaydreamPage> {
  // 当前场景索引
  int _currentSceneIndex = 0;
  // 场景列表
  final List<DreamScene> _scenes = [];
  // 是否正在加载
  bool _isLoading = true;
  // 是否正在生成新场景
  bool _isGenerating = false;
  // 当前显示的名言索引
  int _currentQuoteIndex = 0;
  // 定时器
  Timer? _quoteTimer;
  
  // 音频播放器相关
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isMusicPlaying = false;
  bool _isMusicLoaded = false;

  @override
  void initState() {
    super.initState();
    _initializeDream();
    _startQuoteTimer();
    _initializeAudio();
  }

  void _startQuoteTimer() {
    _quoteTimer?.cancel();
    _quoteTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_isLoading) {
        setState(() {
          _currentQuoteIndex = (_currentQuoteIndex + 1) % _quotes.length;
        });
      }
    });
  }

  // 初始化音频
  Future<void> _initializeAudio() async {
    try {
      // 设置循环播放
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      // 设置音量为30%
      await _audioPlayer.setVolume(0.3);
      
      setState(() {
        _isMusicLoaded = true;
      });
      
      // 监听播放状态变化
      _audioPlayer.onPlayerStateChanged.listen((PlayerState state) {
        if (mounted) {
          setState(() {
            _isMusicPlaying = state == PlayerState.playing;
          });
        }
      });
      
      debugPrint('音频初始化成功');
    } catch (e) {
      debugPrint('音频初始化失败: $e');
      setState(() {
        _isMusicLoaded = false;
      });
    }
  }

  // 切换音乐播放状态
  Future<void> _toggleMusic() async {
    if (!_isMusicLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔇 音频功能暂不可用'),
          duration: Duration(seconds: 1),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    try {
      if (_isMusicPlaying) {
        await _audioPlayer.pause();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('🔇 背景音乐已暂停'),
            duration: const Duration(seconds: 1),
            backgroundColor: Colors.grey.shade600,
          ),
        );
      } else {
        await _audioPlayer.play(AssetSource('audio/dream_music.mp3'));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('🎵 背景音乐已开启'),
            duration: const Duration(seconds: 1),
            backgroundColor: Colors.green.shade600,
          ),
        );
      }
    } catch (e) {
      debugPrint('音乐播放控制失败: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🔇 播放失败: ${e.toString().contains('FileSystemException') ? '音频文件不存在' : '播放错误'}'),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }

  @override
  void dispose() {
    _quoteTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  // 解析流式响应的JSON
  Map<String, dynamic> _parseStreamResponse(String response) {
    debugPrint('开始解析响应，长度: ${response.length}');
    debugPrint('响应前100字符: ${response.length > 100 ? response.substring(0, 100) : response}');
    
    try {
      // 尝试直接解析JSON
      final result = jsonDecode(response) as Map<String, dynamic>;
      debugPrint('直接JSON解析成功');
      return result;
    } catch (e) {
      debugPrint('直接JSON解析失败: $e');
      
      try {
        // 清理响应文本，移除可能的控制字符和多余空白
        String cleanResponse = response
            .replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '') // 移除控制字符
            .trim();
        
        debugPrint('清理后的响应: $cleanResponse');
        
        // 尝试解析清理后的JSON
        final result = jsonDecode(cleanResponse) as Map<String, dynamic>;
        debugPrint('清理后JSON解析成功');
        return result;
      } catch (e2) {
        debugPrint('清理后JSON解析失败: $e2');
        
        try {
          // 尝试提取JSON部分（更宽松的方式）
          final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(response);
          if (jsonMatch != null) {
            final jsonStr = jsonMatch.group(0)!;
            debugPrint('提取到的JSON: $jsonStr');
            final result = jsonDecode(jsonStr) as Map<String, dynamic>;
            debugPrint('提取JSON解析成功');
            return result;
          }
        } catch (e3) {
          debugPrint('提取JSON解析失败: $e3');
        }
        
        // 尝试更宽松的JSON提取
        final lines = response.split('\n');
        for (final line in lines) {
          if (line.trim().startsWith('{')) {
            try {
              final result = jsonDecode(line.trim()) as Map<String, dynamic>;
              debugPrint('逐行JSON解析成功');
              return result;
            } catch (_) {}
          }
        }
      }
      
      // 如果仍然失败，返回默认结构（包含多个场景）
      debugPrint('所有解析方法都失败，使用默认数据: $response');
      return {
        'prompts': [
          'A mystical dream landscape with ethereal lighting, floating islands, aurora borealis, fantasy realm',
          'Enchanted forest with glowing mushrooms, fairy lights, misty atmosphere, magical creatures',
          'Celestial garden with crystal flowers, starlight streams, cosmic butterflies, dreamy ambiance',
          'Ancient temple in clouds, golden light rays, floating petals, serene meditation space'
        ],
        'explanations': [
          '梦境如诗，意境深远',
          '森林幽深，光影斑驳',
          '星河璀璨，花开彼岸',
          '古刹钟声，禅意悠然'
        ],
      };
    }
  }

  // 初始化梦境
  Future<void> _initializeDream() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 调用 DeepSeek API 生成梦境剧本，传递风格关键词
      String fullResponse = '';
      await for (final chunk in DeepSeekService.generateDreamScript(
        styleKeywords: widget.dreamStyle?.keywords,
      )) {
        fullResponse += chunk;
      }
      
      debugPrint('DeepSeek完整响应: $fullResponse');
      
      // 解析JSON响应
      final result = _parseStreamResponse(fullResponse);
      final prompts = (result['prompts'] as List).cast<String>();
      final explanations = (result['explanations'] as List).cast<String>();
      
      // 调用即梦AI生成图片
      final imageUrls = await JimengService.generateImages(prompts);
      
      setState(() {
        _scenes.clear();
        for (var i = 0; i < prompts.length; i++) {
          _scenes.add(
            DreamScene(
              imageUrl: imageUrls[i],
              prompt: prompts[i],
              description: explanations[i],
            ),
          );
        }
      });
    } catch (e) {
      debugPrint('初始化梦境失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('初始化梦境失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 生成新场景
  Future<void> _generateNewScene() async {
    if (_isGenerating) return;

    setState(() {
      _isGenerating = true;
    });

    try {
      // 调用 DeepSeek API 生成新的场景描述，传递风格关键词
      String fullResponse = '';
      await for (final chunk in DeepSeekService.generateDreamScene(
        styleKeywords: widget.dreamStyle?.keywords,
      )) {
        fullResponse += chunk;
      }
      
      debugPrint('DeepSeek场景响应: $fullResponse');
      
      // 解析JSON响应
      final result = _parseStreamResponse(fullResponse);
      final prompts = (result['prompts'] as List).cast<String>();
      final explanations = (result['explanations'] as List).cast<String>();
      
      // 调用即梦AI生成图片
      final imageUrls = await JimengService.generateImages(prompts);
      
      setState(() {
        for (var i = 0; i < prompts.length; i++) {
          _scenes.add(
            DreamScene(
              imageUrl: imageUrls[i],
              prompt: prompts[i],
              description: explanations[i],
            ),
          );
        }
        _currentSceneIndex = _scenes.length - 1;
      });
    } catch (e) {
      debugPrint('生成新场景失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('生成新场景失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }

  // 切换到下一个场景
  void _nextScene() {
    if (_currentSceneIndex < _scenes.length - 1) {
      setState(() {
        _currentSceneIndex++;
      });
    } else {
      _generateNewScene();
    }
  }

  // 切换到上一个场景
  void _previousScene() {
    if (_currentSceneIndex > 0) {
      setState(() {
        _currentSceneIndex--;
      });
    }
  }

  // 保存图片到本地
  Future<void> _saveImageToGallery() async {
    if (_scenes.isEmpty) return;
    
    try {
      // 检查并请求权限
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        await Gal.requestAccess();
        final hasAccessAfterRequest = await Gal.hasAccess();
        if (!hasAccessAfterRequest) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('需要相册权限才能保存图片'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }
      
      // 显示保存中提示
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('正在保存图片...'),
          duration: Duration(seconds: 1),
        ),
      );
      
      // 下载图片
      final imageUrl = _scenes[_currentSceneIndex].imageUrl;
      final response = await http.get(Uri.parse(imageUrl));
      
      if (response.statusCode == 200) {
        // 创建临时文件
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/dream_${DateTime.now().millisecondsSinceEpoch}.jpg');
        await tempFile.writeAsBytes(response.bodyBytes);
        
        // 保存到相册
        await Gal.putImage(tempFile.path);
        
        // 删除临时文件
        await tempFile.delete();
        
        // 触觉反馈
        HapticFeedback.lightImpact();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ 图片已保存到相册'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        throw Exception('下载图片失败');
      }
    } catch (e) {
      debugPrint('保存图片失败: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ 保存失败: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // 显示保存确认对话框
  void _showSaveDialog() {
    // 触觉反馈
    HapticFeedback.mediumImpact();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black.withOpacity(0.9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.save_alt,
                color: Colors.white,
                size: 24,
              ),
              SizedBox(width: 12),
              Text(
                '保存图片',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: const Text(
            '是否将当前梦境图片保存到相册？',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                '取消',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 16,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _saveImageToGallery();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
              child: const Text(
                '保存',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 背景图片
          if (!_isLoading && _scenes.isNotEmpty)
            Positioned.fill(
              child: GestureDetector(
                onLongPress: _showSaveDialog,
                child: CachedNetworkImage(
                  imageUrl: _scenes[_currentSceneIndex].imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.black,
                    child: const Center(
                      child: Icon(
                        Icons.error_outline,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // 加载指示器
          if (_isLoading)
            Center(
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height - 120,
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: MediaQuery.of(context).size.height < 600 ? 10 : 20, 
                      horizontal: 20
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 竖排名言
                        Flexible(
                          child: Container(
                            constraints: BoxConstraints(
                              maxHeight: MediaQuery.of(context).size.height < 600 ? 
                                        MediaQuery.of(context).size.height * 0.35 :
                                        MediaQuery.of(context).size.height * 0.4,
                            ),
                            child: Center(
                              child: Builder(
                                builder: (context) {
                                  final screenHeight = MediaQuery.of(context).size.height;
                                  final colLength = screenHeight < 600 ? 6 : 4;
                                  final columns = splitToColumns(_quotes[_currentQuoteIndex], colLength);
                                  final fontSize = screenHeight < 600 ? 18.0 : 
                                                 screenHeight < 800 ? 22.0 : 28.0;
                                  final letterSpacing = screenHeight < 600 ? 2.0 :
                                                       screenHeight < 800 ? 4.0 : 8.0;
                                  
                                  return Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: columns.map((col) {
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 2),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: col.split('').map((char) => Text(
                                            char,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: fontSize,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: letterSpacing,
                                            ),
                                          )).toList(),
                                        ),
                                      );
                                    }).toList(),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: MediaQuery.of(context).size.height < 600 ? 12 : 30),
                        // 底部"梦境编织中"及加载图标
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(color: Colors.white),
                            SizedBox(height: MediaQuery.of(context).size.height < 600 ? 8 : 12),
                            const Text(
                              '梦境编织中',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          // 场景描述
          if (!_isLoading && _scenes.isNotEmpty)
            Positioned(
              bottom: 140, // 调整位置，避免与页数指示器重叠
              left: 20,
              right: 20,
              child: SafeArea(
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.35, // 增加最大高度
                  ),
                  padding: const EdgeInsets.all(16), // 减少内边距以节省空间
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6), // 增加透明度
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      _scenes[_currentSceneIndex].description,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18, // 增大字体，因为只显示中文
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
          // 生成中提示
          if (_isGenerating)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      '正在编织新的梦境...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          
          // 音乐控制按钮 - 右上角
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 20,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: _isMusicPlaying ? Colors.green.shade300 : Colors.white.withOpacity(0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    _isMusicPlaying ? Icons.music_note : Icons.music_off,
                    key: ValueKey(_isMusicPlaying),
                    color: _isMusicPlaying ? Colors.green.shade300 : Colors.white,
                    size: 24,
                  ),
                ),
                onPressed: _isMusicLoaded ? _toggleMusic : null,
                tooltip: _isMusicPlaying ? '暂停音乐' : '播放音乐',
                splashColor: _isMusicPlaying ? Colors.green.withOpacity(0.3) : Colors.white.withOpacity(0.3),
                highlightColor: _isMusicPlaying ? Colors.green.withOpacity(0.2) : Colors.white.withOpacity(0.2),
              ),
            ),
          ),
          
          // 场景指示器
          if (!_isLoading && _scenes.isNotEmpty && _scenes.length > 1)
            Positioned(
              bottom: 90, // 调整位置，避免与按钮重叠
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    '${_currentSceneIndex + 1} / ${_scenes.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ),
          
          // 场景切换按钮
          if (!_isLoading && _scenes.isNotEmpty) ...[
            // 左箭头 - 上一个场景（只在不是第一个场景时显示）
            if (_currentSceneIndex > 0)
              Positioned(
                left: 20,
                bottom: 20, // 调整位置，避免与页数指示器重叠
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 24,
                    ),
                    onPressed: _previousScene,
                    tooltip: '上一个场景',
                    splashColor: Colors.white.withOpacity(0.3),
                    highlightColor: Colors.white.withOpacity(0.2),
                  ),
                ),
              ),
            // 右箭头 - 下一个场景
            Positioned(
              right: 20,
              bottom: 20, // 调整位置，避免与页数指示器重叠
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: Colors.blue.shade300.withOpacity(0.6),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(
                    _currentSceneIndex < _scenes.length - 1 
                        ? Icons.arrow_forward 
                        : Icons.add,
                    color: Colors.blue.shade300,
                    size: 24,
                  ),
                  onPressed: _nextScene,
                  tooltip: _currentSceneIndex < _scenes.length - 1 
                      ? '下一个场景' 
                      : '生成新场景',
                  splashColor: Colors.blue.withOpacity(0.3),
                  highlightColor: Colors.blue.withOpacity(0.2),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// 梦境场景数据模型
class DreamScene {
  final String imageUrl;
  final String prompt;
  final String description;

  DreamScene({
    required this.imageUrl,
    required this.prompt,
    required this.description,
  });
}