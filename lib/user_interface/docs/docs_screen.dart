import 'package:flutter/material.dart';
import 'package:markdown_widget/markdown_widget.dart';

import '../../utiltiies/constant/string_constant.dart';

class DocsScreen extends StatelessWidget {
  const DocsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Docs'),
        centerTitle: true,
      ),
      body: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0),
        child: MarkdownWidget(
          data: StringConstant.docs,
        ),
      ),
    );
  }
}
