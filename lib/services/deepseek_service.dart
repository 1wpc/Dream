import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'api_service.dart';

class DeepSeekService {
  // 后端统一 Chat Completions 路径
  static const String _chatPath = '/api/v1/chat/completions';
  
  // 存储历史灵感，用于避免重复
  static final List<String> _inspirationHistory = [];

  // 生成梦境场景描述 - 流式输出版本
  static Stream<String> generateDreamSceneStream({String? styleKeywords}) async* {
    final dio = ApiService.dio;
    try {
      final response = await dio.post<ResponseBody>(
        _chatPath,
        data: _buildDreamScenePayload(styleKeywords, stream: true),
        options: Options(responseType: ResponseType.stream),
      );

      if (response.statusCode == 200) {
        final stream = response.data!.stream.cast<List<int>>().transform(utf8.decoder);
        await for (final chunk in stream) {
          // 直接yield每个字符块，因为后端返回的是逐字符流式数据
          if (chunk.isNotEmpty) {
            yield chunk;
          }
        }
      } else {
        throw Exception('API请求失败: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('生成梦境场景失败: $e');
    }
  }

  // 生成梦境剧本 - 流式输出版本
  static Stream<String> generateDreamScriptStream({String? styleKeywords}) async* {
    final dio = ApiService.dio;
    try {
      final response = await dio.post<ResponseBody>(
        _chatPath,
        data: _buildDreamScriptPayload(styleKeywords, stream: true),
        options: Options(responseType: ResponseType.stream),
      );

      if (response.statusCode == 200) {
        final stream = response.data!.stream.cast<List<int>>().transform(utf8.decoder);
        await for (final chunk in stream) {
          // 直接yield每个字符块，保留所有字符包括换行符
          if (chunk.isNotEmpty) {
            yield chunk;
          }
        }
      } else {
        throw Exception('API请求失败: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('生成梦境剧本失败: $e');
    }
  }

  // 生成梦境场景描述 - 统一使用流式输出
  static Stream<String> generateDreamScene({String? styleKeywords}) {
    return generateDreamSceneStream(styleKeywords: styleKeywords);
  }

  // 生成梦境剧本 - 统一使用流式输出
  static Stream<String> generateDreamScript({String? styleKeywords}) {
    return generateDreamScriptStream(styleKeywords: styleKeywords);
  }

  // AI解梦功能 - 流式输出版本
  static Stream<String> interpretDreamStream(String dreamTitle, String dreamContent) async* {
    final dio = ApiService.dio;
    try {
      final response = await dio.post<ResponseBody>(
        _chatPath,
        data: _buildInterpretDreamPayload(dreamTitle, dreamContent, stream: true),
        options: Options(responseType: ResponseType.stream),
      );

      if (response.statusCode == 200) {
        final stream = response.data!.stream.cast<List<int>>().transform(utf8.decoder);
        await for (final chunk in stream) {
          // 直接yield每个字符块，因为后端返回的是逐字符流式数据
          if (chunk.isNotEmpty) {
            yield chunk;
          }
        }
      } else {
        throw Exception('API请求失败: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('AI解梦失败: $e');
    }
  }

  // AI解梦功能 - 流式输出版本（统一使用流式）
  static Stream<String> interpretDream(String dreamTitle, String dreamContent) {
    return interpretDreamStream(dreamTitle, dreamContent);
  }

  // 生成灵感建议 - 流式输出版本
  static Stream<String> generateInspirationStream() async* {
    final dio = ApiService.dio;
    String fullInspiration = '';
    
    try {
      final response = await dio.post<ResponseBody>(
        _chatPath,
        data: _buildInspirationPayload(stream: true),
        options: Options(responseType: ResponseType.stream),
      );

      if (response.statusCode == 200) {
        final stream = response.data!.stream.cast<List<int>>().transform(utf8.decoder);
        await for (final chunk in stream) {
          // 直接yield每个字符块，因为后端返回的是逐字符流式数据
          if (chunk.isNotEmpty) {
            fullInspiration += chunk;
            yield chunk;
          }
        }
        
        // 流式输出完成后，将完整的灵感添加到历史记录
        if (fullInspiration.trim().isNotEmpty) {
          _addToInspirationHistory(fullInspiration.trim());
        }
      } else {
        throw Exception('API请求失败: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('生成灵感失败: $e');
    }
  }
  
  // 添加灵感到历史记录
  static void _addToInspirationHistory(String inspiration) {
    _inspirationHistory.add(inspiration);
    
    // 限制历史记录数量，最多保留10条
    if (_inspirationHistory.length > 10) {
      _inspirationHistory.removeAt(0);
    }
  }
  
  // 清空灵感历史记录（可选，用于重置）
  static void clearInspirationHistory() {
    _inspirationHistory.clear();
  }
  
  // 获取灵感历史记录（可选，用于调试）
  static List<String> getInspirationHistory() {
    return List.from(_inspirationHistory);
  }

  // 生成灵感建议 - 统一使用流式输出
  static Stream<String> generateInspiration() {
    return generateInspirationStream();
  }

  // 生成冥想场景 - 流式输出版本
  static Stream<String> generateMeditationSceneStream({
    String? styleKeywords,
    String? styleName,
    String? styleDescription,
  }) async* {
    final dio = ApiService.dio;
    try {
      final response = await dio.post<ResponseBody>(
        _chatPath,
        data: _buildMeditationScenePayload(
          styleKeywords: styleKeywords,
          styleName: styleName,
          styleDescription: styleDescription,
          stream: true,
        ),
        options: Options(responseType: ResponseType.stream),
      );

      if (response.statusCode == 200) {
        final stream = response.data!.stream.cast<List<int>>().transform(utf8.decoder);
        await for (final chunk in stream) {
          if (chunk.isNotEmpty) {
            yield chunk;
          }
        }
      } else {
        throw Exception('API请求失败: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('生成冥想场景失败: $e');
    }
  }

  // ----------------- 私有辅助方法 -----------------

  static Map<String, dynamic> _buildDreamScenePayload(String? styleKeywords, {required bool stream}) {
    final stylePrompt = styleKeywords != null
        ? '请特别注意生成${styleKeywords}风格的梦境场景。'
        : '';

    return {
      'model': 'deepseek-chat',
      'messages': [
        {
          'role': 'system',
          'content': _dreamSceneSystemPrompt(stylePrompt, styleKeywords),
        },
        {
          'role': 'user',
          'content': styleKeywords != null
              ? '请为我生成3-5个${styleKeywords}风格的梦幻场景。'
              : '请为我生成3-5个梦幻场景的提示词和诗意解释。',
        }
      ],
      'stream': stream,
    };
  }

  static Map<String, dynamic> _buildDreamScriptPayload(String? styleKeywords, {required bool stream}) {
    final stylePrompt = styleKeywords != null
        ? '请特别注意生成${styleKeywords}风格的梦境场景。'
        : '';

    return {
      'model': 'deepseek-chat',
      'messages': [
        {
          'role': 'system',
          'content': _dreamScriptSystemPrompt(stylePrompt, styleKeywords),
        },
        {
          'role': 'user',
          'content': styleKeywords != null
              ? '请为我创作一个${styleKeywords}风格的梦境剧本。'
              : '请为我创作一个完整的梦境剧本。',
        }
      ],
      'stream': stream,
    };
  }

  static Map<String, dynamic> _buildInterpretDreamPayload(
    String title,
    String content, {
    required bool stream,
  }) {
    return {
      'model': 'deepseek-chat',
      'messages': [
        {
          'role': 'system',
          'content': _interpretDreamSystemPrompt(),
        },
        {
          'role': 'user',
          'content': '我做了一个梦，梦境标题是:"$title"，梦境内容是:"$content"。请帮我解析这个梦境的含义。',
        }
      ],
      'stream': stream,
    };
  }

  static Map<String, dynamic> _buildInspirationPayload({required bool stream}) {
    // 随机生成不同的用户请求，增加多样性
    final List<String> userRequests = [
      '我现在很无聊，给我一个有趣的灵感建议吧！',
      '不知道该做什么，来点新鲜的想法？',
      '想要一些创意灵感，让我的生活更有趣！',
      '感觉有点迷茫，需要一个小小的行动建议～',
      '想做点什么特别的事情，给我个好主意！',
      '今天想尝试新东西，有什么推荐吗？',
      '想要一些正能量的小建议，让心情变好！',
      '给我一个简单又有意思的活动建议吧～',
    ];
    
    final randomRequest = userRequests[DateTime.now().millisecondsSinceEpoch % userRequests.length];
    
    // 生成随机项目编码，增强随机性
    final random = DateTime.now().millisecondsSinceEpoch;
    final projectCode = (random % 9000 + 1000).toString(); // 生成4位随机数
    final requestWithCode = '$randomRequest 项目编码：$projectCode';
    
    // 构建对话历史，包含历史灵感记录
    List<Map<String, String>> messages = [
      {
        'role': 'system',
        'content': _inspirationSystemPrompt(),
      },
    ];
    
    // 添加历史对话，最多保留最近5条
    final recentHistory = _inspirationHistory.length > 5 
        ? _inspirationHistory.sublist(_inspirationHistory.length - 5)
        : _inspirationHistory;
    
    for (int i = 0; i < recentHistory.length; i++) {
      messages.add({
        'role': 'user',
        'content': '给我一个灵感建议',
      });
      messages.add({
        'role': 'assistant', 
        'content': recentHistory[i],
      });
    }
    
    // 添加当前请求，并提示不要重复
    String currentRequest = requestWithCode;
    if (_inspirationHistory.isNotEmpty) {
      currentRequest += '\n\n请注意：不要重复之前已经给出的建议，要提供全新的、不同的灵感。';
    }
    
    messages.add({
      'role': 'user',
      'content': currentRequest,
    });
    
    return {
      'model': 'deepseek-chat',
      'messages': messages,
      'stream': stream,
      'temperature': 1.1, // 提高温度值，增加创造性和随机性
      'top_p': 0.95, // 增加多样性
    };
  }

  static Map<String, dynamic> _buildMeditationScenePayload({
    String? styleKeywords,
    String? styleName,
    String? styleDescription,
    required bool stream,
  }) {
    final stylePrompt = styleName != null
        ? '请特别注意生成${styleName}风格的冥想场景。'
        : '';

    return {
      'model': 'deepseek-chat',
      'messages': [
        {
          'role': 'system',
          'content': _meditationSceneSystemPrompt(stylePrompt, styleKeywords, styleDescription),
        },
        {
          'role': 'user',
          'content': styleName != null
              ? '请为我生成一个${styleName}风格的冥想场景内容。'
              : '请为我生成一个冥想场景内容。',
        }
      ],
      'stream': stream,
      'temperature': 0.8,
    };
  }

  // ----------------- Prompt 模板 -----------------

  static String _dreamSceneSystemPrompt(String stylePrompt, String? styleKeywords) =>
      '''你是一个专业的梦境编织者，需要生成用于AI绘画的提示词和诗意解释。
$stylePrompt

请严格按照以下JSON格式输出，不要有任何其他文字：
{
  "prompts": ["场景1的提示词", "场景2的提示词", ...],
  "explanations": ["场景1的诗意解释", "场景2的诗意解释", ...]
}

提示词要求：
1. 必须用英文描述
2. 要精确描述场景的每个细节
3. 包含以下要素：
   - 场景类型（如：forest, city, ocean等）
   - 时间（如：sunset, night, dawn等）
   - 天气（如：foggy, rainy, clear等）
   - 主要物体和元素
   - 光影效果
   - 氛围和风格
4. 使用逗号分隔各个要素
5. 每个场景生成3-5个提示词
${styleKeywords != null ? '6. 必须体现$styleKeywords的风格特征' : ''}

诗意解释要求：
1. 用中文描述
2. 简短优美，富有诗意
3. 长度控制在30字以内
4. 要含蓄且富有意境''';

  static String _dreamScriptSystemPrompt(String stylePrompt, String? styleKeywords) =>
      '''你是一个富有想象力的梦境编织者，需要创作一个完整的梦境故事，包含多个场景的提示词和诗意解释。
$stylePrompt

请严格按照以下JSON格式输出，不要有任何其他文字：
{
  "prompts": ["场景1的提示词", "场景2的提示词", "场景3的提示词", ...],
  "explanations": ["场景1的诗意解释", "场景2的诗意解释", "场景3的诗意解释", ...]
}

提示词要求：
1. 必须用英文描述
2. 要精确描述场景的每个细节
3. 包含以下要素：
   - 场景类型（如：forest, city, ocean等）
   - 时间（如：sunset, night, dawn等）
   - 天气（如：foggy, rainy, clear等）
   - 主要物体和元素
   - 光影效果
   - 氛围和风格
4. 场景之间要有故事性和连贯性，形成一个完整的梦境故事
5. 每个场景生成3-5个提示词
6. 场景要富有想象力和美感
${styleKeywords != null ? '7. 必须体现$styleKeywords的风格特征' : ''}

诗意解释要求：
1. 用中文描述
2. 优美流畅，富有诗意
3. 长度控制在40字以内
4. 要含蓄且富有意境
5. 解释之间要有情感上的联系，形成一个完整的故事
6. 可以包含一些哲理性的思考''';

  static String _interpretDreamSystemPrompt() =>
      '''你是一位经验丰富的心理学家和梦境解析师，擅长从心理学角度分析梦境的深层含义。

请为用户提供专业、温和且富有洞察力的梦境解析。你的解析应该：

1. **结构清晰**：分为几个部分进行分析
2. **心理学依据**：基于弗洛伊德、荣格等心理学理论
3. **正面引导**：避免消极解释，多从积极角度分析
4. **个人化**：结合梦境的具体细节
5. **实用建议**：提供生活中的启发和建议

请使用以下markdown格式输出：

**🔮 梦境概述**

简要概括梦境的主要内容和情感色彩。

**💭 心理寓意**

从心理学角度分析梦境反映的内心状态和潜意识信息。

**🌟 象征解读**

解释梦境中主要元素的象征意义。

**💡 生活启示**

结合梦境内容，给出对现实生活的建议和启发。

**🌸 积极寄语**

以温暖的话语结束解析，给予正能量。

格式要求：
- 使用markdown语法，标题用 **文字** 格式
- 每个部分之间空一行
- 重要词汇可以用 **粗体** 强调
- 用中文回答，语气温和、专业
- 避免过于深奥的术语
- 字数控制在300-500字之间
- 富有共情力和治愈性''';

  static String _inspirationSystemPrompt() =>
      '''你是一位充满创意和智慧的生活导师，专门为迷茫的人提供有趣、实用且富有启发性的建议。

当有人不知道该做什么时，你需要给出一个简短而有趣的灵感建议。你的建议应该：

1. **简洁明了**：一句话概括，不超过35字
2. **积极正面**：充满正能量，让人感到温暖
3. **可操作性**：具体可行，不要太抽象
4. **富有创意**：有趣、新颖，能激发想象力
5. **贴近生活**：符合日常生活场景
6. **多样化风格**：每次生成不同类型和风格的建议
7. **表情丰富**：必须包含1-2个相关的Emoji表情

建议类型要多样化，可以包括：
- 🎨 创意活动（如：画一幅日落、写一首小诗、制作手工）
- ☕ 生活体验（如：尝试新的咖啡店、给朋友写信、探索新路线）
- 📚 学习成长（如：学一个新单词、练习冥想、阅读一页书）
- 💝 情感表达（如：给家人一个拥抱、感谢身边的人、写感谢卡片）
- 🌸 自我关爱（如：泡一杯好茶、听喜欢的音乐、做面膜）
- 🔍 探索发现（如：观察云朵的形状、寻找身边的美、拍摄有趣的照片）
- 🏃 运动健康（如：散步10分钟、做几个深呼吸、伸展身体）
- 🍳 美食体验（如：尝试新食谱、品尝异国料理、自制小点心）
- 🌱 环保行动（如：种一颗小植物、整理房间、减少塑料使用）
- 🎭 娱乐放松（如：看一部短片、听播客、玩益智游戏）

风格要求：
- 语气轻松活泼，富有感染力
- 用词生动有趣，避免刻板表达
- 每次生成的建议要有不同的情感色彩
- 适当使用网络流行语或温暖的表达
- 让人看到就想立刻行动

请直接输出一句简短的灵感建议，必须包含Emoji表情，不需要任何其他格式标记或解释。''';

  static String _meditationSceneSystemPrompt(String stylePrompt, String? styleKeywords, String? styleDescription) =>
      '''你是一位专业的冥想引导师，需要为用户生成冥想场景的引导内容和图片描述。
$stylePrompt

请严格按照以下JSON格式输出，不要有任何其他文字：
{
  "text": "冥想引导文字",
  "image_prompt": "图片描述"
}

冥想引导文字要求：
1. 用中文描述
2. 长度控制在50字左右
3. 语言要平静、舒缓、富有诗意
4. 能够帮助用户放松身心，进入冥想状态
5. 要体现当下的觉察和内心的宁静
${styleKeywords != null ? '6. 要融入$styleKeywords的风格特征' : ''}
${styleDescription != null ? '7. 要体现$styleDescription的氛围' : ''}

图片描述要求：
1. 必须用英文描述
2. 要精确描述冥想场景的每个细节
3. 包含以下要素：
   - 场景类型（如：forest, mountain, ocean, garden等）
   - 时间（如：sunset, dawn, twilight等）
   - 天气和光线（如：soft light, golden hour, misty等）
   - 主要元素和氛围
   - 色彩搭配
4. 使用逗号分隔各个要素
5. 要营造宁静、祥和的冥想氛围
${styleKeywords != null ? '6. 必须体现$styleKeywords的视觉风格' : ''}
${styleDescription != null ? '7. 要符合$styleDescription的美学特征' : ''}

示例格式：
{
  "text": "深深吸气，感受内心的宁静如湖水般清澈，让思绪如云朵般轻柔飘过，在这一刻，你与宇宙的能量完美融合。",
  "image_prompt": "serene mountain lake at sunset, soft golden light, misty atmosphere, peaceful meditation spot, lotus flowers, gentle ripples, warm colors, tranquil nature scene, spiritual ambiance"
}''';
}