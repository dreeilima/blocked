import 'package:flutter/material.dart';

/// Custom page route com animação de fade + scale para dialogs
class DialogRoute<T> extends PageRoute<T> {
  final WidgetBuilder builder;

  DialogRoute({required this.builder, super.settings});

  @override
  Color? get barrierColor => Colors.black54;

  @override
  String? get barrierLabel => 'Dialog';

  @override
  bool get barrierDismissible => true;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return builder(context);
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Fade transition para o barrier
    final fadeAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOut,
    );

    // Scale + Fade para o dialog
    final scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));

    return FadeTransition(
      opacity: fadeAnimation,
      child: ScaleTransition(scale: scaleAnimation, child: child),
    );
  }

  @override
  bool get maintainState => true;

  @override
  bool get opaque => false;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 300);
}

/// Helper function para mostrar dialog com animação customizada
Future<T?> showAnimatedDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  return Navigator.of(
    context,
  ).push<T>(DialogRoute<T>(builder: builder, settings: const RouteSettings()));
}
