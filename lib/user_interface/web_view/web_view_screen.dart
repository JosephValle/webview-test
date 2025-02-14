import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'package:webview_test/user_interface/web_view/widgets/docs_widget.dart';
import 'package:webview_test/user_interface/web_view/widgets/refresh_widget.dart';
import 'package:webview_test/utiltiies/constant/string_constant.dart';

class WebViewScreen extends StatefulWidget {
  const WebViewScreen({super.key});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  InAppWebViewController? _webViewController;
  String? receivedData;
  bool setToInt = true;
  int setTo = 1;

  /// Whether the device is currently offline or not. It starts as `null`
  /// to indicate we haven't checked connectivity yet.
  bool? _isOffline;

  /// HTML string to use if offline
  String? _offlineHtml;

  @override
  void initState() {
    super.initState();
    // Request permissions
    Permission.camera.request();
    Permission.microphone.request();
    Permission.location.request();

    _checkConnectivity();
  }

  /// Checks whether there is an internet connection. If not, prepare offline HTML.
  Future<void> _checkConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    final bool noInternet = (connectivityResult.first == ConnectivityResult.none);
    print("The connectivity result is: $connectivityResult");

    print('No Internet: $noInternet');
    if (noInternet) {
      // Device is offline, build the offline HTML (with local image reference)
      await _buildOfflineHtml();
      setState(() {
        _isOffline = true;
      });
    } else {
      // Device is online
      setState(() {
        _isOffline = false;
      });
    }
  }

  /// Build offline HTML string referencing a local image in the documents directory.
  Future<void> _buildOfflineHtml() async {
    // 1. Get the documents directory path.
    final directory = await getApplicationDocumentsDirectory();

    // 2. Construct the file:// URL for your image (right_hand_tap.png).
    final String imagePath = 'file://${directory.path}/right_hand_tap.png';

    // 3. Build a simple HTML referencing the local image.
    _offlineHtml = '''
    <!DOCTYPE html>
    <html>
      <head>
        <meta charset="utf-8"/>
        <title>Offline Page</title>
      </head>
      <body style="text-align:center;">
        <h2>You are offline!</h2>
        <p>This is an offline page with a local image.</p>
        <img src="$imagePath" alt="Instruction Image" style="max-width: 80%; height: auto;"/>
      </body>
    </html>
    ''';
  }

  void createWebView(InAppWebViewController controller) {
    _webViewController = controller;

    // Handler that will be called from JS: window.flutter_inappwebview.callHandler('returnData', data)
    _webViewController?.addJavaScriptHandler(
      handlerName: 'returnData',
      callback: (data) {
        // data will be the string passed to postMessage
        setState(() {
          receivedData = data.first.toString();
        });
      },
    );
  }

  String getDisplayString(Map<String, dynamic>? dataAsJson) {
    String displayString = 'The data fields received are:';
    if (dataAsJson != null) {
      dataAsJson.forEach((key, value) {
        displayString += '\n$key: ${value.toString().length}';
      });
    }
    return displayString;
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic>? dataAsJson =
        receivedData != null ? jsonDecode(receivedData!) : null;
    final String displayString = getDisplayString(dataAsJson);

    // If we haven't checked connectivity yet, show a loader or empty Container.
    if (_isOffline == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: _buildBackWidget(),
        title: Text(
          _webViewController != null && receivedData == null
              ? 'In WebView'
              : 'WebView Example',
        ),
        actions: [
          if (_webViewController != null) RefreshWidget(_webViewController),
          if (_webViewController == null) const DocsWidget(),
        ],
      ),
      body: SafeArea(
        child: receivedData == null
            ? InAppWebView(
                initialData: _getInitialData(),
                initialSettings: InAppWebViewSettings(
                  mediaPlaybackRequiresUserGesture: false,
                  allowsInlineMediaPlayback: true,
                  cacheEnabled: true,
                ),
                onWebViewCreated: (controller) => createWebView(controller),
                onLoadStop: (controller, url) async {
                  // Insert your custom JS override here
                  await controller.evaluateJavascript(
                    source: '''
                    // Only if window.returnData doesn’t already have our override:
                    if (!window.returnDataOverridden) {
                      window.returnDataOverridden = true;
                      const originalReturnData = window.returnData;
                      window.returnData = {
                        postMessage: function(data) {
                          // Forward to Flutter
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
                  debugPrint(consoleMessage.message);
                },
                onReceivedServerTrustAuthRequest:
                    (controller, challenge) async {
                  return ServerTrustAuthResponse(
                    action: ServerTrustAuthResponseAction.PROCEED,
                  );
                },
              )
            : SingleChildScrollView(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        displayString,
                        style: const TextStyle(fontSize: 18),
                      ),
                      if (dataAsJson!['image'] != null)
                        AspectRatio(
                          aspectRatio: 9 / 16,
                          // The json['image'] is a base64 string
                          child: Image.memory(
                            base64Decode(dataAsJson['image'].split(',')[1]),
                            fit: BoxFit.cover,
                          ),
                        ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  /// Determine the initial data to load in the InAppWebView
  /// based on whether we are offline or online.
  InAppWebViewInitialData _getInitialData() {
    if (_isOffline == true && _offlineHtml != null) {
      // Offline scenario
      return InAppWebViewInitialData(
        data: _offlineHtml!,
        baseUrl: WebUri(''), // or you could use: WebUri('file:///')
      );
    } else {
      // Online scenario
      return InAppWebViewInitialData(
        data: StringConstant.html,
        baseUrl: WebUri(
          StringConstant.mainUrl + (setToInt ? '?length_of_test=$setTo' : ''),
        ),
      );
    }
  }

  Widget? _buildBackWidget() {
    if (_webViewController != null) {
      return IconButton(
        onPressed: () {
          setState(() {
            _webViewController = null;
            receivedData = null;
          });
        },
        icon: const Icon(Icons.arrow_back),
      );
    }
    return null;
  }
}
