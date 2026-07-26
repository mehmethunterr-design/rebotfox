import 'dart:math';
import '../models/repair.dart';

class PriceItem {
  const PriceItem(this.brand, this.model, this.repairType, this.price, this.duration, this.warranty);
  final String brand;
  final String model;
  final String repairType;
  final double price;
  final String duration;
  final String warranty;
}

class MockRepository {
  MockRepository._();
  static final instance = MockRepository._();

  final prices = <PriceItem>[
    const PriceItem('Apple', 'iPhone 14', 'Ekran Değişimi', 4500, '60–90 dakika', '6 ay'),
    const PriceItem('Apple', 'iPhone 14', 'Batarya Değişimi', 2750, '45–60 dakika', '6 ay'),
    const PriceItem('Apple', 'iPhone 13', 'Şarj Soketi', 2200, '60–120 dakika', '3 ay'),
    const PriceItem('Samsung', 'Galaxy S23', 'Ekran Değişimi', 5200, '90–120 dakika', '6 ay'),
    const PriceItem('Samsung', 'Galaxy A54', 'Batarya Değişimi', 1800, '45–60 dakika', '6 ay'),
    const PriceItem('Xiaomi', 'Redmi Note 13', 'Ekran Değişimi', 2600, '60–90 dakika', '6 ay'),
  ];

  final repairs = <Repair>[
    Repair(
      trackingCode: 'RFX-20260725-483921',
      customerName: 'Mehmet Avcı',
      phone: '05551234567',
      brand: 'Apple',
      model: 'iPhone 14',
      repairType: 'Ekran Değişimi',
      problem: 'Ekran kırık ve dokunmatik zaman zaman çalışmıyor.',
      status: RepairStatus.repairing,
      createdAt: DateTime(2026, 7, 25, 13, 30),
      estimatedPrice: 4500,
    ),
  ];

  String createTrackingCode() {
    final now = DateTime.now();
    final date = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final random = (100000 + Random().nextInt(900000)).toString();
    return 'RFX-$date-$random';
  }

  Repair? findRepair(String trackingCode, String phone) {
    final normalizedCode = trackingCode.trim().toUpperCase();
    final normalizedPhone = phone.replaceAll(RegExp(r'\D'), '');
    for (final repair in repairs) {
      if (repair.trackingCode.toUpperCase() == normalizedCode &&
          repair.phone.replaceAll(RegExp(r'\D'), '') == normalizedPhone) {
        return repair;
      }
    }
    return null;
  }
}
