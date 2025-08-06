import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../services/deepseek_service.dart';
import 'dart:io';
import 'edit_dream_page.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class DreamDetailPage extends StatefulWidget {
  final DreamRecord dream;

  const DreamDetailPage({
    super.key,
    required this.dream,
  });

  @override
  State<DreamDetailPage> createState() => _DreamDetailPageState();
}

class _DreamDetailPageState extends State<DreamDetailPage> with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  double _pullOffset = 0.0; // 下拉偏移量
  double _scrollOffset = 0.0; // 滚动偏移量
  final DatabaseService _databaseService = DatabaseService();
  
  // 缓存背景组件
  Widget? _cachedBackgroundWidget;
  bool _imageExists = false;
  
  // AI解梦相关状态
  bool _isInterpreting = false;
  String? _dreamInterpretation;
  bool _showInterpretation = false;
  String _streamingText = ''; // 流式输出的累积文本

  // 分享相关状态
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _initializeBackground();
    _checkExistingInterpretation();
  }

  // 检查是否已有AI解析
  void _checkExistingInterpretation() {
    if (widget.dream.aiInterpretation != null && widget.dream.aiInterpretation!.isNotEmpty) {
      setState(() {
        _dreamInterpretation = widget.dream.aiInterpretation;
        _showInterpretation = true;
      });
    }
  }

  // 保存AI解析结果到数据库
  Future<void> _saveInterpretationToDatabase(String interpretation) async {
    try {
      final updatedDream = DreamRecord(
        id: widget.dream.id,
        title: widget.dream.title,
        time: widget.dream.time,
        content: widget.dream.content,
        imageUrl: widget.dream.imageUrl,
        aiInterpretation: interpretation,
      );
      await _databaseService.updateDream(updatedDream);
    } catch (e) {
      print('保存AI解析失败: $e');
    }
  }

  // 初始化背景，避免重复构建
  Future<void> _initializeBackground() async {
    if (widget.dream.imageUrl != null) {
      try {
        _imageExists = await File(widget.dream.imageUrl!).exists();
      } catch (e) {
        _imageExists = false;
      }
    } else {
      _imageExists = false;
    }
    
    // 构建并缓存背景组件
    _cachedBackgroundWidget = _buildBackgroundImage();
    
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    
    final newOffset = _scrollController.offset;
    
    // 减少更新频率，只在变化超过3像素时才更新
    if ((newOffset - _scrollOffset).abs() > 3) {
      setState(() {
        _scrollOffset = newOffset;
      });
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    // 只有当滚动到顶部时才处理下拉
    if (_scrollController.offset <= 0) {
      setState(() {
        _pullOffset = (_pullOffset + details.delta.dy).clamp(0.0, 300.0);
      });
    }
  }

  void _onPanEnd(DragEndDetails details) {
    // 松手时不回弹，保持当前状态
    // 如果下拉距离小于一定值，则回到初始状态
    if (_pullOffset < 50) {
      setState(() {
        _pullOffset = 0.0;
      });
    }
  }

  Future<void> _interpretDream() async {
    if (_isInterpreting) return;

    setState(() {
      _isInterpreting = true;
      _showInterpretation = true; // 立即显示解析区域
      _streamingText = ''; // 清空之前的文本
      _dreamInterpretation = null;
    });

    try {
      // 使用流式输出
      await for (final chunk in DeepSeekService.interpretDreamStream(
        widget.dream.title,
        widget.dream.content,
      )) {
        setState(() {
          _streamingText += chunk;
        });
      }
      
      // 流式输出完成
      setState(() {
        _dreamInterpretation = _streamingText;
        _isInterpreting = false;
      });

      // 保存AI解析结果到数据库
      await _saveInterpretationToDatabase(_streamingText);

      // 添加触觉反馈
      HapticFeedback.lightImpact();
    } catch (e) {
      setState(() {
        _isInterpreting = false;
        _showInterpretation = false;
        _streamingText = '';
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)!.aiInterpretationFailed}：${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    }
  }

  // 简单的markdown样式文本渲染函数
  Widget _buildMarkdownText(String text) {
    final lines = text.split('\n');
    List<Widget> widgets = [];
    
    for (String line in lines) {
      line = line.trim();
      if (line.isEmpty) {
        widgets.add(const SizedBox(height: 8));
        continue;
      }
      
      // 处理标题 **文本**
      if (line.startsWith('**') && line.endsWith('**') && line.length > 4) {
        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            line.substring(2, line.length - 2),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A237E),
              height: 1.5,
            ),
          ),
        ));
      }
      // 处理小标题或重点文字
      else if (line.contains('**')) {
        List<TextSpan> spans = [];
        RegExp boldRegex = RegExp(r'\*\*(.*?)\*\*');
        int lastEnd = 0;
        
        for (Match match in boldRegex.allMatches(line)) {
          if (match.start > lastEnd) {
            spans.add(TextSpan(
              text: line.substring(lastEnd, match.start),
              style: const TextStyle(
                fontSize: 15,
                height: 1.8,
                color: Color(0xFF333333),
              ),
            ));
          }
          spans.add(TextSpan(
            text: match.group(1),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A237E),
              height: 1.8,
            ),
          ));
          lastEnd = match.end;
        }
        
        if (lastEnd < line.length) {
          spans.add(TextSpan(
            text: line.substring(lastEnd),
            style: const TextStyle(
              fontSize: 15,
              height: 1.8,
              color: Color(0xFF333333),
            ),
          ));
        }
        
        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: RichText(
            text: TextSpan(children: spans),
          ),
        ));
      }
      // 普通文本
      else {
        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text(
            line,
            style: const TextStyle(
              fontSize: 15,
              height: 1.8,
              color: Color(0xFF333333),
            ),
          ),
        ));
      }
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Future<void> _deleteDream() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.confirmDelete),
        content: Text(AppLocalizations.of(context)!.confirmDeleteDreamMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              AppLocalizations.of(context)!.delete,
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _databaseService.deleteDream(widget.dream.id!);
        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.deleteSuccess)),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${AppLocalizations.of(context)!.deleteFailed}：$e')),
          );
        }
      }
    }
  }

  Widget _buildBackgroundImage() {
    if (!_imageExists) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF667eea),
              Color(0xFF764ba2),
              Color(0xFFf093fb),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: const Center(
          child: Icon(
            Icons.nights_stay,
            color: Colors.white,
            size: 64,
          ),
        ),
      );
    }

    return Image.file(
      File(widget.dream.imageUrl!),
      fit: BoxFit.cover,
      cacheWidth: null,
      cacheHeight: null,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF667eea),
                Color(0xFF764ba2),
                Color(0xFFf093fb),
              ],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.nights_stay,
              color: Colors.white,
              size: 64,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    
    final screenHeight = MediaQuery.of(context).size.height;
    
    // 计算各种效果参数
    final pullProgress = (_pullOffset / 200).clamp(0.0, 1.0);
    final scrollProgress = _scrollOffset > 0 ? (_scrollOffset / 300).clamp(0.0, 1.0) : 0.0;
    
    // 遮罩透明度：下拉时减少，让背景更清晰
    final overlayOpacity = (0.6 * (1 - pullProgress)).clamp(0.0, 0.6);
    
    // 内容透明度和位移
    final contentOpacity = (1 - pullProgress * 1.2).clamp(0.0, 1.0);
    
    // 导航栏效果
    final appBarOpacity = scrollProgress > 0.3 ? 0.9 : 0.0;
    final iconColor = appBarOpacity > 0.5 ? Colors.black : Colors.white;

    return Scaffold(
      body: GestureDetector(
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        child: Stack(
          children: [
            // 背景图片
            Positioned.fill(
              child: _cachedBackgroundWidget ?? Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF667eea),
                      Color(0xFF764ba2),
                      Color(0xFFf093fb),
                    ],
                    stops: [0.0, 0.5, 1.0],
                  ),
                ),
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
            ),
            
            // 动态渐变遮罩
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(overlayOpacity * 0.3),
                      Colors.black.withOpacity(overlayOpacity),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),

            // 主要内容 - 根据下拉偏移进行变换
            Transform.translate(
              offset: Offset(0, _pullOffset),
              child: Opacity(
                opacity: contentOpacity,
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: const ClampingScrollPhysics(),
                  slivers: [
                    // 顶部空白区域用于展示背景
                    SliverToBoxAdapter(
                      child: Container(
                        height: screenHeight * 0.5,
                        padding: const EdgeInsets.fromLTRB(24, 120, 24, 20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.black.withOpacity(0.3),
                                    Colors.black.withOpacity(0.1),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    widget.dream.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black54,
                                          offset: Offset(0, 2),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _formatDate(widget.dream.time),
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black54,
                                          offset: Offset(0, 1),
                                          blurRadius: 2,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // 内容卡片
                    SliverToBoxAdapter(
                      child: Container(
                        margin: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 30,
                              offset: const Offset(0, 15),
                              spreadRadius: 0,
                            ),
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 拖拽指示器
                            Center(
                              child: Container(
                                margin: const EdgeInsets.only(top: 12, bottom: 20),
                                width: 40,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.nights_stay,
                                        color: Colors.blue.shade700,
                                        size: 24,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        AppLocalizations.of(context)!.dreamContent,
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1A237E),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          const Color(0xFFF8F9FA),
                                          const Color(0xFFF1F3F4),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: const Color(0xFFE8EAED),
                                        width: 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.02),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      widget.dream.content,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        height: 1.8,
                                        color: Color(0xFF333333),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 30),
                                  
                                  // AI解梦按钮
                                  Center(
                                    child: Container(
                                      width: double.infinity,
                                      margin: const EdgeInsets.symmetric(horizontal: 0),
                                      child: ElevatedButton.icon(
                                        onPressed: _isInterpreting ? null : _interpretDream,
                                        icon: _isInterpreting 
                                          ? SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor: AlwaysStoppedAnimation<Color>(
                                                  Colors.white.withOpacity(0.8),
                                                ),
                                              ),
                                            )
                                          : const Icon(
                                              Icons.psychology,
                                              size: 20,
                                            ),
                                        label: Text(
                                          _isInterpreting ? AppLocalizations.of(context)!.interpreting : AppLocalizations.of(context)!.aiInterpretDream,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF667eea),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 32,
                                            vertical: 18,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(30),
                                          ),
                                          elevation: 0,
                                          shadowColor: Colors.transparent,
                                        ).copyWith(
                                          backgroundColor: MaterialStateProperty.resolveWith<Color>(
                                            (Set<MaterialState> states) {
                                              if (states.contains(MaterialState.pressed)) {
                                                return const Color(0xFF5a67d8);
                                              }
                                              return const Color(0xFF667eea);
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  
                                  // AI解梦结果
                                  if (_showInterpretation) ...[
                                    const SizedBox(height: 30),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            const Color(0xFFF3F4F6),
                                            const Color(0xFFE5E7EB),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(22),
                                        border: Border.all(
                                          color: const Color(0xFFD1D5DB),
                                          width: 1,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.03),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF667eea).withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Icon(
                                                  Icons.auto_awesome,
                                                  color: const Color(0xFF667eea),
                                                  size: 20,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Text(
                                                AppLocalizations.of(context)!.aiInterpretationAnalysis,
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF374151),
                                                ),
                                              ),
                                              if (_isInterpreting) ...[
                                                const Spacer(),
                                                SizedBox(
                                                  width: 16,
                                                  height: 16,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor: AlwaysStoppedAnimation<Color>(
                                                      const Color(0xFF667eea),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 16),
                                          // 显示流式文本或完整文本（使用Markdown渲染）
                                          AnimatedSwitcher(
                                            duration: const Duration(milliseconds: 300),
                                            child: _buildMarkdownText(_isInterpreting && _streamingText.isNotEmpty 
                                                ? _streamingText 
                                                : (_dreamInterpretation ?? AppLocalizations.of(context)!.analyzingDream)),
                                            key: ValueKey(_isInterpreting ? _streamingText : _dreamInterpretation),
                                          ),
                                          // 流式输出时的打字机光标效果
                                          if (_isInterpreting && _streamingText.isNotEmpty)
                                            Container(
                                              margin: const EdgeInsets.only(top: 4),
                                              child: Row(
                                                children: [
                                                  Container(
                                                    width: 2,
                                                    height: 16,
                                                    color: const Color(0xFF667eea),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    AppLocalizations.of(context)!.parsing,
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Color(0xFF667eea),
                                                      fontStyle: FontStyle.italic,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  
                                  const SizedBox(height: 40),
                                  Center(
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.auto_awesome,
                                          color: Colors.grey.shade400,
                                          size: 20,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          AppLocalizations.of(context)!.sweetDreams,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade500,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                        const SizedBox(height: 40),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 浮动导航栏
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top,
                  left: 16,
                  right: 16,
                  bottom: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(appBarOpacity),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: iconColor),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Spacer(),
                    // 分享按钮
                    IconButton(
                      icon: _isSharing 
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                              ),
                            )
                          : Icon(Icons.share, color: iconColor),
                      onPressed: _isSharing ? null : () {
                        _showShareOptions();
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.edit, color: iconColor),
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditDreamPage(dream: widget.dream),
                          ),
                        );
                        if (result == true && mounted) {
                          Navigator.pop(context, true);
                        }
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline, color: iconColor),
                      onPressed: _deleteDream,
                    ),
                  ],
                ),
              ),
            ),

            // 下拉提示
            if (pullProgress > 0.1)
              Positioned(
                top: MediaQuery.of(context).padding.top + 100,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      pullProgress > 0.8 ? AppLocalizations.of(context)!.enjoyingView : AppLocalizations.of(context)!.pullToViewFullscreen,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),

            // 重置按钮（当有下拉偏移时显示）
            if (_pullOffset > 50)
              Positioned(
                bottom: 100,
                right: 20,
                child: FloatingActionButton.small(
                  onPressed: () {
                    setState(() {
                      _pullOffset = 0.0;
                    });
                  },
                  backgroundColor: Colors.black.withOpacity(0.6),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  String _formatDate(String isoString) {
    try {
      final date = DateTime.parse(isoString);
      return '${date.year}年${date.month}月${date.day}日 ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return isoString;
    }
  }

  void _showShareOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.98),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, -8),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.shareDreamToCommunity,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)!.chooseShareMethod,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  SizedBox(height: 16),
                  // 快速分享选项
                  Container(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.grey.shade200,
                        width: 1,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      leading: Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.blue.shade400,
                              Colors.blue.shade600,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.2),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.flash_on,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        AppLocalizations.of(context)!.quickShare,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      subtitle: Text(
                        AppLocalizations.of(context)!.quickShareDescription,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey.shade400,
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _quickShare();
                      },
                    ),
                  ),
                  SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 分享梦境到社区  

  // 快速分享梦境
  Future<void> _quickShare() async {
    setState(() {
      _isSharing = true;
    });

    try {

      setState(() {
        _isSharing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text(AppLocalizations.of(context)!.dreamSharedSuccessfully),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
        HapticFeedback.lightImpact();
      }
    } catch (e) {
      setState(() {
        _isSharing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)!.quickShareFailed}：${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}