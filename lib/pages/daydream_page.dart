import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/deepseek_service.dart';
import '../services/jimeng_service.dart';

class DaydreamPage extends StatefulWidget {
  const DaydreamPage({super.key});

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

  @override
  void initState() {
    super.initState();
    _initializeDream();
  }

  // 初始化梦境
  Future<void> _initializeDream() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 调用 DeepSeek API 生成梦境剧本
      final result = await DeepSeekService.generateDreamScript();
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
      // 调用 DeepSeek API 生成新的场景描述
      final result = await DeepSeekService.generateDreamScene();
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
            const Center(
              child: CircularProgressIndicator(),
            ),
          // 场景描述
          if (!_isLoading && _scenes.isNotEmpty)
            Positioned(
              bottom: 50,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(15),
                ),
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
          // 生成中提示
          if (_isGenerating)
            const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    '正在编织新的梦境...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
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