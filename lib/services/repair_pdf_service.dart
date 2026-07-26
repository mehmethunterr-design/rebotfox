import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/repair.dart';

class RepairPdfService {
  RepairPdfService._();

  static const String _companyName = 'Rebotfox Teknik Servis';
  static const String _logoAsset = 'assets/images/rebotfox_logo_round.png';

  static Future<Uint8List> buildServiceReceipt({
    required Repair repair,
    required PdfPageFormat pageFormat,
  }) async {
    final document = pw.Document(
      title: 'Servis Fişi - ${repair.trackingCode}',
      author: _companyName,
      creator: 'Rebotfox',
    );

    final resources = await _loadResources();
    final createdAt = DateTime.now();

    document.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        margin: const pw.EdgeInsets.all(32),
        theme: resources.theme,
        header: (context) => _pageHeader(
          resources: resources,
          documentTitle: 'SERVİS FİŞİ',
          trackingCode: repair.trackingCode,
        ),
        footer: (context) => _pageFooter(
          context: context,
          generatedAt: createdAt,
        ),
        build: (context) => [
          pw.SizedBox(height: 14),
          _trackingOverview(repair),
          pw.SizedBox(height: 18),
          _sectionTitle('Müşteri Bilgileri'),
          _informationTable(
            rows: [
              ['Müşteri', _safe(repair.customerName)],
              ['Telefon', _safe(repair.phone)],
              ['Takip Kodu', repair.trackingCode],
              ['Servise Giriş', _formatDateTime(repair.createdAt)],
            ],
          ),
          pw.SizedBox(height: 18),
          _sectionTitle('Cihaz ve Onarım Bilgileri'),
          _informationTable(
            rows: [
              ['Cihaz', '${_safe(repair.brand)} ${_safe(repair.model)}'],
              ['İşlem', _safe(repair.repairType)],
              ['Servis Durumu', repair.status.label],
              ['Son Güncelleme', _formatDateTime(repair.updatedAt)],
            ],
          ),
          pw.SizedBox(height: 12),
          _descriptionBox(
            title: 'Müşteri Arıza Bildirimi',
            value: _safe(
              repair.problem,
              emptyText: 'Arıza açıklaması girilmemiş.',
            ),
          ),
          pw.SizedBox(height: 18),
          _sectionTitle('Ücret ve Ödeme Bilgileri'),
          _priceSummary(repair),
          pw.SizedBox(height: 22),
          _noticeBox(
            'Bu belge cihazın teknik servise teslim edildiğini ve '
            'yukarıdaki bilgilerin kayıt altına alındığını gösterir. '
            'Takip kodunuzu cihaz teslim edilene kadar saklayınız.',
          ),
          pw.SizedBox(height: 34),
          _signatureArea(
            leftTitle: 'Müşteri İmzası',
            rightTitle: 'Servis Yetkilisi',
          ),
        ],
      ),
    );

    return document.save();
  }

  static Future<Uint8List> buildPaymentReceipt({
    required Repair repair,
    required PdfPageFormat pageFormat,
  }) async {
    if (repair.payments.isEmpty) {
      throw StateError(
        'Ödeme makbuzu oluşturmak için en az bir ödeme kaydı gerekir.',
      );
    }

    final payments = [...repair.payments]..sort(
        (first, second) => first.paidAt.compareTo(second.paidAt),
      );

    final document = pw.Document(
      title: 'Ödeme Makbuzu - ${repair.trackingCode}',
      author: _companyName,
      creator: 'Rebotfox',
    );

    final resources = await _loadResources();
    final createdAt = DateTime.now();

    document.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        margin: const pw.EdgeInsets.all(32),
        theme: resources.theme,
        header: (context) => _pageHeader(
          resources: resources,
          documentTitle: 'ÖDEME MAKBUZU',
          trackingCode: repair.trackingCode,
        ),
        footer: (context) => _pageFooter(
          context: context,
          generatedAt: createdAt,
        ),
        build: (context) => [
          pw.SizedBox(height: 14),
          _sectionTitle('Makbuz Bilgileri'),
          _informationTable(
            rows: [
              ['Müşteri', _safe(repair.customerName)],
              ['Telefon', _safe(repair.phone)],
              [
                'Cihaz',
                '${_safe(repair.brand)} ${_safe(repair.model)}',
              ],
              ['Takip Kodu', repair.trackingCode],
              ['İşlem', _safe(repair.repairType)],
            ],
          ),
          pw.SizedBox(height: 18),
          _sectionTitle('Ödeme Hareketleri'),
          _paymentTable(payments),
          pw.SizedBox(height: 18),
          _priceSummary(repair),
          pw.SizedBox(height: 22),
          _noticeBox(
            'Yukarıdaki ödemeler Rebotfox servis kaydına işlenmiştir. '
            'Bu belge ödeme bilgilerinin dökümüdür.',
          ),
          pw.SizedBox(height: 34),
          _signatureArea(
            leftTitle: 'Ödemeyi Yapan',
            rightTitle: 'Ödemeyi Alan',
          ),
        ],
      ),
    );

    return document.save();
  }

  static Future<_PdfResources> _loadResources() async {
    final logoData = await rootBundle.load(_logoAsset);
    final logo = pw.MemoryImage(
      logoData.buffer.asUint8List(),
    );

    pw.Font regularFont;
    pw.Font boldFont;

    try {
      regularFont = await PdfGoogleFonts.openSansRegular();
      boldFont = await PdfGoogleFonts.openSansBold();
    } catch (_) {
      regularFont = pw.Font.helvetica();
      boldFont = pw.Font.helveticaBold();
    }

    return _PdfResources(
      logo: logo,
      theme: pw.ThemeData.withFont(
        base: regularFont,
        bold: boldFont,
      ),
    );
  }

  static pw.Widget _pageHeader({
    required _PdfResources resources,
    required String documentTitle,
    required String trackingCode,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 12),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(
            color: PdfColors.grey400,
            width: 0.8,
          ),
        ),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Container(
            width: 54,
            height: 54,
            padding: const pw.EdgeInsets.all(5),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(12),
            ),
            child: pw.Image(
              resources.logo,
              fit: pw.BoxFit.contain,
            ),
          ),
          pw.SizedBox(width: 14),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  _companyName,
                  style: pw.TextStyle(
                    fontSize: 19,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.green800,
                  ),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  documentTitle,
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 1.1,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ),
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Takip Kodu',
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey600,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                trackingCode,
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _pageFooter({
    required pw.Context context,
    required DateTime generatedAt,
  }) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 14),
      padding: const pw.EdgeInsets.only(top: 9),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(
            color: PdfColors.grey300,
            width: 0.6,
          ),
        ),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Text(
              'Oluşturulma: ${_formatDateTime(generatedAt)}',
              style: const pw.TextStyle(
                fontSize: 8,
                color: PdfColors.grey600,
              ),
            ),
          ),
          pw.Text(
            'Sayfa ${context.pageNumber} / ${context.pagesCount}',
            style: const pw.TextStyle(
              fontSize: 8,
              color: PdfColors.grey600,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _trackingOverview(Repair repair) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.green50,
        borderRadius: pw.BorderRadius.circular(14),
        border: pw.Border.all(
          color: PdfColors.green200,
          width: 0.8,
        ),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.BarcodeWidget(
            barcode: pw.Barcode.qrCode(),
            data: repair.trackingCode,
            width: 82,
            height: 82,
          ),
          pw.SizedBox(width: 18),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  repair.trackingCode,
                  style: pw.TextStyle(
                    fontSize: 17,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.green900,
                  ),
                ),
                pw.SizedBox(height: 7),
                pw.Text(
                  '${_safe(repair.brand)} ${_safe(repair.model)}',
                  style: pw.TextStyle(
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  repair.repairType,
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.SizedBox(height: 8),
                _statusPill(
                  label: repair.status.label,
                  background: PdfColors.green100,
                  foreground: PdfColors.green900,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _sectionTitle(String title) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 12,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.green800,
        ),
      ),
    );
  }

  static pw.Widget _informationTable({
    required List<List<String>> rows,
  }) {
    return pw.Table(
      border: pw.TableBorder.all(
        color: PdfColors.grey300,
        width: 0.6,
      ),
      columnWidths: const {
        0: pw.FlexColumnWidth(1.25),
        1: pw.FlexColumnWidth(2.75),
      },
      children: [
        for (var index = 0; index < rows.length; index++)
          pw.TableRow(
            decoration: pw.BoxDecoration(
              color: index.isEven ? PdfColors.grey50 : PdfColors.white,
            ),
            children: [
              _tableCell(
                rows[index][0],
                bold: true,
                color: PdfColors.grey700,
              ),
              _tableCell(rows[index][1]),
            ],
          ),
      ],
    );
  }

  static pw.Widget _descriptionBox({
    required String title,
    required String value,
  }) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(13),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(
          color: PdfColors.grey300,
          width: 0.6,
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey700,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            value,
            style: const pw.TextStyle(
              fontSize: 10,
              lineSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _priceSummary(Repair repair) {
    final statusColor = switch (repair.paymentStatus) {
      PaymentStatus.paid => PdfColors.green800,
      PaymentStatus.partial => PdfColors.blue800,
      PaymentStatus.unpaid => PdfColors.orange800,
    };

    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(
          color: PdfColors.grey300,
          width: 0.7,
        ),
      ),
      child: pw.Column(
        children: [
          pw.Row(
            children: [
              pw.Expanded(
                child: _amountBlock(
                  label: 'Toplam Ücret',
                  value: _formatPrice(repair.estimatedPrice),
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Expanded(
                child: _amountBlock(
                  label: 'Tahsil Edilen',
                  value: _formatPrice(repair.paidAmount),
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Expanded(
                child: _amountBlock(
                  label: 'Kalan',
                  value: _formatPrice(repair.remainingAmount),
                  valueColor: repair.remainingAmount > 0
                      ? PdfColors.orange800
                      : PdfColors.green800,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            children: [
              pw.Text(
                'Ödeme Durumu:',
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey700,
                ),
              ),
              pw.SizedBox(width: 7),
              _statusPill(
                label: repair.paymentStatus.label,
                background: PdfColors.grey200,
                foreground: statusColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _paymentTable(
    List<RepairPayment> payments,
  ) {
    final rows = <pw.TableRow>[
      pw.TableRow(
        decoration: const pw.BoxDecoration(
          color: PdfColors.green800,
        ),
        children: [
          _tableCell(
            'Tarih',
            bold: true,
            color: PdfColors.white,
          ),
          _tableCell(
            'Yöntem',
            bold: true,
            color: PdfColors.white,
          ),
          _tableCell(
            'Tutar',
            bold: true,
            color: PdfColors.white,
            alignRight: true,
          ),
        ],
      ),
    ];

    for (var index = 0; index < payments.length; index++) {
      final payment = payments[index];

      rows.add(
        pw.TableRow(
          decoration: pw.BoxDecoration(
            color: index.isEven ? PdfColors.grey50 : PdfColors.white,
          ),
          children: [
            _tableCell(_formatDateTime(payment.paidAt)),
            _tableCell(payment.method.label),
            _tableCell(
              _formatPrice(payment.amount),
              bold: true,
              alignRight: true,
            ),
          ],
        ),
      );
    }

    return pw.Table(
      border: pw.TableBorder.all(
        color: PdfColors.grey300,
        width: 0.6,
      ),
      columnWidths: const {
        0: pw.FlexColumnWidth(1.5),
        1: pw.FlexColumnWidth(1.5),
        2: pw.FlexColumnWidth(1),
      },
      children: rows,
    );
  }

  static pw.Widget _tableCell(
    String value, {
    bool bold = false,
    PdfColor? color,
    bool alignRight = false,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 8,
      ),
      alignment:
          alignRight ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
      child: pw.Text(
        value,
        textAlign: alignRight ? pw.TextAlign.right : pw.TextAlign.left,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color,
        ),
      ),
    );
  }

  static pw.Widget _amountBlock({
    required String label,
    required String value,
    PdfColor? valueColor,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(
            fontSize: 8,
            color: PdfColors.grey600,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 13,
            fontWeight: pw.FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  static pw.Widget _statusPill({
    required String label,
    required PdfColor background,
    required PdfColor foreground,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: pw.BoxDecoration(
        color: background,
        borderRadius: pw.BorderRadius.circular(20),
      ),
      child: pw.Text(
        label,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
          color: foreground,
        ),
      ),
    );
  }

  static pw.Widget _noticeBox(String value) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.amber50,
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(
          color: PdfColors.amber300,
          width: 0.6,
        ),
      ),
      child: pw.Text(
        value,
        style: const pw.TextStyle(
          fontSize: 8,
          color: PdfColors.grey800,
          lineSpacing: 1.5,
        ),
      ),
    );
  }

  static pw.Widget _signatureArea({
    required String leftTitle,
    required String rightTitle,
  }) {
    pw.Widget signature(String title) {
      return pw.Expanded(
        child: pw.Column(
          children: [
            pw.Container(
              height: 40,
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(
                    color: PdfColors.grey500,
                    width: 0.7,
                  ),
                ),
              ),
            ),
            pw.SizedBox(height: 7),
            pw.Text(
              title,
              style: const pw.TextStyle(
                fontSize: 8,
                color: PdfColors.grey700,
              ),
            ),
          ],
        ),
      );
    }

    return pw.Row(
      children: [
        signature(leftTitle),
        pw.SizedBox(width: 36),
        signature(rightTitle),
      ],
    );
  }

  static String _safe(
    String value, {
    String emptyText = '-',
  }) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? emptyText : trimmed;
  }

  static String _formatPrice(double value) {
    final hasDecimals = value.truncateToDouble() != value;
    final raw = value.toStringAsFixed(hasDecimals ? 2 : 0);
    final parts = raw.split('.');

    final formattedWhole = parts.first.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    );

    if (parts.length == 1) {
      return '$formattedWhole TL';
    }

    return '$formattedWhole,${parts[1]} TL';
  }

  static String _formatDateTime(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$day.$month.${date.year} $hour:$minute';
  }
}

class _PdfResources {
  const _PdfResources({
    required this.logo,
    required this.theme,
  });

  final pw.MemoryImage logo;
  final pw.ThemeData theme;
}
