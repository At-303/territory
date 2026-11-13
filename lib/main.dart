import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/home_screen.dart';
import 'storage.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final store = await ProgressStore.load();
  runApp(TerritoryApp(store: store));
}

class TerritoryApp extends StatelessWidget {
  const TerritoryApp({super.key, required this.store});

  final ProgressStore store;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Territory',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: HomeScreen(store: store),
    );
  }
}
