import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/app_theme.dart';
import '../models/repair.dart';
import '../widgets/common.dart';

class TrackingDetailScreen extends StatelessWidget {
  const TrackingDetailScreen({super.key, required this.repair, this.createdNow = false});
  final Repair repair;
  final bool createdNow;

  String get price => '${repair.estimatedPrice.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')} ₺';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(createdNow ? 'Talep Oluşturuldu' : 'Servis Takibi')),
      body: PageFrame(maxWidth: 820, child: ListView(padding: const EdgeInsets.only(top: 12, bottom: 32), children: [
        if (createdNow) Container(padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: .12), borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.primary.withValues(alpha: .35))), child: const Row(children: [Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 30), SizedBox(width: 12), Expanded(child: Text('Talebiniz başarıyla oluşturuldu. Takip kodunuzu kaydedin.', style: TextStyle(fontWeight: FontWeight.w800)))])),
        if (createdNow) const SizedBox(height: 16),
        Card(child: Padding(padding: const EdgeInsets.all(22), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Takip Kodu', style: TextStyle(color: AppColors.textMuted)), const SizedBox(height: 5), SelectableText(repair.trackingCode, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900, letterSpacing: .4))])), IconButton.filledTonal(onPressed: () { Clipboard.setData(ClipboardData(text: repair.trackingCode)); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Takip kodu kopyalandı.'))); }, icon: const Icon(Icons.copy_rounded))]),
          const SizedBox(height: 18),
          StatusChip(status: repair.status),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 14),
          _DetailRow('Cihaz', '${repair.brand} ${repair.model}'),
          _DetailRow('İşlem', repair.repairType),
          _DetailRow('Tahmini Fiyat', repair.estimatedPrice > 0 ? price : 'İnceleme sonrası'),
          _DetailRow('Müşteri', repair.customerName),
        ]))),
        const SizedBox(height: 18),
        const SectionTitle('Servis Süreci', subtitle: 'Cihazınızın geçtiği aşamaları buradan izleyebilirsiniz.'),
        const SizedBox(height: 14),
        Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(children: RepairStatus.values.map((status) {
          final current = RepairStatus.values.indexOf(repair.status);
          final index = RepairStatus.values.indexOf(status);
          final done = index <= current;
          return _Timeline(status: status, done: done, last: index == RepairStatus.values.length - 1);
        }).toList()))),
      ])),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 7), child: Row(children: [SizedBox(width: 130, child: Text(label, style: const TextStyle(color: AppColors.textMuted))), Expanded(child: Text(value, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w800)))]));
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.status, required this.done, required this.last});
  final RepairStatus status;
  final bool done;
  final bool last;
  @override
  Widget build(BuildContext context) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Column(children: [CircleAvatar(radius: 17, backgroundColor: done ? status.color : AppColors.surfaceSoft, child: Icon(status.icon, color: done ? AppColors.background : AppColors.textMuted, size: 18)), if (!last) Container(width: 2, height: 42, color: done ? status.color.withValues(alpha: .45) : AppColors.border)]),
    const SizedBox(width: 14),
    Expanded(child: Padding(padding: const EdgeInsets.only(top: 7), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(status.label, style: TextStyle(fontWeight: FontWeight.w900, color: done ? AppColors.text : AppColors.textMuted)), const SizedBox(height: 4), Text(done ? 'Bu aşama tamamlandı veya devam ediyor.' : 'Henüz bu aşamaya geçilmedi.', style: const TextStyle(color: AppColors.textMuted, fontSize: 12))]))),
  ]);
}
