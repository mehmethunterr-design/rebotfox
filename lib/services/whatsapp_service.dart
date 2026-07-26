import 'package:url_launcher/url_launcher.dart';

import '../models/repair.dart';

class WhatsAppService {
  const WhatsAppService._();

  static String normalizeTurkishPhone(String value) {
    var digits = value.replaceAll(RegExp(r'\D'), '');

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

  static String messageFor(
    Repair repair, {
    RepairStatus? status,
  }) {
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
      <String, String>{
        'text': message,
      },
    );

    return launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
  }
}
