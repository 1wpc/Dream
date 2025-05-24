import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/deepseek_service.dart';
import '../services/jimeng_service.dart';
import 'dream_style_selection_page.dart';
import 'dart:async';

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

  @override
  void initState() {
    super.initState();
    _initializeDream();
    _startQuoteTimer();
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

  @override
  void dispose() {
    _quoteTimer?.cancel();
    super.dispose();
  }

  // 初始化梦境
  Future<void> _initializeDream() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 调用 DeepSeek API 生成梦境剧本，传递风格关键词
      final result = await DeepSeekService.generateDreamScript(
        styleKeywords: widget.dreamStyle?.keywords,
      );
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
      final result = await DeepSeekService.generateDreamScene(
        styleKeywords: widget.dreamStyle?.keywords,
      );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 背景图片
          if (!_isLoading && _scenes.isNotEmpty)
            Positioned.fill(
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
          // 半透明遮罩
          Container(
            color: Colors.black.withOpacity(0.3),
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
              bottom: 50,
              left: 20,
              right: 20,
              child: SafeArea(
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.3,
                  ),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _scenes[_currentSceneIndex].description,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '提示词: ${_scenes[_currentSceneIndex].prompt}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
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
        ],
      ),
      // 点击切换场景
      floatingActionButton: !_isLoading && _scenes.isNotEmpty
          ? FloatingActionButton(
              onPressed: _nextScene,
              child: const Icon(Icons.arrow_forward),
            )
          : null,
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