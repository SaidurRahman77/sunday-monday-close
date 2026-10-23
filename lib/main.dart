import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/login_screen.dart';

final GlobalKey<NavigatorState> navigatorKey =
    GlobalKey<NavigatorState>();

final GlobalKey<ScaffoldMessengerState>
    scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options:
        DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    const MyApp(),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return MaterialApp(
      navigatorKey:
          navigatorKey,
      scaffoldMessengerKey:
          scaffoldMessengerKey,
      debugShowCheckedModeBanner:
          false,
      title:
          'Sunday Monday Close',
      theme:
          ThemeData(
        brightness:
            Brightness.light,
        useMaterial3:
            true,
      ),
      home:
          const LoginScreen(),
    );
  }
}