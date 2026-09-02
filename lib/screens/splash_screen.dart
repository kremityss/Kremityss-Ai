import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../theme/app_colors.dart';
import '../services/llm_service.dart';
import '../services/model_manager.dart';
import '../services/chat_storage_service.dart';
import '../services/local_api_server_service.dart';
import '../services/wakelock_service.dart';
import '../services/log_service.dart';
import '../services/background_optimizer_service.dart';
import '../services/premium_access_service.dart';
import '../routes/app_routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  String _status = 'Initializing...';
  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    _initApp();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initApp() async {
    final startedAt = DateTime.now();
    try {
      final log = Get.find<LogService>()..init();

      setState(() => _status = 'Setting up storage...');
      log.info('Initializing storage...', source: 'Splash');
      await Get.find<ChatStorageService>().init();

      setState(() => _status = 'Loading model catalog...');
      log.info('Loading model catalog...', source: 'Splash');
      await Get.find<ModelManager>().init();

      setState(() => _status = 'Preparing AI engine...');
      log.info('Preparing AI engine...', source: 'Splash');
      await Get.find<LlmService>().init();

      setState(() => _status = 'Preparing local API...');
      log.info('Preparing local API...', source: 'Splash');
      await Get.find<LocalApiServerService>().init();

      setState(() => _status = 'Setting up background services...');
      log.info('Setting up background services...', source: 'Splash');
      await Get.find<WakelockService>().init();

      setState(() => _status = 'Ready');
      log.info('All services initialized successfully', source: 'Splash');

      // Keep the cinematic intro on screen for the requested ten seconds.
      final elapsed = DateTime.now().difference(startedAt);
      final remaining = const Duration(seconds: 10) - elapsed;
      if (remaining > Duration.zero) {
        await Future.delayed(remaining);
      }

      if (mounted) {
        await BackgroundOptimizerService.checkAndPrompt(context);
      }
      final access = Get.find<PremiumAccessService>();
      Get.offAllNamed(access.hasLicense.value ? AppRoutes.home : AppRoutes.licenseGate);
    } catch (e) {
      if (mounted) setState(() => _status = 'Startup error');
      try {
        Get.find<LogService>().error('Init failed: $e', source: 'Splash');
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050506),
      body: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedBuilder(
            animation: _animationController,
            builder: (_, __) => CustomPaint(
              painter: _CinematicBackdropPainter(
                progress: _animationController.value,
                accent: AppColors.accent,
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  final t = _animationController.value;
                  final pulse = 1 + math.sin(t * math.pi * 2) * 0.035;
                  final rotation = t * math.pi * 2;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Transform.rotate(
                        angle: rotation,
                        child: Transform.scale(scale: pulse, child: child),
                      ),
                      const SizedBox(height: 30),
                      Opacity(
                        opacity: Curves.easeOut.transform(
                          ((t - 0.12) / 0.20).clamp(0.0, 1.0),
                        ),
                        child: const Text(
                          'KREM|AI',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 31,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 8,
                          ),
                        ),
                      ),
                      const SizedBox(height: 9),
                      Opacity(
                        opacity: Curves.easeOut.transform(
                          ((t - 0.22) / 0.18).clamp(0.0, 1.0),
                        ),
                        child: Text(
                          'BY KREM|AI',
                          style: TextStyle(
                            color: AppColors.accent,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 4,
                            shadows: [
                              Shadow(
                                color: AppColors.accent.withValues(alpha: 0.8),
                                blurRadius: 14,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 44),
                      SizedBox(
                        width: 170,
                        child: LinearProgressIndicator(
                          minHeight: 2,
                          value: t,
                          backgroundColor: Colors.white.withValues(alpha: 0.12),
                          valueColor: AlwaysStoppedAnimation(AppColors.accent),
                        ),
                      ),
                      const SizedBox(height: 13),
                      Text(
                        _status.toUpperCase(),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.56),
                          fontSize: 10,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  );
                },
                child: Container(
                  width: 158,
                  height: 158,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.9),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.55),
                        blurRadius: 42,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/branding/devhub_kremityss_logo.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CinematicBackdropPainter extends CustomPainter {
  const _CinematicBackdropPainter({required this.progress, required this.accent});

  final double progress;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final shortest = math.min(size.width, size.height);
    final phase = progress * math.pi * 2;

    final glow = Paint()
      ..shader = RadialGradient(
        colors: [accent.withValues(alpha: 0.18), Colors.transparent],
      ).createShader(Rect.fromCircle(center: center, radius: shortest * 0.48));
    canvas.drawCircle(center, shortest * 0.48, glow);

    final rings = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = accent.withValues(alpha: 0.18);
    for (var i = 1; i <= 5; i++) {
      canvas.drawCircle(center, shortest * (0.17 + i * 0.075), rings);
    }

    final beams = Paint()
      ..color = accent.withValues(alpha: 0.12)
      ..strokeWidth = 1;
    for (var i = 0; i < 12; i++) {
      final angle = phase * (i.isEven ? 1 : -1) + i * math.pi / 6;
      final end = center + Offset(math.cos(angle), math.sin(angle)) * shortest * 0.48;
      canvas.drawLine(center, end, beams);
    }

    final scanline = Paint()..color = Colors.white.withValues(alpha: 0.025);
    for (double y = 0; y < size.height; y += 6) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 1), scanline);
    }
  }

  @override
  bool shouldRepaint(covariant _CinematicBackdropPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.accent != accent;
}
