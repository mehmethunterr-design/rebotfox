import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../data/mock_repository.dart';
import '../widgets/common.dart';
import 'request_screen.dart';

class PriceScreen extends StatefulWidget {
  const PriceScreen({super.key});
  @override
  State<PriceScreen> createState() => _PriceScreenState();
}

class _PriceScreenState extends State<PriceScreen> {
  String? brand;
  String? model;
  String? repairType;

  List<String> get brands => MockRepository.instance.prices.map((e) => e.brand).toSet().toList();
  List<String> get models => MockRepository.instance.prices.where((e) => e.brand == brand).map((e) => e.model).toSet().toList();
  List<String> get repairTypes => MockRepository.instance.prices.where((e) => e.brand == brand && e.model == model).map((e) => e.repairType).toSet().toList();
  PriceItem? get selected {
    for (final p in MockRepository.instance.prices) {
      if (p.brand == brand && p.model == model && p.repairType == repairType) return p;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return PageFrame(
      child: ListView(padding: const EdgeInsets.only(top: 24, bottom: 32), children: [
        const RebotfoxLogo(compact: true),
        const SizedBox(height: 28),
        const Text('Tamir Fiyatı Öğren', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        const Text('Cihazınızı ve yapılacak işlemi seçin. Fiyatı anında görün.', style: TextStyle(color: AppColors.textMuted, fontSize: 15)),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              DropdownButtonFormField<String>(
                initialValue: brand,
                decoration: const InputDecoration(labelText: 'Marka', prefixIcon: Icon(Icons.business_rounded)),
                items: brands.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (value) => setState(() { brand = value; model = null; repairType = null; }),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: model,
                decoration: const InputDecoration(labelText: 'Model', prefixIcon: Icon(Icons.smartphone_rounded)),
                items: models.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: brand == null ? null : (value) => setState(() { model = value; repairType = null; }),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: repairType,
                decoration: const InputDecoration(labelText: 'Tamir İşlemi', prefixIcon: Icon(Icons.build_rounded)),
                items: repairTypes.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: model == null ? null : (value) => setState(() => repairType = value),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 18),
        AnimatedSwitcher(duration: const Duration(milliseconds: 250), child: selected == null ? const _EmptyPrice() : _PriceResult(item: selected!)),
      ]),
    );
  }
}

class _EmptyPrice extends StatelessWidget {
  const _EmptyPrice();
  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(children: const [
            Icon(Icons.manage_search_rounded, size: 52, color: AppColors.textMuted),
            SizedBox(height: 12),
            Text('Fiyatı görmek için seçim yapın', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
            SizedBox(height: 6),
            Text('Marka, model ve tamir işlemini seçtiğinizde fiyat burada görünecek.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textMuted)),
          ]),
        ),
      );
}

class _PriceResult extends StatelessWidget {
  const _PriceResult({required this.item});
  final PriceItem item;
  String get price => '${item.price.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')} ₺';

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF163B28), Color(0xFF10291D)]),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF2A6A47)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Tahmini Fiyat', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(price, style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w900, color: AppColors.primary)),
          const SizedBox(height: 12),
          Text('${item.brand} ${item.model} • ${item.repairType}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          Wrap(spacing: 10, runSpacing: 10, children: [InfoPill(icon: Icons.schedule_rounded, text: item.duration), InfoPill(icon: Icons.verified_user_outlined, text: '${item.warranty} garanti')]),
          const SizedBox(height: 18),
          const Text('Fiyat parça ve işçilik dahil yaklaşık tutardır. Cihaz incelemesinden sonra kesinleştirilir.', style: TextStyle(color: AppColors.textMuted, height: 1.45)),
          const SizedBox(height: 22),
          SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => RequestScreen(prefill: item))), icon: const Icon(Icons.add_circle_outline_rounded), label: const Text('Tamir Talebi Oluştur'))),
        ]),
      );
}
