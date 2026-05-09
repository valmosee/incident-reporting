import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'Login.dart';
import 'showMap.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // must be first!

  await Supabase.initialize(
    url: 'https://virccuuftyhsgxajexds.supabase.co',
    anonKey: 'sb_publishable__VJYd1XnI8lmgIbVoXLKZQ_YqhNpqAF',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AMBW',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const Login(),
      routes: {'/map': (context) => Showmap(),
               '/login': (context) => Login()},
    );
  }
}
