import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Local Website from ZIP with MyCap',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const WebViewScreen(),
    );
  }
}

class WebViewScreen extends StatefulWidget {
  const WebViewScreen({super.key});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  InAppWebViewController? _webViewController;
  bool _isLoading = true;
  String? _indexFilePath;
  String? receivedData;

  @override
  void initState() {
    super.initState();
    Permission.camera.request();
    Permission.microphone.request();
    Permission.location.request();
    _prepareLocalFiles();
  }

  Future<String?> _findIndexHtml(String directoryPath) async {
    final dir = Directory(directoryPath);
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is File &&
          entity.path.endsWith('index.html') &&
          !entity.path.contains('__MACOSX')) {
        return entity.path;
      }
    }
    return null;
  }

  Future<void> _prepareLocalFiles() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final extractionDirPath = '${documentsDir.path}/website_test';

    if (await Directory(extractionDirPath).exists()) {
      final foundIndex = await _findIndexHtml(extractionDirPath);
      if (foundIndex != null) {
        debugPrint('Using existing extracted website.');
        _indexFilePath = foundIndex;
        setState(() => _isLoading = false);
        return;
      }
    }

    // Ensure the extraction directory exists.
    final extractionDir = Directory(extractionDirPath);
    if (!await extractionDir.exists()) {
      await extractionDir.create(recursive: true);
    }

    // Load the ZIP file from assets.
    final ByteData data = await rootBundle.load('assets/web.zip');
    final List<int> bytes = data.buffer.asUint8List();

    // Decode the archive.
    final archive = ZipDecoder().decodeBytes(bytes);

    // Extract files and directories.
    for (final file in archive) {
      final filename = file.name;
      final filePath = '$extractionDirPath/$filename';
      if (file.isFile) {
        final data = file.content as List<int>;
        final outFile = File(filePath);
        await outFile.create(recursive: true);
        await outFile.writeAsBytes(data);
        debugPrint('Extracting $filename to $filePath');
      } else {
        final dir = Directory(filePath);
        await dir.create(recursive: true);
        debugPrint('Extracting $filename to $filePath');
      }
    }

    // Locate index.html after extraction.
    final foundIndex = await _findIndexHtml(extractionDirPath);
    if (foundIndex != null) {
      _indexFilePath = foundIndex;
    } else {
      throw Exception('index.html not found in the extracted ZIP');
    }
    setState(() => _isLoading = false);
  }

  void _setupJavaScriptHandler() {
    _webViewController?.addJavaScriptHandler(
      handlerName: 'returnData',
      callback: (data) {
        setState(() {
          receivedData = data.first.toString();
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (receivedData != null) {
      Map<String, dynamic>? jsonData;
      try {
        jsonData = jsonDecode(receivedData!);
      } catch (e) {
        jsonData = {'error': 'Invalid JSON received'};
      }
      return Scaffold(
        appBar: AppBar(
          title: const Text('Data Received'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              // Reset the received data and reload the webview.
              setState(() {
                receivedData = null;
              });
              _webViewController?.reload();
            },
          ),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Text(
              jsonData.toString(),
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Local Website from ZIP')),
      body:
      _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
        child: InAppWebView(
          // Load the extracted local index.html.
          initialUrlRequest: URLRequest(
            url: WebUri('file://$_indexFilePath'),
          ),
          initialSettings: InAppWebViewSettings(
            javaScriptEnabled: true,
            allowFileAccessFromFileURLs: true,
            allowUniversalAccessFromFileURLs: true,
            // Allow the webview to access the folder containing index.html.
            allowingReadAccessTo: WebUri(
              'file://${_indexFilePath!.substring(0, _indexFilePath!.lastIndexOf('/'))}/',
            ),
            mediaPlaybackRequiresUserGesture: false,
            allowsInlineMediaPlayback: true,
          ),
          onWebViewCreated: (controller) {
            _webViewController = controller;
            _setupJavaScriptHandler();
          },
          onLoadStop: (controller, url) async {
            // Override window.returnData in JavaScript to forward data to Flutter.
            await controller.evaluateJavascript(
              source: '''
                      if (!window.returnDataOverridden) {
                        window.returnDataOverridden = true;
                        window.returnData = {
                          postMessage: function(data) {
                            window.flutter_inappwebview.callHandler("returnData", data);
                          }
                        };
                      }
                    ''',
            );
          },
          onPermissionRequest: (controller, request) async {
            return PermissionResponse(
              resources: request.resources,
              action: PermissionResponseAction.GRANT,
            );
          },
          onConsoleMessage: (controller, consoleMessage) {
            debugPrint('Console Message: ${consoleMessage.message}');
          },
          onReceivedServerTrustAuthRequest: (
              controller,
              challenge,
              ) async {
            return ServerTrustAuthResponse(
              action: ServerTrustAuthResponseAction.PROCEED,
            );
          },
        ),
      ),
    );
  }
}
