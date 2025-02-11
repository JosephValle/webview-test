import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:webview_test/user_interface/web_view/web_view_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final camera = await Permission.camera.request();
  print(camera.isGranted);
  final mic = await Permission.microphone.request();

  print(mic.isGranted);
  final loc = await Permission.location.request();
  print(loc.isGranted);

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
