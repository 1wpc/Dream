import 'dart:convert';
import 'package:http/http.dart' as http;

class DeepSeekService {
  static const String _baseUrl = 'https://api.deepseek.com/chat/completions';
  static const String _apiKey = 'sk-c9bfee1559c84971a736c525a6470fc3'; 

  // 生成梦境场景描述
  static Future<Map<String, List<String>>> generateDreamScene({String? styleKeywords}) async {
    try {
      // 构建风格相关的提示
      final stylePrompt = styleKeywords != null 
        ? '请特别注意生成${styleKeywords}风格的梦境场景。' 
        : '';
        
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'deepseek-chat',
          'messages': [
            {
              'role': 'system',
              'content': '''你是一个专业的梦境编织者，需要生成用于AI绘画的提示词和诗意解释。
$stylePrompt

请严格按照以下JSON格式输出，不要有任何其他文字：
{
  "prompts": ["场景1的提示词", "场景2的提示词", ...],
  "explanations": ["场景1的诗意解释", "场景2的诗意解释", ...],
  "englishDescriptions": ["场景1的英文描述", "场景2的英文描述", ...]
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
3. 长度控制在20字以内
4. 要含蓄且富有意境

英文描述要求：
1. 用英文描述
2. 简洁优雅，富有意境
3. 长度控制在10个单词以内
4. 要呼应中文的诗意

示例输出：
{
  "prompts": [
    "mystical forest, sunset, golden rays through trees, floating lanterns, ethereal atmosphere, soft focus, dreamy lighting, magical realism style",
    "ancient temple, night, full moon, misty, stone steps, glowing paper lanterns, zen garden, cinematic lighting, oriental style"
  ],
  "explanations": [
    "林间光影，如梦似幻",
    "月下古寺，禅意悠然"
  ],
  "englishDescriptions": [
    "Golden light through mystical woods",
    "Moonlit temple in serene meditation"
  ]
}'''
            },
            {
              'role': 'user',
              'content': styleKeywords != null 
                ? '请为我生成一个$styleKeywords风格的梦幻场景。'
                : '请为我生成一个梦幻场景的提示词和诗意解释。'
            }
          ],
          'stream': false,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        final result = jsonDecode(content) as Map<String, dynamic>;
        return {
          'prompts': (result['prompts'] as List).cast<String>(),
          'explanations': (result['explanations'] as List).cast<String>(),
          'englishDescriptions': (result['englishDescriptions'] as List).cast<String>(),
        };
      } else {
        throw Exception('API请求失败: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('生成梦境场景失败: $e');
    }
  }

  // 生成梦境剧本
  static Future<Map<String, List<String>>> generateDreamScript({String? styleKeywords}) async {
    try {
      // 构建风格相关的提示
      final stylePrompt = styleKeywords != null 
        ? '请特别注意生成${styleKeywords}风格的梦境场景。' 
        : '';
      
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'deepseek-chat',
          'messages': [
            {
              'role': 'system',
              'content': '''你是一个富有想象力的梦境编织者，需要创作一个完整的梦境故事，包含多个场景的提示词和诗意解释。
$stylePrompt

请严格按照以下JSON格式输出，不要有任何其他文字：
{
  "prompts": ["场景1的提示词", "场景2的提示词", "场景3的提示词", ...],
  "explanations": ["场景1的诗意解释", "场景2的诗意解释", "场景3的诗意解释", ...],
  "englishDescriptions": ["场景1的英文描述", "场景2的英文描述", "场景3的英文描述", ...]
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
3. 长度控制在30字以内
4. 要含蓄且富有意境
5. 解释之间要有情感上的联系，形成一个完整的故事
6. 可以包含一些哲理性的思考

英文描述要求：
1. 用英文描述
2. 简洁优雅，富有意境
3. 长度控制在10个单词以内
4. 要呼应中文的诗意
5. 描述之间要有连贯性

示例输出：
{
  "prompts": [
    "mystical forest, sunset, golden rays through trees, floating lanterns, ethereal atmosphere, soft focus, dreamy lighting, magical realism style",
    "ancient temple, night, full moon, misty, stone steps, glowing paper lanterns, zen garden, cinematic lighting, oriental style",
    "crystal cave, dawn, bioluminescent crystals, underground lake, reflections, magical particles, fantasy style"
  ],
  "explanations": [
    "林间光影，如梦似幻，仿佛置身于童话世界",
    "月下古寺，禅意悠然，心若止水",
    "晶洞晨光，心若明镜，照见本心"
  ],
  "englishDescriptions": [
    "Golden light through mystical fairy woods",
    "Moonlit temple in serene meditation",
    "Crystal cave reflecting inner light"
  ]
}'''
            },
            {
              'role': 'user',
              'content': styleKeywords != null 
                ? '请为我创作一个$styleKeywords风格的梦境剧本。'
                : '请为我创作一个完整的梦境剧本。'
            }
          ],
          'stream': false,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        final result = jsonDecode(content) as Map<String, dynamic>;
        return {
          'prompts': (result['prompts'] as List).cast<String>(),
          'explanations': (result['explanations'] as List).cast<String>(),
          'englishDescriptions': (result['englishDescriptions'] as List).cast<String>(),
        };
      } else {
        throw Exception('API请求失败: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('生成梦境剧本失败: $e');
    }
  }

  // AI解梦功能 - 流式输出版本
  static Stream<String> interpretDreamStream(String dreamTitle, String dreamContent) async* {
    try {
      final request = http.Request('POST', Uri.parse(_baseUrl));
      request.headers.addAll({
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      });
      
      request.body = jsonEncode({
        'model': 'deepseek-chat',
        'messages': [
          {
            'role': 'system',
            'content': '''你是一位经验丰富的心理学家和梦境解析师，擅长从心理学角度分析梦境的深层含义。

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
- 富有共情力和治愈性'''
          },
          {
            'role': 'user',
            'content': '我做了一个梦，梦境标题是："$dreamTitle"，梦境内容是："$dreamContent"。请帮我解析这个梦境的含义。'
          }
        ],
        'stream': true, // 启用流式输出
      });

      final response = await http.Client().send(request);
      
      if (response.statusCode == 200) {
        String buffer = '';
        await for (final chunk in response.stream.transform(utf8.decoder)) {
          buffer += chunk;
          
          // 处理可能包含多个事件的缓冲区
          final lines = buffer.split('\n');
          buffer = lines.removeLast(); // 保留可能不完整的最后一行
          
          for (final line in lines) {
            if (line.trim().isEmpty) continue;
            if (!line.startsWith('data: ')) continue;
            
            final dataStr = line.substring(6).trim();
            if (dataStr == '[DONE]') {
              return; // 流结束
            }
            
            try {
              final data = jsonDecode(dataStr);
              final delta = data['choices']?[0]?['delta'];
              final content = delta?['content'];
              
              if (content != null && content is String && content.isNotEmpty) {
                yield content;
              }
            } catch (e) {
              // 忽略JSON解析错误，继续处理下一个数据块
              continue;
            }
          }
        }
      } else {
        throw Exception('API请求失败: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('AI解梦失败: $e');
    }
  }

  // AI解梦功能 - 保留原版本作为备用
  static Future<String> interpretDream(String dreamTitle, String dreamContent) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'deepseek-chat',
          'messages': [
            {
              'role': 'system',
              'content': '''你是一位经验丰富的心理学家和梦境解析师，擅长从心理学角度分析梦境的深层含义。

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
- 富有共情力和治愈性'''
            },
            {
              'role': 'user',
              'content': '我做了一个梦，梦境标题是："$dreamTitle"，梦境内容是："$dreamContent"。请帮我解析这个梦境的含义。'
            }
          ],
          'stream': false,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'] as String;
      } else {
        throw Exception('API请求失败: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('AI解梦失败: $e');
    }
  }
} 