// lib/screens/welcome_screen.dart
//
// Экран приветствия — показывается только при первом запуске.
// Пользователь должен принять условия использования и политику
// конфиденциальности, после чего флаг сохраняется в SharedPreferences
// и экран больше не показывается.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'home_screen.dart';

/// Ключ в SharedPreferences, сигнализирующий о принятии условий.
const _kTermsAccepted = 'onboarding_terms_accepted';

/// Проверяет, нужно ли показывать экран приветствия.
Future<bool> needsOnboarding() async {
  final prefs = await SharedPreferences.getInstance();
  return !(prefs.getBool(_kTermsAccepted) ?? false);
}

/// Сохраняет факт принятия условий.
Future<void> markTermsAccepted() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_kTermsAccepted, true);
}

// ── URLs ──────────────────────────────────────────────────────────────────────
// Замените на реальные ссылки после публикации в репозитории.
const _termsUrl =
    'https://matveyb9.github.io/weather_app/docs/terms_of_use';
const _privacyUrl =
    'https://matveyb9.github.io/weather_app/docs/privacy_policy';

// ── Screen ────────────────────────────────────────────────────────────────────

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _accepted = false;
  bool _loading  = false;

  Future<void> _accept() async {
    setState(() => _loading = true);
    await markTermsAccepted();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // ── Иконка ────────────────────────────────────────────────────
              Container(
                width:  96,
                height: 96,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.wb_sunny_rounded,
                  size:  52,
                  color: theme.colorScheme.primary,
                ),
              ),

              const SizedBox(height: 28),

              // ── Заголовок ─────────────────────────────────────────────────
              Text(
                'Добро пожаловать\nв Погоду',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                  height: 1.25,
                ),
              ),

              const SizedBox(height: 16),

              // ── Подзаголовок ──────────────────────────────────────────────
              Text(
                'Точный прогноз для любого города мира.\nБез рекламы, без регистрации.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                  height: 1.5,
                ),
              ),

              const Spacer(flex: 2),

              // ── Фичи ──────────────────────────────────────────────────────
              _FeatureRow(
                icon:  Icons.cloud_done_rounded,
                title: 'Открытые данные',
                sub:   'Open-Meteo API — бесплатно и без ключа',
              ),
              const SizedBox(height: 14),
              _FeatureRow(
                icon:  Icons.privacy_tip_rounded,
                title: 'Приватность',
                sub:   'Данные не передаются третьим лицам',
              ),
              const SizedBox(height: 14),
              _FeatureRow(
                icon:  Icons.wifi_off_rounded,
                title: 'Офлайн-режим',
                sub:   'Кэш последних данных без интернета',
              ),

              const Spacer(flex: 3),

              // ── Чекбокс согласия ──────────────────────────────────────────
              GestureDetector(
                onTap: () => setState(() => _accepted = !_accepted),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _accepted,
                      onChanged: (v) => setState(() => _accepted = v ?? false),
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 11),
                        child: RichText(
                          text: TextSpan(
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.75),
                              height: 1.5,
                            ),
                            children: [
                              const TextSpan(text: 'Я принимаю '),
                              TextSpan(
                                text: 'условия использования',
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  decoration: TextDecoration.underline,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () => _openUrl(_termsUrl),
                              ),
                              const TextSpan(text: ' и '),
                              TextSpan(
                                text: 'политику конфиденциальности',
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  decoration: TextDecoration.underline,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () => _openUrl(_privacyUrl),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Кнопка ────────────────────────────────────────────────────
              SizedBox(
                width:  double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: (_accepted && !_loading) ? _accept : null,
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width:  22,
                          height: 22,
                          child:  CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Начать',
                          style: TextStyle(
                            fontSize:   16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 12),

              // ── Сноска ────────────────────────────────────────────────────
              Text(
                'Версия 1.0.0',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
                ),
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Вспомогательный виджет строки фичи ───────────────────────────────────────

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String   title;
  final String   sub;

  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width:  44,
          height: 44,
          decoration: BoxDecoration(
            color: theme.colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size:  22,
            color: theme.colorScheme.secondary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                sub,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
