import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/models/prayer_times.dart';
import '../../../core/models/task_item.dart';
import '../../../core/models/prayer_config.dart';

class AIService {
  static String buildSystemPrompt({
    required PrayerTimes prayers,
    required List<TaskItem> currentTasks,
    required Map<String, PrayerConfig> prayerConfigs,
  }) {
    final taskListStr = currentTasks.map((t) {
      final start = '${t.startTime.hour.toString().padLeft(2, '0')}:${t.startTime.minute.toString().padLeft(2, '0')}';
      final end = '${t.endTime.hour.toString().padLeft(2, '0')}:${t.endTime.minute.toString().padLeft(2, '0')}';
      return '- [${t.isFlexible ? "مرن" : "ثابت"}] ${t.title} من $start إلى $end';
    }).join('\n');

    final prayerListStr = prayers.toList().map((p) {
      final time = p['time'] as DateTime;
      final timeStr = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      return '${p['name']}: $timeStr';
    }).join('\n');

    final configListStr = prayerConfigs.values.map((c) {
      return '- صلاة ${c.prayerName}: تبدأ ${c.minutesOffsetFromAdhan >= 0 ? "بعد" : "قبل"} الأذان بـ ${c.minutesOffsetFromAdhan.abs()} دقيقة، وتستغرق ${c.durationMinutes} دقيقة.';
    }).join('\n');

    return '''
أنت "سياق AI"، مساعد ذكي متقدم لتنظيم الوقت اليومي للمسلمين متوافق مع أوقات الصلاة. 
مهمتك هي مساعدة المستخدم في إعادة ترتيب وتخطيط جدول يومه بذكاء ومرونة.

سياق اليوم للمستخدم:
- أوقات الأذان اليوم:
$prayerListStr

- فترات حظر الصلاة المحددة من المستخدم (لا يمكن جدولة مهام فيها):
$configListStr

- المهام الحالية المجدولة اليوم (شاملة فترات الفراغ والنوم والصلوات):
$taskListStr

إرشادات هامة جداً:
1. يجب أن ترد باللغة العربية بأسلوب راقٍ وودود وموجز.
2. إذا طلب المستخدم إضافة مهمة جديدة أو تعديل جدول أعماله، قم بصياغة جدول مقترح له يراعي أوقات الصلاة والنوم وفترات الفراغ.
3. لتتمكن من تعديل جدول المستخدم تلقائياً، يمكنك إدراج أمر برمجياً بتنسيق JSON في نهاية ردك ليقوم التطبيق بتنفيذه تلقائياً. يجب وضع كود الـ JSON داخل وسم ```json ... ``` وتأكد من أن يكون صالحاً (Valid JSON).

تنسيق الأوامر البرمجية (JSON Command):
لإضافة مهمة:
```json
{
  "command": "add_task",
  "title": "عنوان المهمة",
  "description": "الوصف",
  "startTime": "HH:mm", // بصيغة 24 ساعة (مثال: 14:30)
  "endTime": "HH:mm",
  "isFlexible": true
}
```

لإزالة مهمة:
```json
{
  "command": "delete_task",
  "title": "عنوان المهمة المراد حذفها"
}
```

رد على المستخدم الآن وساعده في إدارة يومه.
''';
  }

  /// إرسال الرسالة للمزود المختار ديناميكياً
  static Future<String> sendMessage({
    required String providerId,
    required String apiKey,
    required String? model,
    required String? customEndpoint,
    required String message,
    required List<Map<String, String>> chatHistory,
    required PrayerTimes prayers,
    required List<TaskItem> currentTasks,
    required Map<String, PrayerConfig> prayerConfigs,
  }) async {
    if (apiKey.isEmpty && providerId != 'custom') {
      return 'تنبيه: يرجى إدخال مفتاح الـ API الخاص بـ $providerId في صفحة الإعدادات أولاً لتتمكن من استخدام المساعد الذكي.';
    }

    final systemPrompt = buildSystemPrompt(
      prayers: prayers,
      currentTasks: currentTasks,
      prayerConfigs: prayerConfigs,
    );

    try {
      if (providerId == 'gemini') {
        return await _sendToGemini(apiKey, model ?? 'gemini-1.5-flash', systemPrompt, chatHistory, message);
      } else if (providerId == 'claude') {
        return await _sendToClaude(apiKey, model ?? 'claude-3-5-sonnet-20241022', systemPrompt, chatHistory, message);
      } else {
        // جميع المزودين المتوافقين مع بروتوكول OpenAI (OpenAI, Groq, DeepSeek, Mistral, OpenRouter, Cohere, Together, Ollama)
        return await _sendToOpenAiCompatible(
          providerId: providerId,
          apiKey: apiKey,
          model: model,
          customEndpoint: customEndpoint,
          systemPrompt: systemPrompt,
          chatHistory: chatHistory,
          message: message,
        );
      }
    } catch (e) {
      return 'عذراً، حدث خطأ أثناء الاتصال بمزود الذكاء الاصطناعي ($providerId): $e';
    }
  }

  // Google Gemini API
  static Future<String> _sendToGemini(
    String apiKey,
    String model,
    String systemPrompt,
    List<Map<String, String>> chatHistory,
    String message,
  ) async {
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey',
    );

    final contents = <Map<String, dynamic>>[];
    contents.add({
      'role': 'user',
      'parts': [{'text': systemPrompt}]
    });
    contents.add({
      'role': 'model',
      'parts': [{'text': 'مفهوم. أنا سياق AI، وسألتزم بمساعدة المستخدم باللغة العربية وتوليد أوامر التعديل في جداول أعماله بصيغة JSON بدقة.'}]
    });

    for (var chat in chatHistory) {
      contents.add({
        'role': chat['role'] == 'user' ? 'user' : 'model',
        'parts': [{'text': chat['message'] ?? ''}]
      });
    }

    contents.add({
      'role': 'user',
      'parts': [{'text': message}]
    });

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': contents,
        'generationConfig': {'temperature': 0.7, 'maxOutputTokens': 1024},
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return data['candidates'][0]['content']['parts'][0]['text'] ?? 'لم يتم الحصول على رد.';
    } else {
      return 'خطأ من Gemini (${response.statusCode}): ${response.body}';
    }
  }

  // Anthropic Claude API
  static Future<String> _sendToClaude(
    String apiKey,
    String model,
    String systemPrompt,
    List<Map<String, String>> chatHistory,
    String message,
  ) async {
    final url = Uri.parse('https://api.anthropic.com/v1/messages');

    final messages = <Map<String, dynamic>>[];
    for (var chat in chatHistory) {
      messages.add({
        'role': chat['role'] == 'user' ? 'user' : 'assistant',
        'content': chat['message'] ?? '',
      });
    }
    messages.add({'role': 'user', 'content': message});

    final response = await http.post(
      url,
      headers: {
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
        'content-type': 'application/json',
      },
      body: jsonEncode({
        'model': model,
        'system': systemPrompt,
        'messages': messages,
        'max_tokens': 1024,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      final contentList = data['content'] as List;
      return contentList.map((c) => c['text']).join('\n');
    } else {
      return 'خطأ من Claude (${response.statusCode}): ${response.body}';
    }
  }

  // OpenAI & OpenAI-compatible providers
  static Future<String> _sendToOpenAiCompatible({
    required String providerId,
    required String apiKey,
    required String? model,
    required String? customEndpoint,
    required String systemPrompt,
    required List<Map<String, String>> chatHistory,
    required String message,
  }) async {
    String endpoint;
    String defaultModel;

    switch (providerId) {
      case 'openai':
        endpoint = 'https://api.openai.com/v1/chat/completions';
        defaultModel = 'gpt-4o-mini';
        break;
      case 'groq':
        endpoint = 'https://api.groq.com/openai/v1/chat/completions';
        defaultModel = 'llama-3.3-70b-versatile';
        break;
      case 'deepseek':
        endpoint = 'https://api.deepseek.com/chat/completions';
        defaultModel = 'deepseek-chat';
        break;
      case 'mistral':
        endpoint = 'https://api.mistral.ai/v1/chat/completions';
        defaultModel = 'mistral-large-latest';
        break;
      case 'openrouter':
        endpoint = 'https://openrouter.ai/api/v1/chat/completions';
        defaultModel = 'google/gemini-2.0-flash-exp:free';
        break;
      case 'cohere':
        endpoint = 'https://api.cohere.ai/v1/chat/completions';
        defaultModel = 'command-r-plus';
        break;
      case 'together':
        endpoint = 'https://api.together.xyz/v1/chat/completions';
        defaultModel = 'meta-llama/Meta-Llama-3.1-70B-Instruct-Turbo';
        break;
      case 'custom':
        endpoint = (customEndpoint != null && customEndpoint.isNotEmpty)
            ? (customEndpoint.endsWith('/chat/completions') ? customEndpoint : '$customEndpoint/chat/completions')
            : 'http://localhost:11434/v1/chat/completions';
        defaultModel = 'llama3';
        break;
      default:
        endpoint = 'https://api.openai.com/v1/chat/completions';
        defaultModel = 'gpt-4o-mini';
    }

    final selectedModel = (model != null && model.isNotEmpty) ? model : defaultModel;

    final messages = <Map<String, dynamic>>[];
    messages.add({'role': 'system', 'content': systemPrompt});

    for (var chat in chatHistory) {
      messages.add({
        'role': chat['role'] == 'user' ? 'user' : 'assistant',
        'content': chat['message'] ?? '',
      });
    }

    messages.add({'role': 'user', 'content': message});

    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (apiKey.isNotEmpty) {
      headers['Authorization'] = 'Bearer $apiKey';
    }
    if (providerId == 'openrouter') {
      headers['HTTP-Referer'] = 'https://siyaq.app';
      headers['X-Title'] = 'Siyaq Smart Scheduler';
    }

    final response = await http.post(
      Uri.parse(endpoint),
      headers: headers,
      body: jsonEncode({
        'model': selectedModel,
        'messages': messages,
        'temperature': 0.7,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return data['choices'][0]['message']['content'] ?? 'لم يتم الحصول على رد.';
    } else {
      return 'خطأ من مزود $providerId (${response.statusCode}): ${response.body}';
    }
  }

  // للتوافق مع استدعاءات الكود القديمة
  static Future<String> sendMessageToGemini({
    required String apiKey,
    required String message,
    required List<Map<String, String>> chatHistory,
    required PrayerTimes prayers,
    required List<TaskItem> currentTasks,
    required Map<String, PrayerConfig> prayerConfigs,
  }) async {
    return sendMessage(
      providerId: 'gemini',
      apiKey: apiKey,
      model: 'gemini-1.5-flash',
      customEndpoint: null,
      message: message,
      chatHistory: chatHistory,
      prayers: prayers,
      currentTasks: currentTasks,
      prayerConfigs: prayerConfigs,
    );
  }
}
