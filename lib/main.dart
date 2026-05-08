import 'package:flutter/material.dart';
import 'package:kelompokc_incidentreporting/showMap.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'Login.dart';
import 'showMap.dart';

void main() async {
  await Supabase.initialize(
    url: 'https://virccuuftyhsgxajexds.supabase.co',
    anonKey: 'sb_publishable__VJYd1XnI8lmgIbVoXLKZQ_YqhNpqAF',
  );

  runApp(MaterialApp(title: 'AMBW', home: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AMBW',
      theme: ThemeData(primarySwatch: Colors.blue),
      // initialRoute: '/',
      // routes: {'/': (context) => Login()},
      home: Showmap(),
    );
  }
}
