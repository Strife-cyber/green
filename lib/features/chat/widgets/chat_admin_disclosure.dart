import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../../theme/app_colors.dart';

/// CHAT-03 transparency line: "Greenish admins can read order chats if a
/// dispute is opened." Shown under the thread list and inside each thread.
class ChatAdminDisclosure extends StatelessWidget {
  const ChatAdminDisclosure({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.tan.withValues(alpha: 0.2),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.shield_outlined,
              size: 14, color: AppColors.tanDark),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              context.t.chatAdminDisclosure,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.tanDark),
            ),
          ),
        ],
      ),
    );
  }
}
