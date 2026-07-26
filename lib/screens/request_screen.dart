import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_theme.dart';
import '../data/mock_repository.dart';
import '../data/repair_repository.dart';
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
    name.dispose();
    phone.dispose();
    email.dispose();
    problem.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final priceRepository = MockRepository.instance;

    final brands =
        priceRepository.prices.map((item) => item.brand).toSet().toList();

    final models = priceRepository.prices
        .where((item) => item.brand == brand)
        .map((item) => item.model)
        .toSet()
        .toList();

    final repairs = priceRepository.prices
        .where((item) => item.brand == brand && item.model == model)
        .map((item) => item.repairType)
        .toSet()
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Tamir Talebi')),
      body: PageFrame(
        maxWidth: 760,
        child: Form(
          key: formKey,
          child: ListView(
            padding: const EdgeInsets.only(top: 12, bottom: 32),
            children: [
              const Text(
                'Cihazınızı bize anlatın',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Bilgileri doldurun; servis ekibimiz en kısa sürede sizinle iletişime geçsin.',
                style: TextStyle(
                  color: AppColors.textMuted,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: name,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Ad Soyad *',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
                validator: (value) =>
                    (value?.trim().length ?? 0) < 3
                        ? 'Ad soyad en az 3 karakter olmalı.'
                        : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: phone,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                ],
                decoration: const InputDecoration(
                  labelText: 'Telefon Numarası *',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                validator: (value) =>
                    (value?.length ?? 0) < 10
                        ? 'Geçerli bir telefon numarası girin.'
                        : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'E-posta (isteğe bağlı)',
                  prefixIcon: Icon(Icons.mail_outline_rounded),
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: brand,
                decoration: const InputDecoration(
                  labelText: 'Marka *',
                  prefixIcon: Icon(Icons.business_rounded),
                ),
                items: brands
                    .map(
                      (item) => DropdownMenuItem(
                        value: item,
                        child: Text(item),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    brand = value;
                    model = null;
                    repairType = null;
                  });
                },
                validator: (value) =>
                    value == null ? 'Marka seçin.' : null,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: model,
                decoration: const InputDecoration(
                  labelText: 'Model *',
                  prefixIcon: Icon(Icons.smartphone_rounded),
                ),
                items: models
                    .map(
                      (item) => DropdownMenuItem(
                        value: item,
                        child: Text(item),
                      ),
                    )
                    .toList(),
                onChanged: brand == null
                    ? null
                    : (value) {
                        setState(() {
                          model = value;
                          repairType = null;
                        });
                      },
                validator: (value) =>
                    value == null ? 'Model seçin.' : null,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: repairType,
                decoration: const InputDecoration(
                  labelText: 'Tamir İşlemi *',
                  prefixIcon: Icon(Icons.build_rounded),
                ),
                items: repairs
                    .map(
                      (item) => DropdownMenuItem(
                        value: item,
                        child: Text(item),
                      ),
                    )
                    .toList(),
                onChanged: model == null
                    ? null
                    : (value) =>
                        setState(() => repairType = value),
                validator: (value) =>
                    value == null ? 'Tamir işlemi seçin.' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: problem,
                minLines: 4,
                maxLines: 7,
                decoration: const InputDecoration(
                  labelText: 'Sorun Açıklaması *',
                  alignLabelWithHint: true,
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 74),
                    child: Icon(Icons.description_outlined),
                  ),
                ),
                validator: (value) =>
                    (value?.trim().length ?? 0) < 10
                        ? 'Sorunu en az 10 karakterle açıklayın.'
                        : null,
              ),
              const SizedBox(height: 16),
              Card(
                child: CheckboxListTile(
                  value: accepted,
                  onChanged: (value) =>
                      setState(() => accepted = value ?? false),
                  activeColor: AppColors.primary,
                  title: const Text(
                    'KVKK ve servis koşullarını kabul ediyorum.',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: const Text(
                    'Talebinizi işleyebilmemiz için onay gereklidir.',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: submitting ? null : _submit,
                  icon: submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.send_rounded),
                  label: Text(
                    submitting
                        ? 'Gönderiliyor...'
                        : 'Talebi Gönder',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!(formKey.currentState?.validate() ?? false)) {
      return;
    }

    if (!accepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Lütfen KVKK ve servis koşullarını kabul edin.',
          ),
        ),
      );
      return;
    }

    setState(() => submitting = true);

    try {
      PriceItem? selectedPrice;

      for (final item in MockRepository.instance.prices) {
        if (item.brand == brand &&
            item.model == model &&
            item.repairType == repairType) {
          selectedPrice = item;
          break;
        }
      }

      final repair =
          await RepairRepository.instance.createRepair(
        customerName: name.text,
        phone: phone.text,
        email: email.text,
        brand: brand!,
        model: model!,
        repairType: repairType!,
        problem: problem.text,
        estimatedPrice: selectedPrice?.price ?? 0,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => TrackingDetailScreen(
            repair: repair,
            createdNow: true,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Talep Firebase’e kaydedilemedi: $error',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => submitting = false);
      }
    }
  }
}
