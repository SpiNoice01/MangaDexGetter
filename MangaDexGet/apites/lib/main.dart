import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:apites/pages/main/main_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      home: const MainScreen(),
      theme: ThemeData(primarySwatch: Colors.blue),
    );
  }
}
