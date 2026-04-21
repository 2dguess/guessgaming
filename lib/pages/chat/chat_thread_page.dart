import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../config/theme.dart' show AppTheme, rootScaffoldMessengerKey;
import '../../state/auth/auth_controller.dart';
import '../../state/chat/dm_controller.dart';

class ChatThreadPage extends ConsumerStatefulWidget {
  final String threadId;
  final String peerTitle;

  const ChatThreadPage({
    super.key,
    required this.threadId,
    this.peerTitle = 'Chat',
  });

  @override
  ConsumerState<ChatThreadPage> createState() => _ChatThreadPageState();
}

class _ChatThreadPageState extends ConsumerState<ChatThreadPage> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  bool _sending = false;
  Timer? _markReadDebounce;

  /// Short time next to message text (saves vertical space vs full line).
  static final _compactTimeFmt = DateFormat('HH:mm');

  @override
  void dispose() {
    _markReadDebounce?.cancel();
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scheduleMarkRead() {
    _markReadDebounce?.cancel();
    _markReadDebounce = Timer(const Duration(milliseconds: 400), () async {
      if (!mounted) return;
      await ref.read(dmRepositoryProvider).markThreadRead(widget.threadId);
      if (!mounted) return;
      ref.invalidate(dmUnreadConversationsCountProvider);
      ref.invalidate(dmThreadListProvider);
      ref.invalidate(dmThreadReadStateProvider(widget.threadId));
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    final me = ref.read(currentUserProvider)?.id;
    if (me == null) return;

    setState(() => _sending = true);
    try {
      await ref.read(dmRepositoryProvider).sendMessage(
            threadId: widget.threadId,
            senderId: me,
            body: text,
          );
      _controller.clear();
      ref.invalidate(dmMessagesProvider(widget.threadId));
      ref.invalidate(dmThreadListProvider);
      _scheduleMarkRead();
      await Future.delayed(const Duration(milliseconds: 100));
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    } catch (e) {
      rootScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('Send failed: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(currentUserProvider)?.id;
    ref.watch(dmInboxRealtimeBootstrapProvider);

    ref.listen(
      dmMessagesProvider(widget.threadId),
      (_, __) => _scheduleMarkRead(),
    );

    final messagesAsync = ref.watch(dmMessagesProvider(widget.threadId));
    final readAsync = ref.watch(dmThreadReadStateProvider(widget.threadId));

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        title: Text(widget.peerTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFF8FAFC),
              Color.lerp(
                    AppTheme.primaryLight,
                    Colors.white,
                    0.88,
                  ) ??
                  AppTheme.backgroundColor,
              Color.lerp(
                    AppTheme.accentColor,
                    const Color(0xFFF0FDFA),
                    0.85,
                  ) ??
                  const Color(0xFFF0FDFA),
            ],
            stops: const [0.0, 0.55, 1.0],
          ),
        ),
        child: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              data: (msgs) {
                final peerRead = readAsync.maybeWhen(
                  data: (s) => s?.peerLastReadAtFor(me ?? ''),
                  orElse: () => null,
                );

                if (msgs.isEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _scheduleMarkRead();
                  });
                  return Center(
                    child: Text(
                      'No messages yet.\nSend the first one below.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                  );
                }

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scroll.hasClients) {
                    _scroll.jumpTo(_scroll.position.maxScrollExtent);
                  }
                  _scheduleMarkRead();
                });

                return ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.all(AppTheme.paddingL),
                  itemCount: msgs.length,
                  itemBuilder: (context, i) {
                    final m = msgs[i];
                    final mine = m.senderId == me;
                    final seen = mine &&
                        peerRead != null &&
                        !m.createdAt.toUtc().isAfter(peerRead.toUtc());

                    final maxBubbleW =
                        MediaQuery.sizeOf(context).width * 0.82;
                    final bodyStyle = TextStyle(
                      color: mine ? Colors.white : AppTheme.textPrimary,
                    );
                    final timeStyle = TextStyle(
                      fontSize: 10,
                      height: 1.15,
                      color: mine ? Colors.white60 : AppTheme.textSecondary,
                    );

                    return Align(
                      alignment:
                          mine ? Alignment.centerRight : Alignment.centerLeft,
                      child: Card(
                        elevation: 1,
                        margin: const EdgeInsets.only(bottom: AppTheme.paddingM),
                        color: mine
                            ? AppTheme.primaryColor
                            : AppTheme.backgroundColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusM),
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: maxBubbleW),
                          child: IntrinsicWidth(
                            child: Padding(
                              padding: const EdgeInsets.all(AppTheme.paddingM),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: mine
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment.start,
                                children: [
                                  Text.rich(
                                    TextSpan(
                                      style: bodyStyle,
                                      children: [
                                        TextSpan(text: m.body),
                                        TextSpan(
                                          text:
                                              '  ${_compactTimeFmt.format(m.createdAt.toLocal())}',
                                          style: timeStyle,
                                        ),
                                      ],
                                    ),
                                    textAlign: mine
                                        ? TextAlign.end
                                        : TextAlign.start,
                                    textWidthBasis:
                                        TextWidthBasis.longestLine,
                                  ),
                                if (mine)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Icon(
                                          seen ? Icons.done_all : Icons.check,
                                          size: 12,
                                          color: seen
                                              ? Colors.lightBlueAccent
                                              : Colors.white60,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          seen ? 'Seen' : 'Sent',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.white60,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Align(
                                    alignment: mine
                                        ? Alignment.centerRight
                                        : Alignment.centerLeft,
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: me == null
                                            ? null
                                            : () async {
                                                try {
                                                  await ref
                                                      .read(
                                                          dmRepositoryProvider)
                                                      .toggleDmMessageLike(
                                                        messageId: m.id,
                                                        userId: me,
                                                      );
                                                  if (!context.mounted) {
                                                    return;
                                                  }
                                                  ref.invalidate(
                                                    dmMessagesProvider(
                                                      widget.threadId,
                                                    ),
                                                  );
                                                } catch (e) {
                                                  rootScaffoldMessengerKey
                                                      .currentState
                                                      ?.showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        'Like failed: $e',
                                                      ),
                                                      backgroundColor:
                                                          AppTheme.errorColor,
                                                    ),
                                                  );
                                                }
                                              },
                                        borderRadius: BorderRadius.circular(8),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                            vertical: 2,
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                m.likedByMe
                                                    ? Icons.favorite
                                                    : Icons.favorite_border,
                                                size: 16,
                                                color: m.likedByMe
                                                    ? AppTheme.likeColor
                                                    : (mine
                                                        ? Colors.white54
                                                        : AppTheme
                                                            .textSecondary),
                                              ),
                                              if (m.likesCount > 0) ...[
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${m.likesCount}',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color: mine
                                                        ? Colors.white70
                                                        : AppTheme
                                                            .textSecondary,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.94),
                  Color.lerp(
                        AppTheme.primaryLight,
                        Colors.white,
                        0.75,
                      ) ??
                      Colors.white,
                  AppTheme.accentColor.withValues(alpha: 0.06),
                ],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(22),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryDark.withValues(alpha: 0.10),
                  blurRadius: 20,
                  offset: const Offset(0, -6),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, -2),
                ),
              ],
              border: Border(
                top: BorderSide(
                  color: AppTheme.primaryLight.withValues(alpha: 0.35),
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.paddingM,
                  AppTheme.paddingM,
                  AppTheme.paddingM,
                  AppTheme.paddingL,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusXL),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withValues(alpha: 0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                          border: Border.all(
                            color: AppTheme.primaryLight.withValues(alpha: 0.25),
                          ),
                        ),
                        child: TextField(
                          controller: _controller,
                          minLines: 1,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: 'Message…',
                            filled: true,
                            fillColor: Colors.transparent,
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusXL),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.paddingM,
                              vertical: AppTheme.paddingS,
                            ),
                          ),
                          textCapitalization: TextCapitalization.sentences,
                          onSubmitted: (_) => _send(),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTheme.paddingS),
                    IconButton.filled(
                      style: IconButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shadowColor:
                            AppTheme.primaryDark.withValues(alpha: 0.35),
                      ),
                      onPressed: _sending ? null : _send,
                      icon: _sending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send_rounded),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}
