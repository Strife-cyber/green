import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/utils/file_download.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/money.dart';
import '../../../data/models/receipt.dart';
import '../../../data/repositories/providers.dart';
import '../../../l10n/l10n_ext.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/refreshable_async_view.dart';
import '../../../theme/app_colors.dart';

/// Admin receipt copies (`GET /receipts/me`, REC-03) — every issued receipt
/// lands in the admin mailbox; each row offers view + PDF download.
final _adminReceiptsProvider = FutureProvider.autoDispose<List<Receipt>>(
  (ref) => ref.watch(receiptRepositoryProvider).mine(),
);

class AdminReceiptsScreen extends ConsumerWidget {
  const AdminReceiptsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receipts = ref.watch(_adminReceiptsProvider);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Navigator.canPop(context) ? const BackButton() : null,
        title: Text(context.t.receiptsTitle),
      ),
      body: RefreshableAsyncView<List<Receipt>>(
        value: receipts,
        onRefresh: () async => ref.invalidate(_adminReceiptsProvider),
        onRetry: () => ref.invalidate(_adminReceiptsProvider),
        empty: EmptyState(
          icon: Icons.receipt_long_outlined,
          title: context.t.noReceiptsTitle,
          message: context.t.noReceiptsBody,
        ),
        builder: (list) => ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) => _ReceiptTile(receipt: list[index]),
        ),
      ),
    );
  }
}

class _ReceiptTile extends ConsumerStatefulWidget {
  final Receipt receipt;

  const _ReceiptTile({required this.receipt});

  @override
  ConsumerState<_ReceiptTile> createState() => _ReceiptTileState();
}

class _ReceiptTileState extends ConsumerState<_ReceiptTile> {
  bool _downloading = false;

  Future<void> _download() async {
    setState(() => _downloading = true);
    try {
      final bytes = await ref
          .read(receiptRepositoryProvider)
          .downloadPdfBytes(widget.receipt.id);
      if (!mounted) return;
      if (bytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.t.receiptNotReady)),
        );
        return;
      }
      await downloadFile(
        bytes: Uint8List.fromList(bytes),
        filename: '${widget.receipt.receiptNumber}.pdf',
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final r = widget.receipt;
    return Card(
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: AppColors.greenPale,
          child: Icon(Icons.receipt_long_outlined, color: AppColors.greenDark),
        ),
        title: Text(r.receiptNumber, style: theme.textTheme.titleSmall),
        subtitle: Text(
          '${context.t.orderPrefix}${orderReference(r.orderId)} · '
          '${formatMoney(r.amount)} · ${formatDate(r.issuedAt)}',
          style: theme.textTheme.bodySmall?.copyWith(color: AppColors.tanDark),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: context.t.view,
              icon: const Icon(Icons.open_in_new, size: 20),
              onPressed: () => context.push(AppRoutes.receipt(r.orderId)),
            ),
            IconButton(
              tooltip: context.t.downloadPdf,
              icon: _downloading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download_outlined, size: 20),
              onPressed: _downloading ? null : _download,
            ),
          ],
        ),
      ),
    );
  }
}
