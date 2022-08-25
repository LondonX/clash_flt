import 'package:flutter/material.dart';
import 'plugin_example.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "clash_flt",
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const PluginExample(),
    );
  }
}
