import 'package:flutter/material.dart';

class MyMonsterScreen extends StatelessWidget {
  const MyMonsterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Monster Screen'),
      ),
      body: Center(
        child: Text('This is the My Monster Screen'),
      ),
    );
  }
}