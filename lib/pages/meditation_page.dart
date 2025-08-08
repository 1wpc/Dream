import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'smart_meditation_page.dart';

// 音乐模型类
class MeditationMusic {
  final String name;
  final String fileName;
  final String description;
  final IconData icon;
  final List<Color> gradient;

  const MeditationMusic({
    required this.name,
    required this.fileName,
    required this.description,
    required this.icon,
    required this.gradient,
  });
}

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
  MeditationMusic? _selectedMusic; // 选择的音乐
  
  // 音乐选项
  final List<MeditationMusic> _musicOptions = [
    MeditationMusic(
      name: '海洋梦境',
      fileName: 'Ocean Dreaming.mp3',
      description: '海浪声与轻柔旋律的完美融合',
      icon: Icons.waves,
      gradient: [Color(0xFF4FC3F7), Color(0xFF29B6F6)],
    ),
    MeditationMusic(
      name: '星际漂流',
      fileName: 'Stellar Drift.mp3',
      description: '宇宙般深邃的冥想音乐',
      icon: Icons.star,
      gradient: [Color(0xFF7986CB), Color(0xFF5C6BC0)],
    ),
    MeditationMusic(
      name: '静谧回响',
      fileName: 'Silent Echoes.mp3',
      description: '空灵的回响带来内心平静',
      icon: Icons.graphic_eq,
      gradient: [Color(0xFF81C784), Color(0xFF66BB6A)],
    ),
    MeditationMusic(
      name: '共鸣宁静',
      fileName: 'Resonant Stillness.mp3',
      description: '深度放松的共鸣频率',
      icon: Icons.radio_button_checked,
      gradient: [Color(0xFFBA68C8), Color(0xFFAB47BC)],
    ),
    MeditationMusic(
      name: '松林低语',
      fileName: 'Whispering Pines.mp3',
      description: '森林中的自然声音',
      icon: Icons.park,
      gradient: [Color(0xFF4DB6AC), Color(0xFF26A69A)],
    ),
    MeditationMusic(
      name: '梦境音乐',
      fileName: 'dream_music.mp3',
      description: '经典的冥想伴奏',
      icon: Icons.music_note,
      gradient: [Color(0xFFFFB74D), Color(0xFFFF9800)],
    ),
  ];
  
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
    if (_selectedMusic == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('请选择冥想音乐'),
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
          musicFileName: _selectedMusic!.fileName,
        ),
      ),
    );
  }
  
  void _selectMusic() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A1A2E),
              Color(0xFF16213E),
            ],
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '选择冥想音乐',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _musicOptions.length,
                itemBuilder: (context, index) {
                  final music = _musicOptions[index];
                  final isSelected = _selectedMusic?.fileName == music.fileName;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedMusic = music;
                      });
                      Navigator.pop(context);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? Colors.white.withOpacity(0.1)
                            : Colors.transparent,
                        border: Border.all(
                          color: isSelected 
                              ? Colors.white
                              : Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: music.gradient,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              music.icon,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  music.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  music.description,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check_circle,
                              color: Colors.white,
                              size: 24,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
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
                      
                      // 音乐选择
                      const Text(
                        '选择冥想音乐',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      GestureDetector(
                        onTap: _selectMusic,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: _selectedMusic != null 
                                ? Colors.white.withOpacity(0.1)
                                : Colors.transparent,
                            border: Border.all(
                              color: _selectedMusic != null 
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Row(
                            children: [
                              if (_selectedMusic != null) ...[
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: _selectedMusic!.gradient,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    _selectedMusic!.icon,
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
                                        _selectedMusic!.name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _selectedMusic!.description,
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
                                  Icons.music_note_outlined,
                                  color: Colors.white70,
                                  size: 24,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    '点击选择冥想音乐',
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