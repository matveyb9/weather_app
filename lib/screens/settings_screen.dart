// lib/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/settings_model.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки'),
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, _) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [

            // ── Units ──────────────────────────────────────────────────────
            _SectionHeader(label: 'Единицы измерения', icon: Icons.straighten_rounded),
            const SizedBox(height: 8),

            _SegmentCard(
              label: 'Температура',
              icon: Icons.thermostat_rounded,
              iconColor: const Color(0xFFFFB300),
              children: TempUnit.values.map((u) => _Chip(
                label: u.symbol,
                selected: settings.tempUnit == u,
                onTap: () => settings.setTempUnit(u),
              )).toList(),
            ),

            _SegmentCard(
              label: 'Скорость ветра',
              icon: Icons.air_rounded,
              iconColor: const Color(0xFF78909C),
              children: WindUnit.values.map((u) => _Chip(
                label: u.symbol,
                selected: settings.windUnit == u,
                onTap: () => settings.setWindUnit(u),
              )).toList(),
            ),

            _SegmentCard(
              label: 'Давление',
              icon: Icons.compress_rounded,
              iconColor: const Color(0xFF8D6E63),
              children: PressureUnit.values.map((u) => _Chip(
                label: u.symbol,
                selected: settings.pressureUnit == u,
                onTap: () => settings.setPressureUnit(u),
              )).toList(),
            ),

            const SizedBox(height: 24),

            // ── Appearance ─────────────────────────────────────────────────
            _SectionHeader(label: 'Оформление', icon: Icons.palette_rounded),
            const SizedBox(height: 8),

            _ThemeCard(settings: settings),

            const SizedBox(height: 24),

            // ── About ──────────────────────────────────────────────────────
            _SectionHeader(label: 'О приложении', icon: Icons.info_outline_rounded),
            const SizedBox(height: 8),

            _InfoCard(),

            const SizedBox(height: 24),

            // ── Reset ──────────────────────────────────────────────────────
            Center(
              child: OutlinedButton.icon(
                onPressed: () => _confirmReset(context, settings),
                icon: const Icon(Icons.restart_alt_rounded),
                label: const Text('Сбросить настройки'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                  side: BorderSide(color: theme.colorScheme.error.withValues(alpha: 0.5)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmReset(
      BuildContext context, SettingsProvider settings) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Сбросить настройки?'),
        content: const Text(
            'Все настройки вернутся к значениям по умолчанию:\n'
            '°C, м/с, мм рт.ст., тема — системная.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Сбросить'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await settings.resetToDefaults();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Настройки сброшены')),
        );
      }
    }
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  final IconData icon;
  const _SectionHeader({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

// ── Segment card (icon + label + chips) ───────────────────────────────────────

class _SegmentCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color iconColor;
  final List<Widget> children;
  const _SegmentCard({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: iconColor),
          const SizedBox(width: 12),
          Text(label, style: theme.textTheme.bodyMedium),
          const Spacer(),
          Wrap(spacing: 8, children: children),
        ],
      ),
    );
  }
}

// ── Chip ──────────────────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Chip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: selected
              ? null
              : Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: selected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurfaceVariant,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ── Theme card ────────────────────────────────────────────────────────────────

class _ThemeCard extends StatelessWidget {
  final SettingsProvider settings;
  const _ThemeCard({required this.settings});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        children: AppTheme.values.map((t) {
          final selected = settings.appTheme == t;
          final isLast = t == AppTheme.values.last;
          return Column(
            children: [
              ListTile(
                leading: Icon(
                  _themeIcon(t),
                  color: selected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                title: Text(t.label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      color: selected ? theme.colorScheme.primary : null,
                    )),
                trailing: selected
                    ? Icon(Icons.check_circle_rounded,
                        color: theme.colorScheme.primary)
                    : const Icon(Icons.radio_button_unchecked_rounded),
                onTap: () => settings.setAppTheme(t),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(
                    top: t == AppTheme.values.first
                        ? const Radius.circular(20)
                        : Radius.zero,
                    bottom: isLast ? const Radius.circular(20) : Radius.zero,
                  ),
                ),
              ),
              if (!isLast)
                Divider(
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  IconData _themeIcon(AppTheme t) => switch (t) {
    AppTheme.system => Icons.brightness_auto_rounded,
    AppTheme.light  => Icons.light_mode_rounded,
    AppTheme.dark   => Icons.dark_mode_rounded,
  };
}

// ── Info card ─────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoRow(label: 'Версия', value: '1.0.0'),
          const SizedBox(height: 8),
          _InfoRow(label: 'Данные о погоде', value: 'Open-Meteo API'),
          const SizedBox(height: 8),
          _InfoRow(label: 'Геокодирование', value: 'Open-Meteo + OpenStreetMap'),
          const SizedBox(height: 8),
          _InfoRow(label: 'Лицензия API', value: 'Бесплатно, без ключа'),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            )),
        Text(value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            )),
      ],
    );
  }
}
