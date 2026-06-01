import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'Login.dart';
import 'showMap.dart';
import 'user-side/createReport.dart';
import 'user-side/dashboardUser.dart';
import 'user-side/historyReport.dart';
import 'user-side/detailReport.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // must be first!
  usePathUrlStrategy(); // for web, to remove the # from the URL

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
      routes: {
        '/map': (context) => Showmap(),
        '/login': (context) => Login(),
        '/createReport': (context) => CreateReport(),
        '/dashboardUser': (context) => DashboardUser(),
        '/userHistoryReport': (context) => HistoryReport(),
        '/detailReport': (context) => DetailReportPage(
          reportId: ModalRoute.of(context)!.settings.arguments as int,
        ),
      },
    );
  }
}
