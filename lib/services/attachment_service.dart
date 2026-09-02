import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

import '../models/chat_attachment.dart';

class AttachmentService {
  final ImagePicker _imagePicker = ImagePicker();

  Future<List<ChatAttachment>> pickPhotos({bool fromCamera = false}) async {
    final files = fromCamera
        ? <XFile>[?await _imagePicker.pickImage(source: ImageSource.camera)]
        : await _imagePicker.pickMultiImage(imageQuality: 85, maxWidth: 2048);

    final attachments = <ChatAttachment>[];
    for (final file in files) {
      final bytes = await file.readAsBytes();
      attachments.add(ChatAttachment(
        name: file.name,
        mimeType: _mimeType(file.name, fallback: 'image/jpeg'),
        bytes: bytes,
      ));
    }
    return attachments;
  }

  Future<List<ChatAttachment>> pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: true,
      type: FileType.any,
    );
    if (result == null) return const [];

    final attachments = <ChatAttachment>[];
    for (final picked in result.files) {
      final bytes = picked.bytes ??
          (picked.path == null ? null : await File(picked.path!).readAsBytes());
      if (bytes == null) continue;

      final mime = _mimeType(picked.name);
      final text = _extractText(picked.name, bytes, mime);
      attachments.add(ChatAttachment(
        name: picked.name,
        mimeType: mime,
        bytes: bytes,
        extractedText: text,
      ));
    }
    return attachments;
  }

  String? _extractText(String name, Uint8List bytes, String mime) {
    final lower = name.toLowerCase();
    final isText = mime.startsWith('text/') ||
        lower.endsWith('.md') ||
        lower.endsWith('.csv') ||
        lower.endsWith('.json') ||
        lower.endsWith('.yaml') ||
        lower.endsWith('.yml') ||
        lower.endsWith('.xml') ||
        lower.endsWith('.dart') ||
        lower.endsWith('.py') ||
        lower.endsWith('.js') ||
        lower.endsWith('.swift');
    if (!isText) return null;
    return utf8.decode(bytes, allowMalformed: true);
  }

  String _mimeType(String name, {String fallback = 'application/octet-stream'}) {
    final extension = name.contains('.') ? name.split('.').last.toLowerCase() : '';
    const types = <String, String>{
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'gif': 'image/gif',
      'webp': 'image/webp',
      'heic': 'image/heic',
      'mp4': 'video/mp4',
      'm4v': 'video/x-m4v',
      'mov': 'video/quicktime',
      'webm': 'video/webm',
      'mkv': 'video/x-matroska',
      'avi': 'video/x-msvideo',
      'txt': 'text/plain',
      'md': 'text/markdown',
      'csv': 'text/csv',
      'json': 'application/json',
      'xml': 'application/xml',
      'yaml': 'text/yaml',
      'yml': 'text/yaml',
      'pdf': 'application/pdf',
      'doc': 'application/msword',
      'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'xls': 'application/vnd.ms-excel',
      'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    };
    return types[extension] ?? fallback;
  }
}
