import 'package:flutter/material.dart';
import 'loginpage.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PIUTTEC',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF79B904),
          primary: const Color(0xFF79B904), // Color principal (Verde UTTEC)
          secondary: const Color(0xFF1E88E5), // Color secundario (Azul)
          error: const Color(0xFFDB0404), // Rojo estandarizado para errores
        ),
      ),
      home: const LoginPage(),
    );
  }
}