import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../data/mock_repository.dart';
import '../models/repair.dart';
import '../widgets/common.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});
  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  @override
  Widget build(BuildContext context) {
    final repairs = MockRepository.instance.repairs;
    return Scaffold(
      appBar: AppBar(title: const Text('Yönetim Paneli'), actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none_rounded))]),
      body: PageFrame(child: ListView(padding: const EdgeInsets.only(top: 10, bottom: 32), children: [
        const RebotfoxLogo(compact: true),
        const SizedBox(height: 24),
        const Text('Rebotfox Yönetim Paneli', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        const Text('Servis operasyonunu tek ekrandan yönetin.', style: TextStyle(color: AppColors.textMuted)),
        const SizedBox(height: 22),
        LayoutBuilder(builder: (context, constraints) {
          final columns = constraints.maxWidth > 900 ? 4 : constraints.maxWidth > 560 ? 2 : 1;
          return GridView.count(crossAxisCount: columns, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: columns == 1 ? 2.8 : 1.7, children: [
            _Stat('Toplam Kayıt', '${repairs.length}', Icons.receipt_long_rounded, AppColors.info),
            _Stat('Tamirde', '${repairs.where((e) => e.status == RepairStatus.repairing).length}', Icons.build_rounded, AppColors.primary),
            _Stat('Teslime Hazır', '${repairs.where((e) => e.status == RepairStatus.ready).length}', Icons.verified_rounded, AppColors.warning),
            _Stat('Tahmini Ciro', '${repairs.fold<double>(0, (sum, item) => sum + item.estimatedPrice).toStringAsFixed(0)} ₺', Icons.payments_rounded, AppColors.primary),
          ]);
        }),
        const SizedBox(height: 28),
        const SectionTitle('Servis Kayıtları', subtitle: 'Durumları görüntüleyin ve güncelleyin.'),
        const SizedBox(height: 14),
        ...repairs.map((repair) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Card(child: Padding(padding: const EdgeInsets.all(18), child: Row(children: [
          CircleAvatar(backgroundColor: repair.status.color.withValues(alpha: .12), child: Icon(repair.status.icon, color: repair.status.color)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${repair.brand} ${repair.model}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)), const SizedBox(height: 4), Text('${repair.customerName} • ${repair.trackingCode}', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)), const SizedBox(height: 10), StatusChip(status: repair.status)])),
          PopupMenuButton<RepairStatus>(tooltip: 'Durumu değiştir', onSelected: (value) => setState(() => repair.status = value), itemBuilder: (_) => RepairStatus.values.map((s) => PopupMenuItem(value: s, child: Text(s.label))).toList()),
        ]))))),
      ])),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.title, this.value, this.icon, this.color);
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [CircleAvatar(backgroundColor: color.withValues(alpha: .12), child: Icon(icon, color: color)), const Spacer(), Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)), const SizedBox(height: 3), Text(title, style: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w700))])));
}
