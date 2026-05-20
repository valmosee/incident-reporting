import 'package:flutter/material.dart';

class DashboardUser extends StatelessWidget {
  const DashboardUser({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JalanKita',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0D1B2A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF1565C0),
          secondary: Color(0xFF4D9EFF),
        ),
      ),
      home: const DashboardPage(),
    );
  }
}

// ── Model ────────────────────────────────────────────────────────────
enum StatusLaporan { diproses, menunggu, selesai, ditolak }

class Laporan {
  final String judul;
  final String lokasi;
  final String tanggal;
  final StatusLaporan status;
  const Laporan({
    required this.judul,
    required this.lokasi,
    required this.tanggal,
    required this.status,
  });
}

class Notifikasi {
  final String pesan;
  final String waktu;
  final bool dibaca;
  const Notifikasi({
    required this.pesan,
    required this.waktu,
    this.dibaca = false,
  });
}

// ── Dummy data ───────────────────────────────────────────────────────
const _laporanList = [
  Laporan(
    judul: 'Jalan berlubang dalam di Jl. Rungkut Asri Tengah',
    lokasi: 'Rungkut, Surabaya',
    tanggal: '12 Mei 2026',
    status: StatusLaporan.diproses,
  ),
  Laporan(
    judul: 'Aspal terkelupas panjang 20m di Jl. Medokan Ayu',
    lokasi: 'Rungkut, Surabaya',
    tanggal: '9 Mei 2026',
    status: StatusLaporan.menunggu,
  ),
  Laporan(
    judul: 'Lubang di persimpangan Jl. Kendangsari',
    lokasi: 'Tenggilis Mejoyo',
    tanggal: '1 Mei 2026',
    status: StatusLaporan.selesai,
  ),
  Laporan(
    judul: 'Retak melintang di Jl. Prapen Indah',
    lokasi: 'Prapen, Surabaya',
    tanggal: '27 Apr 2026',
    status: StatusLaporan.ditolak,
  ),
];

const _notifList = [
  Notifikasi(
    pesan: 'Pekerja ditugaskan ke laporan Jl. Rungkut Asri Tengah.',
    waktu: '13 Mei · 08:00',
  ),
  Notifikasi(
    pesan: 'Laporan Jl. Medokan Ayu telah diverifikasi admin.',
    waktu: '10 Mei · 11:22',
  ),
  Notifikasi(
    pesan: 'Laporan Jl. Prapen Indah ditolak. Alasan: duplikat.',
    waktu: '28 Apr · 09:05',
    dibaca: true,
  ),
];

// ── Konstanta warna ──────────────────────────────────────────────────
const _navy = Color(0xFF0D1B2A);
const _navy2 = Color(0xFF1A2D42);
const _navy3 = Color(0xFF132236);
const _blue = Color(0xFF1565C0);
const _blueBright = Color(0xFF4D9EFF);
const _green = Color(0xFF22C55E);
const _amber = Color(0xFFF59E0B);
const _red = Color(0xFFEF4444);
const _blueTag = Color(0xFF3B82F6);
const _textMuted = Color(0x99FFFFFF);
const _textDim = Color(0x59FFFFFF);
const _border = Color(0x1AFFFFFF);

// ── Dashboard Page ───────────────────────────────────────────────────
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _navy,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Header(),
              const SizedBox(height: 4),
              const _StatsRow(),
              const SizedBox(height: 20),
              _SectionTitle(
                title: 'Laporan saya',
                action: 'Lihat semua →',
                onActionTap: () {},
              ),
              const SizedBox(height: 10),
              const _LaporanList(),
              const SizedBox(height: 20),
              const _TwoColRow(
                left: _PetaPanel(),
                right: _TimelinePanel(),
              ),
              const SizedBox(height: 10),
              const _TwoColRow(
                left: _StatusPanel(),
                right: _NotifPanel(),
              ),
              const SizedBox(height: 20),
              const _TipsSection(),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Header ───────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [_blue, _blueBright],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            alignment: Alignment.center,
            child: const Text(
              'AR',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Name + role
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ahmad Rizky',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                Text(
                  'Warga · Surabaya Selatan',
                  style: TextStyle(color: _textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          // Actions
          _IconBtn(
            icon: Icons.notifications_outlined,
            onTap: () {},
          ),
          const SizedBox(width: 8),
          _IconBtn(
            icon: Icons.settings_outlined,
            onTap: () {},
          ),
          const SizedBox(width: 8),
          // Buat laporan button
          GestureDetector(
            onTap: () {},
            child: Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: _blue,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.add, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'Buat laporan',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: _navy2,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _border),
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: _textMuted, size: 18),
      ),
    );
  }
}

// ── Stats Row ────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 2-column on narrow screens
          final crossAxis = constraints.maxWidth < 360 ? 2 : 4;
          return GridView.count(
            crossAxisCount: crossAxis,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: crossAxis == 4 ? 0.85 : 1.3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: const [
              _StatCard(
                icon: Icons.description_outlined,
                label: 'Total laporan',
                value: '12',
                sub: 'Sejak bergabung',
                valueColor: Colors.white,
              ),
              _StatCard(
                icon: Icons.access_time_outlined,
                label: 'Menunggu',
                value: '3',
                sub: 'Belum ditangani',
                valueColor: _amber,
              ),
              _StatCard(
                icon: Icons.build_outlined,
                label: 'Diproses',
                value: '5',
                sub: 'Sedang dikerjakan',
                valueColor: _blueTag,
              ),
              _StatCard(
                icon: Icons.check_circle_outline,
                label: 'Selesai',
                value: '4',
                sub: 'Berhasil diperbaiki',
                valueColor: _green,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String sub;
  final Color valueColor;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.sub,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _navy2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _textDim, size: 13),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: _textDim,
                    fontSize: 10,
                    letterSpacing: 0.3,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 26,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            sub,
            style: const TextStyle(color: _textDim, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

// ── Section title ────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String title;
  final String action;
  final VoidCallback onActionTap;

  const _SectionTitle({
    required this.title,
    required this.action,
    required this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          GestureDetector(
            onTap: onActionTap,
            child: Text(
              action,
              style: const TextStyle(color: _blueBright, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Laporan List ─────────────────────────────────────────────────────
class _LaporanList extends StatelessWidget {
  const _LaporanList();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: _laporanList
            .map((l) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _LaporanCard(laporan: l),
                ))
            .toList(),
      ),
    );
  }
}

class _LaporanCard extends StatelessWidget {
  final Laporan laporan;
  const _LaporanCard({required this.laporan});

  (IconData, Color, Color) get _iconStyle {
    switch (laporan.status) {
      case StatusLaporan.diproses:
        return (
          Icons.build_outlined,
          const Color(0xFF60A5FA),
          const Color(0x263B82F6),
        );
      case StatusLaporan.menunggu:
        return (
          Icons.access_time_outlined,
          const Color(0xFFFCD34D),
          const Color(0x26F59E0B),
        );
      case StatusLaporan.selesai:
        return (
          Icons.check_circle_outline,
          const Color(0xFF4ADE80),
          const Color(0x2622C55E),
        );
      case StatusLaporan.ditolak:
        return (
          Icons.close,
          const Color(0xFFFCA5A5),
          const Color(0x26EF4444),
        );
    }
  }

  Widget _badge() {
    switch (laporan.status) {
      case StatusLaporan.diproses:
        return _Badge(
          label: 'Diproses',
          textColor: const Color(0xFF60A5FA),
          bgColor: const Color(0x263B82F6),
          borderColor: const Color(0x4D3B82F6),
        );
      case StatusLaporan.menunggu:
        return _Badge(
          label: 'Menunggu',
          textColor: const Color(0xFFFCD34D),
          bgColor: const Color(0x26F59E0B),
          borderColor: const Color(0x4DF59E0B),
        );
      case StatusLaporan.selesai:
        return _Badge(
          label: 'Selesai',
          textColor: const Color(0xFF4ADE80),
          bgColor: const Color(0x2622C55E),
          borderColor: const Color(0x4D22C55E),
        );
      case StatusLaporan.ditolak:
        return _Badge(
          label: 'Ditolak',
          textColor: const Color(0xFFFCA5A5),
          bgColor: const Color(0x26EF4444),
          borderColor: const Color(0x4DEF4444),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final (icon, iconColor, iconBg) = _iconStyle;
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _navy2,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            // Title + meta
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    laporan.judul,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        color: _textDim,
                        size: 11,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          '${laporan.lokasi}  ·  ${laporan.tanggal}',
                          style: const TextStyle(
                            color: _textDim,
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _badge(),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color textColor;
  final Color bgColor;
  final Color borderColor;

  const _Badge({
    required this.label,
    required this.textColor,
    required this.bgColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── Two Column Row ───────────────────────────────────────────────────
class _TwoColRow extends StatelessWidget {
  final Widget left;
  final Widget right;
  const _TwoColRow({required this.left, required this.right});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 360) {
            return Column(
              children: [left, const SizedBox(height: 10), right],
            );
          }
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: left),
                const SizedBox(width: 10),
                Expanded(child: right),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Panel wrapper ────────────────────────────────────────────────────
class _Panel extends StatelessWidget {
  final Widget child;
  const _Panel({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _navy2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: child,
    );
  }
}

// ── Peta Panel ───────────────────────────────────────────────────────
class _PetaPanel extends StatelessWidget {
  const _PetaPanel();

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Peta laporan saya',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              GestureDetector(
                onTap: () {},
                child: const Text(
                  'Buka peta ↗',
                  style: TextStyle(color: _blueBright, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Mock map
          Container(
            height: 90,
            decoration: BoxDecoration(
              color: _navy3,
              borderRadius: BorderRadius.circular(10),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CustomPaint(
                painter: _MapPainter(),
                child: const SizedBox.expand(),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Surabaya Selatan · 4 titik dilaporkan',
            style: TextStyle(color: _textDim, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 0.5;

    // Grid lines
    for (double y = size.height / 3; y < size.height; y += size.height / 3) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    for (double x = size.width / 4; x < size.width; x += size.width / 4) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    // Dots
    final dots = [
      Offset(size.width * 0.28, size.height * 0.22),
      Offset(size.width * 0.45, size.height * 0.44),
      Offset(size.width * 0.65, size.height * 0.61),
      Offset(size.width * 0.80, size.height * 0.28),
    ];

    for (final dot in dots) {
      canvas.drawCircle(
        dot,
        8,
        Paint()..color = _blueBright.withOpacity(0.25),
      );
      canvas.drawCircle(
        dot,
        4,
        Paint()..color = _blueBright,
      );
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── Timeline Panel ───────────────────────────────────────────────────
class _TimelinePanel extends StatelessWidget {
  const _TimelinePanel();

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Laporan aktif terbaru',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          _TimelineItem(
            label: 'Laporan dikirim',
            time: '12 Mei · 09:14',
            done: true,
          ),
          _TimelineItem(
            label: 'Diverifikasi admin',
            time: '12 Mei · 13:40',
            done: true,
          ),
          _TimelineItem(
            label: 'Pekerja ditugaskan',
            time: '13 Mei · 08:00',
            done: true,
          ),
          _TimelineItem(
            label: 'Perbaikan selesai',
            time: 'Menunggu konfirmasi',
            done: false,
          ),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final String label;
  final String time;
  final bool done;

  const _TimelineItem({
    required this.label,
    required this.time,
    required this.done,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: done
                ? Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: _blueTag,
                      shape: BoxShape.circle,
                    ),
                  )
                : Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: _border, width: 2),
                    ),
                  ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: done ? Colors.white : _textDim,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
              Text(
                time,
                style: const TextStyle(color: _textDim, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Status Panel ─────────────────────────────────────────────────────
class _StatusPanel extends StatelessWidget {
  const _StatusPanel();

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Status keseluruhan',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          _StatusBar(label: 'Selesai', count: '4 / 12', ratio: 4 / 12, color: _green),
          const SizedBox(height: 8),
          _StatusBar(label: 'Diproses', count: '5 / 12', ratio: 5 / 12, color: _blueTag),
          const SizedBox(height: 8),
          _StatusBar(label: 'Menunggu', count: '3 / 12', ratio: 3 / 12, color: _amber),
        ],
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  final String label;
  final String count;
  final double ratio;
  final Color color;

  const _StatusBar({
    required this.label,
    required this.count,
    required this.ratio,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: _textMuted, fontSize: 11)),
            Text(count, style: const TextStyle(color: _textMuted, fontSize: 11)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 5,
            backgroundColor: Colors.white.withOpacity(0.08),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

// ── Notif Panel ──────────────────────────────────────────────────────
class _NotifPanel extends StatelessWidget {
  const _NotifPanel();

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Notifikasi',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              GestureDetector(
                onTap: () {},
                child: const Text(
                  'Tandai semua dibaca',
                  style: TextStyle(color: _blueBright, fontSize: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ..._notifList.map((n) => _NotifItem(notif: n)),
        ],
      ),
    );
  }
}

class _NotifItem extends StatelessWidget {
  final Notifikasi notif;
  const _NotifItem({required this.notif});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _border, width: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: notif.dibaca
                ? Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: _border),
                    ),
                  )
                : Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: _blueBright,
                      shape: BoxShape.circle,
                    ),
                  ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notif.pesan,
                  style: TextStyle(
                    color: notif.dibaca ? _textDim : Colors.white,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  notif.waktu,
                  style: const TextStyle(color: _textDim, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tips Section ─────────────────────────────────────────────────────
class _TipsSection extends StatelessWidget {
  const _TipsSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tips pelaporan',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          _TipItem(
            icon: Icons.camera_alt_outlined,
            title: 'Upload foto yang jelas',
            desc:
                'Foto dari dekat dan jauh membantu admin memverifikasi laporan lebih cepat.',
          ),
          _TipItem(
            icon: Icons.location_on_outlined,
            title: 'Aktifkan GPS saat melapor',
            desc:
                'Koordinat yang akurat membantu pekerja menemukan lokasi dengan tepat.',
          ),
          _TipItem(
            icon: Icons.description_outlined,
            title: 'Deskripsikan kerusakan dengan detail',
            desc:
                'Sebutkan panjang, kedalaman, dan risiko yang ditimbulkan.',
          ),
        ],
      ),
    );
  }
}

class _TipItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;

  const _TipItem({
    required this.icon,
    required this.title,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _navy2,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: _blueBright, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: const TextStyle(
                    color: _textDim,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}