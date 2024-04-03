import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'Screens/home_screen.dart';
import 'splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitDown,
    DeviceOrientation.portraitUp,
  ]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    
    return const MaterialApp(
      title: 'Betpro Winner',
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}
