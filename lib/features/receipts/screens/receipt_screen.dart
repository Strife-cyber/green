import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/file_download.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/order.dart';
import '../../../data/models/receipt.dart';
import '../../../data/repositories/providers.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../shared/widgets/amount_text.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../theme/app_colors.dart';
import '../controllers/receipt_controller.dart';

/// Smart receipt for a completed order (REC-01..04): order summary, amount
/// breakdown, the GREENISH commission line. The PDF download is intentionally
/// disabled until the backend receipt service generates it (REC-04).
class ReceiptScreen extends ConsumerStatefulWidget {
  final String orderId;

  const ReceiptScreen({super.key, required this.orderId});

  @override
  ConsumerState<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends ConsumerState<ReceiptScreen> {
  bool _downloading = false;

  /// `GET /receipts/{id}/download` → save/share the PDF blob (REC-04).
  Future<void> _download(Receipt receipt) async {
    setState(() => _downloading = true);
    try {
      final bytes = await ref
          .read(receiptRepositoryProvider)
          .downloadPdfBytes(receipt.id);
      if (!mounted) return;
      if (bytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.t.receiptNotReady)),
        );
        return;
      }
      await downloadFile(
        bytes: Uint8List.fromList(bytes),
        filename: '${receipt.receiptNumber}.pdf',
        mimeType: 'application/pdf',
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.t.downloadFailed)),
        );
      }
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  /// Shares the PDF through the platform sheet (native) / downloads it (web).
  Future<void> _share(Receipt receipt) => _download(receipt);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final receipt = ref.watch(receiptControllerProvider(widget.orderId));
    final order = ref.watch(receiptOrderProvider(widget.orderId));

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Navigator.canPop(context) ? const BackButton() : null,
        title: const Text('Receipt')),
      body: AsyncView<Receipt>(
        value: receipt,
        onRetry: () => ref.invalidate(receiptControllerProvider(widget.orderId)),
        builder: (r) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _Header(receipt: r),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    order.when(
                      data: (o) => _OrderSummary(order: o),
                      loading: () => const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (_, _) => const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('Order details unavailable'),
                      ),
                    ),
                    const Divider(height: 24),
                    _AmountRow(label: 'Items', amount: r.amount - r.deliveryFee),
                    _AmountRow(label: 'Delivery fee', amount: r.deliveryFee),
                    _AmountRow(label: 'Total', amount: r.amount, emphasized: true),
                    const Divider(height: 24),
                    _AmountRow(label: 'GREENISH commission', amount: r.commission),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Issued ${formatDateTime(r.issuedAt)}',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(color: AppColors.tanDark),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed:
                  _downloading ? null : () => _download(r),
              icon: _downloading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.download_outlined),
              label: Text(context.t.downloadPdf),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _downloading ? null : () => _share(r),
              icon: const Icon(Icons.share_outlined),
              label: Text(context.t.shareReceipt),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final Receipt receipt;

  const _Header({required this.receipt});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(receipt.receiptNumber, style: theme.textTheme.titleLarge),
              Text('Receipt', style: theme.textTheme.bodySmall),
            ],
          ),
        ),
        StatusBadge(label: 'Issued', color: AppColors.green),
      ],
    );
  }
}

class _OrderSummary extends StatelessWidget {
  final Order order;

  const _OrderSummary({required this.order});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text('Order ${orderReference(order.id)}', style: theme.textTheme.titleMedium)),
            StatusBadge.order(order.status),
          ],
        ),
        const SizedBox(height: 8),
        _SummaryLine(label: 'Seller', value: order.sellerName ?? '—'),
        if (order.deliveryAddressLabel != null)
          _SummaryLine(label: 'Delivery to', value: order.deliveryAddressLabel!),
        if (order.placedAt != null)
          _SummaryLine(label: 'Placed', value: formatDateTime(order.placedAt!)),
      ],
    );
  }
}

class _SummaryLine extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label, style: theme.textTheme.bodySmall),
          ),
          Expanded(
            child: Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  final String label;
  final int amount;
  final bool emphasized;

  const _AmountRow({required this.label, required this.amount, this.emphasized = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = emphasized
        ? theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)
        : theme.textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium),
          AmountText(amount, style: style),
        ],
      ),
    );
  }
}
