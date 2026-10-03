import 'package:flutter/material.dart';

enum BannerTone { info, warning, error, neutral }

/// Aviso en línea (privacidad, proveedor remoto, errores).
class InfoBanner extends StatelessWidget {
  const InfoBanner({
    super.key,
    required this.message,
    this.title,
    this.icon,
    this.tone = BannerTone.info,
    this.action,
    this.onClose,
  });

  final String? title;
  final String message;
  final IconData? icon;
  final BannerTone tone;
  final Widget? action;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (bg, fg) = switch (tone) {
      BannerTone.info => (scheme.secondaryContainer, scheme.onSecondaryContainer),
      BannerTone.warning =>
        (scheme.tertiaryContainer, scheme.onTertiaryContainer),
      BannerTone.error => (scheme.errorContainer, scheme.onErrorContainer),
      BannerTone.neutral =>
        (scheme.surfaceContainerHighest, scheme.onSurfaceVariant),
    };
    final defaultIcon = switch (tone) {
      BannerTone.info => Icons.info_outline,
      BannerTone.warning => Icons.privacy_tip_outlined,
      BannerTone.error => Icons.error_outline,
      BannerTone.neutral => Icons.info_outline,
    };
    return Semantics(
      container: true,
      liveRegion: tone == BannerTone.error,
      child: Container(
        decoration: BoxDecoration(
            color: bg, borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(icon ?? defaultIcon, size: 20, color: fg),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null)
                    Text(title!,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: fg, fontWeight: FontWeight.w600)),
                  Text(message,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: fg, height: 1.4)),
                  if (action != null) ...[const SizedBox(height: 4), action!],
                ],
              ),
            ),
            if (onClose != null)
              IconButton(
                tooltip: 'Cerrar',
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.close, size: 18, color: fg),
                onPressed: onClose,
              ),
          ],
        ),
      ),
    );
  }
}
