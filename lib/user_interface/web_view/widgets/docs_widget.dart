import 'package:flutter/material.dart';

import '../../docs/docs_screen.dart';

class DocsWidget extends StatelessWidget {
  const DocsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const DocsScreen()),
        );
      },
      icon: const Icon(Icons.find_in_page_rounded),
    );
  }
}
