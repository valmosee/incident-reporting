import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkSession();
    });
  }

  Future<void> _checkSession() async {
    final session = Supabase.instance.client.auth.currentSession;

    if (session == null) {
      // no session → go to login
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    // session exists → check role and redirect
    try {
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('role')
          .eq('id', session.user.id)
          .single();

      final role = profile['role'];
      if (!mounted) return;

      if (role == 'admin') {
        Navigator.pushReplacementNamed(context, '/admin');
      } else if (role == 'worker') {
        Navigator.pushReplacementNamed(context, '/worker');
      } else {
        Navigator.pushReplacementNamed(context, '/map');
      }
    } catch (e) {
      // profile fetch failed → go to login
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    // show loading spinner while checking session
    return const Scaffold(
      backgroundColor: Color(0xFF0A2540),
      body: Center(child: CircularProgressIndicator(color: Colors.white)),
    );
  }
}
