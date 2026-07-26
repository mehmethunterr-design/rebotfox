import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/app_theme.dart';
import '../data/mock_repository.dart';
import '../models/repair.dart';
import '../widgets/common.dart';
import 'tracking_detail_screen.dart';

class RequestScreen extends StatefulWidget {
  const RequestScreen({super.key, this.prefill});
  final PriceItem? prefill;
  @override
  State<RequestScreen> createState() => _RequestScreenState();
}

class _RequestScreenState extends State<RequestScreen> {
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController();
  final phone = TextEditingController();
  final email = TextEditingController();
  final problem = TextEditingController();
  bool accepted = false;
  bool submitting = false;
  String? brand;
  String? model;
  String? repairType;

  @override
  void initState() {
    super.initState();
    brand = widget.prefill?.brand;
    model = widget.prefill?.model;
    repairType = widget.prefill?.repairType;
  }

  @override
  void dispose() {
    name.dispose(); phone.dispose(); email.dispose(); problem.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = MockRepository.instance;
    final brands = repo.prices.map((e) => e.brand).toSet().toList();
    final models = repo.prices.where((e) => e.brand == brand).map((e) => e.model).toSet().toList();
    final repairs = repo.prices.where((e) => e.brand == brand && e.model == model).map((e) => e.repairType).toSet().toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Tamir Talebi')),
      body: PageFrame(
        maxWidth: 760,
        child: Form(
          key: formKey,
          child: ListView(padding: const EdgeInsets.only(top: 12, bottom: 32), children: [
            const Text('Cihazınızı bize anlatın', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            const Text('Bilgileri doldurun; servis ekibimiz en kısa sürede sizinle iletişime geçsin.', style: TextStyle(color: AppColors.textMuted, height: 1.45)),
            const SizedBox(height: 24),
            TextFormField(controller: name, textInputAction: TextInputAction.next, decoration: const InputDecoration(labelText: 'Ad Soyad *', prefixIcon: Icon(Icons.person_outline_rounded)), validator: (v) => (v?.trim().length ?? 0) < 3 ? 'Ad soyad en az 3 karakter olmalı.' : null),
            const SizedBox(height: 14),
            TextFormField(controller: phone, keyboardType: TextInputType.phone, inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(11)], decoration: const InputDecoration(labelText: 'Telefon Numarası *', prefixIcon: Icon(Icons.phone_outlined)), validator: (v) => (v?.length ?? 0) < 10 ? 'Geçerli bir telefon numarası girin.' : null),
            const SizedBox(height: 14),
            TextFormField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'E-posta (isteğe bağlı)', prefixIcon: Icon(Icons.mail_outline_rounded))),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(initialValue: brand, decoration: const InputDecoration(labelText: 'Marka *', prefixIcon: Icon(Icons.business_rounded)), items: brands.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v) => setState(() { brand = v; model = null; repairType = null; }), validator: (v) => v == null ? 'Marka seçin.' : null),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(initialValue: model, decoration: const InputDecoration(labelText: 'Model *', prefixIcon: Icon(Icons.smartphone_rounded)), items: models.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: brand == null ? null : (v) => setState(() { model = v; repairType = null; }), validator: (v) => v == null ? 'Model seçin.' : null),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(initialValue: repairType, decoration: const InputDecoration(labelText: 'Tamir İşlemi *', prefixIcon: Icon(Icons.build_rounded)), items: repairs.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: model == null ? null : (v) => setState(() => repairType = v), validator: (v) => v == null ? 'Tamir işlemi seçin.' : null),
            const SizedBox(height: 14),
            TextFormField(controller: problem, minLines: 4, maxLines: 7, decoration: const InputDecoration(labelText: 'Sorun Açıklaması *', alignLabelWithHint: true, prefixIcon: Padding(padding: EdgeInsets.only(bottom: 74), child: Icon(Icons.description_outlined))), validator: (v) => (v?.trim().length ?? 0) < 10 ? 'Sorunu en az 10 karakterle açıklayın.' : null),
            const SizedBox(height: 16),
            Card(child: CheckboxListTile(value: accepted, onChanged: (v) => setState(() => accepted = v ?? false), activeColor: AppColors.primary, title: const Text('KVKK ve servis koşullarını kabul ediyorum.', style: TextStyle(fontWeight: FontWeight.w700)), subtitle: const Text('Talebinizi işleyebilmemiz için onay gereklidir.', style: TextStyle(color: AppColors.textMuted)))),
            const SizedBox(height: 18),
            SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: submitting ? null : _submit, icon: submitting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send_rounded), label: Text(submitting ? 'Gönderiliyor...' : 'Talebi Gönder'))),
          ]),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    if (!accepted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen KVKK ve servis koşullarını kabul edin.')));
      return;
    }
    setState(() => submitting = true);
    await Future<void>.delayed(const Duration(milliseconds: 650));
    PriceItem? price;
    for (final item in MockRepository.instance.prices) {
      if (item.brand == brand && item.model == model && item.repairType == repairType) {
        price = item;
        break;
      }
    }
    final repair = Repair(
      trackingCode: MockRepository.instance.createTrackingCode(),
      customerName: name.text.trim(),
      phone: phone.text.trim(),
      brand: brand!,
      model: model!,
      repairType: repairType!,
      problem: problem.text.trim(),
      status: RepairStatus.requestReceived,
      createdAt: DateTime.now(),
      estimatedPrice: price?.price ?? 0,
    );
    MockRepository.instance.repairs.add(repair);
    if (!mounted) return;
    setState(() => submitting = false);
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => TrackingDetailScreen(repair: repair, createdNow: true)));
  }
}
