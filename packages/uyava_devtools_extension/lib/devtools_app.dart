import 'package:flutter/material.dart';

import 'graph_view_page.dart';
import 'src/devtools_extension_stub.dart'
    if (dart.library.js_interop) 'package:devtools_extensions/devtools_extensions.dart';

class UyavaExtension extends StatelessWidget {
  const UyavaExtension({super.key});

  @override
  Widget build(BuildContext context) {
    return DevToolsExtension(
      child: Builder(
        builder: (context) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return MaterialApp(
            title: 'Uyava Extension',
            theme: ThemeData.light(useMaterial3: true),
            darkTheme: ThemeData.dark(useMaterial3: true),
            themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
            home: const GraphViewPage(),
          );
        },
      ),
    );
  }
}
