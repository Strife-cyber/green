import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../data/models/chat.dart';
import '../../data/repositories/providers.dart';
import '../../l10n/l10n.dart';

/// Opens the chat thread for an order.
///
/// Thread ids are backend-generated and unrelated to order ids, so the real
/// thread is resolved from `GET /chat/threads` (matched by `orderId`) before
/// navigating. Falls back to a snackbar when no thread exists yet.
Future<void> openChatForOrder(
  BuildContext context,
  WidgetRef ref,
  String orderId,
) async {
  ChatThread? thread;
  try {
    thread = await ref.read(chatRepositoryProvider).threadForOrder(orderId);
  } catch (_) {
    thread = null;
  }
  if (!context.mounted) return;
  if (thread != null) {
    context.push(AppRoutes.chat(thread.id));
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.t.chatNoThreadForOrder)),
    );
  }
}
