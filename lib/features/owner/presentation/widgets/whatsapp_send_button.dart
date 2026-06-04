import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

class WhatsAppSendButton extends StatelessWidget {
  const WhatsAppSendButton({
    super.key,
    required this.onPressed,
    this.enabled = true,
    this.tooltip = 'Send',
  });

  final VoidCallback? onPressed;
  final bool enabled;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final canSend = enabled && onPressed != null;
    final color = canSend
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).disabledColor;

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: canSend ? onPressed : null,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.xxs),
          child: Icon(Icons.send_rounded, size: 18, color: color),
        ),
      ),
    );
  }
}

class SectionHeaderWithShare extends StatelessWidget {
  const SectionHeaderWithShare({
    super.key,
    required this.title,
    this.trailing,
    this.onShare,
    this.shareEnabled = true,
    this.uppercase = false,
  });

  final String title;
  final Widget? trailing;
  final VoidCallback? onShare;
  final bool shareEnabled;
  final bool uppercase;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final titleStyle = uppercase
        ? AppText.meta.copyWith(
            color: primary,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          )
        : Theme.of(context).textTheme.titleMedium;

    return Row(
      children: [
        Expanded(
          child: Text(uppercase ? title.toUpperCase() : title, style: titleStyle),
        ),
        if (trailing != null) trailing!,
        if (onShare != null) ...[
          if (trailing != null) const SizedBox(width: AppSpace.xs),
          WhatsAppSendButton(onPressed: onShare, enabled: shareEnabled),
        ],
      ],
    );
  }
}
