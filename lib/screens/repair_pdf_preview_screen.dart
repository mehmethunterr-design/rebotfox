import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../models/repair.dart';
import '../services/repair_pdf_service.dart';

enum RepairDocumentType {
  serviceReceipt,
  paymentReceipt,
}

extension RepairDocumentTypeX on RepairDocumentType {
  String get title => switch (this) {
        RepairDocumentType.serviceReceipt => 'Servis Fişi',
        RepairDocumentType.paymentReceipt => 'Ödeme Makbuzu',
      };

  String fileName(String trackingCode) {
    final safeCode = trackingCode.replaceAll(
      RegExp(r'[^A-Za-z0-9_-]'),
      '_',
    );

    return switch (this) {
      RepairDocumentType.serviceReceipt => 'rebotfox_servis_fisi_$safeCode.pdf',
      RepairDocumentType.paymentReceipt =>
        'rebotfox_odeme_makbuzu_$safeCode.pdf',
    };
  }
}

class RepairPdfPreviewScreen extends StatelessWidget {
  const RepairPdfPreviewScreen({
    required this.repair,
    required this.documentType,
    super.key,
  });

  final Repair repair;
  final RepairDocumentType documentType;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(documentType.title),
      ),
      body: PdfPreview(
        initialPageFormat: PdfPageFormat.a4,
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false,
        allowPrinting: true,
        allowSharing: true,
        pdfFileName: documentType.fileName(
          repair.trackingCode,
        ),
        shareActionExtraSubject:
            '${documentType.title} - ${repair.trackingCode}',
        shareActionExtraBody: 'Rebotfox ${documentType.title.toLowerCase()}',
        loadingWidget: const Center(
          child: CircularProgressIndicator(),
        ),
        onError: (context, error) {
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.picture_as_pdf_outlined,
                    size: 56,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'PDF oluşturulamadı',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$error',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
        build: _buildDocument,
      ),
    );
  }

  Future<Uint8List> _buildDocument(
    PdfPageFormat pageFormat,
  ) {
    return switch (documentType) {
      RepairDocumentType.serviceReceipt => RepairPdfService.buildServiceReceipt(
          repair: repair,
          pageFormat: pageFormat,
        ),
      RepairDocumentType.paymentReceipt => RepairPdfService.buildPaymentReceipt(
          repair: repair,
          pageFormat: pageFormat,
        ),
    };
  }
}
