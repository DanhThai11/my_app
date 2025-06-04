import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'; // Để dùng kIsWeb
import 'package:flutter/material.dart';

import 'package:my_app/pages/add_product_screen.dart';
import 'package:my_app/pages/admin.dart';
import 'package:my_app/pages/cart.dart';
import 'package:my_app/pages/home.dart';
import 'package:my_app/pages/login_screen.dart';
import 'package:my_app/pages/productmanager.dart';
import 'package:my_app/pages/register.dart';
import 'package:my_app/pages/splash_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyCMtUO2stxoFHEU17heMR_Q1jjSey7IMWY",
          authDomain: "ecommerce-0101-bebfa.firebaseapp.com",
          projectId: "ecommerce-0101-bebfa",
          storageBucket: "ecommerce-0101-bebfa.appspot.com",
          messagingSenderId: "219216853902",
          appId: "1:219216853902:web:2a14925dbd3c840045c2df",
          measurementId: "G-25H91N3XHZ",
        ),
      );
    } else {
      await Firebase.initializeApp(); // Native platforms: dùng google-services.json
    }
    print('✅ Firebase đã kết nối thành công!');
  } catch (e) {
    print('❌ Lỗi kết nối Firebase: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      themeMode: ThemeMode.system,
      theme: ThemeData(),
      darkTheme: ThemeData.dark(),
      home: LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
