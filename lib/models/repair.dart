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

enum PaymentMethod {
  cash,
  card,
  transfer,
  other,
}

extension PaymentMethodX on PaymentMethod {
  String get label => switch (this) {
        PaymentMethod.cash => 'Nakit',
        PaymentMethod.card => 'Kart',
        PaymentMethod.transfer => 'Havale / EFT',
        PaymentMethod.other => 'Diğer',
      };

  IconData get icon => switch (this) {
        PaymentMethod.cash => Icons.payments_outlined,
        PaymentMethod.card => Icons.credit_card_rounded,
        PaymentMethod.transfer => Icons.account_balance_outlined,
        PaymentMethod.other => Icons.more_horiz_rounded,
      };

  static PaymentMethod fromName(String? value) {
    return PaymentMethod.values.firstWhere(
      (method) => method.name == value,
      orElse: () => PaymentMethod.other,
    );
  }
}

enum PaymentStatus {
  unpaid,
  partial,
  paid,
}

extension PaymentStatusX on PaymentStatus {
  String get label => switch (this) {
        PaymentStatus.unpaid => 'Ödenmedi',
        PaymentStatus.partial => 'Kısmi Ödendi',
        PaymentStatus.paid => 'Ödendi',
      };

  Color get color => switch (this) {
        PaymentStatus.unpaid => AppColors.warning,
        PaymentStatus.partial => AppColors.info,
        PaymentStatus.paid => AppColors.primary,
      };

  IconData get icon => switch (this) {
        PaymentStatus.unpaid => Icons.money_off_csred_outlined,
        PaymentStatus.partial => Icons.timelapse_rounded,
        PaymentStatus.paid => Icons.check_circle_outline_rounded,
      };
}

class RepairPayment {
  const RepairPayment({
    required this.id,
    required this.amount,
    required this.method,
    required this.paidAt,
  });

  final String id;
  final double amount;
  final PaymentMethod method;
  final DateTime paidAt;

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'amount': amount,
      'method': method.name,
      'paidAt': Timestamp.fromDate(paidAt),
    };
  }

  factory RepairPayment.fromFirestore(Map<String, dynamic> data) {
    final rawPaidAt = data['paidAt'];

    return RepairPayment(
      id: (data['id'] as String?) ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      method: PaymentMethodX.fromName(data['method'] as String?),
      paidAt: rawPaidAt is Timestamp
          ? rawPaidAt.toDate()
          : DateTime.fromMillisecondsSinceEpoch(0),
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
    required this.updatedAt,
    required this.estimatedPrice,
    required this.beforePhotoUrls,
    required this.afterPhotoUrls,
    this.payments = const [],
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
  final DateTime updatedAt;
  final double estimatedPrice;
  final List<String> beforePhotoUrls;
  final List<String> afterPhotoUrls;
  final List<RepairPayment> payments;

  double get paidAmount {
    return payments.fold<double>(
      0,
      (total, payment) => total + payment.amount,
    );
  }

  double get remainingAmount {
    final remaining = estimatedPrice - paidAmount;
    return remaining > 0 ? remaining : 0;
  }

  PaymentStatus get paymentStatus {
    if (estimatedPrice <= 0 || remainingAmount <= 0.01) {
      return PaymentStatus.paid;
    }

    if (paidAmount <= 0.01) {
      return PaymentStatus.unpaid;
    }

    return PaymentStatus.partial;
  }

  RepairPayment? get latestPayment {
    if (payments.isEmpty) {
      return null;
    }

    var latest = payments.first;

    for (final payment in payments.skip(1)) {
      if (payment.paidAt.isAfter(latest.paidAt)) {
        latest = payment;
      }
    }

    return latest;
  }

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
      'beforePhotoUrls': beforePhotoUrls,
      'afterPhotoUrls': afterPhotoUrls,
      'payments': payments
          .map((payment) => payment.toFirestore())
          .toList(growable: false),
    };
  }

  factory Repair.fromFirestore(
    String documentId,
    Map<String, dynamic> data,
  ) {
    final rawCreatedAt = data['createdAt'];
    final rawUpdatedAt = data['updatedAt'];
    final rawPayments = data['payments'];

    final createdAt =
        rawCreatedAt is Timestamp ? rawCreatedAt.toDate() : DateTime.now();

    final updatedAt =
        rawUpdatedAt is Timestamp ? rawUpdatedAt.toDate() : createdAt;

    final payments = rawPayments is List
        ? rawPayments
            .whereType<Map>()
            .map(
              (item) => RepairPayment.fromFirestore(
                Map<String, dynamic>.from(item),
              ),
            )
            .where((payment) => payment.amount > 0)
            .toList(growable: false)
        : const <RepairPayment>[];

    return Repair(
      trackingCode: (data['trackingCode'] as String?) ?? documentId,
      customerName: (data['customerName'] as String?) ?? '',
      phone: (data['phone'] as String?) ?? '',
      brand: (data['brand'] as String?) ?? '',
      model: (data['model'] as String?) ?? '',
      repairType: (data['repairType'] as String?) ?? '',
      problem: (data['problem'] as String?) ?? '',
      status: RepairStatusX.fromName(data['status'] as String?),
      createdAt: createdAt,
      updatedAt: updatedAt,
      estimatedPrice: (data['estimatedPrice'] as num?)?.toDouble() ?? 0,
      beforePhotoUrls: (data['beforePhotoUrls'] as List<dynamic>?)
              ?.whereType<String>()
              .toList() ??
          const [],
      afterPhotoUrls: (data['afterPhotoUrls'] as List<dynamic>?)
              ?.whereType<String>()
              .toList() ??
          const [],
      payments: payments,
    );
  }
}
