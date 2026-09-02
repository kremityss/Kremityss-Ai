import 'package:hive/hive.dart';

part 'message_model.g.dart';

@HiveType(typeId: 1)
enum MessageRole {
  @HiveField(0)
  user,
  @HiveField(1)
  assistant,
  @HiveField(2)
  system,
}

@HiveType(typeId: 2)
class MessageModel extends HiveObject {
  @HiveField(0)
  final MessageRole role;

  @HiveField(1)
  String content;

  @HiveField(2)
  final DateTime timestamp;

  @HiveField(3)
  String? imageBase64;

  @HiveField(4)
  String? imageMimeType;

  @HiveField(5)
  final List<String> attachmentNames;

  @HiveField(6)
  final List<String> attachmentMimeTypes;

  @HiveField(7)
  final List<String> attachmentBase64;

  MessageModel({
    required this.role,
    required this.content,
    DateTime? timestamp,
    this.imageBase64,
    this.imageMimeType,
    List<String>? attachmentNames,
    List<String>? attachmentMimeTypes,
    List<String>? attachmentBase64,
  })  : attachmentNames = attachmentNames ?? const [],
        attachmentMimeTypes = attachmentMimeTypes ?? const [],
        attachmentBase64 = attachmentBase64 ?? const [],
        timestamp = timestamp ?? DateTime.now();

  bool get hasAttachments => attachmentNames.isNotEmpty;

  bool get isUser => role == MessageRole.user;
  bool get isAssistant => role == MessageRole.assistant;
  bool get isSystem => role == MessageRole.system;

  Map<String, String> toLlamaMessage() {
    return {
      'role': role.name,
      'content': content,
    };
  }
}
