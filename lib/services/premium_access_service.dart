import 'dart:convert';
import 'dart:math';

import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;

import 'devhub_links.dart';

/// Premium entitlement state for Krem|Ai.
///
/// The app sends only the key, product, and an app-generated installation ID to
/// the first-party KremCheats validation endpoint. No seller secret is shipped.
class PremiumAccessService extends GetxService {
  static const validationUrl = DevHubLinks.licenseValidationUrl;
  static const productId = DevHubLinks.productId;

  final isPremium = false.obs;
  final isChecking = false.obs;
  final keyHint = ''.obs;

  late Box _box;
  String? _activeKey;

  String get maskedKey {
    final key = _activeKey;
    if (key == null || key.length < 8) return '';
    return '${key.substring(0, 4)}••••${key.substring(key.length - 4)}';
  }

  @override
  void onInit() {
    super.onInit();
    _box = Hive.box('settings');
    _activeKey = _box.get('premium_key') as String?;
    isPremium.value = _box.get('premium_active', defaultValue: false) as bool;
    keyHint.value = _box.get('premium_hint', defaultValue: '') as String;
  }

  Future<String> _installationId() async {
    final saved = _box.get('license_installation_id') as String?;
    if (saved != null && saved.isNotEmpty) return saved;
    final random = Random.secure();
    final bytes = List<int>.generate(24, (_) => random.nextInt(256));
    final created = base64UrlEncode(bytes).replaceAll('=', '');
    await _box.put('license_installation_id', created);
    return created;
  }

  /// Validates and binds a Krem|Ai key to this app installation.
  Future<bool> activateKey(String rawKey) async {
    final key = rawKey.trim();
    if (key.isEmpty) {
      keyHint.value = 'Enter a Krem|Ai license key.';
      return false;
    }
    if (validationUrl.isEmpty) {
      isPremium.value = false;
      keyHint.value = 'KremCheats license validation is not connected.';
      return false;
    }

    isChecking.value = true;
    try {
      final response = await http
          .post(
            Uri.parse(validationUrl),
            headers: {'content-type': 'application/json'},
            body: jsonEncode({
              'key': key,
              'product': productId,
              'hwidUuid': await _installationId(),
            }),
          )
          .timeout(const Duration(seconds: 15));
      final decoded = jsonDecode(response.body);
      final data = decoded is Map ? Map<String, dynamic>.from(decoded) : null;
      final valid = response.statusCode >= 200 &&
          response.statusCode < 300 &&
          data?['valid'] == true;

      isPremium.value = valid;
      if (valid) {
        _activeKey = key;
        keyHint.value = 'Krem|Ai Premium active';
        await _box.put('premium_key', key);
        await _box.put('premium_active', true);
        await _box.put('premium_hint', keyHint.value);
      } else {
        keyHint.value = 'This Krem|Ai license is invalid, inactive, expired, or bound to another device.';
        await clearEntitlement();
      }
      return valid;
    } catch (_) {
      isPremium.value = false;
      keyHint.value = 'Could not reach KremCheats license validation. Try again later.';
      return false;
    } finally {
      isChecking.value = false;
    }
  }

  Future<void> clearEntitlement() async {
    _activeKey = null;
    isPremium.value = false;
    await _box.delete('premium_key');
    await _box.put('premium_active', false);
  }

  bool requirePremium() {
    if (isPremium.value) return true;
    Get.snackbar(
      'Premium feature',
      'A paid Krem|Ai license is required for custom GGUF files and model links.',
      snackPosition: SnackPosition.BOTTOM,
    );
    return false;
  }
}
