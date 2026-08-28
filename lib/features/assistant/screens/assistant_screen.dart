import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/models/task_item.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/solarium_glass_container.dart';
import '../../../core/widgets/siyaq_toast.dart';
import '../../dashboard/providers/schedule_provider.dart';
import '../../settings/providers/settings_provider.dart';
import '../services/ai_service.dart';

class AssistantScreen extends ConsumerStatefulWidget {
  final ScrollController scrollController;

  const AssistantScreen({
    super.key,
    required this.scrollController,
  });

  @override
  ConsumerState<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends ConsumerState<AssistantScreen> {
  final List<Map<String, String>> _messages = [
    {
      'role': 'model',
      'message': 'أهلاً بك! أنا مساعدك الذكي ميقاف AI. كيف يمكنني مساعدتك في تخطيط وجدولة يومك بما يتناسب مع صلواتك اليوم؟ يمكنك إخباري بجدولك المعتاد وسأقوم بتعديله لك تلقائياً.'
    }
  ];
  
  final _textController = TextEditingController();
  bool _isTyping = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  // إرسال رسالة ومعالجة رد الذكاء الاصطناعي والأوامر
  Future<void> _sendMessage() async {
    final userMessage = _textController.text.trim();
    if (userMessage.isEmpty) return;

    _textController.clear();
    setState(() {
      _messages.add({'role': 'user', 'message': userMessage});
      _isTyping = true;
    });

    final settings = ref.read(settingsProvider);
    final selectedDate = ref.read(selectedDateProvider);
    
    // جلب الصلوات والمهام الحالية لتغذيتها للنموذج كسياق
    final prayersAsync = ref.read(prayerTimesProvider(selectedDate));
    final prayers = prayersAsync.value;
    
    if (prayers == null) {
      setState(() {
        _messages.add({
          'role': 'model',
          'message': 'عذراً، يجب تحميل أوقات الصلاة أولاً للتاريخ المحدد ليتمكن المساعد من تعديل الجدول.'
        });
        _isTyping = false;
      });
      return;
    }

    final currentTasks = ref.read(scheduleProvider.notifier).getAdjustedTasksForDate(selectedDate, prayers);

    // إرسال للـ API وفق المزود المختار في الإعدادات
    final activeProvider = settings.activeAiProvider;
    final apiKey = settings.apiKeys[activeProvider] ?? (activeProvider == 'gemini' ? settings.geminiApiKey : (activeProvider == 'openai' ? settings.openaiApiKey : ''));
    final model = settings.providerModels[activeProvider];
    final endpoint = settings.customEndpoints[activeProvider];

    final response = await AIService.sendMessage(
      providerId: activeProvider,
      apiKey: apiKey,
      model: model,
      customEndpoint: endpoint,
      message: userMessage,
      chatHistory: _messages.sublist(0, _messages.length - 1), // استبعاد الرسالة الحالية
      prayers: prayers,
      currentTasks: currentTasks,
      prayerConfigs: settings.prayerConfigs,
    );

    setState(() {
      _messages.add({'role': 'model', 'message': response});
      _isTyping = false;
    });

    // فحص إذا كان هناك كود JSON في الرد لتنفيذه تلقائياً
    _checkForAgentCommands(response, selectedDate);
  }

  // استخراج الـ JSON وتطبيقه على الجدول (العميل الذكي - Agent)
  void _checkForAgentCommands(String response, DateTime selectedDate) {
    try {
      if (response.contains('```json')) {
        final startIndex = response.indexOf('```json') + 7;
        final endIndex = response.indexOf('```', startIndex);
        
        if (endIndex != -1) {
          final jsonStr = response.substring(startIndex, endIndex).trim();
          final commandData = jsonDecode(jsonStr) as Map<String, dynamic>;
          
          final command = commandData['command'] as String?;
          if (command == 'add_task') {
            final title = commandData['title'] as String;
            final desc = commandData['description'] as String? ?? '';
            final startTimeStr = commandData['startTime'] as String; // HH:mm
            final endTimeStr = commandData['endTime'] as String;
            final isFlexible = commandData['isFlexible'] as bool? ?? true;

            // تحويل نصوص الوقت إلى DateTime كامل
            final startParts = startTimeStr.split(':');
            final endParts = endTimeStr.split(':');
            
            final startDateTime = DateTime(
              selectedDate.year,
              selectedDate.month,
              selectedDate.day,
              int.parse(startParts[0]),
              int.parse(startParts[1]),
            );

            final endDateTime = DateTime(
              selectedDate.year,
              selectedDate.month,
              selectedDate.day,
              int.parse(endParts[0]),
              int.parse(endParts[1]),
            );

            final newTask = TaskItem(
              id: const Uuid().v4(),
              title: title,
              description: desc,
              startTime: startDateTime,
              endTime: endDateTime,
              isFlexible: isFlexible,
            );

            // إضافة المهمة
            ref.read(scheduleProvider.notifier).addTask(newTask);

            SiyaqToast.show(
              context,
              'تمت إضافة مهمة "$title" بنجاح وتعديلها تلقائياً مع الصلاة! ✨',
              type: SiyaqToastType.success,
            );
          } else if (command == 'delete_task') {
            final title = commandData['title'] as String;
            
            // البحث عن مهمة بهذا العنوان لحذفها
            final allTasks = ref.read(scheduleProvider).allTasks;
            final taskToDelete = allTasks.firstWhere(
              (t) => t.title.toLowerCase().contains(title.toLowerCase()),
              orElse: () => TaskItem(id: '', title: '', startTime: DateTime.now(), endTime: DateTime.now()),
            );

            if (taskToDelete.id.isNotEmpty) {
              ref.read(scheduleProvider.notifier).deleteTask(taskToDelete.id);
              SiyaqToast.show(
                context,
                'تم حذف مهمة "$title" بنجاح.',
                type: SiyaqToastType.info,
              );
            }
          }
        }
      }
    } catch (e) {
      print('Failed to execute AI command: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: Colors.transparent,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // قائمة الرسائل
            Expanded(
              child: ListView.builder(
                controller: widget.scrollController,
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                padding: const EdgeInsets.only(
                  top: 90.0,
                  left: 20.0,
                  right: 20.0,
                  bottom: 20.0,
                ),
                itemCount: _messages.length + (_isTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _messages.length) {
                    // مؤشر الكتابة للذكاء الاصطناعي
                    return Align(
                      alignment: Alignment.centerRight,
                      child: SolariumGlassContainer(
                        margin: const EdgeInsets.only(bottom: 12, right: 40),
                        borderRadius: 16,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        child: const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: SiyaqColors.accentGold),
                        ),
                      ),
                    );
                  }

                  final message = _messages[index];
                  final isUser = message['role'] == 'user';

                  return Align(
                    alignment: isUser ? Alignment.centerLeft : Alignment.centerRight,
                    child: SolariumGlassContainer(
                      margin: EdgeInsets.only(
                        bottom: 12,
                        left: isUser ? 40 : 0,
                        right: isUser ? 0 : 40,
                      ),
                      borderRadius: 20,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      customBgColor: isUser 
                          ? (isDark ? SiyaqColors.accentGold.withOpacity(0.2) : const Color(0xFFFEF3C7))
                          : null,
                      customBorderColor: isUser
                          ? (isDark ? SiyaqColors.accentGold.withOpacity(0.4) : const Color(0xFFFCD34D))
                          : null,
                      child: Text(
                        message['message'] ?? '',
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          color: isUser 
                              ? (isDark ? Colors.white : const Color(0xFF92400E)) 
                              : (isDark ? Colors.white : const Color(0xFF0F172A)),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // صندوق الكتابة
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 105),
              child: Row(
                children: [
                  Expanded(
                    child: SolariumGlassContainer(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      borderRadius: 24,
                      child: TextField(
                        controller: _textController,
                        style: TextStyle(
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: 'اطلب من ميقاف تنظيم يومك...',
                          hintStyle: TextStyle(
                            color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          fillColor: Colors.transparent,
                          filled: false,
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // زر الإرسال المتوهج
                  InkWell(
                    onTap: _sendMessage,
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? SiyaqColors.accentGold : const Color(0xFFD97706),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: SiyaqColors.accentGoldGlow.withOpacity(isDark ? 0.35 : 0.2),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
