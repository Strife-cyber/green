import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:record/record.dart';

import '../../../core/network/media_url.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/money.dart';
import '../../../data/models/chat.dart';
import '../../../data/models/enums.dart';
import '../../../data/repositories/providers.dart';
import '../../../l10n/l10n.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/image_network.dart';
import '../../../shared/widgets/local_file_image.dart';
import '../../../shared/widgets/photo_picker.dart';
import '../../../shared/widgets/report_dialog.dart';
import '../../../theme/app_colors.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/chat_controller.dart';
import '../widgets/chat_admin_disclosure.dart';

/// Loads the thread (by id or order id) so the chat can report the other
/// participant and render the order-context header (D8).
final chatThreadProvider = FutureProvider.family<ChatThread, String>(
  (ref, threadId) async {
    final threads = await ref.watch(chatRepositoryProvider).threads();
    return threads.firstWhere(
      (t) => t.id == threadId || t.orderId == threadId,
      orElse: () => throw StateError('Thread not found: $threadId'),
    );
  },
);

/// One conversation: an order-context header, WhatsApp-style message bubbles,
/// live delivery ticks, a typing indicator, a text/image/voice composer and
/// realtime updates (CHAT-02/03).
class ChatScreen extends ConsumerStatefulWidget {
  final String threadId;

  const ChatScreen({super.key, required this.threadId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _composer = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final AudioRecorder _recorder = AudioRecorder();
  bool _recording = false;
  String? _recordingPath;

  @override
  void initState() {
    super.initState();
    // Mark the thread read as soon as it opens (CHAT-03).
    Future<void>.microtask(() {
      if (mounted) {
        ref.read(chatControllerProvider(widget.threadId).notifier).markRead();
      }
    });
    // Debounced typing indicator for the counterparty (CHAT-05).
    _composer.addListener(_onComposerChanged);
  }

  @override
  void dispose() {
    _composer.removeListener(_onComposerChanged);
    _composer.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onComposerChanged() {
    final notifier = ref.read(chatControllerProvider(widget.threadId).notifier);
    if (_composer.text.trim().isEmpty) {
      notifier.stopTyping();
    } else {
      notifier.notifyTyping();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatControllerProvider(widget.threadId));
    // React to live messages (scroll down), send failures and gateway errors.
    ref.listen(chatControllerProvider(widget.threadId), (previous, next) {
      if (next.error != null && next.error != previous?.error && next.messages.isNotEmpty) {
        _showSnack(context.t.chatSendFailed);
      }
      if (next.realtimeError != null && next.realtimeError != previous?.realtimeError) {
        _showSnack(next.realtimeError!);
      }
      if ((previous?.messages.length ?? 0) != next.messages.length) {
        _scrollToBottom(force: (previous?.messages.length ?? 0) == 0);
      }
    });

    final currentUserId = ref.watch(authControllerProvider).valueOrNull?.user?.id;
    final thread = ref.watch(chatThreadProvider(widget.threadId)).valueOrNull;
    final otherParticipantId = _otherParticipantId(thread, currentUserId);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Navigator.canPop(context) ? const BackButton() : null,
        title: Text(context.t.chatTitle),
        actions: [
          if (otherParticipantId != null)
            IconButton(
              tooltip: context.t.report,
              icon: const Icon(Icons.flag_outlined),
              onPressed: () => showReportDialog(
                context,
                ref,
                reportedId: otherParticipantId,
                targetType: ReportTargetType.chat,
                targetId: widget.threadId,
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          const ChatAdminDisclosure(),
          ?_orderHeader(thread),
          // WhatsApp-style light chat backdrop behind the message list.
          Expanded(
            child: Container(
              color: const Color(0xFFE8E2D4),
              child: _messages(state, currentUserId),
            ),
          ),
          _composerBar(state),
        ],
      ),
    );
  }

  /// The user on the other side of this thread, or null if unknown.
  String? _otherParticipantId(ChatThread? thread, String? currentUserId) {
    if (thread == null || currentUserId == null) return null;
    if (thread.buyerId != currentUserId) return thread.buyerId;
    if (thread.sellerId != currentUserId) return thread.sellerId;
    return thread.driverId;
  }

  /// The counterpart's display name (enriched `counterparty` first, legacy
  /// participants as fallback).
  String _counterpartName(ChatThread thread) {
    if (thread.counterpartyName != null) return thread.counterpartyName!;
    final currentUserId = ref.read(authControllerProvider).valueOrNull?.user?.id;
    if (currentUserId == null || currentUserId == thread.buyerId) {
      return thread.sellerName ?? context.t.roleSeller;
    }
    if (currentUserId == thread.sellerId) {
      return thread.buyerName ?? context.t.roleBuyer;
    }
    return thread.buyerName ?? thread.sellerName ?? context.t.chatTitle;
  }

  /// Tappable order-context strip above the messages: product preview, order
  /// status, farmer/seller name and total. Opens the order screen.
  Widget? _orderHeader(ChatThread? thread) {
    if (thread == null || thread.orderId.isEmpty) return null;
    final role = ref.read(authControllerProvider).valueOrNull?.user?.role;
    final product = thread.productPreview;
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: InkWell(
        onTap: () => _openOrder(thread, role),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              _ProductThumb(product: product),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _counterpartName(thread),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      product?.name ?? context.t.chatOrderContext,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.tanDark),
                    ),
                    if (thread.orderStatus != null || thread.orderTotal > 0) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (thread.orderStatus != null)
                            _OrderStatusPill(status: thread.orderStatus!),
                          if (thread.orderStatus != null && thread.orderTotal > 0)
                            const SizedBox(width: 8),
                          if (thread.orderTotal > 0)
                            Text(
                              formatMoney(thread.orderTotal),
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(color: AppColors.tanDark),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${context.t.orderPrefix}${orderReference(thread.orderId)}',
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: AppColors.tanDark),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: AppColors.tanDark),
            ],
          ),
        ),
      ),
    );
  }

  void _openOrder(ChatThread thread, UserRole? role) {
    switch (role) {
      case UserRole.buyer:
        context.push(AppRoutes.orderDetail(thread.orderId));
      case UserRole.seller:
        context.push(AppRoutes.sellerOrderDetail(thread.orderId));
      default:
        // Driver/admin have no order screen from here — ignore the tap.
        break;
    }
  }

  Widget _messages(ChatState state, String? currentUserId) {
    if (state.loading && state.messages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && state.messages.isEmpty) {
      return ErrorView(
        message: state.error!,
        onRetry: () => ref.read(chatControllerProvider(widget.threadId).notifier).refresh(),
      );
    }
    if (state.messages.isEmpty && !state.counterpartyTyping) {
      return EmptyState(
        icon: Icons.chat_bubble_outline,
        title: context.t.chatNoMessages,
        message: context.t.chatNoMessagesHint,
      );
    }
    final messages = state.messages;
    final showTyping = state.counterpartyTyping;
    return RefreshIndicator(
      onRefresh: () => ref.read(chatControllerProvider(widget.threadId).notifier).refresh(),
      child: ListView.builder(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: messages.length + (showTyping ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == messages.length) {
            return const _TypingBubble();
          }
          final message = messages[index];
          final showDivider =
              index == 0 || !_sameDay(messages[index - 1].sentAt, message.sentAt);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showDivider) _DayDivider(date: message.sentAt),
              _MessageBubble(
                message: message,
                isMine: message.isMine(currentUserId ?? ''),
                onRetry: () => ref
                    .read(chatControllerProvider(widget.threadId).notifier)
                    .retry(message),
              ),
            ],
          );
        },
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Widget _composerBar(ChatState state) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          border: Border(top: BorderSide(color: AppColors.tan.withValues(alpha: 0.4))),
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.attach_file, color: AppColors.tanDark),
              onPressed: () => _pickImage(),
              tooltip: context.t.chatAttachImage,
            ),
            Expanded(
              child: TextField(
                controller: _composer,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                decoration: InputDecoration(
                  hintText: context.t.chatComposerHint,
                  border: InputBorder.none,
                  filled: false,
                ),
                onSubmitted: (_) => _sendText(),
              ),
            ),
            IconButton(
              icon: Icon(
                _recording ? Icons.stop_circle : Icons.mic_none,
                color: _recording ? AppColors.orangeDark : AppColors.greenDark,
              ),
              onPressed: _recording ? _stopAndSendVoice : _startRecording,
              tooltip: _recording ? context.t.chatStopVoice : context.t.chatRecordVoice,
            ),
            IconButton(
              icon: const Icon(Icons.send, color: AppColors.green),
              onPressed: state.sending ? null : _sendText,
              tooltip: context.t.chatSend,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendText() async {
    final text = _composer.text.trim();
    if (text.isEmpty) return;
    // Optimistic: the pending bubble renders the message immediately, so the
    // composer is cleared right away — and restored only if the send failed,
    // so a draft is never silently lost (CHAT-04).
    _composer.clear();
    final sent =
        await ref.read(chatControllerProvider(widget.threadId).notifier).sendText(text);
    if (!mounted) return;
    if (!sent) _composer.text = text;
  }

  Future<void> _pickImage() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(context.t.chatAttachImage, style: Theme.of(sheetContext).textTheme.titleMedium),
            const SizedBox(height: 16),
            PhotoPicker(
              size: 120,
              onPicked: (path) => Navigator.of(sheetContext).pop(path),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (picked != null && mounted) {
      await ref.read(chatControllerProvider(widget.threadId).notifier).sendImage(picked);
    }
  }

  Future<void> _startRecording() async {
    // `record` ≥6 supports web via getUserMedia/MediaRecorder — the file
    // `path` is ignored there and `stop()` returns a blob URL that
    // `XFile.readAsBytes` can upload. On browsers without mic support we
    // degrade to the disabled-state snackbar instead of crashing.
    try {
      if (!await _recorder.hasPermission()) {
        if (mounted) {
          _showSnack(kIsWeb
              ? context.t.chatVoiceWebUnavailable
              : context.t.chatMicPermission);
        }
        return;
      }
      // dart:io system temp avoids a path_provider dependency; on web the
      // path is unused but must still be non-empty.
      final path = kIsWeb
          ? 'voice_${DateTime.now().millisecondsSinceEpoch}.m4a'
          : '${Directory.systemTemp.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: path,
      );
      if (mounted) {
        setState(() {
          _recording = true;
          _recordingPath = path;
        });
      }
    } catch (_) {
      if (mounted) _showSnack(context.t.chatRecordFailed);
    }
  }

  Future<void> _stopAndSendVoice() async {
    try {
      final path = await _recorder.stop() ?? _recordingPath;
      if (mounted) setState(() => _recording = false);
      if (path != null && path.isNotEmpty) {
        await ref.read(chatControllerProvider(widget.threadId).notifier).sendVoice(path);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _recording = false);
        _showSnack(context.t.chatVoiceFinishFailed);
      }
    }
  }

  /// Smoothly scrolls to the newest message. Without [force], only auto-scrolls
  /// when the user is already near the bottom so reading history isn't yanked.
  void _scrollToBottom({bool force = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final position = _scroll.position;
      if (!force && position.maxScrollExtent - position.pixels > 120) return;
      _scroll.animateTo(
        position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

/// Centered day/time separator between message groups (WhatsApp-style).
class _DayDivider extends StatelessWidget {
  final DateTime date;

  const _DayDivider({required this.date});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFE3DCCB),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _label(context),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.tanDark),
          ),
        ),
      ),
    );
  }

  String _label(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    final days = today.difference(day).inDays;
    if (days == 0) return context.t.chatToday;
    if (days == 1) return context.t.chatYesterday;
    return formatDate(date);
  }
}

/// Animated three-dot "typing…" bubble shown while the counterparty types.
class _TypingBubble extends StatefulWidget {
  const _TypingBubble();

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.backgroundElevated,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Semantics(
              label: context.t.chatTyping,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < 3; i++)
                    _TypingDot(controller: _controller, index: i),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingDot extends StatelessWidget {
  final Animation<double> controller;
  final int index;

  const _TypingDot({required this.controller, required this.index});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        // Stagger each dot so the three ripple left → right.
        final t = ((controller.value * 3 - index) / 3).clamp(0.0, 1.0);
        final opacity = 0.3 + 0.7 * t;
        final size = 6.0 + 4.0 * t;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Opacity(
            opacity: opacity,
            child: Container(
              width: size,
              height: size,
              decoration: const BoxDecoration(
                color: AppColors.tanDark,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMine;

  /// Re-sends a failed message (shown as a retry affordance on the bubble).
  final VoidCallback? onRetry;

  const _MessageBubble({
    required this.message,
    required this.isMine,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // WhatsApp-style: my bubbles are green-tinted, the other party's are cream.
    final bubbleColor = isMine ? AppColors.greenContainer : AppColors.backgroundElevated;
    final textColor = AppColors.ink;
    final timeColor = isMine ? const Color(0xFF4B5D46) : AppColors.tanDark;
    final state = message.deliveryState;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Row(
        mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: bubbleColor,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(12),
                      topRight: const Radius.circular(12),
                      bottomLeft: Radius.circular(isMine ? 12 : 2),
                      bottomRight: Radius.circular(isMine ? 2 : 12),
                    ),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 2, offset: const Offset(0, 1)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _content(context, theme, textColor),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_time(message.sentAt), style: theme.textTheme.labelSmall?.copyWith(fontSize: 10, color: timeColor)),
                          if (isMine) ...[
                            const SizedBox(width: 4),
                            if (state == MessageDeliveryState.failed && onRetry != null)
                              InkWell(
                                onTap: onRetry,
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.all(2),
                                  child: Icon(
                                    Icons.refresh,
                                    size: 14,
                                    color: const Color(0xFFB3261E),
                                  ),
                                ),
                              )
                            else
                              _DeliveryTick(state: state, color: timeColor),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // WhatsApp-style tail on the outer bottom corner.
                Positioned(
                  bottom: 0,
                  left: isMine ? null : -5,
                  right: isMine ? -5 : null,
                  child: Transform.rotate(
                    angle: isMine ? 0.785398 : -0.785398,
                    child: Container(width: 10, height: 10, color: bubbleColor),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _content(BuildContext context, ThemeData theme, Color textColor) {
    switch (message.type) {
      case MessageType.image:
        return _ImageContent(message: message);
      case MessageType.voice:
        return _VoiceBubble(message: message, textColor: textColor);
      case MessageType.text:
        return Text(
          message.content,
          style: theme.textTheme.bodyMedium?.copyWith(color: textColor),
        );
    }
  }

  String _time(DateTime time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

/// WhatsApp delivery tick driven by the message state: ✓ sent · ✓✓ delivered ·
/// ✓✓ read (blue). Pending messages show a clock until the server acks.
class _DeliveryTick extends StatelessWidget {
  final MessageDeliveryState state;
  final Color color;

  const _DeliveryTick({required this.state, required this.color});

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case MessageDeliveryState.pending:
        return Icon(Icons.schedule, size: 14, color: color.withValues(alpha: 0.6));
      case MessageDeliveryState.failed:
        return const SizedBox.shrink(); // the retry affordance covers this state
      case MessageDeliveryState.sent:
        return Icon(Icons.done, size: 14, color: color);
      case MessageDeliveryState.delivered:
        return Icon(Icons.done_all, size: 14, color: color);
      case MessageDeliveryState.read:
        return Icon(Icons.done_all, size: 14, color: const Color(0xFF1E6FEB));
    }
  }
}

/// Native-feeling voice bubble: play/pause toggle, a thin progress bar and the
/// duration. Each bubble owns its own player so playback state stays local.
class _VoiceBubble extends StatefulWidget {
  final ChatMessage message;
  final Color textColor;

  const _VoiceBubble({required this.message, required this.textColor});

  @override
  State<_VoiceBubble> createState() => _VoiceBubbleState();
}

class _VoiceBubbleState extends State<_VoiceBubble> {
  AudioPlayer? _player;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration>? _durationSub;
  StreamSubscription<void>? _completeSub;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _playing = false;

  @override
  void dispose() {
    _positionSub?.cancel();
    _durationSub?.cancel();
    _completeSub?.cancel();
    _player?.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    final source = _source();
    if (source == null) return;
    try {
      final player = _player ??= AudioPlayer();
      if (_positionSub == null) {
        _positionSub = player.onPositionChanged.listen((d) {
          if (mounted) setState(() => _position = d);
        });
        _durationSub = player.onDurationChanged.listen((d) {
          if (mounted) setState(() => _duration = d);
        });
        _completeSub = player.onPlayerComplete.listen((_) {
          if (mounted) {
            setState(() {
              _playing = false;
              _position = Duration.zero;
            });
          }
        });
      }
      if (_playing) {
        await player.pause();
      } else {
        await player.play(source);
      }
      if (mounted) setState(() => _playing = !_playing);
    } catch (_) {
      // Audio playback unavailable (e.g. missing file) — ignore.
    }
  }

  /// Voice files come back as relative paths (`/uploads/chat/…`) — resolve
  /// them to an absolute URL; pending messages still hold the local file path.
  Source? _source() {
    final fileUrl = widget.message.fileUrl;
    if (fileUrl == null || fileUrl.isEmpty) return null;
    return isLocalMediaPath(fileUrl)
        ? DeviceFileSource(fileUrl)
        : UrlSource(resolveMediaUrl(fileUrl));
  }

  String _durationLabel() {
    final total = _duration.inSeconds;
    if (total <= 0) return '';
    final m = (total ~/ 60).toString().padLeft(2, '0');
    final s = (total % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final progress = _duration.inMilliseconds > 0
        ? (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0)
        : null;
    return Semantics(
      label: context.t.chatVoiceNote,
      button: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: _toggle,
            borderRadius: BorderRadius.circular(16),
            child: Icon(
              _playing ? Icons.pause_circle_filled : Icons.play_circle_fill,
              size: 28,
              color: widget.textColor,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 110,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                backgroundColor: widget.textColor.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation<Color>(widget.textColor),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _durationLabel(),
            style: TextStyle(fontSize: 10, color: widget.textColor),
          ),
        ],
      ),
    );
  }
}

class _ImageContent extends StatelessWidget {
  final ChatMessage message;

  const _ImageContent({required this.message});

  @override
  Widget build(BuildContext context) {
    final filePath = message.fileUrl;
    if (filePath != null && isLocalMediaPath(filePath)) {
      // `Image.file` can't render blob URLs on web — LocalFileImage reads the
      // picked file's bytes cross-platform instead.
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: LocalFileImage(
          path: filePath,
          width: 180,
          height: 140,
          fit: BoxFit.cover,
        ),
      );
    }
    return ImageNetwork(url: filePath, width: 180, height: 140, borderRadius: BorderRadius.circular(8));
  }
}

/// Small tinted tag showing the order's live status on the order header.
class _OrderStatusPill extends StatelessWidget {
  final OrderStatus status;

  const _OrderStatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      OrderStatus.pending => context.t.orderStatusPending,
      OrderStatus.confirmed => context.t.orderStatusConfirmed,
      OrderStatus.shipped => context.t.orderStatusShipped,
      OrderStatus.delivered => context.t.orderStatusDelivered,
      OrderStatus.cancelled => context.t.orderStatusCancelled,
    };
    final color = switch (status) {
      OrderStatus.pending => AppColors.orange,
      OrderStatus.confirmed => const Color(0xFF4A7CBE),
      OrderStatus.shipped => AppColors.green,
      OrderStatus.delivered => AppColors.tanDark,
      OrderStatus.cancelled => const Color(0xFFB3261E),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// Product thumbnail for the order-context header, with a branded fallback.
class _ProductThumb extends StatelessWidget {
  final ChatThreadProductPreview? product;

  const _ProductThumb({this.product});

  @override
  Widget build(BuildContext context) {
    final url = product?.imageUrl;
    if (url != null && url.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: ImageNetwork(url: url, width: 44, height: 44, fit: BoxFit.cover),
      );
    }
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.greenContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.eco_outlined, color: AppColors.greenDark),
    );
  }
}
