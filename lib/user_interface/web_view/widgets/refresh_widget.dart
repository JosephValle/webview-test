import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class RefreshWidget extends StatelessWidget {
  final InAppWebViewController? webViewController;

  const RefreshWidget(this.webViewController, {super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        webViewController?.reload();
      },
      icon: const Icon(Icons.refresh),
    );
  }
}
