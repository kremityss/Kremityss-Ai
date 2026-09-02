import 'dart:async';
import 'dart:convert';

import 'package:get/get.dart';

import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../services/llm_service.dart';
import '../services/chat_storage_service.dart';
import '../services/web_search_service.dart';
import '../models/chat_attachment.dart';

class ChatController extends GetxController {
  static const defaultDeveloperPrompt = '''You are Krem|Ai, a private local-first coding assistant. Internet context is used only when the user enables it.

Be highly useful, direct, technically precise, and honest about uncertainty. Analyze the user’s request before answering. For coding tasks, provide complete runnable solutions, preserve the user’s existing architecture, explain important trade-offs briefly, and identify bugs, edge cases, security risks, and missing dependencies. Prefer clear Markdown with headings, concise explanations, and fenced code blocks with the correct language tag. When revising code, show the exact replacement or a focused diff and explain where it belongs. Never invent APIs, test results, file contents, or tool actions. Use attached text and files as source material, clearly distinguishing facts from assumptions. For images and binary files, describe only what the available local model can actually infer. Ask one focused clarification question only when it is necessary to avoid a wrong implementation.''';
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
    final chat = activeChat;
    if (chat == null) return;

    final attachmentPrompt = attachments
        .where((a) => a.hasExtractedText)
        .map((a) => '\n\n--- File: ${a.name} ---\n${a.extractedText}')
        .join();
    final webContext = useInternet ? await _webSearch.search(text) : '';
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
      final effectivePrompt = customPrompt.trim().isEmpty
          ? defaultDeveloperPrompt
          : '$defaultDeveloperPrompt\\n\\nAdditional user instructions:\\n$customPrompt';
      final stream = _llm.generate(
        messages: history,
        systemPrompt: effectivePrompt,
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
