import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

/// Android back first delegates to the current page (including session guards).
/// Root routes entered with go/deep links receive a sensible parent destination.
class AppBackButtonDispatcher extends RootBackButtonDispatcher {
  final GoRouter router;
  final GlobalKey<NavigatorState> navigatorKey;
  static bool _confirmingExit = false;

  AppBackButtonDispatcher({required this.router, required this.navigatorKey});

  @override
  Future<bool> didPopRoute() async {
    if (await super.didPopRoute()) return true;
    return handleRootBack();
  }

  Future<bool> handleRootBack() async {
    final path = router.routeInformationProvider.value.uri.path;
    if (path == '/home') {
      final context = navigatorKey.currentContext;
      if (context == null || !context.mounted || _confirmingExit) return true;
      _confirmingExit = true;
      try {
        final exit = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Keluar dari aplikasi?'),
            content: const Text('Apakah Anda yakin ingin keluar dari KerKom?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Keluar'),
              ),
            ],
          ),
        );
        if (exit == true) await SystemNavigator.pop();
      } finally {
        _confirmingExit = false;
      }
      return true;
    }
    if (path == '/landing' || path == '/') return false;
    final String destination;
    if (path.startsWith('/calibration/')) {
      destination = '/lobby/${path.split('/').last}';
    } else if (path == '/login' ||
        path == '/register' ||
        path == '/forgot-password') {
      destination = path == '/forgot-password' ? '/login' : '/landing';
    } else if (const {
      '/edit-profile',
      '/sensor-settings',
      '/sensor-sensitivity',
      '/alarm-settings',
      '/account-settings',
      '/about-app',
    }.contains(path)) {
      destination = '/profile';
    } else if (path.startsWith('/history-detail/')) {
      destination = '/history';
    } else {
      destination = '/home';
    }
    router.go(destination);
    return true;
  }
}

/// Register a pop guard with Navigator so Android also sends back events when
/// its predictive-back integration sees a single root page.
class RootBackScope extends StatelessWidget {
  final GoRouter router;
  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;

  const RootBackScope({
    super.key,
    required this.router,
    required this.navigatorKey,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => PopScope<Object?>(
    canPop: router.canPop(),
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop) {
        AppBackButtonDispatcher(
          router: router,
          navigatorKey: navigatorKey,
        ).handleRootBack();
      }
    },
    child: child,
  );
}
