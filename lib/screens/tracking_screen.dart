import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_theme.dart';
import '../data/repair_repository.dart';
import '../widgets/common.dart';
import 'tracking_detail_screen.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  final code = TextEditingController();
  final phone = TextEditingController();
  final formKey = GlobalKey<FormState>();

  bool searching = false;

  @override
  void dispose() {
    code.dispose();
    phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageFrame(
      maxWidth: 720,
      child: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.only(top: 24, bottom: 32),
          children: [
            const RebotfoxLogo(compact: true),
            const SizedBox(height: 28),
            const Text(
              'Cihazımı Takip Et',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Takip kodunuzu ve kayıtlı telefon numaranızı girin.',
              style: TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    TextFormField(
                      controller: code,
                      textCapitalization:
                          TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'Takip Kodu',
                        hintText: 'RFX-20260725-483921',
                        prefixIcon: Icon(Icons.qr_code_rounded),
                      ),
                      validator: (value) =>
                          (value?.trim().isEmpty ?? true)
                              ? 'Takip kodunu girin.'
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
                        labelText: 'Telefon Numarası',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      validator: (value) =>
                          (value?.length ?? 0) < 10
                              ? 'Geçerli telefon numarası girin.'
                              : null,
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: searching ? null : _search,
                        icon: searching
                            ? const SizedBox(
                                width: 19,
                                height: 19,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.search_rounded),
                        label: Text(
                          searching
                              ? 'Sorgulanıyor...'
                              : 'Sorgula',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceSoft,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lock_outline_rounded,
                    color: AppColors.primary,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Güvenliğiniz için takip kodu ve telefon numarası birlikte doğrulanır.',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _search() async {
    if (!(formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => searching = true);

    try {
      final repair =
          await RepairRepository.instance.findRepair(
        code.text,
        phone.text,
      );

      if (!mounted) {
        return;
      }

      if (repair == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Bilgilerle eşleşen servis kaydı bulunamadı.',
            ),
          ),
        );
        return;
      }

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              TrackingDetailScreen(repair: repair),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Firestore sorgusu başarısız: $error',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => searching = false);
      }
    }
  }
}
