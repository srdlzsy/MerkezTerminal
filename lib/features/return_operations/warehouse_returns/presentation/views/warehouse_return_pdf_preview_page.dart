import 'package:flutter/material.dart';
import 'package:furpa_merkez_terminal/features/return_operations/warehouse_returns/data/models/warehouse_return_models.dart';
import 'package:printing/printing.dart';

class WarehouseReturnPdfPreviewPage extends StatelessWidget {
  const WarehouseReturnPdfPreviewPage({
    super.key,
    required this.documentNoLabel,
    required this.document,
  });

  final String documentNoLabel;
  final WarehouseReturnPdfDocument document;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('PDF - $documentNoLabel'),
      ),
      body: PdfPreview(
        pdfFileName: document.fileName,
        build: (_) => document.bytes,
        allowPrinting: false,
        allowSharing: false,
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false,
        loadingWidget: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}
