import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../core/app_theme.dart';

enum RepairStatus {
  requestReceived,
  diagnosing,
  waitingApproval,
  waitingPart,
  repairing,
  testing,
  ready,
  delivered,
}

extension RepairStatusX on RepairStatus {
  String get label => switch (this) {
        RepairStatus.requestReceived => 'Talep Alındı',
        RepairStatus.diagnosing => 'Arıza Tespiti',
        RepairStatus.waitingApproval => 'Onay Bekliyor',
        RepairStatus.waitingPart => 'Parça Bekliyor',
        RepairStatus.repairing => 'Tamir Ediliyor',
        RepairStatus.testing => 'Test Ediliyor',
        RepairStatus.ready => 'Teslime Hazır',
        RepairStatus.delivered => 'Teslim Edildi',
      };

  Color get color => switch (this) {
        RepairStatus.requestReceived => AppColors.info,
        RepairStatus.diagnosing => AppColors.warning,
        RepairStatus.waitingApproval => AppColors.warning,
        RepairStatus.waitingPart => const Color(0xFFB779FF),
        RepairStatus.repairing => AppColors.primary,
        RepairStatus.testing => const Color(0xFF62D0FF),
        RepairStatus.ready => AppColors.primary,
        RepairStatus.delivered => AppColors.primaryDark,
      };

  IconData get icon => switch (this) {
        RepairStatus.requestReceived => Icons.inbox_rounded,
        RepairStatus.diagnosing => Icons.search_rounded,
        RepairStatus.waitingApproval => Icons.schedule_rounded,
        RepairStatus.waitingPart => Icons.inventory_2_outlined,
        RepairStatus.repairing => Icons.build_rounded,
        RepairStatus.testing => Icons.science_outlined,
        RepairStatus.ready => Icons.verified_rounded,
        RepairStatus.delivered => Icons.done_all_rounded,
      };

  static RepairStatus fromName(String? value) {
    return RepairStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => RepairStatus.requestReceived,
    );
  }
}

class Repair {
  Repair({
    required this.trackingCode,
    required this.customerName,
    required this.phone,
    required this.brand,
    required this.model,
    required this.repairType,
    required this.problem,
    required this.status,
    required this.createdAt,
    required this.estimatedPrice,
  });

  final String trackingCode;
  final String customerName;
  final String phone;
  final String brand;
  final String model;
  final String repairType;
  final String problem;
  RepairStatus status;
  final DateTime createdAt;
  final double estimatedPrice;

  Map<String, dynamic> toFirestore() {
    return {
      'trackingCode': trackingCode,
      'customerName': customerName,
      'phone': phone,
      'brand': brand,
      'model': model,
      'repairType': repairType,
      'problem': problem,
      'status': status.name,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'estimatedPrice': estimatedPrice,
    };
  }

  factory Repair.fromFirestore(
    String documentId,
    Map<String, dynamic> data,
  ) {
    final rawCreatedAt = data['createdAt'];

    return Repair(
      trackingCode: (data['trackingCode'] as String?) ?? documentId,
      customerName: (data['customerName'] as String?) ?? '',
      phone: (data['phone'] as String?) ?? '',
      brand: (data['brand'] as String?) ?? '',
      model: (data['model'] as String?) ?? '',
      repairType: (data['repairType'] as String?) ?? '',
      problem: (data['problem'] as String?) ?? '',
      status: RepairStatusX.fromName(data['status'] as String?),
      createdAt: rawCreatedAt is Timestamp
          ? rawCreatedAt.toDate()
          : DateTime.now(),
      estimatedPrice: (data['estimatedPrice'] as num?)?.toDouble() ?? 0,
    );
  }
}
