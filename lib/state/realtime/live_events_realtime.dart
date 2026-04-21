import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/theme.dart';
import '../../generated/live_v1.pb.dart';
import '../auth/auth_controller.dart';
import '../betting/betting_controller.dart';
import '../feed/feed_controller.dart';

@immutable
class LiveProtoMetrics {
  final int decodeSuccessCount;
  final int decodeErrorCount;
  final int fallbackJsonCount;

  const LiveProtoMetrics({
    this.decodeSuccessCount = 0,
    this.decodeErrorCount = 0,
    this.fallbackJsonCount = 0,
  });

  LiveProtoMetrics copyWith({
    int? decodeSuccessCount,
    int? decodeErrorCount,
    int? fallbackJsonCount,
  }) {
    return LiveProtoMetrics(
      decodeSuccessCount: decodeSuccessCount ?? this.decodeSuccessCount,
      decodeErrorCount: decodeErrorCount ?? this.decodeErrorCount,
      fallbackJsonCount: fallbackJsonCount ?? this.fallbackJsonCount,
    );
  }
}

final liveProtoMetricsProvider =
    StateProvider<LiveProtoMetrics>((_) => const LiveProtoMetrics());

@immutable
class LiveProtoCircuitState {
  final bool isOpen;
  final int consecutiveDecodeErrors;
  final DateTime? openUntil;

  const LiveProtoCircuitState({
    this.isOpen = false,
    this.consecutiveDecodeErrors = 0,
    this.openUntil,
  });

  LiveProtoCircuitState copyWith({
    bool? isOpen,
    int? consecutiveDecodeErrors,
    DateTime? openUntil,
  }) {
    return LiveProtoCircuitState(
      isOpen: isOpen ?? this.isOpen,
      consecutiveDecodeErrors:
          consecutiveDecodeErrors ?? this.consecutiveDecodeErrors,
      openUntil: openUntil ?? this.openUntil,
    );
  }
}

final liveProtoCircuitProvider =
    StateProvider<LiveProtoCircuitState>((_) => const LiveProtoCircuitState());

final liveProtoOpsLogProvider =
    StateProvider<List<String>>((_) => const <String>[]);

/// Subscribes to protobuf broadcast events and maps them into app-level refresh actions.
///
/// Expected broadcast payload shape:
/// - `data_b64` or `payload_b64` (base64-encoded EventEnvelope bytes)
/// - or `bytes` as `List<int>`
final liveEventsRealtimeBootstrapProvider = Provider<void>((ref) {
  const int decodeErrorThreshold = 5;
  const Duration circuitOpenDuration = Duration(seconds: 30);

  final user = ref.watch(currentUserProvider);
  if (user == null) return;

  final client = ref.watch(supabaseClientProvider);
  final channelNames = <String>{
    // Legacy/user-scoped channel support.
    'live-events-${user.id}',
    // Worker default channel.
    'realtime/betting',
  };
  final channels = channelNames.map(client.channel).toList();
  Timer? bettingRefreshDebounce;
  Timer? feedRefreshDebounce;
  Timer? toastDebounce;
  Future<EventEnvelope> decodeInBackground(Uint8List bytes) {
    return Isolate.run(() => EventEnvelope.fromBuffer(bytes));
  }

  Uint8List? extractBytes(dynamic payload) {
    if (payload is! Map) return null;
    final map = Map<String, dynamic>.from(payload);
    final inner = map['payload'];
    final innerMap = inner is Map ? Map<String, dynamic>.from(inner) : const <String, dynamic>{};
    final b64 = (map['data_b64'] ??
            map['payload_b64'] ??
            map['b64'] ??
            innerMap['data_b64'] ??
            innerMap['payload_b64'] ??
            innerMap['b64'])
        as String?;
    if (b64 != null && b64.isNotEmpty) {
      try {
        return base64Decode(b64);
      } catch (_) {
        return null;
      }
    }

    final raw = map['bytes'];
    if (raw is List) {
      try {
        return Uint8List.fromList(raw.cast<int>());
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  Map<String, dynamic>? parseJsonFallback(dynamic payload) {
    if (payload is! Map) return null;
    final map = Map<String, dynamic>.from(payload);
    final dynamic raw = map['json_fallback'] ??
        (map['payload'] is Map
            ? Map<String, dynamic>.from(map['payload'])['json_fallback']
            : null);
    if (raw == null) return null;
    if (raw is Map<String, dynamic>) return raw;
    if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) return decoded;
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  void markDecodeSuccess() {
    final m = ref.read(liveProtoMetricsProvider);
    ref.read(liveProtoMetricsProvider.notifier).state = m.copyWith(
          decodeSuccessCount: m.decodeSuccessCount + 1,
        );
    ref.read(liveProtoCircuitProvider.notifier).state =
        const LiveProtoCircuitState();
  }

  void appendOpsLog(String message) {
    final now = DateTime.now().toIso8601String();
    final current = ref.read(liveProtoOpsLogProvider);
    final next = <String>['$now  $message', ...current];
    ref.read(liveProtoOpsLogProvider.notifier).state =
        next.take(30).toList(growable: false);
  }

  void markDecodeError() {
    final m = ref.read(liveProtoMetricsProvider);
    ref.read(liveProtoMetricsProvider.notifier).state = m.copyWith(
          decodeErrorCount: m.decodeErrorCount + 1,
        );
    final c = ref.read(liveProtoCircuitProvider);
    final nextErrors = c.consecutiveDecodeErrors + 1;
    if (nextErrors >= decodeErrorThreshold) {
      final until = DateTime.now().add(circuitOpenDuration);
      ref.read(liveProtoCircuitProvider.notifier).state = c.copyWith(
            isOpen: true,
            consecutiveDecodeErrors: nextErrors,
            openUntil: until,
          );
      if (kDebugMode) {
        debugPrint('[LiveProto] Circuit OPEN until $until');
      }
      appendOpsLog('Circuit OPEN (decode errors >= $decodeErrorThreshold)');
      return;
    }
    ref.read(liveProtoCircuitProvider.notifier).state = c.copyWith(
          consecutiveDecodeErrors: nextErrors,
        );
  }

  void markFallbackJson() {
    final m = ref.read(liveProtoMetricsProvider);
    ref.read(liveProtoMetricsProvider.notifier).state = m.copyWith(
          fallbackJsonCount: m.fallbackJsonCount + 1,
        );
  }

  void onEnvelope(EventEnvelope env) {
    if (kDebugMode) {
      toastDebounce?.cancel();
      toastDebounce = Timer(const Duration(milliseconds: 150), () {
        rootScaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 2),
            content: Text(
              'Live event received: ${env.whichPayload().name}',
            ),
          ),
        );
      });
    }

    if (kDebugMode) {
      debugPrint(
        '[LiveProto] source=${env.source} channel=${env.channel} seq=${env.seq}',
      );
    }

    switch (env.whichPayload()) {
      case EventEnvelope_Payload.socialPostCreated:
        // Debounce full feed reload so rapid events do not wipe in-flight optimistic likes.
        feedRefreshDebounce?.cancel();
        feedRefreshDebounce = Timer(const Duration(milliseconds: 650), () {
          ref.read(feedControllerProvider.notifier).loadPosts(refresh: true);
        });
        return;
      case EventEnvelope_Payload.socialGiftSent:
        final postId = env.socialGiftSent.postId;
        if (postId.isNotEmpty) {
          ref.read(feedControllerProvider.notifier).refreshPostGiftStats(postId);
        }
        return;
      case EventEnvelope_Payload.bettingBetPlaced:
      case EventEnvelope_Payload.bettingSettlementApplied:
        bettingRefreshDebounce?.cancel();
        bettingRefreshDebounce = Timer(const Duration(milliseconds: 500), () {
          ref.read(bettingControllerProvider.notifier).loadData();
        });
        return;
      case EventEnvelope_Payload.liveDrawStateUpdated:
      case EventEnvelope_Payload.liveOddsUpdated:
      case EventEnvelope_Payload.systemNotice:
      case EventEnvelope_Payload.heartbeat:
      case EventEnvelope_Payload.notSet:
        return;
    }
  }

  for (final channel in channels) {
    channel.onBroadcast(
      event: 'live_v1',
      callback: (payload) async {
        if (kDebugMode) {
          debugPrint('[LiveProto] raw broadcast payload=$payload');
        }
        final c = ref.read(liveProtoCircuitProvider);
        if (c.isOpen) {
          final now = DateTime.now();
          if (c.openUntil != null && now.isAfter(c.openUntil!)) {
            ref.read(liveProtoCircuitProvider.notifier).state =
                const LiveProtoCircuitState();
            if (kDebugMode) {
              debugPrint('[LiveProto] Circuit CLOSED (cooldown complete).');
            }
            appendOpsLog('Circuit CLOSED (cooldown complete)');
          } else {
            // Circuit is open: skip protobuf decode to protect UI thread and fallback path.
            final jsonFallback = parseJsonFallback(payload);
            if (jsonFallback != null) {
              markFallbackJson();
            }
            if (kDebugMode) {
              debugPrint('[LiveProto] Circuit OPEN, protobuf decode skipped.');
            }
            appendOpsLog('Circuit OPEN: protobuf decode skipped');
            return;
          }
        }
        final bytes = extractBytes(payload);
        if (bytes == null) {
          final jsonFallback = parseJsonFallback(payload);
          if (jsonFallback != null) {
            markFallbackJson();
            if (kDebugMode) {
              debugPrint('[LiveProto] JSON fallback used: $jsonFallback');
            }
            return;
          }
          if (kDebugMode) {
            debugPrint('[LiveProto] Ignored broadcast (no parseable protobuf bytes).');
          }
          return;
        }
        try {
          final env = await decodeInBackground(bytes);
          markDecodeSuccess();
          onEnvelope(env);
        } catch (e) {
          markDecodeError();
          if (kDebugMode) {
            debugPrint('[LiveProto] Decode failed: $e');
          }
        }
      },
    ).subscribe();
  }

  ref.onDispose(() {
    bettingRefreshDebounce?.cancel();
    feedRefreshDebounce?.cancel();
    toastDebounce?.cancel();
    for (final channel in channels) {
      client.removeChannel(channel);
    }
  });
});
