import 'package:flutter/material.dart';

/// Root widget for the TindaTrack application.
class MainApp extends StatelessWidget {
  /// Creates the root TindaTrack application widget.
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TindaTrack',
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('TindaTrack'),
              SizedBox(height: 8),
              Text('Offline inventory tracker'),
            ],
          ),
        ),
      ),
    );
  }
}
