import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config/firebase_config.dart';
import 'core/router/app_router.dart';
import 'core/router/app_back_button_dispatcher.dart';
import 'core/services/deep_link_service.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  try {
    // Inisialisasi Firebase dengan kredensial google-services.json eksisting
    await Firebase.initializeApp(
      options: KerkomFirebaseConfig.options,
    );
  } catch (error) {
    debugPrint('Inisialisasi Firebase Realtime Database info: $error');
  }

  runApp(
    const ProviderScope(
      child: KerkomApp(),
    ),
  );
}

class KerkomApp extends ConsumerStatefulWidget {
  const KerkomApp({super.key});

  @override
  ConsumerState<KerkomApp> createState() => _KerkomAppState();
}

class _KerkomAppState extends ConsumerState<KerkomApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final router = ref.read(routerProvider);
      ref.read(deepLinkServiceProvider).initialize(ref, router);
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Kerkom',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerDelegate: router.routerDelegate,
      routeInformationParser: router.routeInformationParser,
      routeInformationProvider: router.routeInformationProvider,
      backButtonDispatcher: AppBackButtonDispatcher(router: router, navigatorKey: rootNavigatorKey),
    );
  }
}
