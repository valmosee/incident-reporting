import 'dart:async';
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
  String _role = 'user';
  final supabase = Supabase.instance.client;

  // At the top of your State class
  final List<String> _bgImages = [
    'assets/images/kecelakaan-di-darmo-surabaya_169.jpeg',
    'assets/images/kerusakan_jalan.jpeg',
    // 'assets/images/your-second-image.jpeg',
    // 'assets/images/your-third-image.jpeg',
  ];
  int _currentBgIndex = 0;
  Timer? _bgTimer;

  Future<void> _login() async {
    setState(() => _loading = true);
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );

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
        SnackBar(
          content: Text('Login gagal: $e'),
          // ✅ uses theme error color
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
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

    _bgTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        setState(() {
          _currentBgIndex = (_currentBgIndex + 1) % _bgImages.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _bgTimer?.cancel();
    super.dispose();
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
      // ✅ uses theme surface color
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
    );
  }

  Widget _buildDesktopLayout() {
    return SizedBox(
      height: MediaQuery.of(context).size.height,
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
            // ✅ uses theme surface color
            color: Theme.of(context).colorScheme.surface,
            padding: EdgeInsets.fromLTRB(28, 16, 28, safeBottom + 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selamat datang kembali',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    // ✅ uses theme text color
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Masuk untuk melanjutkan ke JalanKita',
                  style: TextStyle(
                    fontSize: 12,
                    // ✅ muted text via onSurface with opacity
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
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
                    child: const Text(
                      'Lupa password?',
                      style: TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _login,
                    // ✅ no style needed — picks up ElevatedButtonTheme from theme.dart
                    child: _loading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              // ✅ spinner color matches button foreground
                              color: Theme.of(context).colorScheme.onPrimary,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Masuk',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
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
    // ✅ left panel uses theme secondary color (navy)
    final panelColor = Theme.of(context).colorScheme.secondary;

    return Container(
      width: isMobile
          ? double.infinity
          : MediaQuery.of(context).size.width * 0.3,
      height: isMobile ? 300 : null,
      decoration: BoxDecoration(color: panelColor),
      child: Stack(
        children: [
          Positioned(
            top: -40,
            left: -40,
            child: _bubble(180, Colors.white.withValues(alpha: 0.05)),
          ),
          Positioned(
            top: 140,
            left: 120,
            child: _bubble(120, Colors.white.withValues(alpha: 0.05)),
          ),
          Positioned(
            bottom: 60,
            right: -60,
            child: _bubble(220, Colors.white.withValues(alpha: 0.04)),
          ),
          Positioned(
            bottom: 250,
            left: 110,
            child: _bubble(220, Colors.white.withValues(alpha: 0.04)),
          ),
          Positioned(
            top: 160,
            right: -30,
            child: _bubble(100, Colors.white.withValues(alpha: 0.06)),
          ),
          Positioned(
            bottom: -30,
            left: 20,
            child: _bubble(120, Colors.white.withValues(alpha: 0.03)),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    // ✅ icon circle uses primary (amber) with opacity
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(90),
                  ),
                  child: Icon(
                    Icons.map_rounded,
                    // ✅ icon uses primary accent (amber)
                    color: Theme.of(context).colorScheme.primary,
                    size: 50,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'JalanKita',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isMobile
                        ? 24
                        : 60, // no const, isMobile is runtime
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  'Platform pelaporan infrastruktur jalan rusak Kota Surabaya',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isMobile ? 16 : 20,
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
    return Stack(
      fit: StackFit.expand,
      children: [
        // 🖼️ Animated background slideshow
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 800),
          child: Container(
            key: ValueKey(_currentBgIndex),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              image: DecorationImage(
                image: AssetImage(_bgImages[_currentBgIndex]),
                fit: BoxFit.cover,
                opacity: 0.18,
              ),
            ),
          ),
        ),

        // 📋 Your form on top
        Center(
          child: Container(
            width: 700,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 36),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Selamat datang kembali',
                  style: TextStyle(
                    fontSize: 45,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Masuk untuk melanjutkan ke JalanKita',
                  style: TextStyle(
                    fontSize: 18,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
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
                    child: const Text(
                      'Lupa password?',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _login,
                    child: _loading
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Theme.of(context).colorScheme.onPrimary,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Masuk', style: TextStyle(fontSize: 22)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildField(
    String label,
    TextEditingController ctrl,
    IconData icon, {
    String hint = '',
    bool obscure = false,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 24, // was 12
            fontWeight: FontWeight.w500,
            color: cs.onSurface.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 6), // was 5
        TextField(
          controller: ctrl,
          obscureText: obscure ? _obscure : false,
          style: const TextStyle(fontSize: 20), // add explicit text size
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 28), // was 18
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 16,
            ), // bigger tap area
            suffixIcon: obscure
                ? IconButton(
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 28, // was 18
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  )
                : null,
          ),
        ),
      ],
    );
  }

  Widget _roleTab(String label, String value, IconData icon) {
    final active = _role == value;
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _role = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24), // was 8
          decoration: BoxDecoration(
            // ✅ active uses secondary (navy), inactive uses surface with border
            color: active ? cs.secondary : cs.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: active ? cs.secondary : cs.outline),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 50,
                // ✅ active icon uses primary (amber), inactive uses muted
                color: active
                    ? cs.primary
                    : cs.onSurface.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: active
                      ? Colors.white
                      : cs.onSurface.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
