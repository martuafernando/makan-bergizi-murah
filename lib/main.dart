import 'package:flutter/material.dart';
import 'screens/scanner_screen.dart';

void main() {
  runApp(const MakanBergiziApp());
}

class MakanBergiziApp extends StatelessWidget {
  const MakanBergiziApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Scan Nilai Gizi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4CAF50),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const ScannerScreen(),
    );
  }
}
