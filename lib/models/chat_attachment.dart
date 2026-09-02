import 'dart:typed_data';

/// A user-selected attachment prepared for a local chat message.
///
/// The current llamadart path is text-only. Text-readable files are therefore
/// included in the prompt, while images are retained for display and future
/// multimodal model support.
class ChatAttachment {
  final String name;
  final String mimeType;
  final Uint8List? bytes;
  final String? extractedText;

  const ChatAttachment({
    required this.name,
    required this.mimeType,
    this.bytes,
    this.extractedText,
  });

  bool get isImage => mimeType.startsWith('image/');
  bool get isVideo => mimeType.startsWith('video/');
  bool get hasExtractedText => extractedText != null && extractedText!.trim().isNotEmpty;
}
