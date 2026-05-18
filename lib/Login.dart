import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String _role = 'user'; // 'user' | 'admin' | 'worker'
  final supabase = Supabase.instance.client;

  Future<void> _login() async {
    setState(() => _loading = true);
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );

      // ambil role dari tabel profiles
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('role')
          .eq('id', Supabase.instance.client.auth.currentUser!.id)
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login gagal: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null && mounted) {
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
    }
  });
  }

  Future<void> evtlogout(BuildContext context) async {
    try {
      await Supabase.instance.client.auth.signOut();

      debugPrint("Logout berhasil");
    } catch (e) {
      debugPrint("ERROR LOGOUT: $e");
    }
  }

  Future<void> evtregister(String email, String password) async {
    debugPrint("start register");

    try {
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {'display_name': "-", 'phone': '-', 'provider_type': 'user'},
      );

      debugPrint("response: $response");

      if (response.user != null) {
        debugPrint('Register berhasil');
      } else {
        debugPrint("Register gagal");
      }
    } catch (e) {
      debugPrint("ERROR REGISTER: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
    );
  }

  Widget _buildDesktopLayout() {
    return SizedBox(
      height: MediaQuery.of(context).size.height, // full screen height
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildLeftPanel(),
          Expanded(child: _buildRightPanel()),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    final safeBottom = MediaQuery.of(context).padding.bottom;

    return Column(
      children: [
        SizedBox(height: 280, child: _buildLeftPanel()),
        Expanded(
          child: Container(
            color: Colors.white,
            padding: EdgeInsets.fromLTRB(28, 16, 28, safeBottom + 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Selamat datang kembali',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Masuk untuk melanjutkan ke JalanKita',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _roleTab('Masyarakat', 'user', Icons.person_outline),
                    const SizedBox(width: 6),
                    _roleTab('Admin', 'admin', Icons.shield_outlined),
                    const SizedBox(width: 6),
                    _roleTab('Pekerja', 'worker', Icons.engineering_outlined),
                  ],
                ),
                const SizedBox(height: 12),
                _buildField(
                  'Email',
                  _emailCtrl,
                  Icons.mail_outline,
                  hint: 'email@contoh.com',
                ),
                const SizedBox(height: 10),
                _buildField(
                  'Password',
                  _passCtrl,
                  Icons.lock_outline,
                  hint: '••••••••',
                  obscure: true,
                ),
                const Spacer(),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 4,
                      ),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Lupa password?'),
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _loading
                        ? null
                        : () => _login(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A5CFF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Masuk',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLeftPanel() {
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Container(
      width: MediaQuery.of(context).size.width < 700
          ? double.infinity
          : MediaQuery.of(context).size.width * 0.3,
      height: isMobile ? 300 : null, // explicit height on mobile,
      decoration: const BoxDecoration(color: Color(0xFF0A2540)),
      child: Stack(
        children: [
          // bubble decorations
          Positioned(
            top: -40,
            left: -40,
            child: _bubble(180, Colors.blue.withValues(alpha: 0.08)),
          ),
          Positioned(
            top: 140,
            left: 120,
            child: _bubble(120, Colors.blue.withValues(alpha: 0.08)),
          ),
          Positioned(
            bottom: 60,
            right: -60,
            child: _bubble(220, Colors.blue.withValues(alpha: 0.06)),
          ),
          Positioned(
            bottom: 250,
            left: 110,
            child: _bubble(220, Colors.blue.withValues(alpha: 0.06)),
          ),
          Positioned(
            top: 160,
            right: -30,
            child: _bubble(100, Colors.blue.withValues(alpha: 0.1)),
          ),
          Positioned(
            bottom: -30,
            left: 20,
            child: _bubble(120, Colors.white.withValues(alpha: 0.04)),
          ),

          // content centered
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(121, 0, 0, 0),
                    borderRadius: BorderRadius.circular(90),
                  ),
                  child: const Icon(
                    Icons.map_rounded,
                    color: Colors.white,
                    size: 50,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'JalanKita',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32, // bigger title
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Platform pelaporan infrastruktur jalan rusak Kota Surabaya',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white38,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bubble(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }

  Widget _buildRightPanel() {
    return Container(
      // no fixed width — Expanded in Row handles it
      padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 48),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.zero,
      ),
      child: Center(
        // centers the form content horizontally
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 400,
          ), // form doesn't stretch too wide on large screens
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center, // centers vertically
            mainAxisSize: MainAxisSize.max,
            children: [
              const Text(
                'Selamat datang kembali',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'Masuk untuk melanjutkan ke JalanKita',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _roleTab('Masyarakat', 'user', Icons.person_outline),
                  const SizedBox(width: 6),
                  _roleTab('Admin', 'admin', Icons.shield_outlined),
                  const SizedBox(width: 6),
                  _roleTab('Pekerja', 'worker', Icons.engineering_outlined),
                ],
              ),
              const SizedBox(height: 20),
              _buildField(
                'Email',
                _emailCtrl,
                Icons.mail_outline,
                hint: 'email@contoh.com',
              ),
              const SizedBox(height: 12),
              _buildField(
                'Password',
                _passCtrl,
                Icons.lock_outline,
                hint: '••••••••',
                obscure: true,
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: const Text('Lupa password?'),
                ),
              ),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: _loading
                      ? null
                      : () => _login(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A5CFF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Masuk',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statPill(String num, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white10,
        border: Border.all(color: Colors.white12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            num,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: Colors.white38),
          ),
        ],
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController ctrl,
    IconData icon, {
    String hint = '',
    bool obscure = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 5),
        TextField(
          controller: ctrl,
          obscureText: obscure ? _obscure : false,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 18),
            suffixIcon: obscure
                ? IconButton(
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 18,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  )
                : null,
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300, width: 0.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300, width: 0.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  // Maybe delete this later, for testing role-based UI
  Widget _roleTab(String label, String value, IconData icon) {
    final active = _role == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _role = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active ? const Color(0xFF0A2540) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: active ? const Color(0xFF0A2540) : Colors.grey.shade300,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 16, color: active ? Colors.white : Colors.grey),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: active ? Colors.white : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
