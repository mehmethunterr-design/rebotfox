import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../widgets/common.dart';
import 'request_screen.dart';
import 'admin_gate_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onTabRequested});
  final ValueChanged<int> onTabRequested;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final desktop = width >= 900;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: PageFrame(
            child: Padding(
              padding: const EdgeInsets.only(top: 18, bottom: 36),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const RebotfoxLogo(),
                  const Spacer(),
                  IconButton.filledTonal(onPressed: () {}, icon: const Icon(Icons.notifications_none_rounded)),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    tooltip: 'Hesap menüsü',
                    icon: const CircleAvatar(backgroundColor: AppColors.surfaceSoft, child: Icon(Icons.person_rounded, color: AppColors.text)),
                    onSelected: (value) {
                      if (value == 'admin') {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AdminGateScreen(),
                          ),
                        );
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'admin',
                        child: Text('Yönetici girişi'),
                      ),
                    ],
                  ),
                ]),
                const SizedBox(height: 26),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(desktop ? 42 : 24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: const LinearGradient(colors: [Color(0xFF153B27), Color(0xFF0E251A)]),
                    border: Border.all(color: const Color(0xFF2A6A47)),
                  ),
                  child: desktop
                      ? Row(children: [Expanded(child: _HeroText(onTabRequested: onTabRequested)), const SizedBox(width: 30), const _HeroVisual()])
                      : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_HeroText(onTabRequested: onTabRequested), const SizedBox(height: 24), const Center(child: _HeroVisual())]),
                ),
                const SizedBox(height: 34),
                const SectionTitle('Hızlı İşlemler', subtitle: 'En sık kullanılan işlemlere tek dokunuşla ulaşın.'),
                const SizedBox(height: 16),
                GridView.count(
                  crossAxisCount: desktop ? 4 : 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: desktop ? 1.6 : 1.15,
                  children: [
                    _QuickAction(Icons.payments_rounded, 'Fiyat Hesapla', 'Anında fiyat görün', () => onTabRequested(1)),
                    _QuickAction(Icons.add_reaction_outlined, 'Tamir Talebi', 'Yeni kayıt oluşturun', () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RequestScreen()))),
                    _QuickAction(Icons.location_searching_rounded, 'Cihaz Takip', 'Servis durumunu görün', () => onTabRequested(2)),
                    _QuickAction(Icons.chat_bubble_outline_rounded, 'WhatsApp', 'Hızlı destek alın', () => _showWhatsapp(context)),
                  ],
                ),
                const SizedBox(height: 34),
                const SectionTitle('Hizmetlerimiz', subtitle: 'Telefon ve tabletler için profesyonel teknik servis.'),
                const SizedBox(height: 16),
                Wrap(spacing: 12, runSpacing: 12, children: const [
                  _Service(Icons.smartphone_rounded, 'Ekran Değişimi'),
                  _Service(Icons.battery_charging_full_rounded, 'Batarya Değişimi'),
                  _Service(Icons.usb_rounded, 'Şarj Soketi'),
                  _Service(Icons.camera_alt_outlined, 'Kamera'),
                  _Service(Icons.mic_none_rounded, 'Ses Sistemleri'),
                  _Service(Icons.memory_rounded, 'Anakart Onarımı'),
                  _Service(Icons.water_drop_outlined, 'Su Teması'),
                  _Service(Icons.tablet_android_rounded, 'Tablet Tamiri'),
                ]),
                const SizedBox(height: 34),
                const SectionTitle('Neden Rebotfox?'),
                const SizedBox(height: 16),
                GridView.count(
                  crossAxisCount: desktop ? 4 : 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: desktop ? 1.45 : 1.05,
                  children: const [
                    _Trust(Icons.workspace_premium_outlined, 'Uzman Servis', 'Deneyimli teknik ekip'),
                    _Trust(Icons.receipt_long_outlined, 'Şeffaf Fiyat', 'İşlem öncesi net teklif'),
                    _Trust(Icons.speed_rounded, 'Hızlı İşlem', 'Zamanında teslimat'),
                    _Trust(Icons.verified_user_outlined, 'Garantili Onarım', 'İşçilik garantisi'),
                  ],
                ),
              ]),
            ),
          ),
        ),
      ],
    );
  }

  static void _showWhatsapp(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 10, 24, 28),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('WhatsApp Destek', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          const Text('Numara: 0555 000 00 00', style: TextStyle(color: AppColors.textMuted)),
          const SizedBox(height: 18),
          SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.chat_rounded), label: const Text('Mesajı hazırla'))),
        ]),
      ),
    );
  }
}

class _HeroText extends StatelessWidget {
  const _HeroText({required this.onTabRequested});
  final ValueChanged<int> onTabRequested;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: .12), borderRadius: BorderRadius.circular(999)),
        child: const Text('HIZLI • GÜVENİLİR • PROFESYONEL', style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: .8)),
      ),
      const SizedBox(height: 16),
      const Text('Cihazınız\nemin ellerde.', style: TextStyle(fontSize: 42, height: 1.05, fontWeight: FontWeight.w900, letterSpacing: -1.6)),
      const SizedBox(height: 14),
      const Text('Tamir fiyatını öğrenin, servis talebi oluşturun ve cihazınızı anlık olarak takip edin.', style: TextStyle(color: AppColors.textMuted, fontSize: 16, height: 1.5)),
      const SizedBox(height: 24),
      Wrap(spacing: 12, runSpacing: 12, children: [
        FilledButton.icon(onPressed: () => onTabRequested(1), icon: const Icon(Icons.payments_rounded), label: const Text('Fiyat Öğren')),
        OutlinedButton.icon(onPressed: () => onTabRequested(2), icon: const Icon(Icons.location_searching_rounded), label: const Text('Cihazımı Takip Et')),
      ]),
    ]);
  }
}

class _HeroVisual extends StatelessWidget {
  const _HeroVisual();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      height: 220,
      decoration: BoxDecoration(color: AppColors.background.withValues(alpha: .4), borderRadius: BorderRadius.circular(28)),
      child: Stack(alignment: Alignment.center, children: [
        Container(width: 118, height: 190, decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.border, width: 3))),
        const Positioned(top: 29, child: SizedBox(width: 42, child: Divider(thickness: 4, color: AppColors.border))),
        const Icon(Icons.build_circle_rounded, size: 76, color: AppColors.primary),
        const Positioned(right: 18, top: 26, child: CircleAvatar(radius: 25, backgroundColor: AppColors.primary, child: Icon(Icons.verified_rounded, color: AppColors.background))),
      ]),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction(this.icon, this.title, this.subtitle, this.onTap);
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: AppColors.primary, size: 30),
          const Spacer(),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
        ]),
      ),
    ),
  );
}

class _Service extends StatelessWidget {
  const _Service(this.icon, this.title);
  final IconData icon;
  final String title;
  @override
  Widget build(BuildContext context) => Container(
    width: 170,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.border)),
    child: Row(children: [Icon(icon, color: AppColors.primary), const SizedBox(width: 10), Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)))]),
  );
}

class _Trust extends StatelessWidget {
  const _Trust(this.icon, this.title, this.subtitle);
  final IconData icon;
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        CircleAvatar(backgroundColor: AppColors.primary.withValues(alpha: .12), child: Icon(icon, color: AppColors.primary)),
        const Spacer(),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        const SizedBox(height: 5),
        Text(subtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
      ]),
    ),
  );
}
