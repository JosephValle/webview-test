import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
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

  @override
  void initState() {
    super.initState();
    Permission.camera.request();
    Permission.microphone.request();
    Permission.location.request();
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
          // I think this one is use url and have blob as backup
          initialData: InAppWebViewInitialData(
            data: StringConstant.html,
            baseUrl: WebUri(
              StringConstant.mainUrl +
                  (setToInt ? '?length_of_test=$setTo' : ''),
            ),
          ),
          // this is just url
          // initialUrlRequest: URLRequest(
          //   url: WebUri(
          //     "${StringConstant.mainUrl}${setToInt ? "?length_of_test=$setTo" : ""}",
          //   ),
          // ),
          initialSettings: InAppWebViewSettings(
            mediaPlaybackRequiresUserGesture: false,
            allowsInlineMediaPlayback: true,
          ),
          onWebViewCreated: (controller) => createWebView(controller),
          onLoadStop: (controller, url) async {
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
                    // the json[image] is a base64 string
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