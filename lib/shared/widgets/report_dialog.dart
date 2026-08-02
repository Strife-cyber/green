import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/enums.dart';
import '../../data/repositories/providers.dart';
import '../../data/repositories/report_repository.dart';

/// Flag reasons offered in the report dialog (D8 / ADM-07).
const kReportReasons = ['Spam', 'Harassment', 'Fraud', 'Scam', 'Other'];

/// Opens the report dialog and, on submit, files a report through
/// [ReportRepository]. Shows a success snackbar once submitted.
Future<void> showReportDialog(
  BuildContext context,
  WidgetRef ref, {
  required String reportedId,
  required ReportTargetType targetType,
  String? targetId,
}) async {
  final submitted = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => _ReportDialog(
      reportedId: reportedId,
      targetType: targetType,
      targetId: targetId,
    ),
  );
  if (submitted == true && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Report submitted. Our team will review it.')),
    );
  }
}

class _ReportDialog extends ConsumerStatefulWidget {
  final String reportedId;
  final ReportTargetType targetType;
  final String? targetId;

  const _ReportDialog({
    required this.reportedId,
    required this.targetType,
    this.targetId,
  });

  @override
  ConsumerState<_ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends ConsumerState<_ReportDialog> {
  String _reason = kReportReasons.first;
  final _details = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      await ref.read(reportRepositoryProvider).submit(ReportInput(
            reportedId: widget.reportedId,
            targetType: widget.targetType,
            targetId: widget.targetId,
            reason: _reason,
            details: _details.text.trim().isEmpty ? null : _details.text.trim(),
          ));
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not submit the report. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Report'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Tell us why this content is a problem.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _reason,
            decoration: const InputDecoration(labelText: 'Reason'),
            items: [
              for (final reason in kReportReasons)
                DropdownMenuItem(value: reason, child: Text(reason)),
            ],
            onChanged: (v) => setState(() => _reason = v ?? _reason),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _details,
            maxLines: 3,
            maxLength: 240,
            decoration: const InputDecoration(
              labelText: 'Details (optional)',
              alignLabelWithHint: true,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Submit report'),
        ),
      ],
    );
  }
}
