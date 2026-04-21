// This is a generated file - do not edit.
//
// Generated from live_v1.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

enum EventEnvelope_Payload {
  socialPostCreated,
  socialGiftSent,
  liveDrawStateUpdated,
  liveOddsUpdated,
  bettingBetPlaced,
  bettingSettlementApplied,
  systemNotice,
  heartbeat,
  notSet
}

/// Transport envelope for all realtime events.
class EventEnvelope extends $pb.GeneratedMessage {
  factory EventEnvelope({
    $core.String? eventId,
    $fixnum.Int64? serverTsMs,
    $core.String? source,
    $core.String? channel,
    $fixnum.Int64? seq,
    SocialPostCreated? socialPostCreated,
    SocialGiftSent? socialGiftSent,
    LiveDrawStateUpdated? liveDrawStateUpdated,
    LiveOddsUpdated? liveOddsUpdated,
    BettingBetPlaced? bettingBetPlaced,
    BettingSettlementApplied? bettingSettlementApplied,
    SystemNotice? systemNotice,
    Heartbeat? heartbeat,
  }) {
    final result = create();
    if (eventId != null) result.eventId = eventId;
    if (serverTsMs != null) result.serverTsMs = serverTsMs;
    if (source != null) result.source = source;
    if (channel != null) result.channel = channel;
    if (seq != null) result.seq = seq;
    if (socialPostCreated != null) result.socialPostCreated = socialPostCreated;
    if (socialGiftSent != null) result.socialGiftSent = socialGiftSent;
    if (liveDrawStateUpdated != null)
      result.liveDrawStateUpdated = liveDrawStateUpdated;
    if (liveOddsUpdated != null) result.liveOddsUpdated = liveOddsUpdated;
    if (bettingBetPlaced != null) result.bettingBetPlaced = bettingBetPlaced;
    if (bettingSettlementApplied != null)
      result.bettingSettlementApplied = bettingSettlementApplied;
    if (systemNotice != null) result.systemNotice = systemNotice;
    if (heartbeat != null) result.heartbeat = heartbeat;
    return result;
  }

  EventEnvelope._();

  factory EventEnvelope.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory EventEnvelope.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, EventEnvelope_Payload>
      _EventEnvelope_PayloadByTag = {
    10: EventEnvelope_Payload.socialPostCreated,
    11: EventEnvelope_Payload.socialGiftSent,
    12: EventEnvelope_Payload.liveDrawStateUpdated,
    13: EventEnvelope_Payload.liveOddsUpdated,
    14: EventEnvelope_Payload.bettingBetPlaced,
    15: EventEnvelope_Payload.bettingSettlementApplied,
    16: EventEnvelope_Payload.systemNotice,
    17: EventEnvelope_Payload.heartbeat,
    0: EventEnvelope_Payload.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'EventEnvelope',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'gmaing.events.v1'),
      createEmptyInstance: create)
    ..oo(0, [10, 11, 12, 13, 14, 15, 16, 17])
    ..aOS(1, _omitFieldNames ? '' : 'eventId')
    ..aInt64(2, _omitFieldNames ? '' : 'serverTsMs')
    ..aOS(3, _omitFieldNames ? '' : 'source')
    ..aOS(4, _omitFieldNames ? '' : 'channel')
    ..aInt64(5, _omitFieldNames ? '' : 'seq')
    ..aOM<SocialPostCreated>(10, _omitFieldNames ? '' : 'socialPostCreated',
        subBuilder: SocialPostCreated.create)
    ..aOM<SocialGiftSent>(11, _omitFieldNames ? '' : 'socialGiftSent',
        subBuilder: SocialGiftSent.create)
    ..aOM<LiveDrawStateUpdated>(
        12, _omitFieldNames ? '' : 'liveDrawStateUpdated',
        subBuilder: LiveDrawStateUpdated.create)
    ..aOM<LiveOddsUpdated>(13, _omitFieldNames ? '' : 'liveOddsUpdated',
        subBuilder: LiveOddsUpdated.create)
    ..aOM<BettingBetPlaced>(14, _omitFieldNames ? '' : 'bettingBetPlaced',
        subBuilder: BettingBetPlaced.create)
    ..aOM<BettingSettlementApplied>(
        15, _omitFieldNames ? '' : 'bettingSettlementApplied',
        subBuilder: BettingSettlementApplied.create)
    ..aOM<SystemNotice>(16, _omitFieldNames ? '' : 'systemNotice',
        subBuilder: SystemNotice.create)
    ..aOM<Heartbeat>(17, _omitFieldNames ? '' : 'heartbeat',
        subBuilder: Heartbeat.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EventEnvelope clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EventEnvelope copyWith(void Function(EventEnvelope) updates) =>
      super.copyWith((message) => updates(message as EventEnvelope))
          as EventEnvelope;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static EventEnvelope create() => EventEnvelope._();
  @$core.override
  EventEnvelope createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static EventEnvelope getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<EventEnvelope>(create);
  static EventEnvelope? _defaultInstance;

  @$pb.TagNumber(10)
  @$pb.TagNumber(11)
  @$pb.TagNumber(12)
  @$pb.TagNumber(13)
  @$pb.TagNumber(14)
  @$pb.TagNumber(15)
  @$pb.TagNumber(16)
  @$pb.TagNumber(17)
  EventEnvelope_Payload whichPayload() =>
      _EventEnvelope_PayloadByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(10)
  @$pb.TagNumber(11)
  @$pb.TagNumber(12)
  @$pb.TagNumber(13)
  @$pb.TagNumber(14)
  @$pb.TagNumber(15)
  @$pb.TagNumber(16)
  @$pb.TagNumber(17)
  void clearPayload() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $core.String get eventId => $_getSZ(0);
  @$pb.TagNumber(1)
  set eventId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasEventId() => $_has(0);
  @$pb.TagNumber(1)
  void clearEventId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get serverTsMs => $_getI64(1);
  @$pb.TagNumber(2)
  set serverTsMs($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasServerTsMs() => $_has(1);
  @$pb.TagNumber(2)
  void clearServerTsMs() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get source => $_getSZ(2);
  @$pb.TagNumber(3)
  set source($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSource() => $_has(2);
  @$pb.TagNumber(3)
  void clearSource() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get channel => $_getSZ(3);
  @$pb.TagNumber(4)
  set channel($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasChannel() => $_has(3);
  @$pb.TagNumber(4)
  void clearChannel() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get seq => $_getI64(4);
  @$pb.TagNumber(5)
  set seq($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasSeq() => $_has(4);
  @$pb.TagNumber(5)
  void clearSeq() => $_clearField(5);

  @$pb.TagNumber(10)
  SocialPostCreated get socialPostCreated => $_getN(5);
  @$pb.TagNumber(10)
  set socialPostCreated(SocialPostCreated value) => $_setField(10, value);
  @$pb.TagNumber(10)
  $core.bool hasSocialPostCreated() => $_has(5);
  @$pb.TagNumber(10)
  void clearSocialPostCreated() => $_clearField(10);
  @$pb.TagNumber(10)
  SocialPostCreated ensureSocialPostCreated() => $_ensure(5);

  @$pb.TagNumber(11)
  SocialGiftSent get socialGiftSent => $_getN(6);
  @$pb.TagNumber(11)
  set socialGiftSent(SocialGiftSent value) => $_setField(11, value);
  @$pb.TagNumber(11)
  $core.bool hasSocialGiftSent() => $_has(6);
  @$pb.TagNumber(11)
  void clearSocialGiftSent() => $_clearField(11);
  @$pb.TagNumber(11)
  SocialGiftSent ensureSocialGiftSent() => $_ensure(6);

  @$pb.TagNumber(12)
  LiveDrawStateUpdated get liveDrawStateUpdated => $_getN(7);
  @$pb.TagNumber(12)
  set liveDrawStateUpdated(LiveDrawStateUpdated value) => $_setField(12, value);
  @$pb.TagNumber(12)
  $core.bool hasLiveDrawStateUpdated() => $_has(7);
  @$pb.TagNumber(12)
  void clearLiveDrawStateUpdated() => $_clearField(12);
  @$pb.TagNumber(12)
  LiveDrawStateUpdated ensureLiveDrawStateUpdated() => $_ensure(7);

  @$pb.TagNumber(13)
  LiveOddsUpdated get liveOddsUpdated => $_getN(8);
  @$pb.TagNumber(13)
  set liveOddsUpdated(LiveOddsUpdated value) => $_setField(13, value);
  @$pb.TagNumber(13)
  $core.bool hasLiveOddsUpdated() => $_has(8);
  @$pb.TagNumber(13)
  void clearLiveOddsUpdated() => $_clearField(13);
  @$pb.TagNumber(13)
  LiveOddsUpdated ensureLiveOddsUpdated() => $_ensure(8);

  @$pb.TagNumber(14)
  BettingBetPlaced get bettingBetPlaced => $_getN(9);
  @$pb.TagNumber(14)
  set bettingBetPlaced(BettingBetPlaced value) => $_setField(14, value);
  @$pb.TagNumber(14)
  $core.bool hasBettingBetPlaced() => $_has(9);
  @$pb.TagNumber(14)
  void clearBettingBetPlaced() => $_clearField(14);
  @$pb.TagNumber(14)
  BettingBetPlaced ensureBettingBetPlaced() => $_ensure(9);

  @$pb.TagNumber(15)
  BettingSettlementApplied get bettingSettlementApplied => $_getN(10);
  @$pb.TagNumber(15)
  set bettingSettlementApplied(BettingSettlementApplied value) =>
      $_setField(15, value);
  @$pb.TagNumber(15)
  $core.bool hasBettingSettlementApplied() => $_has(10);
  @$pb.TagNumber(15)
  void clearBettingSettlementApplied() => $_clearField(15);
  @$pb.TagNumber(15)
  BettingSettlementApplied ensureBettingSettlementApplied() => $_ensure(10);

  @$pb.TagNumber(16)
  SystemNotice get systemNotice => $_getN(11);
  @$pb.TagNumber(16)
  set systemNotice(SystemNotice value) => $_setField(16, value);
  @$pb.TagNumber(16)
  $core.bool hasSystemNotice() => $_has(11);
  @$pb.TagNumber(16)
  void clearSystemNotice() => $_clearField(16);
  @$pb.TagNumber(16)
  SystemNotice ensureSystemNotice() => $_ensure(11);

  @$pb.TagNumber(17)
  Heartbeat get heartbeat => $_getN(12);
  @$pb.TagNumber(17)
  set heartbeat(Heartbeat value) => $_setField(17, value);
  @$pb.TagNumber(17)
  $core.bool hasHeartbeat() => $_has(12);
  @$pb.TagNumber(17)
  void clearHeartbeat() => $_clearField(17);
  @$pb.TagNumber(17)
  Heartbeat ensureHeartbeat() => $_ensure(12);
}

/// ------------------------------
/// Social events
/// ------------------------------
class SocialPostCreated extends $pb.GeneratedMessage {
  factory SocialPostCreated({
    $core.String? postId,
    $core.String? authorUserId,
    $core.String? previewText,
    $fixnum.Int64? createdAtMs,
  }) {
    final result = create();
    if (postId != null) result.postId = postId;
    if (authorUserId != null) result.authorUserId = authorUserId;
    if (previewText != null) result.previewText = previewText;
    if (createdAtMs != null) result.createdAtMs = createdAtMs;
    return result;
  }

  SocialPostCreated._();

  factory SocialPostCreated.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SocialPostCreated.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SocialPostCreated',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'gmaing.events.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'postId')
    ..aOS(2, _omitFieldNames ? '' : 'authorUserId')
    ..aOS(3, _omitFieldNames ? '' : 'previewText')
    ..aInt64(4, _omitFieldNames ? '' : 'createdAtMs')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SocialPostCreated clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SocialPostCreated copyWith(void Function(SocialPostCreated) updates) =>
      super.copyWith((message) => updates(message as SocialPostCreated))
          as SocialPostCreated;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SocialPostCreated create() => SocialPostCreated._();
  @$core.override
  SocialPostCreated createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SocialPostCreated getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SocialPostCreated>(create);
  static SocialPostCreated? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get postId => $_getSZ(0);
  @$pb.TagNumber(1)
  set postId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPostId() => $_has(0);
  @$pb.TagNumber(1)
  void clearPostId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get authorUserId => $_getSZ(1);
  @$pb.TagNumber(2)
  set authorUserId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasAuthorUserId() => $_has(1);
  @$pb.TagNumber(2)
  void clearAuthorUserId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get previewText => $_getSZ(2);
  @$pb.TagNumber(3)
  set previewText($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasPreviewText() => $_has(2);
  @$pb.TagNumber(3)
  void clearPreviewText() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get createdAtMs => $_getI64(3);
  @$pb.TagNumber(4)
  set createdAtMs($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasCreatedAtMs() => $_has(3);
  @$pb.TagNumber(4)
  void clearCreatedAtMs() => $_clearField(4);
}

class SocialGiftSent extends $pb.GeneratedMessage {
  factory SocialGiftSent({
    $core.String? postId,
    $core.String? fromUserId,
    $core.String? toUserId,
    $core.String? giftItemId,
    $core.int? quantity,
    $fixnum.Int64? totalValue,
    $fixnum.Int64? createdAtMs,
  }) {
    final result = create();
    if (postId != null) result.postId = postId;
    if (fromUserId != null) result.fromUserId = fromUserId;
    if (toUserId != null) result.toUserId = toUserId;
    if (giftItemId != null) result.giftItemId = giftItemId;
    if (quantity != null) result.quantity = quantity;
    if (totalValue != null) result.totalValue = totalValue;
    if (createdAtMs != null) result.createdAtMs = createdAtMs;
    return result;
  }

  SocialGiftSent._();

  factory SocialGiftSent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SocialGiftSent.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SocialGiftSent',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'gmaing.events.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'postId')
    ..aOS(2, _omitFieldNames ? '' : 'fromUserId')
    ..aOS(3, _omitFieldNames ? '' : 'toUserId')
    ..aOS(4, _omitFieldNames ? '' : 'giftItemId')
    ..aI(5, _omitFieldNames ? '' : 'quantity')
    ..aInt64(6, _omitFieldNames ? '' : 'totalValue')
    ..aInt64(7, _omitFieldNames ? '' : 'createdAtMs')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SocialGiftSent clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SocialGiftSent copyWith(void Function(SocialGiftSent) updates) =>
      super.copyWith((message) => updates(message as SocialGiftSent))
          as SocialGiftSent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SocialGiftSent create() => SocialGiftSent._();
  @$core.override
  SocialGiftSent createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SocialGiftSent getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SocialGiftSent>(create);
  static SocialGiftSent? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get postId => $_getSZ(0);
  @$pb.TagNumber(1)
  set postId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPostId() => $_has(0);
  @$pb.TagNumber(1)
  void clearPostId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get fromUserId => $_getSZ(1);
  @$pb.TagNumber(2)
  set fromUserId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasFromUserId() => $_has(1);
  @$pb.TagNumber(2)
  void clearFromUserId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get toUserId => $_getSZ(2);
  @$pb.TagNumber(3)
  set toUserId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasToUserId() => $_has(2);
  @$pb.TagNumber(3)
  void clearToUserId() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get giftItemId => $_getSZ(3);
  @$pb.TagNumber(4)
  set giftItemId($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasGiftItemId() => $_has(3);
  @$pb.TagNumber(4)
  void clearGiftItemId() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get quantity => $_getIZ(4);
  @$pb.TagNumber(5)
  set quantity($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasQuantity() => $_has(4);
  @$pb.TagNumber(5)
  void clearQuantity() => $_clearField(5);

  @$pb.TagNumber(6)
  $fixnum.Int64 get totalValue => $_getI64(5);
  @$pb.TagNumber(6)
  set totalValue($fixnum.Int64 value) => $_setInt64(5, value);
  @$pb.TagNumber(6)
  $core.bool hasTotalValue() => $_has(5);
  @$pb.TagNumber(6)
  void clearTotalValue() => $_clearField(6);

  @$pb.TagNumber(7)
  $fixnum.Int64 get createdAtMs => $_getI64(6);
  @$pb.TagNumber(7)
  set createdAtMs($fixnum.Int64 value) => $_setInt64(6, value);
  @$pb.TagNumber(7)
  $core.bool hasCreatedAtMs() => $_has(6);
  @$pb.TagNumber(7)
  void clearCreatedAtMs() => $_clearField(7);
}

/// ------------------------------
/// 2D live viewer events
/// ------------------------------
class LiveDrawStateUpdated extends $pb.GeneratedMessage {
  factory LiveDrawStateUpdated({
    $core.String? market,
    $core.String? session,
    $core.String? drawId,
    $core.String? state,
    $core.int? currentValue,
    $core.int? previousValue,
    $fixnum.Int64? resultAtMs,
    $fixnum.Int64? nextTransitionMs,
  }) {
    final result = create();
    if (market != null) result.market = market;
    if (session != null) result.session = session;
    if (drawId != null) result.drawId = drawId;
    if (state != null) result.state = state;
    if (currentValue != null) result.currentValue = currentValue;
    if (previousValue != null) result.previousValue = previousValue;
    if (resultAtMs != null) result.resultAtMs = resultAtMs;
    if (nextTransitionMs != null) result.nextTransitionMs = nextTransitionMs;
    return result;
  }

  LiveDrawStateUpdated._();

  factory LiveDrawStateUpdated.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory LiveDrawStateUpdated.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LiveDrawStateUpdated',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'gmaing.events.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'market')
    ..aOS(2, _omitFieldNames ? '' : 'session')
    ..aOS(3, _omitFieldNames ? '' : 'drawId')
    ..aOS(4, _omitFieldNames ? '' : 'state')
    ..aI(5, _omitFieldNames ? '' : 'currentValue')
    ..aI(6, _omitFieldNames ? '' : 'previousValue')
    ..aInt64(7, _omitFieldNames ? '' : 'resultAtMs')
    ..aInt64(8, _omitFieldNames ? '' : 'nextTransitionMs')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LiveDrawStateUpdated clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LiveDrawStateUpdated copyWith(void Function(LiveDrawStateUpdated) updates) =>
      super.copyWith((message) => updates(message as LiveDrawStateUpdated))
          as LiveDrawStateUpdated;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LiveDrawStateUpdated create() => LiveDrawStateUpdated._();
  @$core.override
  LiveDrawStateUpdated createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static LiveDrawStateUpdated getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LiveDrawStateUpdated>(create);
  static LiveDrawStateUpdated? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get market => $_getSZ(0);
  @$pb.TagNumber(1)
  set market($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMarket() => $_has(0);
  @$pb.TagNumber(1)
  void clearMarket() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get session => $_getSZ(1);
  @$pb.TagNumber(2)
  set session($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSession() => $_has(1);
  @$pb.TagNumber(2)
  void clearSession() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get drawId => $_getSZ(2);
  @$pb.TagNumber(3)
  set drawId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDrawId() => $_has(2);
  @$pb.TagNumber(3)
  void clearDrawId() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get state => $_getSZ(3);
  @$pb.TagNumber(4)
  set state($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasState() => $_has(3);
  @$pb.TagNumber(4)
  void clearState() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get currentValue => $_getIZ(4);
  @$pb.TagNumber(5)
  set currentValue($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasCurrentValue() => $_has(4);
  @$pb.TagNumber(5)
  void clearCurrentValue() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.int get previousValue => $_getIZ(5);
  @$pb.TagNumber(6)
  set previousValue($core.int value) => $_setSignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasPreviousValue() => $_has(5);
  @$pb.TagNumber(6)
  void clearPreviousValue() => $_clearField(6);

  @$pb.TagNumber(7)
  $fixnum.Int64 get resultAtMs => $_getI64(6);
  @$pb.TagNumber(7)
  set resultAtMs($fixnum.Int64 value) => $_setInt64(6, value);
  @$pb.TagNumber(7)
  $core.bool hasResultAtMs() => $_has(6);
  @$pb.TagNumber(7)
  void clearResultAtMs() => $_clearField(7);

  @$pb.TagNumber(8)
  $fixnum.Int64 get nextTransitionMs => $_getI64(7);
  @$pb.TagNumber(8)
  set nextTransitionMs($fixnum.Int64 value) => $_setInt64(7, value);
  @$pb.TagNumber(8)
  $core.bool hasNextTransitionMs() => $_has(7);
  @$pb.TagNumber(8)
  void clearNextTransitionMs() => $_clearField(8);
}

class LiveOddsUpdated extends $pb.GeneratedMessage {
  factory LiveOddsUpdated({
    $core.String? market,
    $core.String? session,
    $core.String? drawId,
    $core.Iterable<OddsItem>? odds,
  }) {
    final result = create();
    if (market != null) result.market = market;
    if (session != null) result.session = session;
    if (drawId != null) result.drawId = drawId;
    if (odds != null) result.odds.addAll(odds);
    return result;
  }

  LiveOddsUpdated._();

  factory LiveOddsUpdated.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory LiveOddsUpdated.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'LiveOddsUpdated',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'gmaing.events.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'market')
    ..aOS(2, _omitFieldNames ? '' : 'session')
    ..aOS(3, _omitFieldNames ? '' : 'drawId')
    ..pPM<OddsItem>(4, _omitFieldNames ? '' : 'odds',
        subBuilder: OddsItem.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LiveOddsUpdated clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LiveOddsUpdated copyWith(void Function(LiveOddsUpdated) updates) =>
      super.copyWith((message) => updates(message as LiveOddsUpdated))
          as LiveOddsUpdated;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LiveOddsUpdated create() => LiveOddsUpdated._();
  @$core.override
  LiveOddsUpdated createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static LiveOddsUpdated getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<LiveOddsUpdated>(create);
  static LiveOddsUpdated? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get market => $_getSZ(0);
  @$pb.TagNumber(1)
  set market($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMarket() => $_has(0);
  @$pb.TagNumber(1)
  void clearMarket() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get session => $_getSZ(1);
  @$pb.TagNumber(2)
  set session($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSession() => $_has(1);
  @$pb.TagNumber(2)
  void clearSession() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get drawId => $_getSZ(2);
  @$pb.TagNumber(3)
  set drawId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDrawId() => $_has(2);
  @$pb.TagNumber(3)
  void clearDrawId() => $_clearField(3);

  @$pb.TagNumber(4)
  $pb.PbList<OddsItem> get odds => $_getList(3);
}

class OddsItem extends $pb.GeneratedMessage {
  factory OddsItem({
    $core.int? digit,
    $core.double? payoutMultiplier,
    $core.bool? suspended,
  }) {
    final result = create();
    if (digit != null) result.digit = digit;
    if (payoutMultiplier != null) result.payoutMultiplier = payoutMultiplier;
    if (suspended != null) result.suspended = suspended;
    return result;
  }

  OddsItem._();

  factory OddsItem.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory OddsItem.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'OddsItem',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'gmaing.events.v1'),
      createEmptyInstance: create)
    ..aI(1, _omitFieldNames ? '' : 'digit')
    ..aD(2, _omitFieldNames ? '' : 'payoutMultiplier')
    ..aOB(3, _omitFieldNames ? '' : 'suspended')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OddsItem clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OddsItem copyWith(void Function(OddsItem) updates) =>
      super.copyWith((message) => updates(message as OddsItem)) as OddsItem;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static OddsItem create() => OddsItem._();
  @$core.override
  OddsItem createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static OddsItem getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<OddsItem>(create);
  static OddsItem? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get digit => $_getIZ(0);
  @$pb.TagNumber(1)
  set digit($core.int value) => $_setSignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDigit() => $_has(0);
  @$pb.TagNumber(1)
  void clearDigit() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.double get payoutMultiplier => $_getN(1);
  @$pb.TagNumber(2)
  set payoutMultiplier($core.double value) => $_setDouble(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPayoutMultiplier() => $_has(1);
  @$pb.TagNumber(2)
  void clearPayoutMultiplier() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.bool get suspended => $_getBF(2);
  @$pb.TagNumber(3)
  set suspended($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSuspended() => $_has(2);
  @$pb.TagNumber(3)
  void clearSuspended() => $_clearField(3);
}

/// ------------------------------
/// Betting events
/// ------------------------------
class BettingBetPlaced extends $pb.GeneratedMessage {
  factory BettingBetPlaced({
    $core.String? betId,
    $core.String? userId,
    $core.int? digit,
    $fixnum.Int64? amount,
    $core.String? drawId,
    $core.String? session,
    $fixnum.Int64? placedAtMs,
  }) {
    final result = create();
    if (betId != null) result.betId = betId;
    if (userId != null) result.userId = userId;
    if (digit != null) result.digit = digit;
    if (amount != null) result.amount = amount;
    if (drawId != null) result.drawId = drawId;
    if (session != null) result.session = session;
    if (placedAtMs != null) result.placedAtMs = placedAtMs;
    return result;
  }

  BettingBetPlaced._();

  factory BettingBetPlaced.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory BettingBetPlaced.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BettingBetPlaced',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'gmaing.events.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'betId')
    ..aOS(2, _omitFieldNames ? '' : 'userId')
    ..aI(3, _omitFieldNames ? '' : 'digit')
    ..aInt64(4, _omitFieldNames ? '' : 'amount')
    ..aOS(5, _omitFieldNames ? '' : 'drawId')
    ..aOS(6, _omitFieldNames ? '' : 'session')
    ..aInt64(7, _omitFieldNames ? '' : 'placedAtMs')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BettingBetPlaced clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BettingBetPlaced copyWith(void Function(BettingBetPlaced) updates) =>
      super.copyWith((message) => updates(message as BettingBetPlaced))
          as BettingBetPlaced;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BettingBetPlaced create() => BettingBetPlaced._();
  @$core.override
  BettingBetPlaced createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static BettingBetPlaced getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<BettingBetPlaced>(create);
  static BettingBetPlaced? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get betId => $_getSZ(0);
  @$pb.TagNumber(1)
  set betId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasBetId() => $_has(0);
  @$pb.TagNumber(1)
  void clearBetId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get userId => $_getSZ(1);
  @$pb.TagNumber(2)
  set userId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasUserId() => $_has(1);
  @$pb.TagNumber(2)
  void clearUserId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get digit => $_getIZ(2);
  @$pb.TagNumber(3)
  set digit($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDigit() => $_has(2);
  @$pb.TagNumber(3)
  void clearDigit() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get amount => $_getI64(3);
  @$pb.TagNumber(4)
  set amount($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasAmount() => $_has(3);
  @$pb.TagNumber(4)
  void clearAmount() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get drawId => $_getSZ(4);
  @$pb.TagNumber(5)
  set drawId($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasDrawId() => $_has(4);
  @$pb.TagNumber(5)
  void clearDrawId() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get session => $_getSZ(5);
  @$pb.TagNumber(6)
  set session($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasSession() => $_has(5);
  @$pb.TagNumber(6)
  void clearSession() => $_clearField(6);

  @$pb.TagNumber(7)
  $fixnum.Int64 get placedAtMs => $_getI64(6);
  @$pb.TagNumber(7)
  set placedAtMs($fixnum.Int64 value) => $_setInt64(6, value);
  @$pb.TagNumber(7)
  $core.bool hasPlacedAtMs() => $_has(6);
  @$pb.TagNumber(7)
  void clearPlacedAtMs() => $_clearField(7);
}

class BettingSettlementApplied extends $pb.GeneratedMessage {
  factory BettingSettlementApplied({
    $core.String? runId,
    $core.String? settlementId,
    $core.String? drawId,
    $core.int? winningDigit,
    $core.int? claimedRows,
    $core.int? appliedRows,
    $fixnum.Int64? adminDelta,
    $fixnum.Int64? appliedAtMs,
  }) {
    final result = create();
    if (runId != null) result.runId = runId;
    if (settlementId != null) result.settlementId = settlementId;
    if (drawId != null) result.drawId = drawId;
    if (winningDigit != null) result.winningDigit = winningDigit;
    if (claimedRows != null) result.claimedRows = claimedRows;
    if (appliedRows != null) result.appliedRows = appliedRows;
    if (adminDelta != null) result.adminDelta = adminDelta;
    if (appliedAtMs != null) result.appliedAtMs = appliedAtMs;
    return result;
  }

  BettingSettlementApplied._();

  factory BettingSettlementApplied.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory BettingSettlementApplied.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BettingSettlementApplied',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'gmaing.events.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'runId')
    ..aOS(2, _omitFieldNames ? '' : 'settlementId')
    ..aOS(3, _omitFieldNames ? '' : 'drawId')
    ..aI(4, _omitFieldNames ? '' : 'winningDigit')
    ..aI(5, _omitFieldNames ? '' : 'claimedRows')
    ..aI(6, _omitFieldNames ? '' : 'appliedRows')
    ..aInt64(7, _omitFieldNames ? '' : 'adminDelta')
    ..aInt64(8, _omitFieldNames ? '' : 'appliedAtMs')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BettingSettlementApplied clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BettingSettlementApplied copyWith(
          void Function(BettingSettlementApplied) updates) =>
      super.copyWith((message) => updates(message as BettingSettlementApplied))
          as BettingSettlementApplied;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BettingSettlementApplied create() => BettingSettlementApplied._();
  @$core.override
  BettingSettlementApplied createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static BettingSettlementApplied getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<BettingSettlementApplied>(create);
  static BettingSettlementApplied? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get runId => $_getSZ(0);
  @$pb.TagNumber(1)
  set runId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRunId() => $_has(0);
  @$pb.TagNumber(1)
  void clearRunId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get settlementId => $_getSZ(1);
  @$pb.TagNumber(2)
  set settlementId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSettlementId() => $_has(1);
  @$pb.TagNumber(2)
  void clearSettlementId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get drawId => $_getSZ(2);
  @$pb.TagNumber(3)
  set drawId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDrawId() => $_has(2);
  @$pb.TagNumber(3)
  void clearDrawId() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get winningDigit => $_getIZ(3);
  @$pb.TagNumber(4)
  set winningDigit($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasWinningDigit() => $_has(3);
  @$pb.TagNumber(4)
  void clearWinningDigit() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get claimedRows => $_getIZ(4);
  @$pb.TagNumber(5)
  set claimedRows($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasClaimedRows() => $_has(4);
  @$pb.TagNumber(5)
  void clearClaimedRows() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.int get appliedRows => $_getIZ(5);
  @$pb.TagNumber(6)
  set appliedRows($core.int value) => $_setSignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasAppliedRows() => $_has(5);
  @$pb.TagNumber(6)
  void clearAppliedRows() => $_clearField(6);

  @$pb.TagNumber(7)
  $fixnum.Int64 get adminDelta => $_getI64(6);
  @$pb.TagNumber(7)
  set adminDelta($fixnum.Int64 value) => $_setInt64(6, value);
  @$pb.TagNumber(7)
  $core.bool hasAdminDelta() => $_has(6);
  @$pb.TagNumber(7)
  void clearAdminDelta() => $_clearField(7);

  @$pb.TagNumber(8)
  $fixnum.Int64 get appliedAtMs => $_getI64(7);
  @$pb.TagNumber(8)
  set appliedAtMs($fixnum.Int64 value) => $_setInt64(7, value);
  @$pb.TagNumber(8)
  $core.bool hasAppliedAtMs() => $_has(7);
  @$pb.TagNumber(8)
  void clearAppliedAtMs() => $_clearField(8);
}

/// ------------------------------
/// Common events
/// ------------------------------
class SystemNotice extends $pb.GeneratedMessage {
  factory SystemNotice({
    $core.String? level,
    $core.String? code,
    $core.String? message,
  }) {
    final result = create();
    if (level != null) result.level = level;
    if (code != null) result.code = code;
    if (message != null) result.message = message;
    return result;
  }

  SystemNotice._();

  factory SystemNotice.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SystemNotice.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SystemNotice',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'gmaing.events.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'level')
    ..aOS(2, _omitFieldNames ? '' : 'code')
    ..aOS(3, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SystemNotice clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SystemNotice copyWith(void Function(SystemNotice) updates) =>
      super.copyWith((message) => updates(message as SystemNotice))
          as SystemNotice;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SystemNotice create() => SystemNotice._();
  @$core.override
  SystemNotice createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SystemNotice getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SystemNotice>(create);
  static SystemNotice? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get level => $_getSZ(0);
  @$pb.TagNumber(1)
  set level($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasLevel() => $_has(0);
  @$pb.TagNumber(1)
  void clearLevel() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get code => $_getSZ(1);
  @$pb.TagNumber(2)
  set code($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCode() => $_has(1);
  @$pb.TagNumber(2)
  void clearCode() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get message => $_getSZ(2);
  @$pb.TagNumber(3)
  set message($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasMessage() => $_has(2);
  @$pb.TagNumber(3)
  void clearMessage() => $_clearField(3);
}

class Heartbeat extends $pb.GeneratedMessage {
  factory Heartbeat({
    $fixnum.Int64? heartbeatSeq,
  }) {
    final result = create();
    if (heartbeatSeq != null) result.heartbeatSeq = heartbeatSeq;
    return result;
  }

  Heartbeat._();

  factory Heartbeat.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Heartbeat.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Heartbeat',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'gmaing.events.v1'),
      createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'heartbeatSeq')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Heartbeat clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Heartbeat copyWith(void Function(Heartbeat) updates) =>
      super.copyWith((message) => updates(message as Heartbeat)) as Heartbeat;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Heartbeat create() => Heartbeat._();
  @$core.override
  Heartbeat createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Heartbeat getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Heartbeat>(create);
  static Heartbeat? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get heartbeatSeq => $_getI64(0);
  @$pb.TagNumber(1)
  set heartbeatSeq($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasHeartbeatSeq() => $_has(0);
  @$pb.TagNumber(1)
  void clearHeartbeatSeq() => $_clearField(1);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
