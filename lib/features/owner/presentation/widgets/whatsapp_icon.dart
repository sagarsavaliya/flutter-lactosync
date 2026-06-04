import 'package:flutter/material.dart';

import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Brand-styled WhatsApp icon (not generic chat bubble).
class WhatsAppIcon extends StatelessWidget {
  const WhatsAppIcon({super.key, this.size = 18, this.enabled = true});

  final double size;
  final bool enabled;

  static const Color brandColor = Color(0xFF25D366);

  @override
  Widget build(BuildContext context) {
    return FaIcon(
      FontAwesomeIcons.whatsapp,
      size: size,
      color: enabled ? brandColor : Theme.of(context).disabledColor,
    );
  }
}
