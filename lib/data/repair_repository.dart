import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/repair.dart';

class RepairRepository {
  RepairRepository._();

  static final RepairRepository instance = RepairRepository._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _repairs =>
      _firestore.collection('repair_requests');

  String createTrackingCode() {
    final now = DateTime.now();
    final date =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final random = (100000 + Random.secure().nextInt(900000)).toString();
    return 'RFX-$date-$random';
  }

  Future<Repair> createRepair({
    required String customerName,
    required String phone,
    required String email,
    required String brand,
    required String model,
    required String repairType,
    required String problem,
    required double estimatedPrice,
  }) async {
    final repair = Repair(
      trackingCode: createTrackingCode(),
      customerName: customerName.trim(),
      phone: _normalizePhone(phone),
      brand: brand,
      model: model,
      repairType: repairType,
      problem: problem.trim(),
      status: RepairStatus.requestReceived,
      createdAt: DateTime.now(),
      estimatedPrice: estimatedPrice,
    );

    final data = repair.toFirestore();
    data['email'] = email.trim();

    await _repairs.doc(repair.trackingCode).set(data);
    return repair;
  }

  Future<Repair?> findRepair(
    String trackingCode,
    String phone,
  ) async {
    final code = trackingCode.trim().toUpperCase();
    final normalizedPhone = _normalizePhone(phone);

    final snapshot = await _repairs.doc(code).get();
    final data = snapshot.data();

    if (!snapshot.exists || data == null) {
      return null;
    }

    final repair = Repair.fromFirestore(snapshot.id, data);

    if (_normalizePhone(repair.phone) != normalizedPhone) {
      return null;
    }

    return repair;
  }

  Stream<Repair?> watchRepair(String trackingCode) {
    final code = trackingCode.trim().toUpperCase();

    return _repairs.doc(code).snapshots().map((snapshot) {
      final data = snapshot.data();

      if (!snapshot.exists || data == null) {
        return null;
      }

      return Repair.fromFirestore(snapshot.id, data);
    });
  }

  Stream<List<Repair>> watchRepairs() {
    return _repairs
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (document) => Repair.fromFirestore(
                  document.id,
                  document.data(),
                ),
              )
              .toList(),
        );
  }

  Future<void> updateStatus(
    String trackingCode,
    RepairStatus status,
  ) {
    return _repairs.doc(trackingCode.trim().toUpperCase()).update({
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  String _normalizePhone(String value) {
    return value.replaceAll(RegExp(r'\D'), '');
  }
}
