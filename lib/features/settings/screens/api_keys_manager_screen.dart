import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/solarium_glass_container.dart';
import '../../../core/widgets/floating_app_bar.dart';
import '../../../core/widgets/siyaq_toast.dart';
import '../providers/settings_provider.dart';

class ApiKeysManagerScreen extends ConsumerStatefulWidget {
  const ApiKeysManagerScreen({super.key});

  @override
  ConsumerState<ApiKeysManagerScreen> createState() => _ApiKeysManagerScreenState();
}

class _ApiKeysManagerScreenState extends ConsumerState<ApiKeysManagerScreen> {
  final ScrollController _scrollController = ScrollController();
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, TextEditingController> _endpointControllers = {};
  final Map<String, bool> _obscureText = {};

  final List<Map<String, dynamic>> _providers = const [
    {
      'id': 'gemini',
      'name': 'Google Gemini',
      'company': 'Google AI Studio',
      'icon': Icons.auto_awesome_rounded,
      'color': Color(0xFF3B82F6),
      'models': [
        'gemini-3.7-flash',
        'gemini-3.6-flash',
        'gemini-3.5-flash',
        'gemini-3.5-flash-lite',
        'gemini-3.1-pro',
        'gemini-2.5-flash',
        'gemini-2.5-pro',
        'gemini-1.5-pro',
        'gemini-1.5-flash',
      ],
      'docsUrl': 'aistudio.google.com',
      'desc': 'أحدث نماذج Google الرائدة لعام 2026 فائقة الذكاء والسرعة في التخطيط والجدولة.',
      'hint': 'AIzaSy...',
    },
    {
      'id': 'openai',
      'name': 'OpenAI (ChatGPT)',
      'company': 'OpenAI Frontier',
      'icon': Icons.bolt_rounded,
      'color': Color(0xFF10A37F),
      'models': [
        'gpt-5.6-sol',
        'gpt-5.6-terra',
        'gpt-5.6-luna',
        'gpt-5',
        'o3',
        'o3-mini',
        'o4-mini',
        'gpt-4o',
        'gpt-4o-mini',
      ],
      'docsUrl': 'platform.openai.com',
      'desc': 'سلسلة GPT-5.6 و o3 المتقدمة ذات التفكير المنطقي العميق في تنظيم الجداول.',
      'hint': 'sk-proj-...',
    },
    {
      'id': 'claude',
      'name': 'Anthropic Claude',
      'company': 'Anthropic',
      'icon': Icons.psychology_alt_rounded,
      'color': Color(0xFFD97706),
      'models': [
        'claude-3-7-sonnet',
        'claude-3-5-sonnet',
        'claude-3-5-haiku',
        'claude-3-opus',
      ],
      'docsUrl': 'console.anthropic.com',
      'desc': 'استثنائي في التحليل اللغوي والتفكير المنطقي المعقد وجدولة المهام.',
      'hint': 'sk-ant-api03-...',
    },
    {
      'id': 'grok',
      'name': 'xAI (Grok)',
      'company': 'xAI',
      'icon': Icons.rocket_launch_rounded,
      'color': Color(0xFFE11D48),
      'models': [
        'grok-4.6',
        'grok-4',
        'grok-3',
        'grok-2',
      ],
      'docsUrl': 'console.x.ai',
      'desc': 'أحدث نماذج Grok-4.6 الذكية فائقة السرعة مع سياق استيعاب ضخم.',
      'hint': 'xai-...',
    },
    {
      'id': 'deepseek',
      'name': 'DeepSeek AI',
      'company': 'DeepSeek',
      'icon': Icons.insights_rounded,
      'color': Color(0xFF0EA5E9),
      'models': [
        'deepseek-chat',
        'deepseek-reasoner',
      ],
      'docsUrl': 'platform.deepseek.com',
      'desc': 'نماذج DeepSeek-V3 و DeepSeek-R1 المتفوقة عالمياً بأقل تكلفة تشغيل.',
      'hint': 'sk-...',
    },
    {
      'id': 'groq',
      'name': 'Groq Cloud',
      'company': 'Groq Inc.',
      'icon': Icons.speed_rounded,
      'color': Color(0xFFF97316),
      'models': [
        'llama-3.3-70b-versatile',
        'deepseek-r1-distill-llama-70b',
        'qwen-2.5-32b',
        'llama-3.1-8b-instant',
        'mixtral-8x7b-32768',
      ],
      'docsUrl': 'console.groq.com',
      'desc': 'الاستجابة الأسرع عالمياً في معالجة الاستفسارات بنماذج Llama و DeepSeek على معالجات LPU.',
      'hint': 'gsk_...',
    },
    {
      'id': 'mistral',
      'name': 'Mistral AI',
      'company': 'Mistral',
      'icon': Icons.flare_rounded,
      'color': Color(0xFFEC4899),
      'models': [
        'mistral-large-latest',
        'mistral-small-latest',
        'codestral-latest',
        'pixtral-large-latest',
      ],
      'docsUrl': 'console.mistral.ai',
      'desc': 'نماذج أوروبية رائدة ومفتوحة في المعالجة الذكية والتخطيط.',
      'hint': '...',
    },
    {
      'id': 'openrouter',
      'name': 'OpenRouter',
      'company': 'OpenRouter Universal',
      'icon': Icons.hub_rounded,
      'color': Color(0xFF8B5CF6),
      'models': [
        'google/gemini-3.7-flash',
        'google/gemini-2.5-flash',
        'openai/gpt-5.6-sol',
        'openai/gpt-4o',
        'anthropic/claude-3.7-sonnet',
        'anthropic/claude-3.5-sonnet',
        'deepseek/deepseek-r1',
        'deepseek/deepseek-chat',
        'x-ai/grok-4',
        'meta-llama/llama-3.3-70b-instruct',
      ],
      'docsUrl': 'openrouter.ai',
      'desc': 'بوابة شاملة توفر الوصول لكافة نماذج العالم بمفتاح واحد موحد.',
      'hint': 'sk-or-v1-...',
    },
    {
      'id': 'cohere',
      'name': 'Cohere AI',
      'company': 'Cohere',
      'icon': Icons.bubble_chart_rounded,
      'color': Color(0xFF14B8A6),
      'models': [
        'command-r-plus-08-2024',
        'command-r-08-2024',
        'command-r',
      ],
      'docsUrl': 'dashboard.cohere.com',
      'desc': 'متخصص في دقة البحث واسترجاع السياق وفهم المحادثات.',
      'hint': '...',
    },
    {
      'id': 'together',
      'name': 'Together AI',
      'company': 'Together',
      'icon': Icons.group_work_rounded,
      'color': Color(0xFF6366F1),
      'models': [
        'deepseek-ai/DeepSeek-R1',
        'deepseek-ai/DeepSeek-V3',
        'meta-llama/Meta-Llama-3.1-70B-Instruct-Turbo',
        'Qwen/Qwen2.5-72B-Instruct-Turbo',
      ],
      'docsUrl': 'api.together.xyz',
      'desc': 'استضافة سريعة لأحدث النماذج المفتوحة المصدر بجودة عالية.',
      'hint': '...',
    },
    {
      'id': 'custom',
      'name': 'نموذج محلي / مخصص (Custom & Ollama)',
      'company': 'Local / Ollama / LM Studio',
      'icon': Icons.computer_rounded,
      'color': Color(0xFF64748B),
      'models': [
        'llama3.3',
        'deepseek-r1',
        'qwen2.5',
        'mistral',
        'custom',
      ],
      'docsUrl': 'ollama.com',
      'desc': 'ربط سيرفر محلي خاص بك متوافق مع OpenAI API مثل Ollama أو LM Studio بدون إنترنت.',
      'hint': 'http://localhost:11434/v1',
      'hasEndpoint': true,
    },
  ];

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    for (var p in _providers) {
      final id = p['id'] as String;
      String val = settings.apiKeys[id] ?? '';
      if (val.isEmpty) {
        if (id == 'gemini') val = settings.geminiApiKey;
        if (id == 'openai') val = settings.openaiApiKey;
      }
      _controllers[id] = TextEditingController(text: val);
      _endpointControllers[id] = TextEditingController(text: settings.customEndpoints[id] ?? '');
      _obscureText[id] = true;
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    for (var c in _controllers.values) {
      c.dispose();
    }
    for (var c in _endpointControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pasteKey(String providerId) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data != null && data.text != null && data.text!.isNotEmpty) {
      _controllers[providerId]?.text = data.text!.trim();
      SiyaqToast.show(context, 'تم لصق المفتاح من الحافظة! 📋', type: SiyaqToastType.info);
    }
  }

  Future<void> _saveProvider(String providerId) async {
    final key = _controllers[providerId]?.text.trim() ?? '';
    final endpoint = _endpointControllers[providerId]?.text.trim() ?? '';

    await ref.read(settingsProvider.notifier).setProviderApiKey(providerId, key);
    if (endpoint.isNotEmpty) {
      await ref.read(settingsProvider.notifier).setCustomEndpoint(providerId, endpoint);
    }

    final providerName = _providers.firstWhere((p) => p['id'] == providerId)['name'];
    if (mounted) {
      SiyaqToast.show(
        context,
        'تم حفظ إعدادات $providerName بنجاح! 💾',
        type: SiyaqToastType.success,
      );
    }
  }

  void _showCustomModelDialog(String providerId, String currentModel) {
    final customCtrl = TextEditingController(text: currentModel);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('إدخال اسم نموذج مخصص', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'اكتب معرّف النموذج الدقيق الذي ترغب في استخدامه من هذا المزود:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: customCtrl,
              decoration: InputDecoration(
                hintText: 'مثال: gemini-3.7-flash أو gpt-5.6-sol',
                filled: true,
                fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: SiyaqColors.accentGold,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              final text = customCtrl.text.trim();
              if (text.isNotEmpty) {
                ref.read(settingsProvider.notifier).setProviderModel(providerId, text);
                Navigator.of(ctx).pop();
                SiyaqToast.show(context, 'تم تعيين النموذج المخصص: $text بنجاح! 🎯', type: SiyaqToastType.success);
              }
            },
            child: const Text('تعيين'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: FloatingAppBar(
        scrollController: _scrollController,
        showBackButton: true,
        title: const Text(
          'مزودي الذكاء الاصطناعي و الـ API',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      body: Container(
        color: Colors.transparent,
        child: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 900),
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                children: [
                  // بطاقة التوضيح والمعلومات
                  SolariumGlassContainer(
                    margin: const EdgeInsets.only(bottom: 20.0),
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: SiyaqColors.accentGold.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.hub_rounded, color: SiyaqColors.accentGold, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ربط مفاتيح الذكاء الاصطناعي (API Keys)',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'يتيح لك سياق التبديل الحر بين كافة مزودي الذكاء الاصطناعي العالميين لعام 2026. يتم حفظ جميع المفاتيح بأمان تام وتشفير محلي على جهازك فقط.',
                                style: TextStyle(
                                  fontSize: 12,
                                  height: 1.4,
                                  color: isDark ? SiyaqColors.darkTextSecondary : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // قائمة المزودين
                  ..._providers.map((p) => _buildProviderCard(context, p, settings, isDark)),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProviderCard(
    BuildContext context,
    Map<String, dynamic> provider,
    SiyaqSettings settings,
    bool isDark,
  ) {
    final id = provider['id'] as String;
    final name = provider['name'] as String;
    final company = provider['company'] as String;
    final icon = provider['icon'] as IconData;
    final color = provider['color'] as Color;
    final models = provider['models'] as List<String>;
    final docsUrl = provider['docsUrl'] as String;
    final desc = provider['desc'] as String;
    final hint = provider['hint'] as String;
    final hasEndpoint = provider['hasEndpoint'] == true;

    final isActive = settings.activeAiProvider == id;
    final selectedModel = settings.providerModels[id] ?? models.first;

    // قائمة العناصر المنسدلة (تشمل النموذج المخصص إن وجد)
    final dropdownItems = List<String>.from(models);
    if (!dropdownItems.contains(selectedModel)) {
      dropdownItems.insert(0, selectedModel);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: SolariumGlassContainer(
        padding: const EdgeInsets.all(16.0),
        customBorderColor: isActive
            ? color.withOpacity(0.5)
            : (isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
        customBgColor: isActive
            ? color.withOpacity(isDark ? 0.08 : 0.04)
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(isDark ? 0.2 : 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (isActive)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: color.withOpacity(0.4)),
                              ),
                              child: Text(
                                'المزود النشط حالياً',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        company,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? SiyaqColors.darkTextSecondary : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                // Radio button to activate
                Transform.scale(
                  scale: 0.9,
                  child: Radio<String>(
                    value: id,
                    groupValue: settings.activeAiProvider,
                    activeColor: color,
                    onChanged: (val) {
                      if (val != null) {
                        ref.read(settingsProvider.notifier).setActiveAiProvider(val);
                        SiyaqToast.show(
                          context,
                          'تم تعيين $name كمزود الذكاء الاصطناعي النشط! 🚀',
                          type: SiyaqToastType.success,
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              desc,
              style: TextStyle(
                fontSize: 12,
                height: 1.35,
                color: isDark ? Colors.white60 : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 14),

            // Endpoint input (if applicable)
            if (hasEndpoint) ...[
              Text(
                'رابط السيرفر المخصص (Endpoint URL):',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white70 : const Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _endpointControllers[id],
                style: TextStyle(fontSize: 13, color: isDark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  hintText: 'http://localhost:11434/v1',
                  hintStyle: TextStyle(fontSize: 12, color: isDark ? Colors.white30 : Colors.black38),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // API Key Input Row
            Text(
              'مفتاح الـ API Key:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white70 : const Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controllers[id],
                    obscureText: _obscureText[id] ?? true,
                    style: TextStyle(fontSize: 13, color: isDark ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      hintText: hint,
                      hintStyle: TextStyle(fontSize: 12, color: isDark ? Colors.white30 : Colors.black38),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      suffixIcon: IconButton(
                        icon: Icon(
                          (_obscureText[id] ?? true) ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          size: 18,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureText[id] = !(_obscureText[id] ?? true);
                          });
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'لصق المفتاح من الحافظة',
                  icon: Icon(Icons.paste_rounded, color: color, size: 20),
                  style: IconButton.styleFrom(
                    backgroundColor: color.withOpacity(isDark ? 0.15 : 0.1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => _pasteKey(id),
                ),
                const SizedBox(width: 6),
                ElevatedButton(
                  onPressed: () => _saveProvider(id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('حفظ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Model Selector Dropdown & Custom Model Button
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'النموذج: ',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(width: 6),
                    DropdownButton<String>(
                      value: dropdownItems.contains(selectedModel) ? selectedModel : dropdownItems.first,
                      underline: const SizedBox(),
                      dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      items: dropdownItems.map((m) => DropdownMenuItem<String>(
                        value: m,
                        child: Text(m),
                      )).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          ref.read(settingsProvider.notifier).setProviderModel(id, val);
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_note_rounded, size: 18),
                      tooltip: 'كتابة اسم نموذج مخصص يدوياً',
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(4),
                      color: color,
                      onPressed: () => _showCustomModelDialog(id, selectedModel),
                    ),
                  ],
                ),
                Text(
                  'الموقع: $docsUrl',
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? SiyaqColors.accentGold : const Color(0xFFB45309),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
