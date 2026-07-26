from __future__ import annotations

from pathlib import Path
import shutil
import sys

ROOT = Path.cwd()
PUBSPEC = ROOT / "pubspec.yaml"
DASHBOARD = ROOT / "lib" / "screens" / "admin_dashboard.dart"
SERVICE = ROOT / "lib" / "services" / "whatsapp_service.dart"

def fail(message: str) -> None:
    print(f"\nHATA: {message}")
    sys.exit(1)

for path in (PUBSPEC, DASHBOARD):
    if not path.exists():
        fail(f"Dosya bulunamadı: {path}. Scripti Rebotfox proje klasöründe çalıştır.")

backup_dir = ROOT / ".rebotfox_patch_backup"
backup_dir.mkdir(exist_ok=True)
shutil.copy2(PUBSPEC, backup_dir / "pubspec.yaml")
shutil.copy2(DASHBOARD, backup_dir / "admin_dashboard.dart")

pubspec = PUBSPEC.read_text(encoding="utf-8-sig")
if "url_launcher:" not in pubspec:
    anchor = "  firebase_crashlytics: ^5.2.6\n"
    if anchor not in pubspec:
        fail("pubspec.yaml içinde firebase_crashlytics satırı bulunamadı.")
    pubspec = pubspec.replace(anchor, anchor + "  url_launcher: ^6.3.2\n")
    PUBSPEC.write_text(pubspec, encoding="utf-8")
    print("OK: url_launcher pubspec.yaml dosyasına eklendi.")
else:
    print("OK: url_launcher zaten mevcut.")

SERVICE.parent.mkdir(parents=True, exist_ok=True)
service_code = '''import 'package:url_launcher/url_launcher.dart';

import '../models/repair.dart';

class WhatsAppService {
  const WhatsAppService._();

  static String normalizeTurkishPhone(String value) {
    var digits = value.replaceAll(RegExp(r'\\D'), '');

    if (digits.startsWith('0090')) {
      digits = digits.substring(2);
    }

    if (digits.startsWith('0') && digits.length == 11) {
      return '90${digits.substring(1)}';
    }

    if (digits.length == 10) {
      return '90$digits';
    }

    return digits;
  }

  static String messageFor(Repair repair, {RepairStatus? status}) {
    final currentStatus = status ?? repair.status;
    final device = '${repair.brand} ${repair.model}';

    return switch (currentStatus) {
      RepairStatus.requestReceived =>
        'Merhaba ${repair.customerName}, $device cihazınız için oluşturduğunuz servis talebi alınmıştır. Takip kodunuz: ${repair.trackingCode}. Rebotfox Teknik Servis',
      RepairStatus.diagnosing =>
        'Merhaba ${repair.customerName}, $device cihazınız teknik incelemeye alınmıştır. Takip kodunuz: ${repair.trackingCode}. Rebotfox Teknik Servis',
      RepairStatus.waitingApproval =>
        'Merhaba ${repair.customerName}, $device cihazınız için onayınız beklenmektedir. Takip kodunuz: ${repair.trackingCode}. Rebotfox Teknik Servis',
      RepairStatus.waitingPart =>
        'Merhaba ${repair.customerName}, $device cihazınız için gerekli parça beklenmektedir. Takip kodunuz: ${repair.trackingCode}. Rebotfox Teknik Servis',
      RepairStatus.repairing =>
        'Merhaba ${repair.customerName}, $device cihazınızın tamir işlemi devam etmektedir. Takip kodunuz: ${repair.trackingCode}. Rebotfox Teknik Servis',
      RepairStatus.testing =>
        'Merhaba ${repair.customerName}, $device cihazınızın tamir sonrası testleri yapılmaktadır. Takip kodunuz: ${repair.trackingCode}. Rebotfox Teknik Servis',
      RepairStatus.ready =>
        'Merhaba ${repair.customerName}, $device cihazınızın işlemleri tamamlanmıştır ve teslim almaya hazırdır. Takip kodunuz: ${repair.trackingCode}. Rebotfox Teknik Servis',
      RepairStatus.delivered =>
        'Merhaba ${repair.customerName}, $device cihazınız teslim edilmiştir. Bizi tercih ettiğiniz için teşekkür ederiz. Rebotfox Teknik Servis',
    };
  }

  static Future<bool> open({
    required String phone,
    required String message,
  }) async {
    final normalizedPhone = normalizeTurkishPhone(phone);
    if (normalizedPhone.length < 10) {
      return false;
    }

    final uri = Uri.https(
      'wa.me',
      '/$normalizedPhone',
      <String, String>{'text': message},
    );

    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
'''
SERVICE.write_text(service_code, encoding="utf-8")
print("OK: lib/services/whatsapp_service.dart oluşturuldu.")

dashboard = DASHBOARD.read_text(encoding="utf-8-sig")

import_anchor = "import '../models/repair.dart';\n"
service_import = "import '../services/whatsapp_service.dart';\n"
if service_import not in dashboard:
    if import_anchor not in dashboard:
        fail("admin_dashboard.dart içinde model import satırı bulunamadı.")
    dashboard = dashboard.replace(import_anchor, import_anchor + service_import, 1)

button_code = '''                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: updating ? null : _openWhatsAppPreview,
                    icon: const Icon(Icons.chat_rounded),
                    label: const Text('WhatsApp'),
                  ),
'''
button_anchor = "                  StatusChip(status: repair.status),\n"
if "label: const Text('WhatsApp')" not in dashboard:
    if button_anchor not in dashboard:
        fail("Admin kartındaki StatusChip satırı bulunamadı.")
    dashboard = dashboard.replace(button_anchor, button_anchor + button_code, 1)

method_code = r'''
  Future<void> _openWhatsAppPreview({RepairStatus? status}) async {
    final controller = TextEditingController(
      text: WhatsAppService.messageFor(widget.repair, status: status),
    );

    final shouldOpen = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('WhatsApp mesajı'),
          content: SizedBox(
            width: 520,
            child: TextField(
              controller: controller,
              minLines: 6,
              maxLines: 10,
              decoration: const InputDecoration(
                labelText: 'Mesaj',
                alignLabelWithHint: true,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Vazgeç'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              icon: const Icon(Icons.open_in_new_rounded),
              label: const Text("WhatsApp'ta Aç"),
            ),
          ],
        );
      },
    );

    final message = controller.text.trim();
    controller.dispose();

    if (shouldOpen != true || message.isEmpty || !mounted) {
      return;
    }

    final opened = await WhatsAppService.open(
      phone: widget.repair.phone,
      message: message,
    );

    if (!mounted) {
      return;
    }

    if (!opened) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'WhatsApp açılamadı. Telefon numarasını ve WhatsApp kurulumunu kontrol edin.',
          ),
        ),
      );
    }
  }

  Future<void> _offerReadyNotification() async {
    final send = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('WhatsApp bildirimi'),
          content: const Text(
            'Müşteriye WhatsApp bildirimi göndermek ister misiniz?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Şimdi değil'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Mesajı hazırla'),
            ),
          ],
        );
      },
    );

    if (send == true && mounted) {
      await _openWhatsAppPreview(status: RepairStatus.ready);
    }
  }

'''
method_anchor = "  Future<void> _updateStatus(RepairStatus status) async {\n"
if "Future<void> _openWhatsAppPreview" not in dashboard:
    if method_anchor not in dashboard:
        fail("_updateStatus metodu bulunamadı.")
    dashboard = dashboard.replace(method_anchor, method_code + method_anchor, 1)

snackbar_anchor = '''      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${widget.repair.trackingCode} durumu “${status.label}” olarak güncellendi.',
          ),
        ),
      );
'''
ready_code = snackbar_anchor + '''
      if (status == RepairStatus.ready && mounted) {
        await _offerReadyNotification();
      }
'''
if "_offerReadyNotification();" not in dashboard:
    if snackbar_anchor not in dashboard:
        fail("Durum güncelleme başarı SnackBar bölümü bulunamadı.")
    dashboard = dashboard.replace(snackbar_anchor, ready_code, 1)

DASHBOARD.write_text(dashboard, encoding="utf-8")
print("OK: Admin paneline WhatsApp butonu ve teslime hazır bildirimi eklendi.")

print("\nİŞLEM TAMAMLANDI.\n\nŞimdi sırayla çalıştır:\n"
      "  flutter pub get\n"
      "  dart format lib/services/whatsapp_service.dart lib/screens/admin_dashboard.dart\n"
      "  flutter analyze\n"
      "  flutter test\n"
      "  flutter run -d zxfmnrfidqeuroo7\n\n"
      "Yedekler .rebotfox_patch_backup klasörüne kaydedildi.\n")
