import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/contract_model.dart';

class PdfService {
  /// Generate a PDF for [contract] and open the system share/print dialog.
  static Future<void> shareContractPdf(ContractModel contract) async {
    final bytes = await generateContractPdf(contract);
    final filename = 'contract_${contract.id.substring(0, 8)}.pdf';
    await Printing.sharePdf(bytes: bytes, filename: filename);
  }

  /// Generate raw PDF bytes for [contract].
  static Future<Uint8List> generateContractPdf(ContractModel contract) async {
    final pdf = pw.Document(
      title: _typeLabel(contract.type),
      author: 'Aqari',
    );

    pw.Font? base;
    pw.Font? bold;
    try {
      base = await PdfGoogleFonts.cairoRegular();
      bold = await PdfGoogleFonts.cairoBold();
    } catch (e) {
      debugPrint('[PdfService] font load failed: $e');
    }

    final theme = pw.ThemeData.withFont(
      base: base ?? pw.Font.helvetica(),
      bold: bold ?? pw.Font.helveticaBold(),
    );

    pdf.addPage(
      pw.MultiPage(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 44, vertical: 48),
        header: (ctx) => _header(contract),
        footer: (ctx) => _footer(ctx),
        build: (ctx) => [
          _titleSection(contract),
          pw.SizedBox(height: 18),
          _metaRow(contract),
          pw.SizedBox(height: 18),
          _partiesTable(contract),
          pw.SizedBox(height: 22),
          _contentSection(contract),
          if (_hasSignatures(contract)) ...[
            pw.SizedBox(height: 24),
            _signaturesSection(contract),
          ],
        ],
      ),
    );

    return pdf.save();
  }

  // ── Page header / footer ─────────────────────────────────────────────────

  static pw.Widget _header(ContractModel contract) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.grey300, width: 1),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'عقاري — Aqari',
            textDirection: pw.TextDirection.rtl,
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey600,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.Text(
            _typeLabel(contract.type),
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  static pw.Widget _footer(pw.Context ctx) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey300, width: 1),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            _fmtDate(DateTime.now()),
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey500),
          ),
          pw.Text(
            'Page ${ctx.pageNumber} / ${ctx.pagesCount}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey500),
          ),
        ],
      ),
    );
  }

  // ── Sections ──────────────────────────────────────────────────────────────

  static pw.Widget _titleSection(ContractModel contract) {
    final statusColor = _statusPdfColor(contract.status);
    return pw.Container(
      padding: const pw.EdgeInsets.all(18),
      decoration: pw.BoxDecoration(
        gradient: const pw.LinearGradient(
          colors: [PdfColor.fromInt(0xFF1E3A5F), PdfColor.fromInt(0xFF2E5077)],
          begin: pw.Alignment.topLeft,
          end: pw.Alignment.bottomRight,
        ),
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                _typeLabel(contract.type),
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                _typeArabicLabel(contract.type),
                textDirection: pw.TextDirection.rtl,
                style: const pw.TextStyle(fontSize: 13, color: PdfColor.fromInt(0xCCFFFFFF)),
              ),
            ],
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: pw.BoxDecoration(
              color: const PdfColor(1, 1, 1, 0.15),
              borderRadius: pw.BorderRadius.circular(20),
              border: pw.Border.all(color: const PdfColor(1, 1, 1, 0.3)),
            ),
            child: pw.Text(
              _statusLabel(contract.status),
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _metaRow(ContractModel contract) {
    final items = <Map<String, String>>[
      {'label': 'Amount', 'value': '${contract.dealAmount.toStringAsFixed(2)} TND'},
      if (contract.startDate != null)
        {'label': 'Start Date', 'value': _fmtDate(contract.startDate!)},
      if (contract.endDate != null)
        {'label': 'End Date', 'value': _fmtDate(contract.endDate!)},
      {'label': 'Created', 'value': _fmtDate(contract.createdAt)},
    ];

    return pw.Row(
      children: items
          .map(
            (item) => pw.Expanded(
              child: pw.Container(
                margin: const pw.EdgeInsets.only(right: 8),
                padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: pw.BoxDecoration(
                  color: const PdfColor.fromInt(0xFFF0F4FF),
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(color: const PdfColor.fromInt(0xFFD0DEFF)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      item['label']!,
                      style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      item['value']!,
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: const PdfColor.fromInt(0xFF1E3A5F),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  static pw.Widget _partiesTable(ContractModel contract) {
    final rows = <List<String>>[
      ['Owner / المالك', contract.ownerName],
      ['Tenant / المستأجر', contract.tenantName],
      if (contract.lawyerName.isNotEmpty && contract.lawyerName != '—')
        ['Lawyer / المحامي', contract.lawyerName],
      ['Property / العقار', contract.propertyAddress],
    ];

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionLabel('Parties / الأطراف'),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          columnWidths: {
            0: const pw.FlexColumnWidth(1),
            1: const pw.FlexColumnWidth(2),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFF5F7FA),
              ),
              children: [
                _cell('Role', bold: true),
                _cell('Name / الاسم', bold: true),
              ],
            ),
            ...rows.map(
              (r) => pw.TableRow(children: [
                _cell(r[0]),
                _cell(r[1], rtl: true),
              ]),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _contentSection(ContractModel contract) {
    if (contract.content.trim().isEmpty) return pw.SizedBox();
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionLabel('Contract Content / نص العقد'),
        pw.SizedBox(height: 10),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(14),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Text(
            contract.content,
            textDirection: pw.TextDirection.rtl,
            style: const pw.TextStyle(fontSize: 11, lineSpacing: 5),
          ),
        ),
      ],
    );
  }

  static pw.Widget _signaturesSection(ContractModel contract) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionLabel('Signatures / التوقيعات'),
        pw.SizedBox(height: 10),
        pw.Row(
          children: [
            _signatureBox('Owner / المالك', contract.ownerSignatureUrl != null),
            pw.SizedBox(width: 20),
            _signatureBox('Tenant / المستأجر', contract.tenantSignatureUrl != null),
            if (contract.lawyerSignatureUrl != null) ...[
              pw.SizedBox(width: 20),
              _signatureBox('Lawyer / المحامي', true),
            ],
          ],
        ),
      ],
    );
  }

  static pw.Widget _signatureBox(String label, bool signed) {
    return pw.Expanded(
      child: pw.Container(
        height: 70,
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
          borderRadius: pw.BorderRadius.circular(6),
          color: signed
              ? const PdfColor.fromInt(0xFFF0FFF4)
              : const PdfColor.fromInt(0xFFFAFAFB),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
            pw.Spacer(),
            pw.Row(
              children: [
                pw.Container(
                  width: 10, height: 10,
                  decoration: pw.BoxDecoration(
                    shape: pw.BoxShape.circle,
                    color: signed ? PdfColors.green600 : PdfColors.grey400,
                  ),
                ),
                pw.SizedBox(width: 6),
                pw.Text(
                  signed ? 'Signed' : 'Pending',
                  style: pw.TextStyle(
                    fontSize: 9,
                    color: signed ? PdfColors.green700 : PdfColors.grey500,
                    fontWeight: signed ? pw.FontWeight.bold : pw.FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  static pw.Widget _sectionLabel(String text) {
    return pw.Row(
      children: [
        pw.Container(
          width: 3, height: 16,
          decoration: pw.BoxDecoration(
            color: const PdfColor.fromInt(0xFF1E3A5F),
            borderRadius: pw.BorderRadius.circular(2),
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: 13,
            fontWeight: pw.FontWeight.bold,
            color: const PdfColor.fromInt(0xFF1E3A5F),
          ),
        ),
      ],
    );
  }

  static pw.Widget _cell(String text, {bool bold = false, bool rtl = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      child: pw.Text(
        text,
        textDirection: rtl ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        style: pw.TextStyle(
          fontSize: 11,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  static bool _hasSignatures(ContractModel c) =>
      c.ownerSignatureUrl != null ||
      c.tenantSignatureUrl != null ||
      c.lawyerSignatureUrl != null;

  static String _typeLabel(ContractType t) {
    switch (t) {
      case ContractType.rental:     return 'Rental Contract';
      case ContractType.sale:       return 'Sale Contract';
      case ContractType.rentalAnnex: return 'Rental Annex';
    }
  }

  static String _typeArabicLabel(ContractType t) {
    switch (t) {
      case ContractType.rental:     return 'عقد كراء محل معد للسكنى';
      case ContractType.sale:       return 'عقد بيع عقار';
      case ContractType.rentalAnnex: return 'ملحق عقد كراء';
    }
  }

  static String _statusLabel(ContractStatus s) {
    switch (s) {
      case ContractStatus.draft:             return 'Draft';
      case ContractStatus.pendingReview:     return 'Pending Review';
      case ContractStatus.pendingSignatures: return 'Pending Signatures';
      case ContractStatus.signedByOwner:     return 'Signed by Owner';
      case ContractStatus.signedByTenant:    return 'Signed by Tenant';
      case ContractStatus.completed:         return 'Completed';
      case ContractStatus.cancelled:         return 'Cancelled';
    }
  }

  static PdfColor _statusPdfColor(ContractStatus s) {
    switch (s) {
      case ContractStatus.draft:             return PdfColors.orange400;
      case ContractStatus.pendingReview:     return PdfColors.blue400;
      case ContractStatus.pendingSignatures: return PdfColors.orange600;
      case ContractStatus.signedByOwner:
      case ContractStatus.signedByTenant:    return PdfColors.indigo400;
      case ContractStatus.completed:         return PdfColors.green600;
      case ContractStatus.cancelled:         return PdfColors.red500;
    }
  }

  static String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
