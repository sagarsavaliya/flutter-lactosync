import 'package:flutter/material.dart';

/// Clears the OS status bar (time, signal, notifications) on every screen.
///
/// Uses [MediaQuery.viewPadding] instead of [MediaQuery.padding] so the inset
/// stays correct on edge-to-edge Android and when the keyboard is open.
class AppScreenSafeArea extends StatelessWidget {
  const AppScreenSafeArea({
    super.key,
    required this.child,
    this.bottom = false,
    this.minimumTop = 0,
  });

  final Widget child;
  final bool bottom;
  final double minimumTop;

  @override
  Widget build(BuildContext context) {
    final viewPadding = MediaQuery.viewPaddingOf(context);
    final top = viewPadding.top > minimumTop ? viewPadding.top : minimumTop;

    return Padding(
      padding: EdgeInsets.only(
        top: top,
        bottom: bottom ? viewPadding.bottom : 0,
      ),
      child: child,
    );
  }
}
