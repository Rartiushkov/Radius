import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:new_app/firebase_options.dart';
import 'package:new_app/login_screen_ui.dart';
import 'package:new_app/register_screen_ui.dart';
import 'package:new_app/specialist_screen.dart';
import 'package:new_app/swipe_home.dart';
import 'package:new_app/auth_check_screen.dart'; // Вынесен в отдельный файл

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Radius App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Roboto',
      ),
      initialRoute: '/',
      routes: {
        '/': (_) => const AuthCheckScreen(),
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/user': (_) => const SwipeHome(),
        '/specialist': (_) => const SpecialistScreen(),
      },
    );
  }
}
