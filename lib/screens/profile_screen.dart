import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../widgets/common.dart';
import 'admin_dashboard.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return PageFrame(maxWidth: 720, child: ListView(padding: const EdgeInsets.only(top: 24, bottom: 32), children: [
      const RebotfoxLogo(compact: true),
      const SizedBox(height: 26),
      Card(child: Padding(padding: const EdgeInsets.all(22), child: Row(children: [
        const CircleAvatar(radius: 34, backgroundColor: AppColors.surfaceSoft, child: Icon(Icons.person_rounded, size: 34, color: AppColors.primary)),
        const SizedBox(width: 16),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Misafir Kullanıcı', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)), SizedBox(height: 4), Text('Giriş yaparak tamirlerinizi kaydedin.', style: TextStyle(color: AppColors.textMuted))])),
        IconButton(onPressed: () {}, icon: const Icon(Icons.edit_outlined)),
      ]))),
      const SizedBox(height: 18),
      _Menu(Icons.receipt_long_outlined, 'Tamirlerim', 'Geçmiş ve aktif servis kayıtları', () {}),
      _Menu(Icons.notifications_none_rounded, 'Bildirimler', 'Servis güncellemeleri', () {}),
      _Menu(Icons.shield_outlined, 'Gizlilik Politikası', 'KVKK ve veri güvenliği', () {}),
      _Menu(Icons.support_agent_rounded, 'İletişim', 'Telefon, WhatsApp ve adres', () {}),
      _Menu(Icons.admin_panel_settings_outlined, 'Admin Paneli', 'Yönetim ekranını aç', () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminDashboard()))),
      const SizedBox(height: 14),
      SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.login_rounded), label: const Text('Giriş Yap / Kayıt Ol'))),
    ]));
  }
}

class _Menu extends StatelessWidget {
  const _Menu(this.icon, this.title, this.subtitle, this.onTap);
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 10), child: Card(child: ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7), leading: CircleAvatar(backgroundColor: AppColors.primary.withValues(alpha: .12), child: Icon(icon, color: AppColors.primary)), title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)), subtitle: Text(subtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)), trailing: const Icon(Icons.chevron_right_rounded), onTap: onTap)));
}
