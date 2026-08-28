import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/models/prayer_config.dart';

class SiyaqSettings {
  final String geminiApiKey;
  final String openaiApiKey;
  final Map<String, String> apiKeys;
  final String activeAiProvider; // 'gemini', 'openai', 'claude', 'grok', 'groq', 'deepseek', 'mistral', 'openrouter', 'cohere', 'together', 'custom'
  final Map<String, String> providerModels;
  final Map<String, String> customEndpoints;
  final Map<String, PrayerConfig> prayerConfigs; // Map of prayer name to its config
  final bool isRamadanModeEnabled; // Automatically activates ramadan template if true and we are in ramadan
  final String themeMode; // 'system', 'light', 'dark'
  final String calculationMethod; // Makkah, MWL, Egyptian, ISNA, Karachi, UAE, Kuwait, Qatar, Singapore, AlAdhanDirect
  final bool confirmDeleteTasks; // إظهار تنبيه تأكيد الحذف

  SiyaqSettings({
    required this.geminiApiKey,
    required this.openaiApiKey,
    this.apiKeys = const {},
    this.activeAiProvider = 'gemini',
    this.providerModels = const {},
    this.customEndpoints = const {},
    required this.prayerConfigs,
    this.isRamadanModeEnabled = false,
    this.themeMode = 'system',
    this.calculationMethod = 'Makkah',
    this.confirmDeleteTasks = true,
  });

  String get activeApiKey {
    if (apiKeys.containsKey(activeAiProvider) && apiKeys[activeAiProvider]!.isNotEmpty) {
      return apiKeys[activeAiProvider]!;
    }
    if (activeAiProvider == 'gemini') return geminiApiKey;
    if (activeAiProvider == 'openai') return openaiApiKey;
    return '';
  }

  String get activeModel {
    if (providerModels.containsKey(activeAiProvider) && providerModels[activeAiProvider]!.isNotEmpty) {
      return providerModels[activeAiProvider]!;
    }
    switch (activeAiProvider) {
      case 'gemini':
        return 'gemini-3.7-flash';
      case 'openai':
        return 'gpt-5.6-sol';
      case 'claude':
        return 'claude-3-7-sonnet';
      case 'grok':
      case 'xai':
        return 'grok-4.6';
      case 'groq':
        return 'llama-3.3-70b-versatile';
      case 'deepseek':
        return 'deepseek-chat';
      case 'mistral':
        return 'mistral-large-latest';
      case 'openrouter':
        return 'google/gemini-3.7-flash';
      case 'cohere':
        return 'command-r-plus-08-2024';
      case 'together':
        return 'deepseek-ai/DeepSeek-R1';
      case 'custom':
        return 'llama3.3';
      default:
        return 'gemini-3.7-flash';
    }
  }

  SiyaqSettings copyWith({
    String? geminiApiKey,
    String? openaiApiKey,
    Map<String, String>? apiKeys,
    String? activeAiProvider,
    Map<String, String>? providerModels,
    Map<String, String>? customEndpoints,
    Map<String, PrayerConfig>? prayerConfigs,
    bool? isRamadanModeEnabled,
    String? themeMode,
    String? calculationMethod,
    bool? confirmDeleteTasks,
  }) {
    return SiyaqSettings(
      geminiApiKey: geminiApiKey ?? this.geminiApiKey,
      openaiApiKey: openaiApiKey ?? this.openaiApiKey,
      apiKeys: apiKeys ?? this.apiKeys,
      activeAiProvider: activeAiProvider ?? this.activeAiProvider,
      providerModels: providerModels ?? this.providerModels,
      customEndpoints: customEndpoints ?? this.customEndpoints,
      prayerConfigs: prayerConfigs ?? this.prayerConfigs,
      isRamadanModeEnabled: isRamadanModeEnabled ?? this.isRamadanModeEnabled,
      themeMode: themeMode ?? this.themeMode,
      calculationMethod: calculationMethod ?? this.calculationMethod,
      confirmDeleteTasks: confirmDeleteTasks ?? this.confirmDeleteTasks,
    );
  }
}

class SettingsNotifier extends Notifier<SiyaqSettings> {
  static const String _geminiKey = 'setting_gemini_key';
  static const String _openaiKey = 'setting_openai_key';
  static const String _apiKeysMapKey = 'setting_api_keys_map';
  static const String _activeAiProviderKey = 'setting_active_ai_provider';
  static const String _providerModelsKey = 'setting_provider_models';
  static const String _customEndpointsKey = 'setting_custom_endpoints';
  static const String _prayerConfigsKey = 'setting_prayer_configs';
  static const String _ramadanModeKey = 'setting_ramadan_mode';
  static const String _themeModeKey = 'setting_theme_mode';
  static const String _calcMethodKey = 'setting_calc_method';
  static const String _confirmDeleteTasksKey = 'setting_confirm_delete_tasks';

  @override
  SiyaqSettings build() {
    final defaultConfigs = {
      'Fajr': PrayerConfig(prayerName: 'Fajr', minutesOffsetFromAdhan: 0, durationMinutes: 20),
      'Dhuhr': PrayerConfig(prayerName: 'Dhuhr', minutesOffsetFromAdhan: 0, durationMinutes: 20),
      'Asr': PrayerConfig(prayerName: 'Asr', minutesOffsetFromAdhan: 0, durationMinutes: 20),
      'Maghrib': PrayerConfig(prayerName: 'Maghrib', minutesOffsetFromAdhan: 0, durationMinutes: 15),
      'Isha': PrayerConfig(prayerName: 'Isha', minutesOffsetFromAdhan: 0, durationMinutes: 25),
    };

    _loadSettings();
    return SiyaqSettings(
      geminiApiKey: '',
      openaiApiKey: '',
      apiKeys: const {},
      activeAiProvider: 'gemini',
      providerModels: const {},
      customEndpoints: const {},
      prayerConfigs: defaultConfigs,
      themeMode: 'system',
      calculationMethod: 'Makkah',
      confirmDeleteTasks: true,
    );
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load prayer configs
    final String? configsJsonStr = prefs.getString(_prayerConfigsKey);
    Map<String, PrayerConfig> configs = state.prayerConfigs;
    if (configsJsonStr != null) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(configsJsonStr);
        configs = decoded.map((key, value) => MapEntry(key, PrayerConfig.fromJson(value)));
      } catch (e) {
        // Fallback to default if error
      }
    }

    // Load API Keys Map
    Map<String, String> loadedApiKeys = {};
    final String? apiKeysJson = prefs.getString(_apiKeysMapKey);
    if (apiKeysJson != null) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(apiKeysJson);
        loadedApiKeys = decoded.map((k, v) => MapEntry(k, v.toString()));
      } catch (_) {}
    }

    final geminiK = prefs.getString(_geminiKey) ?? '';
    final openaiK = prefs.getString(_openaiKey) ?? '';
    if (geminiK.isNotEmpty && !loadedApiKeys.containsKey('gemini')) loadedApiKeys['gemini'] = geminiK;
    if (openaiK.isNotEmpty && !loadedApiKeys.containsKey('openai')) loadedApiKeys['openai'] = openaiK;

    // Load Provider Models
    Map<String, String> loadedModels = {};
    final String? modelsJson = prefs.getString(_providerModelsKey);
    if (modelsJson != null) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(modelsJson);
        loadedModels = decoded.map((k, v) => MapEntry(k, v.toString()));
      } catch (_) {}
    }

    // Load Custom Endpoints
    Map<String, String> loadedEndpoints = {};
    final String? endpointsJson = prefs.getString(_customEndpointsKey);
    if (endpointsJson != null) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(endpointsJson);
        loadedEndpoints = decoded.map((k, v) => MapEntry(k, v.toString()));
      } catch (_) {}
    }

    state = SiyaqSettings(
      geminiApiKey: geminiK,
      openaiApiKey: openaiK,
      apiKeys: loadedApiKeys,
      activeAiProvider: prefs.getString(_activeAiProviderKey) ?? 'gemini',
      providerModels: loadedModels,
      customEndpoints: loadedEndpoints,
      prayerConfigs: configs,
      isRamadanModeEnabled: prefs.getBool(_ramadanModeKey) ?? false,
      themeMode: prefs.getString(_themeModeKey) ?? prefs.getString('theme_mode') ?? 'system',
      calculationMethod: prefs.getString(_calcMethodKey) ?? 'Makkah',
      confirmDeleteTasks: prefs.getBool(_confirmDeleteTasksKey) ?? true,
    );
  }

  Future<void> setProviderApiKey(String provider, String key) async {
    final newMap = Map<String, String>.from(state.apiKeys);
    newMap[provider] = key;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiKeysMapKey, jsonEncode(newMap));
    if (provider == 'gemini') await prefs.setString(_geminiKey, key);
    if (provider == 'openai') await prefs.setString(_openaiKey, key);

    state = state.copyWith(
      apiKeys: newMap,
      geminiApiKey: provider == 'gemini' ? key : state.geminiApiKey,
      openaiApiKey: provider == 'openai' ? key : state.openaiApiKey,
    );
  }

  Future<void> setActiveAiProvider(String provider) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeAiProviderKey, provider);
    state = state.copyWith(activeAiProvider: provider);
  }

  Future<void> setProviderModel(String provider, String model) async {
    final newMap = Map<String, String>.from(state.providerModels);
    newMap[provider] = model;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_providerModelsKey, jsonEncode(newMap));
    state = state.copyWith(providerModels: newMap);
  }

  Future<void> setCustomEndpoint(String provider, String endpoint) async {
    final newMap = Map<String, String>.from(state.customEndpoints);
    newMap[provider] = endpoint;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_customEndpointsKey, jsonEncode(newMap));
    state = state.copyWith(customEndpoints: newMap);
  }

  Future<void> setCalculationMethod(String method) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_calcMethodKey, method);
    state = state.copyWith(calculationMethod: method);
  }

  Future<void> setConfirmDeleteTasks(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_confirmDeleteTasksKey, value);
    state = state.copyWith(confirmDeleteTasks: value);
  }

  Future<void> setGeminiApiKey(String key) async {
    await setProviderApiKey('gemini', key);
  }

  Future<void> setOpenaiApiKey(String key) async {
    await setProviderApiKey('openai', key);
  }

  Future<void> updatePrayerConfig(PrayerConfig config) async {
    final newConfigs = Map<String, PrayerConfig>.from(state.prayerConfigs);
    newConfigs[config.prayerName] = config;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prayerConfigsKey, jsonEncode(
      newConfigs.map((key, value) => MapEntry(key, value.toJson()))
    ));
    
    state = state.copyWith(prayerConfigs: newConfigs);
  }

  Future<void> setRamadanMode(bool isEnabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_ramadanModeKey, isEnabled);
    state = state.copyWith(isRamadanModeEnabled: isEnabled);
  }

  Future<void> setThemeMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, mode);
    state = state.copyWith(themeMode: mode);
  }

  Future<void> resetSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_themeModeKey);
    await prefs.remove(_prayerConfigsKey);
    await prefs.remove(_geminiKey);
    await prefs.remove(_openaiKey);
    await prefs.remove(_apiKeysMapKey);
    await prefs.remove(_activeAiProviderKey);
    await prefs.remove(_providerModelsKey);
    await prefs.remove(_customEndpointsKey);
    await prefs.remove(_ramadanModeKey);
    await prefs.remove(_confirmDeleteTasksKey);

    final defaultConfigs = {
      'Fajr': PrayerConfig(prayerName: 'Fajr', minutesOffsetFromAdhan: 0, durationMinutes: 20),
      'Dhuhr': PrayerConfig(prayerName: 'Dhuhr', minutesOffsetFromAdhan: 0, durationMinutes: 20),
      'Asr': PrayerConfig(prayerName: 'Asr', minutesOffsetFromAdhan: 0, durationMinutes: 20),
      'Maghrib': PrayerConfig(prayerName: 'Maghrib', minutesOffsetFromAdhan: 0, durationMinutes: 15),
      'Isha': PrayerConfig(prayerName: 'Isha', minutesOffsetFromAdhan: 0, durationMinutes: 25),
    };

    state = SiyaqSettings(
      geminiApiKey: '',
      openaiApiKey: '',
      apiKeys: const {},
      activeAiProvider: 'gemini',
      providerModels: const {},
      customEndpoints: const {},
      prayerConfigs: defaultConfigs,
      isRamadanModeEnabled: false,
      themeMode: 'system',
      confirmDeleteTasks: true,
    );
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, SiyaqSettings>(SettingsNotifier.new);
