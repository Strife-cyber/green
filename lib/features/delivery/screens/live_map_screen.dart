import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/app_colors.dart';
import '../controllers/delivery_tracking_controller.dart';
import '../widgets/live_delivery_map.dart';

/// Full-screen live map — watches the SAME
/// [deliveryTrackingControllerProvider] keyed by orderId, so it stays live
/// when pushed from the inline map card on [DeliveryTrackingScreen].
class LiveMapScreen extends ConsumerWidget {
  final String orderId;

  const LiveMapScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final request = DeliveryTrackingRequest(orderId: orderId);
    final state = ref.watch(deliveryTrackingControllerProvider(request));
    final delivery = state.delivery;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Live map'),
        leading: const BackButton(),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox.expand(
              child: delivery == null
                  ? const Center(child: CircularProgressIndicator())
                  : LiveDeliveryMap(delivery: delivery, height: double.infinity),
            ),
          ),
        ),
      ),
    );
  }
}
