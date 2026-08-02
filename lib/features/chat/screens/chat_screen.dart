import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';

import '../../../data/models/chat.dart';
import '../../../data/models/enums.dart';
import '../../../data/repositories/providers.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/image_network.dart';
import '../../../shared/widgets/photo_picker.dart';
import '../../../shared/widgets/report_dialog.dart';
import '../../../theme/app_colors.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/chat_controller.dart';

/// Loads the thread (by id or order id) so the chat can report the other
/// participant (D8).
final chatThreadProvider = FutureProvider.family<ChatThread, String>(
  (ref, threadId) async {
    final threads = await ref.watch(chatRepositoryProvider).threads();
    return threads.firstWhere(
      (t) => t.id == threadId || t.orderId == threadId,
      orElse: () => throw StateError('Thread not found: $threadId'),
    );
  },
);

/// One conversation: message bubbles, a text/image/voice composer and live
/// updates (CHAT-02/03).
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
  AudioPlayer? _player;
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
  }

  @override
  void dispose() {
    _composer.dispose();
    _scroll.dispose();
    _player?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatControllerProvider(widget.threadId));
    // React to live messages (scroll down) and send failures.
    ref.listen(chatControllerProvider(widget.threadId), (previous, next) {
      if (next.error != null && next.error != previous?.error && next.messages.isNotEmpty) {
        _showSnack('Could not send the message.');
      }
      if ((previous?.messages.length ?? 0) != next.messages.length) {
        _scrollToBottom();
      }
    });

    final currentUserId = ref.watch(authControllerProvider).valueOrNull?.user?.id;
    final otherParticipantId = _otherParticipantId(
      ref.watch(chatThreadProvider(widget.threadId)).valueOrNull,
      currentUserId,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
        actions: [
          if (otherParticipantId != null)
            IconButton(
              tooltip: 'Report',
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
          Expanded(child: _messages(state, currentUserId)),
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

  Widget _messages(ChatState state, String? currentUserId) {
    if (state.loading && state.messages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && state.messages.isEmpty) {
      return ErrorView(message: state.error!);
    }
    if (state.messages.isEmpty) {
      return const EmptyState(
        icon: Icons.chat_bubble_outline,
        title: 'No messages yet',
        message: 'Say hello to start the conversation.',
      );
    }
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.all(16),
      itemCount: state.messages.length,
      itemBuilder: (context, index) {
        final message = state.messages[index];
        return _MessageBubble(
          message: message,
          isMine: message.isMine(currentUserId ?? ''),
          onPlayVoice: () => _playVoice(message),
        );
      },
    );
  }

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
              tooltip: 'Attach image',
            ),
            Expanded(
              child: TextField(
                controller: _composer,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                decoration: const InputDecoration(
                  hintText: 'Message…',
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
              tooltip: _recording ? 'Stop & send voice note' : 'Record voice note',
            ),
            IconButton(
              icon: const Icon(Icons.send, color: AppColors.green),
              onPressed: state.sending ? null : _sendText,
              tooltip: 'Send',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendText() async {
    final text = _composer.text.trim();
    if (text.isEmpty) return;
    _composer.clear();
    await ref.read(chatControllerProvider(widget.threadId).notifier).sendText(text);
  }

  Future<void> _pickImage() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Attach an image', style: Theme.of(sheetContext).textTheme.titleMedium),
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
    try {
      if (!await _recorder.hasPermission()) {
        if (mounted) _showSnack('Microphone permission is required for voice notes.');
        return;
      }
      // dart:io system temp avoids a path_provider dependency for the mock.
      final path = '${Directory.systemTemp.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(const RecordConfig(), path: path);
      if (mounted) {
        setState(() {
          _recording = true;
          _recordingPath = path;
        });
      }
    } catch (_) {
      if (mounted) _showSnack('Could not start recording.');
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
        _showSnack('Could not finish the voice note.');
      }
    }
  }

  Future<void> _playVoice(ChatMessage message) async {
    final filePath = message.fileUrl;
    if (filePath == null || filePath.isEmpty) return;
    try {
      final player = AudioPlayer();
      await _player?.dispose();
      _player = player;
      await player.play(DeviceFileSource(filePath));
    } catch (_) {
      // Audio playback unavailable (e.g. tests / missing file) — ignore.
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMine;
  final VoidCallback onPlayVoice;

  const _MessageBubble({
    required this.message,
    required this.isMine,
    required this.onPlayVoice,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bubbleColor = isMine ? AppColors.green : AppColors.backgroundElevated;
    final textColor = isMine ? Colors.white : AppColors.ink;
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMine ? 16 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _content(context, theme, textColor),
            const SizedBox(height: 4),
            Text(
              _time(message.sentAt),
              style: theme.textTheme.labelSmall?.copyWith(
                color: isMine ? Colors.white70 : AppColors.tanDark,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content(BuildContext context, ThemeData theme, Color textColor) {
    switch (message.type) {
      case MessageType.image:
        return _ImageContent(message: message);
      case MessageType.voice:
        return InkWell(
          onTap: onPlayVoice,
          borderRadius: BorderRadius.circular(8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.play_circle_outline, color: textColor),
              const SizedBox(width: 8),
              Text('Voice note', style: theme.textTheme.bodyMedium?.copyWith(color: textColor)),
            ],
          ),
        );
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

class _ImageContent extends StatelessWidget {
  final ChatMessage message;

  const _ImageContent({required this.message});

  @override
  Widget build(BuildContext context) {
    final filePath = message.fileUrl;
    final isLocal = filePath != null &&
        (filePath.startsWith('/') || RegExp(r'^[A-Za-z]:').hasMatch(filePath));
    if (isLocal) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          File(filePath),
          width: 180,
          height: 140,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        ),
      );
    }
    return ImageNetwork(url: filePath, width: 180, height: 140, borderRadius: BorderRadius.circular(8));
  }
}
