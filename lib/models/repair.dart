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
}
