import 'dart:convert';
import 'package:http/http.dart' as http;

class DeepSeekService {
  static const String _baseUrl = 'https://api.deepseek.com/chat/completions';
  static const String _apiKey = 'sk-c9bfee1559c84971a736c525a6470fc3'; 

  // 生成梦境场景描述
  static Future<Map<String, List<String>>> generateDreamScene() async {
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
              'content': '''你是一个专业的梦境编织者，需要生成用于AI绘画的提示词和诗意解释。
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

诗意解释要求：
1. 用中文描述
2. 简短优美，富有诗意
3. 长度控制在20字以内
4. 要含蓄且富有意境

示例输出：
{
  "prompts": [
    "mystical forest, sunset, golden rays through trees, floating lanterns, ethereal atmosphere, soft focus, dreamy lighting, magical realism style",
    "ancient temple, night, full moon, misty, stone steps, glowing paper lanterns, zen garden, cinematic lighting, oriental style"
  ],
  "explanations": [
    "林间光影，如梦似幻",
    "月下古寺，禅意悠然"
  ]
}'''
            },
            {
              'role': 'user',
              'content': '请为我生成一个梦幻场景的提示词和诗意解释。'
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
        };
      } else {
        throw Exception('API请求失败: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('生成梦境场景失败: $e');
    }
  }

  // 生成梦境剧本
  static Future<Map<String, List<String>>> generateDreamScript() async {
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
              'content': '''你是一个富有想象力的梦境编织者，需要创作一个完整的梦境故事，包含多个场景的提示词和诗意解释。
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

诗意解释要求：
1. 用中文描述
2. 优美流畅，富有诗意
3. 长度控制在30字以内
4. 要含蓄且富有意境
5. 解释之间要有情感上的联系，形成一个完整的故事
6. 可以包含一些哲理性的思考

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
  ]
}'''
            },
            {
              'role': 'user',
              'content': '请为我创作一个完整的梦境剧本。'
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
        };
      } else {
        throw Exception('API请求失败: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('生成梦境剧本失败: $e');
    }
  }
} 