import 'dart:convert';
import 'dart:math';

import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;

import 'devhub_links.dart';

/// First-party entitlement state for Krem|Ai.
///
/// Every installation must have a validated key before the main app opens.
/// Free 24-hour keys grant Standard access; paid keys additionally grant Premium.
class PremiumAccessService extends GetxService {
  static const validationUrl = DevHubLinks.licenseValidationUrl;
  static const productId = DevHubLinks.productId;

  final hasLicense = false.obs;
  final isPremium = false.obs;
  final isChecking = false.obs;
  final keyHint = ''.obs;
  final licenseTier = 'Locked'.obs;

  late Box _box;
  String? _activeKey;

  bool get isStandard => hasLicense.value;

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
    hasLicense.value = _box.get('license_active', defaultValue: false) as bool;
    isPremium.value = _box.get('premium_active', defaultValue: false) as bool;
    licenseTier.value = isPremium.value ? 'Premium' : (hasLicense.value ? 'Standard' : 'Locked');
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
      keyHint.value = 'Enter a Krem|Ai key to continue.';
      return false;
    }
    if (validationUrl.isEmpty) {
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

      if (!valid) {
        keyHint.value = 'That key is invalid, expired, inactive, or bound to another device.';
        return false;
      }

      final product = (data?['product'] ?? '').toString().toLowerCase();
      final premium = product.contains('premium') || product.contains('lifetime');
      _activeKey = key;
      hasLicense.value = true;
      isPremium.value = premium;
      licenseTier.value = premium ? 'Premium' : 'Standard';
      keyHint.value = premium
          ? 'Premium access active.'
          : 'Standard access active. Upgrade for all Premium models and tools.';
      await _box.put('premium_key', key);
      await _box.put('license_active', true);
      await _box.put('premium_active', premium);
      await _box.put('premium_hint', keyHint.value);
      return true;
    } catch (_) {
      keyHint.value = 'Could not reach KremCheats. Check your connection and try again.';
      return false;
    } finally {
      isChecking.value = false;
    }
  }

  Future<void> clearEntitlement() async {
    _activeKey = null;
    hasLicense.value = false;
    isPremium.value = false;
    licenseTier.value = 'Locked';
    await _box.delete('premium_key');
    await _box.put('license_active', false);
    await _box.put('premium_active', false);
  }

  bool requireAccess() {
    if (hasLicense.value) return true;
    Get.snackbar(
      'Key required',
      'Enter or request a free key to unlock Standard access.',
      snackPosition: SnackPosition.BOTTOM,
    );
    return false;
  }

  bool requirePremium() {
    if (isPremium.value) return true;
    Get.snackbar(
      'Premium feature',
      'This model or tool requires a paid Krem|Ai Premium key.',
      snackPosition: SnackPosition.BOTTOM,
    );
    return false;
  }
}
