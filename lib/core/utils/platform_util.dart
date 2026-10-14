import 'package:flutter/foundation.dart';
import 'dart:io' as io;

/// Helper utilitas platform yang aman untuk Web, Android, iOS, dan Desktop
class AppPlatform {
  static bool get isWeb => kIsWeb;
  static bool get isAndroid => !kIsWeb && io.Platform.isAndroid;
  static bool get isIOS => !kIsWeb && io.Platform.isIOS;
  static bool get isMobile => isAndroid || isIOS;
}
