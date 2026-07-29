import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../core/brand.dart';
import '../models/repair.dart';

class RebotfoxLogo extends StatelessWidget {
  const RebotfoxLogo({super.key, this.compact = false, this.showSubtitle = true});
  final bool compact;
  final bool showSubtitle;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 42.0 : 54.0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(compact ? 13 : 17),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.secondary],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: .2),
                blurRadius: 20,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(Icons.memory_rounded, color: Colors.white, size: compact ? 25 : 32),
              Positioned(
                right: compact ? 5 : 7,
                bottom: compact ? 5 : 7,
                child: Icon(Icons.build_rounded, color: Colors.white, size: compact ? 11 : 14),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppBrand.name,
              style: TextStyle(
                color: AppColors.text,
                fontSize: compact ? 18 : 23,
                fontWeight: FontWeight.w900,
                letterSpacing: -.5,
              ),
            ),
            if (showSubtitle)
              const Text(
                AppBrand.subtitle,
                style: TextStyle(color: AppColors.textMuted, fontSize: 11),
              ),
          ],
        ),
      ],
    );
  }
}

class PageFrame extends StatelessWidget {
  const PageFrame({super.key, required this.child, this.maxWidth = 1180});
  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: child,
          ),
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.subtitle, this.action});
  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(subtitle!, style: const TextStyle(color: AppColors.textMuted)),
              ],
            ],
          ),
        ),
        if (action != null) action!,
      ],
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});
  final RepairStatus status;

  @override
  Widget build(BuildContext context) {
    final color = status.color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: .35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(status.label, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12)),
        ],
      ),
    );
  }
}

class InfoPill extends StatelessWidget {
  const InfoPill({super.key, required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(color: AppColors.surfaceSoft, borderRadius: BorderRadius.circular(999)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 7),
        Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}
