import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:url_launcher/url_launcher.dart';

import '../routes/app_routes.dart';
import '../services/devhub_links.dart';
import '../services/premium_access_service.dart';
import '../theme/app_colors.dart';

class LicenseGateScreen extends StatefulWidget {
  const LicenseGateScreen({super.key});

  @override
  State<LicenseGateScreen> createState() => _LicenseGateScreenState();
}

class _LicenseGateScreenState extends State<LicenseGateScreen> {
  final _keyController = TextEditingController();
  final _access = Get.find<PremiumAccessService>();

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _activate() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final valid = await _access.activateKey(_keyController.text);
    if (!mounted || !valid) return;
    final settings = Hive.box('settings');
    if (settings.get('portal_prompt_dismissed', defaultValue: false) != true) {
      var dontAskAgain = false;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Connect your KremCheats account'),
            content: const Text('Open the customer portal to view your keys, downloads, community access, and account details.'),
            actions: [
              CheckboxListTile(
                value: dontAskAgain,
                onChanged: (value) => setDialogState(() => dontAskAgain = value ?? false),
                title: const Text('Do not show again'),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('LATER')),
              FilledButton(onPressed: () { Navigator.pop(dialogContext); _open(DevHubLinks.portalUrl); }, child: const Text('OPEN PORTAL')),
            ],
          ),
        ),
      );
      if (dontAskAgain) await settings.put('portal_prompt_dismissed', true);
    }
    Get.offAllNamed(AppRoutes.home);
  }

  Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 470),
              child: Column(
                children: [
                  Container(
                    width: 78,
                    height: 78,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.accentGradient,
                      boxShadow: [BoxShadow(color: AppColors.accent.withValues(alpha: .35), blurRadius: 28)],
                    ),
                    padding: const EdgeInsets.all(2),
                    child: ClipOval(child: Image.asset('assets/branding/devhub_kremityss_logo.png', fit: BoxFit.cover)),
                  ),
                  const SizedBox(height: 22),
                  Text('Unlock KREM|AI', style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800, color: context.text)),
                  const SizedBox(height: 10),
                  Text(
                    'A valid Krem|Ai key is required after startup. Enter your key below, or request a free key to unlock Standard access.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, height: 1.55, color: context.textM),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: context.bgPanel,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: context.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _keyController,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _activate(),
                          decoration: InputDecoration(
                            labelText: 'Krem|Ai license key',
                            hintText: 'Paste your key',
                            prefixIcon: const Icon(Icons.key_rounded),
                            filled: true,
                            fillColor: context.bgInput,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Obx(() => FilledButton.icon(
                          onPressed: _access.isChecking.value ? null : _activate,
                          icon: _access.isChecking.value
                              ? const SizedBox(width: 17, height: 17, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.lock_open_rounded),
                          label: Text(_access.isChecking.value ? 'Checking key...' : 'Unlock Krem|Ai'),
                        )),
                        Obx(() {
                          if (_access.keyHint.value.isEmpty) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(_access.keyHint.value, textAlign: TextAlign.center, style: TextStyle(color: context.textM, fontSize: 12)),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(children: [Expanded(child: Divider(color: context.border)), Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text('OR', style: TextStyle(color: context.textD, fontSize: 11))), Expanded(child: Divider(color: context.border))]),
                  const SizedBox(height: 18),
                  OutlinedButton.icon(
                    onPressed: () => _open(DevHubLinks.freeKeyUrl),
                    icon: const Icon(Icons.card_giftcard_rounded),
                    label: const Text('Request a free Standard key'),
                  ),
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: () => _open(DevHubLinks.premiumUrl),
                    icon: const Icon(Icons.workspace_premium_rounded),
                    label: const Text('Get Premium Lifetime access'),
                  ),
                  const SizedBox(height: 20),
                  Text('Free key: Standard model + standard features for 24 hours. Premium key: all models and premium tools.', textAlign: TextAlign.center, style: TextStyle(color: context.textD, fontSize: 11, height: 1.45)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
