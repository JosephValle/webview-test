import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:webview_test/user_interface/web_view/web_view_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // write assets/left_hand_tap.png to app document directory
  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/left_hand_tap.png');
  if (!await file.exists()) {
    await file.writeAsBytes(
      (await rootBundle.load('assets/left_hand_tap.png')).buffer.asUint8List(),
    );
  }

  await Permission.camera.request();
  await Permission.microphone.request();
  await Permission.location.request();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter WebView Demo',
      theme:
          ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue)),
      home: const WebViewScreen(),
    );
  }
}
