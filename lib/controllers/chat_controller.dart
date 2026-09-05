import 'dart:async';
import 'dart:convert';

import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../services/llm_service.dart';
import '../services/chat_storage_service.dart';
import '../services/web_search_service.dart';
import '../models/chat_attachment.dart';
import '../services/premium_access_service.dart';

class ChatController extends GetxController {
  static const defaultDeveloperPrompt = '''You are Krem|Ai, a private local-first coding assistant. Internet context is used only when the user enables it.

Be highly useful, direct, technically precise, and honest about uncertainty. Analyze the user’s request before answering. Built-in skills: coding (write complete runnable solutions), debugging (find root causes and fixes), code review (identify correctness, security, and performance issues), explain (teach step by step), refactor (preserve behavior while improving structure), summarize (extract decisions and action items), and research (separate verified web context from assumptions). For coding tasks, preserve the user’s existing architecture, explain important trade-offs briefly, and identify bugs, edge cases, security risks, and missing dependencies. Prefer clear Markdown with headings, concise explanations, and fenced code blocks with the correct language tag. When revising code, show the exact replacement or a focused diff and explain where it belongs. Never invent APIs, test results, file contents, or tool actions. Use attached text and files as source material, clearly distinguishing facts from assumptions. Ask one focused clarification question only when it is necessary to avoid a wrong implementation.''';
  final LlmService _llm = Get.find<LlmService>();
  final ChatStorageService _storage = Get.find<ChatStorageService>();
  final WebSearchService _webSearch = Get.find<WebSearchService>();

  final chats = <ChatModel>[].obs;
  final activeChatId = RxnString();
  final isGenerating = false.obs;
  final streamedResponse = ''.obs;
  final temperature = 0.7.obs;
  final systemPrompt = ''.obs;

  StreamSubscription<String>? _genSub;

  static const standardDailyFileLimit = 4;
  final _settings = Hive.box('settings');

  bool _underStandardDailyLimit({int files = 0}) {
    if (Get.find<PremiumAccessService>().isPremium.value) return true;
    if (files == 0) return true;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final storedDay = _settings.get('standard_usage_day') as String?;
    final used = storedDay == today ? (_settings.get('standard_usage_count', defaultValue: 0) as num).toInt() : 0;
    if (used + files > standardDailyFileLimit) return false;
    _settings.put('standard_usage_day', today);
    _settings.put('standard_usage_count', used + files);
    return true;
  }

  String _persistentMemoryContext(ChatModel current) {
    final snippets = <String>[];
    for (final other in chats) {
      if (other.id == current.id) continue;
      for (final message in other.messages.reversed) {
        if (message.content.trim().isEmpty || message.content.startsWith('⚠')) continue;
        snippets.add('${other.title}: ${message.content.trim()}');
        if (snippets.length >= 12) break;
      }
      if (snippets.length >= 12) break;
    }
    final joined = snippets.join('\n');
    if (joined.isEmpty) return '';
    const maxMemoryCharacters = 6000;
    return joined.length > maxMemoryCharacters
        ? joined.substring(0, maxMemoryCharacters)
        : joined;
  }

  @override
  void onInit() {
    super.onInit();
    _loadChats();
    temperature.value = _storage.defaultTemperature;
    systemPrompt.value = _storage.globalSystemPrompt.isNotEmpty
        ? _storage.globalSystemPrompt
        : defaultDeveloperPrompt;
  }

  void _loadChats() {
    chats.value = _storage.getAllChats();
  }

  ChatModel? get activeChat {
    if (activeChatId.value == null) return null;
    try {
      return chats.firstWhere((c) => c.id == activeChatId.value);
    } catch (_) {
      return null;
    }
  }

  /// Create a new chat and switch to it.
  void newChat() {
    final chat = ChatModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      systemPrompt: systemPrompt.value,
    );
    chats.insert(0, chat);
    _storage.saveChat(chat);
    activeChatId.value = chat.id;
  }

  /// Switch to an existing chat.
  void switchChat(String id) {
    activeChatId.value = id;
    final chat = activeChat;
    if (chat != null) {
      systemPrompt.value = chat.systemPrompt;
    }
  }

  /// Delete a chat.
  void deleteChat(String id) {
    chats.removeWhere((c) => c.id == id);
    _storage.deleteChat(id);
    if (activeChatId.value == id) {
      activeChatId.value = chats.isNotEmpty ? chats.first.id : null;
    }
  }

  /// Send a user message and stream AI response.
  Future<void> sendMessage(
    String text, {
    String? modelFilename,
    List<ChatAttachment> attachments = const [],
    bool useInternet = false,
  }) async {
    if (text.trim().isEmpty && attachments.isEmpty) return;
    if (!_underStandardDailyLimit(files: attachments.length)) {
      Get.snackbar('Standard file limit reached', 'Standard access allows 4 attached files per day. Premium access is unlimited.');
      return;
    }
    final chat = activeChat;
    if (chat == null) return;

    var remainingContext = 120000;
    final attachmentPrompt = attachments
        .where((a) => a.hasExtractedText)
        .map((a) {
          final raw = a.extractedText ?? '';
          if (remainingContext <= 0) return '';
          final take = raw.length.clamp(0, remainingContext);
          remainingContext -= take;
          return '\n\n--- File: ${a.name} ---\n${raw.substring(0, take)}';
        })
        .join();
    final webContext = useInternet && text.trim().isNotEmpty
        ? await _webSearch.search(text.trim())
        : '';
    final promptText = text.trim().isEmpty && attachmentPrompt.isEmpty
        ? 'Please review the attached files.'
        : '${text.trim()}$attachmentPrompt${webContext.isNotEmpty ? '\n\n$webContext' : ''}';

    // Add user message
    final userMsg = MessageModel(
      role: MessageRole.user,
      content: promptText,
      attachmentNames: attachments.map((a) => a.name).toList(),
      attachmentMimeTypes: attachments.map((a) => a.mimeType).toList(),
      // Keep only modest previews in Hive; the source file is not copied into chat history.
      attachmentBase64: attachments
          .where((a) => a.isImage && a.bytes != null && a.bytes!.length <= 2 * 1024 * 1024)
          .map((a) => base64Encode(a.bytes!))
          .toList(),
    );
    chat.messages.add(userMsg);
    chat.autoTitle();
    chat.updatedAt = DateTime.now();

    // Lock model to this chat on first message
    if (chat.modelId.isEmpty && modelFilename != null) {
      chat.modelId = modelFilename;
    }

    _storage.saveChat(chat);
    chats.refresh();

    // Build message history for LLM
    final history = chat.messages
        .where((m) => !m.isSystem)
        .toList()
        .reversed
        .take(12)
        .toList()
        .reversed
        .map((m) => m.toLlamaMessage())
        .toList();

    // Start generation
    isGenerating.value = true;
    streamedResponse.value = '';

    final aiMsg = MessageModel(role: MessageRole.assistant, content: '');
    chat.messages.add(aiMsg);
    chats.refresh();

    try {
        final customPrompt = chat.systemPrompt.isNotEmpty
          ? chat.systemPrompt
          : systemPrompt.value;
      final memory = _persistentMemoryContext(chat);
      final memoryPrompt = memory.isEmpty
          ? ''
          : '\n\nRelevant local memory from earlier chats (use only when relevant; do not invent facts):\n$memory';
      final effectivePrompt = customPrompt.trim().isEmpty
          ? defaultDeveloperPrompt
          : '$defaultDeveloperPrompt\n\nAdditional user instructions:\n$customPrompt';
      final promptWithMemory = '$effectivePrompt$memoryPrompt';
      final stream = _llm.generate(
        messages: history,
        systemPrompt: promptWithMemory,
        temperature: temperature.value.clamp(0.15, 0.85),
      );

      await for (final token in stream) {
        streamedResponse.value += token;
        aiMsg.content = streamedResponse.value;
        // Throttle UI refreshes
        chats.refresh();
      }
    } catch (e) {
      if (aiMsg.content.isEmpty) {
        aiMsg.content = '⚠ Error: ${e.toString()}';
      }
    } finally {
      // Clean up any trailing stop tokens or whitespace
      aiMsg.content = aiMsg.content
          .replaceAll(RegExp(
            r'<\|end\|>|<\|eot_id\|>|<\|endoftext\|>|<\|im_end\|>|<\|im_start\|>'
            r'|<end_of_turn>|<start_of_turn>|<\|assistant\|>|<\|user\|>|<\|system\|>'
            r'|<\|pad\|>|</s>|<s>|\[INST\]|\[/INST\]|\[end\]'
          ), '')
          .trim();
      isGenerating.value = false;
      streamedResponse.value = '';
      chat.updatedAt = DateTime.now();
      _storage.saveChat(chat);
      chats.refresh();
    }
  }

  /// Stop current generation.
  void stopGeneration() {
    _llm.stopGeneration();
    isGenerating.value = false;
  }

  /// Update the system prompt for the active chat.
  void updateSystemPrompt(String prompt) {
    systemPrompt.value = prompt;
    final chat = activeChat;
    if (chat != null) {
      chat.systemPrompt = prompt;
      _storage.saveChat(chat);
    }
  }

  /// Set and persist the global system prompt.
  void setGlobalSystemPrompt(String prompt) {
    systemPrompt.value = prompt;
    _storage.globalSystemPrompt = prompt;
  }

  /// Clear global system prompt.
  void clearGlobalSystemPrompt() {
    systemPrompt.value = '';
    _storage.globalSystemPrompt = '';
  }

  void updateTemperature(double temp) {
    temperature.value = temp;
    _storage.defaultTemperature = temp;
  }

  @override
  void onClose() {
    _genSub?.cancel();
    super.onClose();
  }
}
