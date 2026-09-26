import 'package:flutter/widgets.dart';

import '../../data/models/enums.dart';
import '../../l10n/l10n_ext.dart';

/// The single status → plain-language mapper used everywhere an order's state
/// is shown (buyer detail/list, seller queue, driver card). The internal
/// enum values never change — only this mapping and its i18n keys do.
///
/// SHIPPED can carry the driver's estimated arrival time when the delivery
/// payload exposes one (`estimatedArrivalAt`); otherwise it reads as "On the
/// way" on its own.
String orderStatusPhrase(
  BuildContext context,
  OrderStatus status, {
  DateTime? estimatedArrivalAt,
}) {
  final t = context.t;
  switch (status) {
    case OrderStatus.pending:
      return t.orderPlaced;
    case OrderStatus.confirmed:
      return t.orderPreparing;
    case OrderStatus.shipped:
      final eta = estimatedArrivalAt;
      if (eta == null) return t.orderStatusShipped;
      return '${t.orderStatusShipped} · ${t.arrivingAt(time: _hhmm(eta))}';
    case OrderStatus.delivered:
      return t.orderStatusDelivered;
    case OrderStatus.cancelled:
      return t.orderStatusCancelled;
  }
}

String _hhmm(DateTime time) {
  final h = time.hour.toString().padLeft(2, '0');
  final m = time.minute.toString().padLeft(2, '0');
  return '$h:$m';
}
