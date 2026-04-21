// This is a generated file - do not edit.
//
// Generated from live_v1.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports
// ignore_for_file: unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use eventEnvelopeDescriptor instead')
const EventEnvelope$json = {
  '1': 'EventEnvelope',
  '2': [
    {'1': 'event_id', '3': 1, '4': 1, '5': 9, '10': 'eventId'},
    {'1': 'server_ts_ms', '3': 2, '4': 1, '5': 3, '10': 'serverTsMs'},
    {'1': 'source', '3': 3, '4': 1, '5': 9, '10': 'source'},
    {'1': 'channel', '3': 4, '4': 1, '5': 9, '10': 'channel'},
    {'1': 'seq', '3': 5, '4': 1, '5': 3, '10': 'seq'},
    {
      '1': 'social_post_created',
      '3': 10,
      '4': 1,
      '5': 11,
      '6': '.gmaing.events.v1.SocialPostCreated',
      '9': 0,
      '10': 'socialPostCreated'
    },
    {
      '1': 'social_gift_sent',
      '3': 11,
      '4': 1,
      '5': 11,
      '6': '.gmaing.events.v1.SocialGiftSent',
      '9': 0,
      '10': 'socialGiftSent'
    },
    {
      '1': 'live_draw_state_updated',
      '3': 12,
      '4': 1,
      '5': 11,
      '6': '.gmaing.events.v1.LiveDrawStateUpdated',
      '9': 0,
      '10': 'liveDrawStateUpdated'
    },
    {
      '1': 'live_odds_updated',
      '3': 13,
      '4': 1,
      '5': 11,
      '6': '.gmaing.events.v1.LiveOddsUpdated',
      '9': 0,
      '10': 'liveOddsUpdated'
    },
    {
      '1': 'betting_bet_placed',
      '3': 14,
      '4': 1,
      '5': 11,
      '6': '.gmaing.events.v1.BettingBetPlaced',
      '9': 0,
      '10': 'bettingBetPlaced'
    },
    {
      '1': 'betting_settlement_applied',
      '3': 15,
      '4': 1,
      '5': 11,
      '6': '.gmaing.events.v1.BettingSettlementApplied',
      '9': 0,
      '10': 'bettingSettlementApplied'
    },
    {
      '1': 'system_notice',
      '3': 16,
      '4': 1,
      '5': 11,
      '6': '.gmaing.events.v1.SystemNotice',
      '9': 0,
      '10': 'systemNotice'
    },
    {
      '1': 'heartbeat',
      '3': 17,
      '4': 1,
      '5': 11,
      '6': '.gmaing.events.v1.Heartbeat',
      '9': 0,
      '10': 'heartbeat'
    },
  ],
  '8': [
    {'1': 'payload'},
  ],
};

/// Descriptor for `EventEnvelope`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List eventEnvelopeDescriptor = $convert.base64Decode(
    'Cg1FdmVudEVudmVsb3BlEhkKCGV2ZW50X2lkGAEgASgJUgdldmVudElkEiAKDHNlcnZlcl90c1'
    '9tcxgCIAEoA1IKc2VydmVyVHNNcxIWCgZzb3VyY2UYAyABKAlSBnNvdXJjZRIYCgdjaGFubmVs'
    'GAQgASgJUgdjaGFubmVsEhAKA3NlcRgFIAEoA1IDc2VxElUKE3NvY2lhbF9wb3N0X2NyZWF0ZW'
    'QYCiABKAsyIy5nbWFpbmcuZXZlbnRzLnYxLlNvY2lhbFBvc3RDcmVhdGVkSABSEXNvY2lhbFBv'
    'c3RDcmVhdGVkEkwKEHNvY2lhbF9naWZ0X3NlbnQYCyABKAsyIC5nbWFpbmcuZXZlbnRzLnYxLl'
    'NvY2lhbEdpZnRTZW50SABSDnNvY2lhbEdpZnRTZW50El8KF2xpdmVfZHJhd19zdGF0ZV91cGRh'
    'dGVkGAwgASgLMiYuZ21haW5nLmV2ZW50cy52MS5MaXZlRHJhd1N0YXRlVXBkYXRlZEgAUhRsaX'
    'ZlRHJhd1N0YXRlVXBkYXRlZBJPChFsaXZlX29kZHNfdXBkYXRlZBgNIAEoCzIhLmdtYWluZy5l'
    'dmVudHMudjEuTGl2ZU9kZHNVcGRhdGVkSABSD2xpdmVPZGRzVXBkYXRlZBJSChJiZXR0aW5nX2'
    'JldF9wbGFjZWQYDiABKAsyIi5nbWFpbmcuZXZlbnRzLnYxLkJldHRpbmdCZXRQbGFjZWRIAFIQ'
    'YmV0dGluZ0JldFBsYWNlZBJqChpiZXR0aW5nX3NldHRsZW1lbnRfYXBwbGllZBgPIAEoCzIqLm'
    'dtYWluZy5ldmVudHMudjEuQmV0dGluZ1NldHRsZW1lbnRBcHBsaWVkSABSGGJldHRpbmdTZXR0'
    'bGVtZW50QXBwbGllZBJFCg1zeXN0ZW1fbm90aWNlGBAgASgLMh4uZ21haW5nLmV2ZW50cy52MS'
    '5TeXN0ZW1Ob3RpY2VIAFIMc3lzdGVtTm90aWNlEjsKCWhlYXJ0YmVhdBgRIAEoCzIbLmdtYWlu'
    'Zy5ldmVudHMudjEuSGVhcnRiZWF0SABSCWhlYXJ0YmVhdEIJCgdwYXlsb2Fk');

@$core.Deprecated('Use socialPostCreatedDescriptor instead')
const SocialPostCreated$json = {
  '1': 'SocialPostCreated',
  '2': [
    {'1': 'post_id', '3': 1, '4': 1, '5': 9, '10': 'postId'},
    {'1': 'author_user_id', '3': 2, '4': 1, '5': 9, '10': 'authorUserId'},
    {'1': 'preview_text', '3': 3, '4': 1, '5': 9, '10': 'previewText'},
    {'1': 'created_at_ms', '3': 4, '4': 1, '5': 3, '10': 'createdAtMs'},
  ],
};

/// Descriptor for `SocialPostCreated`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List socialPostCreatedDescriptor = $convert.base64Decode(
    'ChFTb2NpYWxQb3N0Q3JlYXRlZBIXCgdwb3N0X2lkGAEgASgJUgZwb3N0SWQSJAoOYXV0aG9yX3'
    'VzZXJfaWQYAiABKAlSDGF1dGhvclVzZXJJZBIhCgxwcmV2aWV3X3RleHQYAyABKAlSC3ByZXZp'
    'ZXdUZXh0EiIKDWNyZWF0ZWRfYXRfbXMYBCABKANSC2NyZWF0ZWRBdE1z');

@$core.Deprecated('Use socialGiftSentDescriptor instead')
const SocialGiftSent$json = {
  '1': 'SocialGiftSent',
  '2': [
    {'1': 'post_id', '3': 1, '4': 1, '5': 9, '10': 'postId'},
    {'1': 'from_user_id', '3': 2, '4': 1, '5': 9, '10': 'fromUserId'},
    {'1': 'to_user_id', '3': 3, '4': 1, '5': 9, '10': 'toUserId'},
    {'1': 'gift_item_id', '3': 4, '4': 1, '5': 9, '10': 'giftItemId'},
    {'1': 'quantity', '3': 5, '4': 1, '5': 5, '10': 'quantity'},
    {'1': 'total_value', '3': 6, '4': 1, '5': 3, '10': 'totalValue'},
    {'1': 'created_at_ms', '3': 7, '4': 1, '5': 3, '10': 'createdAtMs'},
  ],
};

/// Descriptor for `SocialGiftSent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List socialGiftSentDescriptor = $convert.base64Decode(
    'Cg5Tb2NpYWxHaWZ0U2VudBIXCgdwb3N0X2lkGAEgASgJUgZwb3N0SWQSIAoMZnJvbV91c2VyX2'
    'lkGAIgASgJUgpmcm9tVXNlcklkEhwKCnRvX3VzZXJfaWQYAyABKAlSCHRvVXNlcklkEiAKDGdp'
    'ZnRfaXRlbV9pZBgEIAEoCVIKZ2lmdEl0ZW1JZBIaCghxdWFudGl0eRgFIAEoBVIIcXVhbnRpdH'
    'kSHwoLdG90YWxfdmFsdWUYBiABKANSCnRvdGFsVmFsdWUSIgoNY3JlYXRlZF9hdF9tcxgHIAEo'
    'A1ILY3JlYXRlZEF0TXM=');

@$core.Deprecated('Use liveDrawStateUpdatedDescriptor instead')
const LiveDrawStateUpdated$json = {
  '1': 'LiveDrawStateUpdated',
  '2': [
    {'1': 'market', '3': 1, '4': 1, '5': 9, '10': 'market'},
    {'1': 'session', '3': 2, '4': 1, '5': 9, '10': 'session'},
    {'1': 'draw_id', '3': 3, '4': 1, '5': 9, '10': 'drawId'},
    {'1': 'state', '3': 4, '4': 1, '5': 9, '10': 'state'},
    {'1': 'current_value', '3': 5, '4': 1, '5': 5, '10': 'currentValue'},
    {'1': 'previous_value', '3': 6, '4': 1, '5': 5, '10': 'previousValue'},
    {'1': 'result_at_ms', '3': 7, '4': 1, '5': 3, '10': 'resultAtMs'},
    {
      '1': 'next_transition_ms',
      '3': 8,
      '4': 1,
      '5': 3,
      '10': 'nextTransitionMs'
    },
  ],
};

/// Descriptor for `LiveDrawStateUpdated`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List liveDrawStateUpdatedDescriptor = $convert.base64Decode(
    'ChRMaXZlRHJhd1N0YXRlVXBkYXRlZBIWCgZtYXJrZXQYASABKAlSBm1hcmtldBIYCgdzZXNzaW'
    '9uGAIgASgJUgdzZXNzaW9uEhcKB2RyYXdfaWQYAyABKAlSBmRyYXdJZBIUCgVzdGF0ZRgEIAEo'
    'CVIFc3RhdGUSIwoNY3VycmVudF92YWx1ZRgFIAEoBVIMY3VycmVudFZhbHVlEiUKDnByZXZpb3'
    'VzX3ZhbHVlGAYgASgFUg1wcmV2aW91c1ZhbHVlEiAKDHJlc3VsdF9hdF9tcxgHIAEoA1IKcmVz'
    'dWx0QXRNcxIsChJuZXh0X3RyYW5zaXRpb25fbXMYCCABKANSEG5leHRUcmFuc2l0aW9uTXM=');

@$core.Deprecated('Use liveOddsUpdatedDescriptor instead')
const LiveOddsUpdated$json = {
  '1': 'LiveOddsUpdated',
  '2': [
    {'1': 'market', '3': 1, '4': 1, '5': 9, '10': 'market'},
    {'1': 'session', '3': 2, '4': 1, '5': 9, '10': 'session'},
    {'1': 'draw_id', '3': 3, '4': 1, '5': 9, '10': 'drawId'},
    {
      '1': 'odds',
      '3': 4,
      '4': 3,
      '5': 11,
      '6': '.gmaing.events.v1.OddsItem',
      '10': 'odds'
    },
  ],
};

/// Descriptor for `LiveOddsUpdated`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List liveOddsUpdatedDescriptor = $convert.base64Decode(
    'Cg9MaXZlT2Rkc1VwZGF0ZWQSFgoGbWFya2V0GAEgASgJUgZtYXJrZXQSGAoHc2Vzc2lvbhgCIA'
    'EoCVIHc2Vzc2lvbhIXCgdkcmF3X2lkGAMgASgJUgZkcmF3SWQSLgoEb2RkcxgEIAMoCzIaLmdt'
    'YWluZy5ldmVudHMudjEuT2Rkc0l0ZW1SBG9kZHM=');

@$core.Deprecated('Use oddsItemDescriptor instead')
const OddsItem$json = {
  '1': 'OddsItem',
  '2': [
    {'1': 'digit', '3': 1, '4': 1, '5': 5, '10': 'digit'},
    {
      '1': 'payout_multiplier',
      '3': 2,
      '4': 1,
      '5': 1,
      '10': 'payoutMultiplier'
    },
    {'1': 'suspended', '3': 3, '4': 1, '5': 8, '10': 'suspended'},
  ],
};

/// Descriptor for `OddsItem`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List oddsItemDescriptor = $convert.base64Decode(
    'CghPZGRzSXRlbRIUCgVkaWdpdBgBIAEoBVIFZGlnaXQSKwoRcGF5b3V0X211bHRpcGxpZXIYAi'
    'ABKAFSEHBheW91dE11bHRpcGxpZXISHAoJc3VzcGVuZGVkGAMgASgIUglzdXNwZW5kZWQ=');

@$core.Deprecated('Use bettingBetPlacedDescriptor instead')
const BettingBetPlaced$json = {
  '1': 'BettingBetPlaced',
  '2': [
    {'1': 'bet_id', '3': 1, '4': 1, '5': 9, '10': 'betId'},
    {'1': 'user_id', '3': 2, '4': 1, '5': 9, '10': 'userId'},
    {'1': 'digit', '3': 3, '4': 1, '5': 5, '10': 'digit'},
    {'1': 'amount', '3': 4, '4': 1, '5': 3, '10': 'amount'},
    {'1': 'draw_id', '3': 5, '4': 1, '5': 9, '10': 'drawId'},
    {'1': 'session', '3': 6, '4': 1, '5': 9, '10': 'session'},
    {'1': 'placed_at_ms', '3': 7, '4': 1, '5': 3, '10': 'placedAtMs'},
  ],
};

/// Descriptor for `BettingBetPlaced`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List bettingBetPlacedDescriptor = $convert.base64Decode(
    'ChBCZXR0aW5nQmV0UGxhY2VkEhUKBmJldF9pZBgBIAEoCVIFYmV0SWQSFwoHdXNlcl9pZBgCIA'
    'EoCVIGdXNlcklkEhQKBWRpZ2l0GAMgASgFUgVkaWdpdBIWCgZhbW91bnQYBCABKANSBmFtb3Vu'
    'dBIXCgdkcmF3X2lkGAUgASgJUgZkcmF3SWQSGAoHc2Vzc2lvbhgGIAEoCVIHc2Vzc2lvbhIgCg'
    'xwbGFjZWRfYXRfbXMYByABKANSCnBsYWNlZEF0TXM=');

@$core.Deprecated('Use bettingSettlementAppliedDescriptor instead')
const BettingSettlementApplied$json = {
  '1': 'BettingSettlementApplied',
  '2': [
    {'1': 'run_id', '3': 1, '4': 1, '5': 9, '10': 'runId'},
    {'1': 'settlement_id', '3': 2, '4': 1, '5': 9, '10': 'settlementId'},
    {'1': 'draw_id', '3': 3, '4': 1, '5': 9, '10': 'drawId'},
    {'1': 'winning_digit', '3': 4, '4': 1, '5': 5, '10': 'winningDigit'},
    {'1': 'claimed_rows', '3': 5, '4': 1, '5': 5, '10': 'claimedRows'},
    {'1': 'applied_rows', '3': 6, '4': 1, '5': 5, '10': 'appliedRows'},
    {'1': 'admin_delta', '3': 7, '4': 1, '5': 3, '10': 'adminDelta'},
    {'1': 'applied_at_ms', '3': 8, '4': 1, '5': 3, '10': 'appliedAtMs'},
  ],
};

/// Descriptor for `BettingSettlementApplied`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List bettingSettlementAppliedDescriptor = $convert.base64Decode(
    'ChhCZXR0aW5nU2V0dGxlbWVudEFwcGxpZWQSFQoGcnVuX2lkGAEgASgJUgVydW5JZBIjCg1zZX'
    'R0bGVtZW50X2lkGAIgASgJUgxzZXR0bGVtZW50SWQSFwoHZHJhd19pZBgDIAEoCVIGZHJhd0lk'
    'EiMKDXdpbm5pbmdfZGlnaXQYBCABKAVSDHdpbm5pbmdEaWdpdBIhCgxjbGFpbWVkX3Jvd3MYBS'
    'ABKAVSC2NsYWltZWRSb3dzEiEKDGFwcGxpZWRfcm93cxgGIAEoBVILYXBwbGllZFJvd3MSHwoL'
    'YWRtaW5fZGVsdGEYByABKANSCmFkbWluRGVsdGESIgoNYXBwbGllZF9hdF9tcxgIIAEoA1ILYX'
    'BwbGllZEF0TXM=');

@$core.Deprecated('Use systemNoticeDescriptor instead')
const SystemNotice$json = {
  '1': 'SystemNotice',
  '2': [
    {'1': 'level', '3': 1, '4': 1, '5': 9, '10': 'level'},
    {'1': 'code', '3': 2, '4': 1, '5': 9, '10': 'code'},
    {'1': 'message', '3': 3, '4': 1, '5': 9, '10': 'message'},
  ],
};

/// Descriptor for `SystemNotice`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List systemNoticeDescriptor = $convert.base64Decode(
    'CgxTeXN0ZW1Ob3RpY2USFAoFbGV2ZWwYASABKAlSBWxldmVsEhIKBGNvZGUYAiABKAlSBGNvZG'
    'USGAoHbWVzc2FnZRgDIAEoCVIHbWVzc2FnZQ==');

@$core.Deprecated('Use heartbeatDescriptor instead')
const Heartbeat$json = {
  '1': 'Heartbeat',
  '2': [
    {'1': 'heartbeat_seq', '3': 1, '4': 1, '5': 3, '10': 'heartbeatSeq'},
  ],
};

/// Descriptor for `Heartbeat`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List heartbeatDescriptor = $convert.base64Decode(
    'CglIZWFydGJlYXQSIwoNaGVhcnRiZWF0X3NlcRgBIAEoA1IMaGVhcnRiZWF0U2Vx');
