import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'dream_style_selection_page.dart';
import 'smart_meditation_page.dart';

class MeditationPage extends StatefulWidget {
  const MeditationPage({super.key});

  @override
  State<MeditationPage> createState() => _MeditationPageState();
}

class _MeditationPageState extends State<MeditationPage>
    with TickerProviderStateMixin {
  late AnimationController _breathingController;
  late AnimationController _rippleController;
  
  int _duration = 5; // 默认5分钟
  DreamStyle? _selectedStyle; // 选择的风格
  
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
    
    
    
    // 启动呼吸动画
    _breathingController.repeat(reverse: true);
    
    // 启动涟漪动画
    _rippleController.repeat();
  }
  
  @override
  void dispose() {
    _breathingController.dispose();
    _rippleController.dispose();
    super.dispose();
  }
  
  void _startMeditation() async {
    if (_selectedStyle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.pleaseSelectMeditationStyle),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    // 导航到智能冥想页面
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SmartMeditationPage(
          duration: _duration,
          dreamStyle: _selectedStyle!,
        ),
      ),
    );
  }
  
  void _selectStyle() async {
    final result = await Navigator.of(context).push<DreamStyle>(
      MaterialPageRoute(
        builder: (context) => const DreamStyleSelectionPage(),
      ),
    );
    
    if (result != null) {
      setState(() {
        _selectedStyle = result;
      });
    }
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
              Color(0xFF16213e),
              Color(0xFF0f3460),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 顶部导航
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context)!.smartMeditation,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48), // 平衡左侧的返回按钮
                  ],
                ),
              ),
              
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                  child: Column(
                    children: [
                      // 标题
                      Text(
                        AppLocalizations.of(context)!.startSmartMeditationJourney,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: 12),
                      
                      Text(
                        AppLocalizations.of(context)!.selectDurationAndStyle,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // 时长选择
                      Text(
                        AppLocalizations.of(context)!.selectMeditationDuration,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        alignment: WrapAlignment.center,
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
                                    ? Colors.white.withOpacity(0.2)
                                    : Colors.transparent,
                                border: Border.all(
                                  color: isSelected 
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.3),
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child: Text(
                                '${duration}${AppLocalizations.of(context)!.minutes}',
                                style: TextStyle(
                                  color: isSelected 
                                      ? Colors.white
                                      : Colors.white70,
                                  fontSize: 14,
                                  fontWeight: isSelected 
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // 风格选择
                      Text(
                        AppLocalizations.of(context)!.selectMeditationStyle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      GestureDetector(
                        onTap: _selectStyle,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: _selectedStyle != null 
                                ? Colors.white.withOpacity(0.1)
                                : Colors.transparent,
                            border: Border.all(
                              color: _selectedStyle != null 
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Row(
                            children: [
                              if (_selectedStyle != null) ...[
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: _selectedStyle!.gradient,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    _selectedStyle!.icon,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _selectedStyle!.name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _selectedStyle!.description,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ] else ...[
                                const Icon(
                                  Icons.palette_outlined,
                                  color: Colors.white70,
                                  size: 24,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    AppLocalizations.of(context)!.clickToSelectMeditationStyle,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
                              const Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.white70,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // 开始按钮
                      GestureDetector(
                        onTap: _startMeditation,
                        child: Container(
                          constraints: const BoxConstraints(
                            minWidth: 200,
                            maxWidth: 300,
                          ),
                          height: 60,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF8B9AFF),
                                Color(0xFF6C7CE7),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF8B9AFF).withOpacity(0.3),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              AppLocalizations.of(context)!.startMeditation,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
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
    );
  }
  
}