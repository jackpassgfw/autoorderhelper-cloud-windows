import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_size/window_size.dart' as window_size;

import 'router/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _configureWindow();
  runApp(const ProviderScope(child: AutoOrderApp()));
}

class AutoOrderApp extends ConsumerWidget {
  const AutoOrderApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Auto Order Helper',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.grey[50],
        fontFamilyFallback: const [
          'Noto Sans SC',
          'Microsoft YaHei',
          'PingFang SC',
          'Heiti SC',
          'Source Han Sans SC',
          'SimHei',
          'Arial',
        ],
      ),
      routerConfig: router,
      builder: (context, child) => child ?? const SizedBox.shrink(),
    );
  }
}

Future<void> _configureWindow() async {
  if (!(Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    return;
  }

  const double targetWidth = 1280;
  const double targetHeight = 1080; // 50% taller than a 720px base.
  const double minWidth = 1100;
  const double minHeight = 900;

  window_size.setWindowTitle('Auto Order Helper');
  window_size.setWindowMinSize(const Size(minWidth, minHeight));

  final screens = await window_size.getScreenList();
  Rect frame;
  if (screens.isNotEmpty) {
    final screen = screens.first.visibleFrame;
    final left = screen.left + (screen.width - targetWidth) / 2;
    final top = screen.top + (screen.height - targetHeight) / 2;
    frame = Rect.fromLTWH(left, top, targetWidth, targetHeight);
  } else {
    frame = const Rect.fromLTWH(0, 0, targetWidth, targetHeight);
  }
  window_size.setWindowFrame(frame);
}
