/*eslint-disable block-scoped-var, id-length, no-control-regex, no-magic-numbers, no-prototype-builtins, no-redeclare, no-shadow, no-var, sort-vars*/
"use strict";

var $protobuf = require("protobufjs/minimal");

// Common aliases
var $Reader = $protobuf.Reader, $Writer = $protobuf.Writer, $util = $protobuf.util;

// Exported root namespace
var $root = $protobuf.roots["default"] || ($protobuf.roots["default"] = {});

$root.gmaing = (function() {

    /**
     * Namespace gmaing.
     * @exports gmaing
     * @namespace
     */
    var gmaing = {};

    gmaing.events = (function() {

        /**
         * Namespace events.
         * @memberof gmaing
         * @namespace
         */
        var events = {};

        events.v1 = (function() {

            /**
             * Namespace v1.
             * @memberof gmaing.events
             * @namespace
             */
            var v1 = {};

            v1.EventEnvelope = (function() {

                /**
                 * Properties of an EventEnvelope.
                 * @memberof gmaing.events.v1
                 * @interface IEventEnvelope
                 * @property {string|null} [eventId] EventEnvelope eventId
                 * @property {number|Long|null} [serverTsMs] EventEnvelope serverTsMs
                 * @property {string|null} [source] EventEnvelope source
                 * @property {string|null} [channel] EventEnvelope channel
                 * @property {number|Long|null} [seq] EventEnvelope seq
                 * @property {gmaing.events.v1.ISocialPostCreated|null} [socialPostCreated] EventEnvelope socialPostCreated
                 * @property {gmaing.events.v1.ISocialGiftSent|null} [socialGiftSent] EventEnvelope socialGiftSent
                 * @property {gmaing.events.v1.ILiveDrawStateUpdated|null} [liveDrawStateUpdated] EventEnvelope liveDrawStateUpdated
                 * @property {gmaing.events.v1.ILiveOddsUpdated|null} [liveOddsUpdated] EventEnvelope liveOddsUpdated
                 * @property {gmaing.events.v1.IBettingBetPlaced|null} [bettingBetPlaced] EventEnvelope bettingBetPlaced
                 * @property {gmaing.events.v1.IBettingSettlementApplied|null} [bettingSettlementApplied] EventEnvelope bettingSettlementApplied
                 * @property {gmaing.events.v1.ISystemNotice|null} [systemNotice] EventEnvelope systemNotice
                 * @property {gmaing.events.v1.IHeartbeat|null} [heartbeat] EventEnvelope heartbeat
                 */

                /**
                 * Constructs a new EventEnvelope.
                 * @memberof gmaing.events.v1
                 * @classdesc Represents an EventEnvelope.
                 * @implements IEventEnvelope
                 * @constructor
                 * @param {gmaing.events.v1.IEventEnvelope=} [properties] Properties to set
                 */
                function EventEnvelope(properties) {
                    if (properties)
                        for (var keys = Object.keys(properties), i = 0; i < keys.length; ++i)
                            if (properties[keys[i]] != null)
                                this[keys[i]] = properties[keys[i]];
                }

                /**
                 * EventEnvelope eventId.
                 * @member {string} eventId
                 * @memberof gmaing.events.v1.EventEnvelope
                 * @instance
                 */
                EventEnvelope.prototype.eventId = "";

                /**
                 * EventEnvelope serverTsMs.
                 * @member {number|Long} serverTsMs
                 * @memberof gmaing.events.v1.EventEnvelope
                 * @instance
                 */
                EventEnvelope.prototype.serverTsMs = $util.Long ? $util.Long.fromBits(0,0,false) : 0;

                /**
                 * EventEnvelope source.
                 * @member {string} source
                 * @memberof gmaing.events.v1.EventEnvelope
                 * @instance
                 */
                EventEnvelope.prototype.source = "";

                /**
                 * EventEnvelope channel.
                 * @member {string} channel
                 * @memberof gmaing.events.v1.EventEnvelope
                 * @instance
                 */
                EventEnvelope.prototype.channel = "";

                /**
                 * EventEnvelope seq.
                 * @member {number|Long} seq
                 * @memberof gmaing.events.v1.EventEnvelope
                 * @instance
                 */
                EventEnvelope.prototype.seq = $util.Long ? $util.Long.fromBits(0,0,false) : 0;

                /**
                 * EventEnvelope socialPostCreated.
                 * @member {gmaing.events.v1.ISocialPostCreated|null|undefined} socialPostCreated
                 * @memberof gmaing.events.v1.EventEnvelope
                 * @instance
                 */
                EventEnvelope.prototype.socialPostCreated = null;

                /**
                 * EventEnvelope socialGiftSent.
                 * @member {gmaing.events.v1.ISocialGiftSent|null|undefined} socialGiftSent
                 * @memberof gmaing.events.v1.EventEnvelope
                 * @instance
                 */
                EventEnvelope.prototype.socialGiftSent = null;

                /**
                 * EventEnvelope liveDrawStateUpdated.
                 * @member {gmaing.events.v1.ILiveDrawStateUpdated|null|undefined} liveDrawStateUpdated
                 * @memberof gmaing.events.v1.EventEnvelope
                 * @instance
                 */
                EventEnvelope.prototype.liveDrawStateUpdated = null;

                /**
                 * EventEnvelope liveOddsUpdated.
                 * @member {gmaing.events.v1.ILiveOddsUpdated|null|undefined} liveOddsUpdated
                 * @memberof gmaing.events.v1.EventEnvelope
                 * @instance
                 */
                EventEnvelope.prototype.liveOddsUpdated = null;

                /**
                 * EventEnvelope bettingBetPlaced.
                 * @member {gmaing.events.v1.IBettingBetPlaced|null|undefined} bettingBetPlaced
                 * @memberof gmaing.events.v1.EventEnvelope
                 * @instance
                 */
                EventEnvelope.prototype.bettingBetPlaced = null;

                /**
                 * EventEnvelope bettingSettlementApplied.
                 * @member {gmaing.events.v1.IBettingSettlementApplied|null|undefined} bettingSettlementApplied
                 * @memberof gmaing.events.v1.EventEnvelope
                 * @instance
                 */
                EventEnvelope.prototype.bettingSettlementApplied = null;

                /**
                 * EventEnvelope systemNotice.
                 * @member {gmaing.events.v1.ISystemNotice|null|undefined} systemNotice
                 * @memberof gmaing.events.v1.EventEnvelope
                 * @instance
                 */
                EventEnvelope.prototype.systemNotice = null;

                /**
                 * EventEnvelope heartbeat.
                 * @member {gmaing.events.v1.IHeartbeat|null|undefined} heartbeat
                 * @memberof gmaing.events.v1.EventEnvelope
                 * @instance
                 */
                EventEnvelope.prototype.heartbeat = null;

                // OneOf field names bound to virtual getters and setters
                var $oneOfFields;

                /**
                 * EventEnvelope payload.
                 * @member {"socialPostCreated"|"socialGiftSent"|"liveDrawStateUpdated"|"liveOddsUpdated"|"bettingBetPlaced"|"bettingSettlementApplied"|"systemNotice"|"heartbeat"|undefined} payload
                 * @memberof gmaing.events.v1.EventEnvelope
                 * @instance
                 */
                Object.defineProperty(EventEnvelope.prototype, "payload", {
                    get: $util.oneOfGetter($oneOfFields = ["socialPostCreated", "socialGiftSent", "liveDrawStateUpdated", "liveOddsUpdated", "bettingBetPlaced", "bettingSettlementApplied", "systemNotice", "heartbeat"]),
                    set: $util.oneOfSetter($oneOfFields)
                });

                /**
                 * Creates a new EventEnvelope instance using the specified properties.
                 * @function create
                 * @memberof gmaing.events.v1.EventEnvelope
                 * @static
                 * @param {gmaing.events.v1.IEventEnvelope=} [properties] Properties to set
                 * @returns {gmaing.events.v1.EventEnvelope} EventEnvelope instance
                 */
                EventEnvelope.create = function create(properties) {
                    return new EventEnvelope(properties);
                };

                /**
                 * Encodes the specified EventEnvelope message. Does not implicitly {@link gmaing.events.v1.EventEnvelope.verify|verify} messages.
                 * @function encode
                 * @memberof gmaing.events.v1.EventEnvelope
                 * @static
                 * @param {gmaing.events.v1.IEventEnvelope} message EventEnvelope message or plain object to encode
                 * @param {$protobuf.Writer} [writer] Writer to encode to
                 * @returns {$protobuf.Writer} Writer
                 */
                EventEnvelope.encode = function encode(message, writer) {
                    if (!writer)
                        writer = $Writer.create();
                    if (message.eventId != null && Object.hasOwnProperty.call(message, "eventId"))
                        writer.uint32(/* id 1, wireType 2 =*/10).string(message.eventId);
                    if (message.serverTsMs != null && Object.hasOwnProperty.call(message, "serverTsMs"))
                        writer.uint32(/* id 2, wireType 0 =*/16).int64(message.serverTsMs);
                    if (message.source != null && Object.hasOwnProperty.call(message, "source"))
                        writer.uint32(/* id 3, wireType 2 =*/26).string(message.source);
                    if (message.channel != null && Object.hasOwnProperty.call(message, "channel"))
                        writer.uint32(/* id 4, wireType 2 =*/34).string(message.channel);
                    if (message.seq != null && Object.hasOwnProperty.call(message, "seq"))
                        writer.uint32(/* id 5, wireType 0 =*/40).int64(message.seq);
                    if (message.socialPostCreated != null && Object.hasOwnProperty.call(message, "socialPostCreated"))
                        $root.gmaing.events.v1.SocialPostCreated.encode(message.socialPostCreated, writer.uint32(/* id 10, wireType 2 =*/82).fork()).ldelim();
                    if (message.socialGiftSent != null && Object.hasOwnProperty.call(message, "socialGiftSent"))
                        $root.gmaing.events.v1.SocialGiftSent.encode(message.socialGiftSent, writer.uint32(/* id 11, wireType 2 =*/90).fork()).ldelim();
                    if (message.liveDrawStateUpdated != null && Object.hasOwnProperty.call(message, "liveDrawStateUpdated"))
                        $root.gmaing.events.v1.LiveDrawStateUpdated.encode(message.liveDrawStateUpdated, writer.uint32(/* id 12, wireType 2 =*/98).fork()).ldelim();
                    if (message.liveOddsUpdated != null && Object.hasOwnProperty.call(message, "liveOddsUpdated"))
                        $root.gmaing.events.v1.LiveOddsUpdated.encode(message.liveOddsUpdated, writer.uint32(/* id 13, wireType 2 =*/106).fork()).ldelim();
                    if (message.bettingBetPlaced != null && Object.hasOwnProperty.call(message, "bettingBetPlaced"))
                        $root.gmaing.events.v1.BettingBetPlaced.encode(message.bettingBetPlaced, writer.uint32(/* id 14, wireType 2 =*/114).fork()).ldelim();
                    if (message.bettingSettlementApplied != null && Object.hasOwnProperty.call(message, "bettingSettlementApplied"))
                        $root.gmaing.events.v1.BettingSettlementApplied.encode(message.bettingSettlementApplied, writer.uint32(/* id 15, wireType 2 =*/122).fork()).ldelim();
                    if (message.systemNotice != null && Object.hasOwnProperty.call(message, "systemNotice"))
                        $root.gmaing.events.v1.SystemNotice.encode(message.systemNotice, writer.uint32(/* id 16, wireType 2 =*/130).fork()).ldelim();
                    if (message.heartbeat != null && Object.hasOwnProperty.call(message, "heartbeat"))
                        $root.gmaing.events.v1.Heartbeat.encode(message.heartbeat, writer.uint32(/* id 17, wireType 2 =*/138).fork()).ldelim();
                    return writer;
                };

                /**
                 * Encodes the specified EventEnvelope message, length delimited. Does not implicitly {@link gmaing.events.v1.EventEnvelope.verify|verify} messages.
                 * @function encodeDelimited
                 * @memberof gmaing.events.v1.EventEnvelope
                 * @static
                 * @param {gmaing.events.v1.IEventEnvelope} message EventEnvelope message or plain object to encode
                 * @param {$protobuf.Writer} [writer] Writer to encode to
                 * @returns {$protobuf.Writer} Writer
                 */
                EventEnvelope.encodeDelimited = function encodeDelimited(message, writer) {
                    return this.encode(message, writer).ldelim();
                };

                /**
                 * Decodes an EventEnvelope message from the specified reader or buffer.
                 * @function decode
                 * @memberof gmaing.events.v1.EventEnvelope
                 * @static
                 * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
                 * @param {number} [length] Message length if known beforehand
                 * @returns {gmaing.events.v1.EventEnvelope} EventEnvelope
                 * @throws {Error} If the payload is not a reader or valid buffer
                 * @throws {$protobuf.util.ProtocolError} If required fields are missing
                 */
                EventEnvelope.decode = function decode(reader, length, error) {
                    if (!(reader instanceof $Reader))
                        reader = $Reader.create(reader);
                    var end = length === undefined ? reader.len : reader.pos + length, message = new $root.gmaing.events.v1.EventEnvelope();
                    while (reader.pos < end) {
                        var tag = reader.uint32();
                        if (tag === error)
                            break;
                        switch (tag >>> 3) {
                        case 1: {
                                message.eventId = reader.string();
                                break;
                            }
                        case 2: {
                                message.serverTsMs = reader.int64();
                                break;
                            }
                        case 3: {
                                message.source = reader.string();
                                break;
                            }
                        case 4: {
                                message.channel = reader.string();
                                break;
                            }
                        case 5: {
                                message.seq = reader.int64();
                                break;
                            }
                        case 10: {
                                message.socialPostCreated = $root.gmaing.events.v1.SocialPostCreated.decode(reader, reader.uint32());
                                break;
                            }
                        case 11: {
                                message.socialGiftSent = $root.gmaing.events.v1.SocialGiftSent.decode(reader, reader.uint32());
                                break;
                            }
                        case 12: {
                                message.liveDrawStateUpdated = $root.gmaing.events.v1.LiveDrawStateUpdated.decode(reader, reader.uint32());
                                break;
                            }
                        case 13: {
                                message.liveOddsUpdated = $root.gmaing.events.v1.LiveOddsUpdated.decode(reader, reader.uint32());
                                break;
                            }
                        case 14: {
                                message.bettingBetPlaced = $root.gmaing.events.v1.BettingBetPlaced.decode(reader, reader.uint32());
                                break;
                            }
                        case 15: {
                                message.bettingSettlementApplied = $root.gmaing.events.v1.BettingSettlementApplied.decode(reader, reader.uint32());
                                break;
                            }
                        case 16: {
                                message.systemNotice = $root.gmaing.events.v1.SystemNotice.decode(reader, reader.uint32());
                                break;
                            }
                        case 17: {
                                message.heartbeat = $root.gmaing.events.v1.Heartbeat.decode(reader, reader.uint32());
                                break;
                            }
                        default:
                            reader.skipType(tag & 7);
                            break;
                        }
                    }
                    return message;
                };

                /**
                 * Decodes an EventEnvelope message from the specified reader or buffer, length delimited.
                 * @function decodeDelimited
                 * @memberof gmaing.events.v1.EventEnvelope
                 * @static
                 * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
                 * @returns {gmaing.events.v1.EventEnvelope} EventEnvelope
                 * @throws {Error} If the payload is not a reader or valid buffer
                 * @throws {$protobuf.util.ProtocolError} If required fields are missing
                 */
                EventEnvelope.decodeDelimited = function decodeDelimited(reader) {
                    if (!(reader instanceof $Reader))
                        reader = new $Reader(reader);
                    return this.decode(reader, reader.uint32());
                };

                /**
                 * Verifies an EventEnvelope message.
                 * @function verify
                 * @memberof gmaing.events.v1.EventEnvelope
                 * @static
                 * @param {Object.<string,*>} message Plain object to verify
                 * @returns {string|null} `null` if valid, otherwise the reason why it is not
                 */
                EventEnvelope.verify = function verify(message) {
                    if (typeof message !== "object" || message === null)
                        return "object expected";
                    var properties = {};
                    if (message.eventId != null && message.hasOwnProperty("eventId"))
                        if (!$util.isString(message.eventId))
                            return "eventId: string expected";
                    if (message.serverTsMs != null && message.hasOwnProperty("serverTsMs"))
                        if (!$util.isInteger(message.serverTsMs) && !(message.serverTsMs && $util.isInteger(message.serverTsMs.low) && $util.isInteger(message.serverTsMs.high)))
                            return "serverTsMs: integer|Long expected";
                    if (message.source != null && message.hasOwnProperty("source"))
                        if (!$util.isString(message.source))
                            return "source: string expected";
                    if (message.channel != null && message.hasOwnProperty("channel"))
                        if (!$util.isString(message.channel))
                            return "channel: string expected";
                    if (message.seq != null && message.hasOwnProperty("seq"))
                        if (!$util.isInteger(message.seq) && !(message.seq && $util.isInteger(message.seq.low) && $util.isInteger(message.seq.high)))
                            return "seq: integer|Long expected";
                    if (message.socialPostCreated != null && message.hasOwnProperty("socialPostCreated")) {
                        properties.payload = 1;
                        {
                            var error = $root.gmaing.events.v1.SocialPostCreated.verify(message.socialPostCreated);
                            if (error)
                                return "socialPostCreated." + error;
                        }
                    }
                    if (message.socialGiftSent != null && message.hasOwnProperty("socialGiftSent")) {
                        if (properties.payload === 1)
                            return "payload: multiple values";
                        properties.payload = 1;
                        {
                            var error = $root.gmaing.events.v1.SocialGiftSent.verify(message.socialGiftSent);
                            if (error)
                                return "socialGiftSent." + error;
                        }
                    }
                    if (message.liveDrawStateUpdated != null && message.hasOwnProperty("liveDrawStateUpdated")) {
                        if (properties.payload === 1)
                            return "payload: multiple values";
                        properties.payload = 1;
                        {
                            var error = $root.gmaing.events.v1.LiveDrawStateUpdated.verify(message.liveDrawStateUpdated);
                            if (error)
                                return "liveDrawStateUpdated." + error;
                        }
                    }
                    if (message.liveOddsUpdated != null && message.hasOwnProperty("liveOddsUpdated")) {
                        if (properties.payload === 1)
                            return "payload: multiple values";
                        properties.payload = 1;
                        {
                            var error = $root.gmaing.events.v1.LiveOddsUpdated.verify(message.liveOddsUpdated);
                            if (error)
                                return "liveOddsUpdated." + error;
                        }
                    }
                    if (message.bettingBetPlaced != null && message.hasOwnProperty("bettingBetPlaced")) {
                        if (properties.payload === 1)
                            return "payload: multiple values";
                        properties.payload = 1;
                        {
                            var error = $root.gmaing.events.v1.BettingBetPlaced.verify(message.bettingBetPlaced);
                            if (error)
                                return "bettingBetPlaced." + error;
                        }
                    }
                    if (message.bettingSettlementApplied != null && message.hasOwnProperty("bettingSettlementApplied")) {
                        if (properties.payload === 1)
                            return "payload: multiple values";
                        properties.payload = 1;
                        {
                            var error = $root.gmaing.events.v1.BettingSettlementApplied.verify(message.bettingSettlementApplied);
                            if (error)
                                return "bettingSettlementApplied." + error;
                        }
                    }
                    if (message.systemNotice != null && message.hasOwnProperty("systemNotice")) {
                        if (properties.payload === 1)
                            return "payload: multiple values";
                        properties.payload = 1;
                        {
                            var error = $root.gmaing.events.v1.SystemNotice.verify(message.systemNotice);
                            if (error)
                                return "systemNotice." + error;
                        }
                    }
                    if (message.heartbeat != null && message.hasOwnProperty("heartbeat")) {
                        if (properties.payload === 1)
                            return "payload: multiple values";
                        properties.payload = 1;
                        {
                            var error = $root.gmaing.events.v1.Heartbeat.verify(message.heartbeat);
                            if (error)
                                return "heartbeat." + error;
                        }
                    }
                    return null;
                };

                /**
                 * Creates an EventEnvelope message from a plain object. Also converts values to their respective internal types.
                 * @function fromObject
                 * @memberof gmaing.events.v1.EventEnvelope
                 * @static
                 * @param {Object.<string,*>} object Plain object
                 * @returns {gmaing.events.v1.EventEnvelope} EventEnvelope
                 */
                EventEnvelope.fromObject = function fromObject(object) {
                    if (object instanceof $root.gmaing.events.v1.EventEnvelope)
                        return object;
                    var message = new $root.gmaing.events.v1.EventEnvelope();
                    if (object.eventId != null)
                        message.eventId = String(object.eventId);
                    if (object.serverTsMs != null)
                        if ($util.Long)
                            (message.serverTsMs = $util.Long.fromValue(object.serverTsMs)).unsigned = false;
                        else if (typeof object.serverTsMs === "string")
                            message.serverTsMs = parseInt(object.serverTsMs, 10);
                        else if (typeof object.serverTsMs === "number")
                            message.serverTsMs = object.serverTsMs;
                        else if (typeof object.serverTsMs === "object")
                            message.serverTsMs = new $util.LongBits(object.serverTsMs.low >>> 0, object.serverTsMs.high >>> 0).toNumber();
                    if (object.source != null)
                        message.source = String(object.source);
                    if (object.channel != null)
                        message.channel = String(object.channel);
                    if (object.seq != null)
                        if ($util.Long)
                            (message.seq = $util.Long.fromValue(object.seq)).unsigned = false;
                        else if (typeof object.seq === "string")
                            message.seq = parseInt(object.seq, 10);
                        else if (typeof object.seq === "number")
                            message.seq = object.seq;
                        else if (typeof object.seq === "object")
                            message.seq = new $util.LongBits(object.seq.low >>> 0, object.seq.high >>> 0).toNumber();
                    if (object.socialPostCreated != null) {
                        if (typeof object.socialPostCreated !== "object")
                            throw TypeError(".gmaing.events.v1.EventEnvelope.socialPostCreated: object expected");
                        message.socialPostCreated = $root.gmaing.events.v1.SocialPostCreated.fromObject(object.socialPostCreated);
                    }
                    if (object.socialGiftSent != null) {
                        if (typeof object.socialGiftSent !== "object")
                            throw TypeError(".gmaing.events.v1.EventEnvelope.socialGiftSent: object expected");
                        message.socialGiftSent = $root.gmaing.events.v1.SocialGiftSent.fromObject(object.socialGiftSent);
                    }
                    if (object.liveDrawStateUpdated != null) {
                        if (typeof object.liveDrawStateUpdated !== "object")
                            throw TypeError(".gmaing.events.v1.EventEnvelope.liveDrawStateUpdated: object expected");
                        message.liveDrawStateUpdated = $root.gmaing.events.v1.LiveDrawStateUpdated.fromObject(object.liveDrawStateUpdated);
                    }
                    if (object.liveOddsUpdated != null) {
                        if (typeof object.liveOddsUpdated !== "object")
                            throw TypeError(".gmaing.events.v1.EventEnvelope.liveOddsUpdated: object expected");
                        message.liveOddsUpdated = $root.gmaing.events.v1.LiveOddsUpdated.fromObject(object.liveOddsUpdated);
                    }
                    if (object.bettingBetPlaced != null) {
                        if (typeof object.bettingBetPlaced !== "object")
                            throw TypeError(".gmaing.events.v1.EventEnvelope.bettingBetPlaced: object expected");
                        message.bettingBetPlaced = $root.gmaing.events.v1.BettingBetPlaced.fromObject(object.bettingBetPlaced);
                    }
                    if (object.bettingSettlementApplied != null) {
                        if (typeof object.bettingSettlementApplied !== "object")
                            throw TypeError(".gmaing.events.v1.EventEnvelope.bettingSettlementApplied: object expected");
                        message.bettingSettlementApplied = $root.gmaing.events.v1.BettingSettlementApplied.fromObject(object.bettingSettlementApplied);
                    }
                    if (object.systemNotice != null) {
                        if (typeof object.systemNotice !== "object")
                            throw TypeError(".gmaing.events.v1.EventEnvelope.systemNotice: object expected");
                        message.systemNotice = $root.gmaing.events.v1.SystemNotice.fromObject(object.systemNotice);
                    }
                    if (object.heartbeat != null) {
                        if (typeof object.heartbeat !== "object")
                            throw TypeError(".gmaing.events.v1.EventEnvelope.heartbeat: object expected");
                        message.heartbeat = $root.gmaing.events.v1.Heartbeat.fromObject(object.heartbeat);
                    }
                    return message;
                };

                /**
                 * Creates a plain object from an EventEnvelope message. Also converts values to other types if specified.
                 * @function toObject
                 * @memberof gmaing.events.v1.EventEnvelope
                 * @static
                 * @param {gmaing.events.v1.EventEnvelope} message EventEnvelope
                 * @param {$protobuf.IConversionOptions} [options] Conversion options
                 * @returns {Object.<string,*>} Plain object
                 */
                EventEnvelope.toObject = function toObject(message, options) {
                    if (!options)
                        options = {};
                    var object = {};
                    if (options.defaults) {
                        object.eventId = "";
                        if ($util.Long) {
                            var long = new $util.Long(0, 0, false);
                            object.serverTsMs = options.longs === String ? long.toString() : options.longs === Number ? long.toNumber() : long;
                        } else
                            object.serverTsMs = options.longs === String ? "0" : 0;
                        object.source = "";
                        object.channel = "";
                        if ($util.Long) {
                            var long = new $util.Long(0, 0, false);
                            object.seq = options.longs === String ? long.toString() : options.longs === Number ? long.toNumber() : long;
                        } else
                            object.seq = options.longs === String ? "0" : 0;
                    }
                    if (message.eventId != null && message.hasOwnProperty("eventId"))
                        object.eventId = message.eventId;
                    if (message.serverTsMs != null && message.hasOwnProperty("serverTsMs"))
                        if (typeof message.serverTsMs === "number")
                            object.serverTsMs = options.longs === String ? String(message.serverTsMs) : message.serverTsMs;
                        else
                            object.serverTsMs = options.longs === String ? $util.Long.prototype.toString.call(message.serverTsMs) : options.longs === Number ? new $util.LongBits(message.serverTsMs.low >>> 0, message.serverTsMs.high >>> 0).toNumber() : message.serverTsMs;
                    if (message.source != null && message.hasOwnProperty("source"))
                        object.source = message.source;
                    if (message.channel != null && message.hasOwnProperty("channel"))
                        object.channel = message.channel;
                    if (message.seq != null && message.hasOwnProperty("seq"))
                        if (typeof message.seq === "number")
                            object.seq = options.longs === String ? String(message.seq) : message.seq;
                        else
                            object.seq = options.longs === String ? $util.Long.prototype.toString.call(message.seq) : options.longs === Number ? new $util.LongBits(message.seq.low >>> 0, message.seq.high >>> 0).toNumber() : message.seq;
                    if (message.socialPostCreated != null && message.hasOwnProperty("socialPostCreated")) {
                        object.socialPostCreated = $root.gmaing.events.v1.SocialPostCreated.toObject(message.socialPostCreated, options);
                        if (options.oneofs)
                            object.payload = "socialPostCreated";
                    }
                    if (message.socialGiftSent != null && message.hasOwnProperty("socialGiftSent")) {
                        object.socialGiftSent = $root.gmaing.events.v1.SocialGiftSent.toObject(message.socialGiftSent, options);
                        if (options.oneofs)
                            object.payload = "socialGiftSent";
                    }
                    if (message.liveDrawStateUpdated != null && message.hasOwnProperty("liveDrawStateUpdated")) {
                        object.liveDrawStateUpdated = $root.gmaing.events.v1.LiveDrawStateUpdated.toObject(message.liveDrawStateUpdated, options);
                        if (options.oneofs)
                            object.payload = "liveDrawStateUpdated";
                    }
                    if (message.liveOddsUpdated != null && message.hasOwnProperty("liveOddsUpdated")) {
                        object.liveOddsUpdated = $root.gmaing.events.v1.LiveOddsUpdated.toObject(message.liveOddsUpdated, options);
                        if (options.oneofs)
                            object.payload = "liveOddsUpdated";
                    }
                    if (message.bettingBetPlaced != null && message.hasOwnProperty("bettingBetPlaced")) {
                        object.bettingBetPlaced = $root.gmaing.events.v1.BettingBetPlaced.toObject(message.bettingBetPlaced, options);
                        if (options.oneofs)
                            object.payload = "bettingBetPlaced";
                    }
                    if (message.bettingSettlementApplied != null && message.hasOwnProperty("bettingSettlementApplied")) {
                        object.bettingSettlementApplied = $root.gmaing.events.v1.BettingSettlementApplied.toObject(message.bettingSettlementApplied, options);
                        if (options.oneofs)
                            object.payload = "bettingSettlementApplied";
                    }
                    if (message.systemNotice != null && message.hasOwnProperty("systemNotice")) {
                        object.systemNotice = $root.gmaing.events.v1.SystemNotice.toObject(message.systemNotice, options);
                        if (options.oneofs)
                            object.payload = "systemNotice";
                    }
                    if (message.heartbeat != null && message.hasOwnProperty("heartbeat")) {
                        object.heartbeat = $root.gmaing.events.v1.Heartbeat.toObject(message.heartbeat, options);
                        if (options.oneofs)
                            object.payload = "heartbeat";
                    }
                    return object;
                };

                /**
                 * Converts this EventEnvelope to JSON.
                 * @function toJSON
                 * @memberof gmaing.events.v1.EventEnvelope
                 * @instance
                 * @returns {Object.<string,*>} JSON object
                 */
                EventEnvelope.prototype.toJSON = function toJSON() {
                    return this.constructor.toObject(this, $protobuf.util.toJSONOptions);
                };

                /**
                 * Gets the default type url for EventEnvelope
                 * @function getTypeUrl
                 * @memberof gmaing.events.v1.EventEnvelope
                 * @static
                 * @param {string} [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
                 * @returns {string} The default type url
                 */
                EventEnvelope.getTypeUrl = function getTypeUrl(typeUrlPrefix) {
                    if (typeUrlPrefix === undefined) {
                        typeUrlPrefix = "type.googleapis.com";
                    }
                    return typeUrlPrefix + "/gmaing.events.v1.EventEnvelope";
                };

                return EventEnvelope;
            })();

            v1.SocialPostCreated = (function() {

                /**
                 * Properties of a SocialPostCreated.
                 * @memberof gmaing.events.v1
                 * @interface ISocialPostCreated
                 * @property {string|null} [postId] SocialPostCreated postId
                 * @property {string|null} [authorUserId] SocialPostCreated authorUserId
                 * @property {string|null} [previewText] SocialPostCreated previewText
                 * @property {number|Long|null} [createdAtMs] SocialPostCreated createdAtMs
                 */

                /**
                 * Constructs a new SocialPostCreated.
                 * @memberof gmaing.events.v1
                 * @classdesc Represents a SocialPostCreated.
                 * @implements ISocialPostCreated
                 * @constructor
                 * @param {gmaing.events.v1.ISocialPostCreated=} [properties] Properties to set
                 */
                function SocialPostCreated(properties) {
                    if (properties)
                        for (var keys = Object.keys(properties), i = 0; i < keys.length; ++i)
                            if (properties[keys[i]] != null)
                                this[keys[i]] = properties[keys[i]];
                }

                /**
                 * SocialPostCreated postId.
                 * @member {string} postId
                 * @memberof gmaing.events.v1.SocialPostCreated
                 * @instance
                 */
                SocialPostCreated.prototype.postId = "";

                /**
                 * SocialPostCreated authorUserId.
                 * @member {string} authorUserId
                 * @memberof gmaing.events.v1.SocialPostCreated
                 * @instance
                 */
                SocialPostCreated.prototype.authorUserId = "";

                /**
                 * SocialPostCreated previewText.
                 * @member {string} previewText
                 * @memberof gmaing.events.v1.SocialPostCreated
                 * @instance
                 */
                SocialPostCreated.prototype.previewText = "";

                /**
                 * SocialPostCreated createdAtMs.
                 * @member {number|Long} createdAtMs
                 * @memberof gmaing.events.v1.SocialPostCreated
                 * @instance
                 */
                SocialPostCreated.prototype.createdAtMs = $util.Long ? $util.Long.fromBits(0,0,false) : 0;

                /**
                 * Creates a new SocialPostCreated instance using the specified properties.
                 * @function create
                 * @memberof gmaing.events.v1.SocialPostCreated
                 * @static
                 * @param {gmaing.events.v1.ISocialPostCreated=} [properties] Properties to set
                 * @returns {gmaing.events.v1.SocialPostCreated} SocialPostCreated instance
                 */
                SocialPostCreated.create = function create(properties) {
                    return new SocialPostCreated(properties);
                };

                /**
                 * Encodes the specified SocialPostCreated message. Does not implicitly {@link gmaing.events.v1.SocialPostCreated.verify|verify} messages.
                 * @function encode
                 * @memberof gmaing.events.v1.SocialPostCreated
                 * @static
                 * @param {gmaing.events.v1.ISocialPostCreated} message SocialPostCreated message or plain object to encode
                 * @param {$protobuf.Writer} [writer] Writer to encode to
                 * @returns {$protobuf.Writer} Writer
                 */
                SocialPostCreated.encode = function encode(message, writer) {
                    if (!writer)
                        writer = $Writer.create();
                    if (message.postId != null && Object.hasOwnProperty.call(message, "postId"))
                        writer.uint32(/* id 1, wireType 2 =*/10).string(message.postId);
                    if (message.authorUserId != null && Object.hasOwnProperty.call(message, "authorUserId"))
                        writer.uint32(/* id 2, wireType 2 =*/18).string(message.authorUserId);
                    if (message.previewText != null && Object.hasOwnProperty.call(message, "previewText"))
                        writer.uint32(/* id 3, wireType 2 =*/26).string(message.previewText);
                    if (message.createdAtMs != null && Object.hasOwnProperty.call(message, "createdAtMs"))
                        writer.uint32(/* id 4, wireType 0 =*/32).int64(message.createdAtMs);
                    return writer;
                };

                /**
                 * Encodes the specified SocialPostCreated message, length delimited. Does not implicitly {@link gmaing.events.v1.SocialPostCreated.verify|verify} messages.
                 * @function encodeDelimited
                 * @memberof gmaing.events.v1.SocialPostCreated
                 * @static
                 * @param {gmaing.events.v1.ISocialPostCreated} message SocialPostCreated message or plain object to encode
                 * @param {$protobuf.Writer} [writer] Writer to encode to
                 * @returns {$protobuf.Writer} Writer
                 */
                SocialPostCreated.encodeDelimited = function encodeDelimited(message, writer) {
                    return this.encode(message, writer).ldelim();
                };

                /**
                 * Decodes a SocialPostCreated message from the specified reader or buffer.
                 * @function decode
                 * @memberof gmaing.events.v1.SocialPostCreated
                 * @static
                 * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
                 * @param {number} [length] Message length if known beforehand
                 * @returns {gmaing.events.v1.SocialPostCreated} SocialPostCreated
                 * @throws {Error} If the payload is not a reader or valid buffer
                 * @throws {$protobuf.util.ProtocolError} If required fields are missing
                 */
                SocialPostCreated.decode = function decode(reader, length, error) {
                    if (!(reader instanceof $Reader))
                        reader = $Reader.create(reader);
                    var end = length === undefined ? reader.len : reader.pos + length, message = new $root.gmaing.events.v1.SocialPostCreated();
                    while (reader.pos < end) {
                        var tag = reader.uint32();
                        if (tag === error)
                            break;
                        switch (tag >>> 3) {
                        case 1: {
                                message.postId = reader.string();
                                break;
                            }
                        case 2: {
                                message.authorUserId = reader.string();
                                break;
                            }
                        case 3: {
                                message.previewText = reader.string();
                                break;
                            }
                        case 4: {
                                message.createdAtMs = reader.int64();
                                break;
                            }
                        default:
                            reader.skipType(tag & 7);
                            break;
                        }
                    }
                    return message;
                };

                /**
                 * Decodes a SocialPostCreated message from the specified reader or buffer, length delimited.
                 * @function decodeDelimited
                 * @memberof gmaing.events.v1.SocialPostCreated
                 * @static
                 * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
                 * @returns {gmaing.events.v1.SocialPostCreated} SocialPostCreated
                 * @throws {Error} If the payload is not a reader or valid buffer
                 * @throws {$protobuf.util.ProtocolError} If required fields are missing
                 */
                SocialPostCreated.decodeDelimited = function decodeDelimited(reader) {
                    if (!(reader instanceof $Reader))
                        reader = new $Reader(reader);
                    return this.decode(reader, reader.uint32());
                };

                /**
                 * Verifies a SocialPostCreated message.
                 * @function verify
                 * @memberof gmaing.events.v1.SocialPostCreated
                 * @static
                 * @param {Object.<string,*>} message Plain object to verify
                 * @returns {string|null} `null` if valid, otherwise the reason why it is not
                 */
                SocialPostCreated.verify = function verify(message) {
                    if (typeof message !== "object" || message === null)
                        return "object expected";
                    if (message.postId != null && message.hasOwnProperty("postId"))
                        if (!$util.isString(message.postId))
                            return "postId: string expected";
                    if (message.authorUserId != null && message.hasOwnProperty("authorUserId"))
                        if (!$util.isString(message.authorUserId))
                            return "authorUserId: string expected";
                    if (message.previewText != null && message.hasOwnProperty("previewText"))
                        if (!$util.isString(message.previewText))
                            return "previewText: string expected";
                    if (message.createdAtMs != null && message.hasOwnProperty("createdAtMs"))
                        if (!$util.isInteger(message.createdAtMs) && !(message.createdAtMs && $util.isInteger(message.createdAtMs.low) && $util.isInteger(message.createdAtMs.high)))
                            return "createdAtMs: integer|Long expected";
                    return null;
                };

                /**
                 * Creates a SocialPostCreated message from a plain object. Also converts values to their respective internal types.
                 * @function fromObject
                 * @memberof gmaing.events.v1.SocialPostCreated
                 * @static
                 * @param {Object.<string,*>} object Plain object
                 * @returns {gmaing.events.v1.SocialPostCreated} SocialPostCreated
                 */
                SocialPostCreated.fromObject = function fromObject(object) {
                    if (object instanceof $root.gmaing.events.v1.SocialPostCreated)
                        return object;
                    var message = new $root.gmaing.events.v1.SocialPostCreated();
                    if (object.postId != null)
                        message.postId = String(object.postId);
                    if (object.authorUserId != null)
                        message.authorUserId = String(object.authorUserId);
                    if (object.previewText != null)
                        message.previewText = String(object.previewText);
                    if (object.createdAtMs != null)
                        if ($util.Long)
                            (message.createdAtMs = $util.Long.fromValue(object.createdAtMs)).unsigned = false;
                        else if (typeof object.createdAtMs === "string")
                            message.createdAtMs = parseInt(object.createdAtMs, 10);
                        else if (typeof object.createdAtMs === "number")
                            message.createdAtMs = object.createdAtMs;
                        else if (typeof object.createdAtMs === "object")
                            message.createdAtMs = new $util.LongBits(object.createdAtMs.low >>> 0, object.createdAtMs.high >>> 0).toNumber();
                    return message;
                };

                /**
                 * Creates a plain object from a SocialPostCreated message. Also converts values to other types if specified.
                 * @function toObject
                 * @memberof gmaing.events.v1.SocialPostCreated
                 * @static
                 * @param {gmaing.events.v1.SocialPostCreated} message SocialPostCreated
                 * @param {$protobuf.IConversionOptions} [options] Conversion options
                 * @returns {Object.<string,*>} Plain object
                 */
                SocialPostCreated.toObject = function toObject(message, options) {
                    if (!options)
                        options = {};
                    var object = {};
                    if (options.defaults) {
                        object.postId = "";
                        object.authorUserId = "";
                        object.previewText = "";
                        if ($util.Long) {
                            var long = new $util.Long(0, 0, false);
                            object.createdAtMs = options.longs === String ? long.toString() : options.longs === Number ? long.toNumber() : long;
                        } else
                            object.createdAtMs = options.longs === String ? "0" : 0;
                    }
                    if (message.postId != null && message.hasOwnProperty("postId"))
                        object.postId = message.postId;
                    if (message.authorUserId != null && message.hasOwnProperty("authorUserId"))
                        object.authorUserId = message.authorUserId;
                    if (message.previewText != null && message.hasOwnProperty("previewText"))
                        object.previewText = message.previewText;
                    if (message.createdAtMs != null && message.hasOwnProperty("createdAtMs"))
                        if (typeof message.createdAtMs === "number")
                            object.createdAtMs = options.longs === String ? String(message.createdAtMs) : message.createdAtMs;
                        else
                            object.createdAtMs = options.longs === String ? $util.Long.prototype.toString.call(message.createdAtMs) : options.longs === Number ? new $util.LongBits(message.createdAtMs.low >>> 0, message.createdAtMs.high >>> 0).toNumber() : message.createdAtMs;
                    return object;
                };

                /**
                 * Converts this SocialPostCreated to JSON.
                 * @function toJSON
                 * @memberof gmaing.events.v1.SocialPostCreated
                 * @instance
                 * @returns {Object.<string,*>} JSON object
                 */
                SocialPostCreated.prototype.toJSON = function toJSON() {
                    return this.constructor.toObject(this, $protobuf.util.toJSONOptions);
                };

                /**
                 * Gets the default type url for SocialPostCreated
                 * @function getTypeUrl
                 * @memberof gmaing.events.v1.SocialPostCreated
                 * @static
                 * @param {string} [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
                 * @returns {string} The default type url
                 */
                SocialPostCreated.getTypeUrl = function getTypeUrl(typeUrlPrefix) {
                    if (typeUrlPrefix === undefined) {
                        typeUrlPrefix = "type.googleapis.com";
                    }
                    return typeUrlPrefix + "/gmaing.events.v1.SocialPostCreated";
                };

                return SocialPostCreated;
            })();

            v1.SocialGiftSent = (function() {

                /**
                 * Properties of a SocialGiftSent.
                 * @memberof gmaing.events.v1
                 * @interface ISocialGiftSent
                 * @property {string|null} [postId] SocialGiftSent postId
                 * @property {string|null} [fromUserId] SocialGiftSent fromUserId
                 * @property {string|null} [toUserId] SocialGiftSent toUserId
                 * @property {string|null} [giftItemId] SocialGiftSent giftItemId
                 * @property {number|null} [quantity] SocialGiftSent quantity
                 * @property {number|Long|null} [totalValue] SocialGiftSent totalValue
                 * @property {number|Long|null} [createdAtMs] SocialGiftSent createdAtMs
                 */

                /**
                 * Constructs a new SocialGiftSent.
                 * @memberof gmaing.events.v1
                 * @classdesc Represents a SocialGiftSent.
                 * @implements ISocialGiftSent
                 * @constructor
                 * @param {gmaing.events.v1.ISocialGiftSent=} [properties] Properties to set
                 */
                function SocialGiftSent(properties) {
                    if (properties)
                        for (var keys = Object.keys(properties), i = 0; i < keys.length; ++i)
                            if (properties[keys[i]] != null)
                                this[keys[i]] = properties[keys[i]];
                }

                /**
                 * SocialGiftSent postId.
                 * @member {string} postId
                 * @memberof gmaing.events.v1.SocialGiftSent
                 * @instance
                 */
                SocialGiftSent.prototype.postId = "";

                /**
                 * SocialGiftSent fromUserId.
                 * @member {string} fromUserId
                 * @memberof gmaing.events.v1.SocialGiftSent
                 * @instance
                 */
                SocialGiftSent.prototype.fromUserId = "";

                /**
                 * SocialGiftSent toUserId.
                 * @member {string} toUserId
                 * @memberof gmaing.events.v1.SocialGiftSent
                 * @instance
                 */
                SocialGiftSent.prototype.toUserId = "";

                /**
                 * SocialGiftSent giftItemId.
                 * @member {string} giftItemId
                 * @memberof gmaing.events.v1.SocialGiftSent
                 * @instance
                 */
                SocialGiftSent.prototype.giftItemId = "";

                /**
                 * SocialGiftSent quantity.
                 * @member {number} quantity
                 * @memberof gmaing.events.v1.SocialGiftSent
                 * @instance
                 */
                SocialGiftSent.prototype.quantity = 0;

                /**
                 * SocialGiftSent totalValue.
                 * @member {number|Long} totalValue
                 * @memberof gmaing.events.v1.SocialGiftSent
                 * @instance
                 */
                SocialGiftSent.prototype.totalValue = $util.Long ? $util.Long.fromBits(0,0,false) : 0;

                /**
                 * SocialGiftSent createdAtMs.
                 * @member {number|Long} createdAtMs
                 * @memberof gmaing.events.v1.SocialGiftSent
                 * @instance
                 */
                SocialGiftSent.prototype.createdAtMs = $util.Long ? $util.Long.fromBits(0,0,false) : 0;

                /**
                 * Creates a new SocialGiftSent instance using the specified properties.
                 * @function create
                 * @memberof gmaing.events.v1.SocialGiftSent
                 * @static
                 * @param {gmaing.events.v1.ISocialGiftSent=} [properties] Properties to set
                 * @returns {gmaing.events.v1.SocialGiftSent} SocialGiftSent instance
                 */
                SocialGiftSent.create = function create(properties) {
                    return new SocialGiftSent(properties);
                };

                /**
                 * Encodes the specified SocialGiftSent message. Does not implicitly {@link gmaing.events.v1.SocialGiftSent.verify|verify} messages.
                 * @function encode
                 * @memberof gmaing.events.v1.SocialGiftSent
                 * @static
                 * @param {gmaing.events.v1.ISocialGiftSent} message SocialGiftSent message or plain object to encode
                 * @param {$protobuf.Writer} [writer] Writer to encode to
                 * @returns {$protobuf.Writer} Writer
                 */
                SocialGiftSent.encode = function encode(message, writer) {
                    if (!writer)
                        writer = $Writer.create();
                    if (message.postId != null && Object.hasOwnProperty.call(message, "postId"))
                        writer.uint32(/* id 1, wireType 2 =*/10).string(message.postId);
                    if (message.fromUserId != null && Object.hasOwnProperty.call(message, "fromUserId"))
                        writer.uint32(/* id 2, wireType 2 =*/18).string(message.fromUserId);
                    if (message.toUserId != null && Object.hasOwnProperty.call(message, "toUserId"))
                        writer.uint32(/* id 3, wireType 2 =*/26).string(message.toUserId);
                    if (message.giftItemId != null && Object.hasOwnProperty.call(message, "giftItemId"))
                        writer.uint32(/* id 4, wireType 2 =*/34).string(message.giftItemId);
                    if (message.quantity != null && Object.hasOwnProperty.call(message, "quantity"))
                        writer.uint32(/* id 5, wireType 0 =*/40).int32(message.quantity);
                    if (message.totalValue != null && Object.hasOwnProperty.call(message, "totalValue"))
                        writer.uint32(/* id 6, wireType 0 =*/48).int64(message.totalValue);
                    if (message.createdAtMs != null && Object.hasOwnProperty.call(message, "createdAtMs"))
                        writer.uint32(/* id 7, wireType 0 =*/56).int64(message.createdAtMs);
                    return writer;
                };

                /**
                 * Encodes the specified SocialGiftSent message, length delimited. Does not implicitly {@link gmaing.events.v1.SocialGiftSent.verify|verify} messages.
                 * @function encodeDelimited
                 * @memberof gmaing.events.v1.SocialGiftSent
                 * @static
                 * @param {gmaing.events.v1.ISocialGiftSent} message SocialGiftSent message or plain object to encode
                 * @param {$protobuf.Writer} [writer] Writer to encode to
                 * @returns {$protobuf.Writer} Writer
                 */
                SocialGiftSent.encodeDelimited = function encodeDelimited(message, writer) {
                    return this.encode(message, writer).ldelim();
                };

                /**
                 * Decodes a SocialGiftSent message from the specified reader or buffer.
                 * @function decode
                 * @memberof gmaing.events.v1.SocialGiftSent
                 * @static
                 * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
                 * @param {number} [length] Message length if known beforehand
                 * @returns {gmaing.events.v1.SocialGiftSent} SocialGiftSent
                 * @throws {Error} If the payload is not a reader or valid buffer
                 * @throws {$protobuf.util.ProtocolError} If required fields are missing
                 */
                SocialGiftSent.decode = function decode(reader, length, error) {
                    if (!(reader instanceof $Reader))
                        reader = $Reader.create(reader);
                    var end = length === undefined ? reader.len : reader.pos + length, message = new $root.gmaing.events.v1.SocialGiftSent();
                    while (reader.pos < end) {
                        var tag = reader.uint32();
                        if (tag === error)
                            break;
                        switch (tag >>> 3) {
                        case 1: {
                                message.postId = reader.string();
                                break;
                            }
                        case 2: {
                                message.fromUserId = reader.string();
                                break;
                            }
                        case 3: {
                                message.toUserId = reader.string();
                                break;
                            }
                        case 4: {
                                message.giftItemId = reader.string();
                                break;
                            }
                        case 5: {
                                message.quantity = reader.int32();
                                break;
                            }
                        case 6: {
                                message.totalValue = reader.int64();
                                break;
                            }
                        case 7: {
                                message.createdAtMs = reader.int64();
                                break;
                            }
                        default:
                            reader.skipType(tag & 7);
                            break;
                        }
                    }
                    return message;
                };

                /**
                 * Decodes a SocialGiftSent message from the specified reader or buffer, length delimited.
                 * @function decodeDelimited
                 * @memberof gmaing.events.v1.SocialGiftSent
                 * @static
                 * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
                 * @returns {gmaing.events.v1.SocialGiftSent} SocialGiftSent
                 * @throws {Error} If the payload is not a reader or valid buffer
                 * @throws {$protobuf.util.ProtocolError} If required fields are missing
                 */
                SocialGiftSent.decodeDelimited = function decodeDelimited(reader) {
                    if (!(reader instanceof $Reader))
                        reader = new $Reader(reader);
                    return this.decode(reader, reader.uint32());
                };

                /**
                 * Verifies a SocialGiftSent message.
                 * @function verify
                 * @memberof gmaing.events.v1.SocialGiftSent
                 * @static
                 * @param {Object.<string,*>} message Plain object to verify
                 * @returns {string|null} `null` if valid, otherwise the reason why it is not
                 */
                SocialGiftSent.verify = function verify(message) {
                    if (typeof message !== "object" || message === null)
                        return "object expected";
                    if (message.postId != null && message.hasOwnProperty("postId"))
                        if (!$util.isString(message.postId))
                            return "postId: string expected";
                    if (message.fromUserId != null && message.hasOwnProperty("fromUserId"))
                        if (!$util.isString(message.fromUserId))
                            return "fromUserId: string expected";
                    if (message.toUserId != null && message.hasOwnProperty("toUserId"))
                        if (!$util.isString(message.toUserId))
                            return "toUserId: string expected";
                    if (message.giftItemId != null && message.hasOwnProperty("giftItemId"))
                        if (!$util.isString(message.giftItemId))
                            return "giftItemId: string expected";
                    if (message.quantity != null && message.hasOwnProperty("quantity"))
                        if (!$util.isInteger(message.quantity))
                            return "quantity: integer expected";
                    if (message.totalValue != null && message.hasOwnProperty("totalValue"))
                        if (!$util.isInteger(message.totalValue) && !(message.totalValue && $util.isInteger(message.totalValue.low) && $util.isInteger(message.totalValue.high)))
                            return "totalValue: integer|Long expected";
                    if (message.createdAtMs != null && message.hasOwnProperty("createdAtMs"))
                        if (!$util.isInteger(message.createdAtMs) && !(message.createdAtMs && $util.isInteger(message.createdAtMs.low) && $util.isInteger(message.createdAtMs.high)))
                            return "createdAtMs: integer|Long expected";
                    return null;
                };

                /**
                 * Creates a SocialGiftSent message from a plain object. Also converts values to their respective internal types.
                 * @function fromObject
                 * @memberof gmaing.events.v1.SocialGiftSent
                 * @static
                 * @param {Object.<string,*>} object Plain object
                 * @returns {gmaing.events.v1.SocialGiftSent} SocialGiftSent
                 */
                SocialGiftSent.fromObject = function fromObject(object) {
                    if (object instanceof $root.gmaing.events.v1.SocialGiftSent)
                        return object;
                    var message = new $root.gmaing.events.v1.SocialGiftSent();
                    if (object.postId != null)
                        message.postId = String(object.postId);
                    if (object.fromUserId != null)
                        message.fromUserId = String(object.fromUserId);
                    if (object.toUserId != null)
                        message.toUserId = String(object.toUserId);
                    if (object.giftItemId != null)
                        message.giftItemId = String(object.giftItemId);
                    if (object.quantity != null)
                        message.quantity = object.quantity | 0;
                    if (object.totalValue != null)
                        if ($util.Long)
                            (message.totalValue = $util.Long.fromValue(object.totalValue)).unsigned = false;
                        else if (typeof object.totalValue === "string")
                            message.totalValue = parseInt(object.totalValue, 10);
                        else if (typeof object.totalValue === "number")
                            message.totalValue = object.totalValue;
                        else if (typeof object.totalValue === "object")
                            message.totalValue = new $util.LongBits(object.totalValue.low >>> 0, object.totalValue.high >>> 0).toNumber();
                    if (object.createdAtMs != null)
                        if ($util.Long)
                            (message.createdAtMs = $util.Long.fromValue(object.createdAtMs)).unsigned = false;
                        else if (typeof object.createdAtMs === "string")
                            message.createdAtMs = parseInt(object.createdAtMs, 10);
                        else if (typeof object.createdAtMs === "number")
                            message.createdAtMs = object.createdAtMs;
                        else if (typeof object.createdAtMs === "object")
                            message.createdAtMs = new $util.LongBits(object.createdAtMs.low >>> 0, object.createdAtMs.high >>> 0).toNumber();
                    return message;
                };

                /**
                 * Creates a plain object from a SocialGiftSent message. Also converts values to other types if specified.
                 * @function toObject
                 * @memberof gmaing.events.v1.SocialGiftSent
                 * @static
                 * @param {gmaing.events.v1.SocialGiftSent} message SocialGiftSent
                 * @param {$protobuf.IConversionOptions} [options] Conversion options
                 * @returns {Object.<string,*>} Plain object
                 */
                SocialGiftSent.toObject = function toObject(message, options) {
                    if (!options)
                        options = {};
                    var object = {};
                    if (options.defaults) {
                        object.postId = "";
                        object.fromUserId = "";
                        object.toUserId = "";
                        object.giftItemId = "";
                        object.quantity = 0;
                        if ($util.Long) {
                            var long = new $util.Long(0, 0, false);
                            object.totalValue = options.longs === String ? long.toString() : options.longs === Number ? long.toNumber() : long;
                        } else
                            object.totalValue = options.longs === String ? "0" : 0;
                        if ($util.Long) {
                            var long = new $util.Long(0, 0, false);
                            object.createdAtMs = options.longs === String ? long.toString() : options.longs === Number ? long.toNumber() : long;
                        } else
                            object.createdAtMs = options.longs === String ? "0" : 0;
                    }
                    if (message.postId != null && message.hasOwnProperty("postId"))
                        object.postId = message.postId;
                    if (message.fromUserId != null && message.hasOwnProperty("fromUserId"))
                        object.fromUserId = message.fromUserId;
                    if (message.toUserId != null && message.hasOwnProperty("toUserId"))
                        object.toUserId = message.toUserId;
                    if (message.giftItemId != null && message.hasOwnProperty("giftItemId"))
                        object.giftItemId = message.giftItemId;
                    if (message.quantity != null && message.hasOwnProperty("quantity"))
                        object.quantity = message.quantity;
                    if (message.totalValue != null && message.hasOwnProperty("totalValue"))
                        if (typeof message.totalValue === "number")
                            object.totalValue = options.longs === String ? String(message.totalValue) : message.totalValue;
                        else
                            object.totalValue = options.longs === String ? $util.Long.prototype.toString.call(message.totalValue) : options.longs === Number ? new $util.LongBits(message.totalValue.low >>> 0, message.totalValue.high >>> 0).toNumber() : message.totalValue;
                    if (message.createdAtMs != null && message.hasOwnProperty("createdAtMs"))
                        if (typeof message.createdAtMs === "number")
                            object.createdAtMs = options.longs === String ? String(message.createdAtMs) : message.createdAtMs;
                        else
                            object.createdAtMs = options.longs === String ? $util.Long.prototype.toString.call(message.createdAtMs) : options.longs === Number ? new $util.LongBits(message.createdAtMs.low >>> 0, message.createdAtMs.high >>> 0).toNumber() : message.createdAtMs;
                    return object;
                };

                /**
                 * Converts this SocialGiftSent to JSON.
                 * @function toJSON
                 * @memberof gmaing.events.v1.SocialGiftSent
                 * @instance
                 * @returns {Object.<string,*>} JSON object
                 */
                SocialGiftSent.prototype.toJSON = function toJSON() {
                    return this.constructor.toObject(this, $protobuf.util.toJSONOptions);
                };

                /**
                 * Gets the default type url for SocialGiftSent
                 * @function getTypeUrl
                 * @memberof gmaing.events.v1.SocialGiftSent
                 * @static
                 * @param {string} [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
                 * @returns {string} The default type url
                 */
                SocialGiftSent.getTypeUrl = function getTypeUrl(typeUrlPrefix) {
                    if (typeUrlPrefix === undefined) {
                        typeUrlPrefix = "type.googleapis.com";
                    }
                    return typeUrlPrefix + "/gmaing.events.v1.SocialGiftSent";
                };

                return SocialGiftSent;
            })();

            v1.LiveDrawStateUpdated = (function() {

                /**
                 * Properties of a LiveDrawStateUpdated.
                 * @memberof gmaing.events.v1
                 * @interface ILiveDrawStateUpdated
                 * @property {string|null} [market] LiveDrawStateUpdated market
                 * @property {string|null} [session] LiveDrawStateUpdated session
                 * @property {string|null} [drawId] LiveDrawStateUpdated drawId
                 * @property {string|null} [state] LiveDrawStateUpdated state
                 * @property {number|null} [currentValue] LiveDrawStateUpdated currentValue
                 * @property {number|null} [previousValue] LiveDrawStateUpdated previousValue
                 * @property {number|Long|null} [resultAtMs] LiveDrawStateUpdated resultAtMs
                 * @property {number|Long|null} [nextTransitionMs] LiveDrawStateUpdated nextTransitionMs
                 */

                /**
                 * Constructs a new LiveDrawStateUpdated.
                 * @memberof gmaing.events.v1
                 * @classdesc Represents a LiveDrawStateUpdated.
                 * @implements ILiveDrawStateUpdated
                 * @constructor
                 * @param {gmaing.events.v1.ILiveDrawStateUpdated=} [properties] Properties to set
                 */
                function LiveDrawStateUpdated(properties) {
                    if (properties)
                        for (var keys = Object.keys(properties), i = 0; i < keys.length; ++i)
                            if (properties[keys[i]] != null)
                                this[keys[i]] = properties[keys[i]];
                }

                /**
                 * LiveDrawStateUpdated market.
                 * @member {string} market
                 * @memberof gmaing.events.v1.LiveDrawStateUpdated
                 * @instance
                 */
                LiveDrawStateUpdated.prototype.market = "";

                /**
                 * LiveDrawStateUpdated session.
                 * @member {string} session
                 * @memberof gmaing.events.v1.LiveDrawStateUpdated
                 * @instance
                 */
                LiveDrawStateUpdated.prototype.session = "";

                /**
                 * LiveDrawStateUpdated drawId.
                 * @member {string} drawId
                 * @memberof gmaing.events.v1.LiveDrawStateUpdated
                 * @instance
                 */
                LiveDrawStateUpdated.prototype.drawId = "";

                /**
                 * LiveDrawStateUpdated state.
                 * @member {string} state
                 * @memberof gmaing.events.v1.LiveDrawStateUpdated
                 * @instance
                 */
                LiveDrawStateUpdated.prototype.state = "";

                /**
                 * LiveDrawStateUpdated currentValue.
                 * @member {number} currentValue
                 * @memberof gmaing.events.v1.LiveDrawStateUpdated
                 * @instance
                 */
                LiveDrawStateUpdated.prototype.currentValue = 0;

                /**
                 * LiveDrawStateUpdated previousValue.
                 * @member {number} previousValue
                 * @memberof gmaing.events.v1.LiveDrawStateUpdated
                 * @instance
                 */
                LiveDrawStateUpdated.prototype.previousValue = 0;

                /**
                 * LiveDrawStateUpdated resultAtMs.
                 * @member {number|Long} resultAtMs
                 * @memberof gmaing.events.v1.LiveDrawStateUpdated
                 * @instance
                 */
                LiveDrawStateUpdated.prototype.resultAtMs = $util.Long ? $util.Long.fromBits(0,0,false) : 0;

                /**
                 * LiveDrawStateUpdated nextTransitionMs.
                 * @member {number|Long} nextTransitionMs
                 * @memberof gmaing.events.v1.LiveDrawStateUpdated
                 * @instance
                 */
                LiveDrawStateUpdated.prototype.nextTransitionMs = $util.Long ? $util.Long.fromBits(0,0,false) : 0;

                /**
                 * Creates a new LiveDrawStateUpdated instance using the specified properties.
                 * @function create
                 * @memberof gmaing.events.v1.LiveDrawStateUpdated
                 * @static
                 * @param {gmaing.events.v1.ILiveDrawStateUpdated=} [properties] Properties to set
                 * @returns {gmaing.events.v1.LiveDrawStateUpdated} LiveDrawStateUpdated instance
                 */
                LiveDrawStateUpdated.create = function create(properties) {
                    return new LiveDrawStateUpdated(properties);
                };

                /**
                 * Encodes the specified LiveDrawStateUpdated message. Does not implicitly {@link gmaing.events.v1.LiveDrawStateUpdated.verify|verify} messages.
                 * @function encode
                 * @memberof gmaing.events.v1.LiveDrawStateUpdated
                 * @static
                 * @param {gmaing.events.v1.ILiveDrawStateUpdated} message LiveDrawStateUpdated message or plain object to encode
                 * @param {$protobuf.Writer} [writer] Writer to encode to
                 * @returns {$protobuf.Writer} Writer
                 */
                LiveDrawStateUpdated.encode = function encode(message, writer) {
                    if (!writer)
                        writer = $Writer.create();
                    if (message.market != null && Object.hasOwnProperty.call(message, "market"))
                        writer.uint32(/* id 1, wireType 2 =*/10).string(message.market);
                    if (message.session != null && Object.hasOwnProperty.call(message, "session"))
                        writer.uint32(/* id 2, wireType 2 =*/18).string(message.session);
                    if (message.drawId != null && Object.hasOwnProperty.call(message, "drawId"))
                        writer.uint32(/* id 3, wireType 2 =*/26).string(message.drawId);
                    if (message.state != null && Object.hasOwnProperty.call(message, "state"))
                        writer.uint32(/* id 4, wireType 2 =*/34).string(message.state);
                    if (message.currentValue != null && Object.hasOwnProperty.call(message, "currentValue"))
                        writer.uint32(/* id 5, wireType 0 =*/40).int32(message.currentValue);
                    if (message.previousValue != null && Object.hasOwnProperty.call(message, "previousValue"))
                        writer.uint32(/* id 6, wireType 0 =*/48).int32(message.previousValue);
                    if (message.resultAtMs != null && Object.hasOwnProperty.call(message, "resultAtMs"))
                        writer.uint32(/* id 7, wireType 0 =*/56).int64(message.resultAtMs);
                    if (message.nextTransitionMs != null && Object.hasOwnProperty.call(message, "nextTransitionMs"))
                        writer.uint32(/* id 8, wireType 0 =*/64).int64(message.nextTransitionMs);
                    return writer;
                };

                /**
                 * Encodes the specified LiveDrawStateUpdated message, length delimited. Does not implicitly {@link gmaing.events.v1.LiveDrawStateUpdated.verify|verify} messages.
                 * @function encodeDelimited
                 * @memberof gmaing.events.v1.LiveDrawStateUpdated
                 * @static
                 * @param {gmaing.events.v1.ILiveDrawStateUpdated} message LiveDrawStateUpdated message or plain object to encode
                 * @param {$protobuf.Writer} [writer] Writer to encode to
                 * @returns {$protobuf.Writer} Writer
                 */
                LiveDrawStateUpdated.encodeDelimited = function encodeDelimited(message, writer) {
                    return this.encode(message, writer).ldelim();
                };

                /**
                 * Decodes a LiveDrawStateUpdated message from the specified reader or buffer.
                 * @function decode
                 * @memberof gmaing.events.v1.LiveDrawStateUpdated
                 * @static
                 * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
                 * @param {number} [length] Message length if known beforehand
                 * @returns {gmaing.events.v1.LiveDrawStateUpdated} LiveDrawStateUpdated
                 * @throws {Error} If the payload is not a reader or valid buffer
                 * @throws {$protobuf.util.ProtocolError} If required fields are missing
                 */
                LiveDrawStateUpdated.decode = function decode(reader, length, error) {
                    if (!(reader instanceof $Reader))
                        reader = $Reader.create(reader);
                    var end = length === undefined ? reader.len : reader.pos + length, message = new $root.gmaing.events.v1.LiveDrawStateUpdated();
                    while (reader.pos < end) {
                        var tag = reader.uint32();
                        if (tag === error)
                            break;
                        switch (tag >>> 3) {
                        case 1: {
                                message.market = reader.string();
                                break;
                            }
                        case 2: {
                                message.session = reader.string();
                                break;
                            }
                        case 3: {
                                message.drawId = reader.string();
                                break;
                            }
                        case 4: {
                                message.state = reader.string();
                                break;
                            }
                        case 5: {
                                message.currentValue = reader.int32();
                                break;
                            }
                        case 6: {
                                message.previousValue = reader.int32();
                                break;
                            }
                        case 7: {
                                message.resultAtMs = reader.int64();
                                break;
                            }
                        case 8: {
                                message.nextTransitionMs = reader.int64();
                                break;
                            }
                        default:
                            reader.skipType(tag & 7);
                            break;
                        }
                    }
                    return message;
                };

                /**
                 * Decodes a LiveDrawStateUpdated message from the specified reader or buffer, length delimited.
                 * @function decodeDelimited
                 * @memberof gmaing.events.v1.LiveDrawStateUpdated
                 * @static
                 * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
                 * @returns {gmaing.events.v1.LiveDrawStateUpdated} LiveDrawStateUpdated
                 * @throws {Error} If the payload is not a reader or valid buffer
                 * @throws {$protobuf.util.ProtocolError} If required fields are missing
                 */
                LiveDrawStateUpdated.decodeDelimited = function decodeDelimited(reader) {
                    if (!(reader instanceof $Reader))
                        reader = new $Reader(reader);
                    return this.decode(reader, reader.uint32());
                };

                /**
                 * Verifies a LiveDrawStateUpdated message.
                 * @function verify
                 * @memberof gmaing.events.v1.LiveDrawStateUpdated
                 * @static
                 * @param {Object.<string,*>} message Plain object to verify
                 * @returns {string|null} `null` if valid, otherwise the reason why it is not
                 */
                LiveDrawStateUpdated.verify = function verify(message) {
                    if (typeof message !== "object" || message === null)
                        return "object expected";
                    if (message.market != null && message.hasOwnProperty("market"))
                        if (!$util.isString(message.market))
                            return "market: string expected";
                    if (message.session != null && message.hasOwnProperty("session"))
                        if (!$util.isString(message.session))
                            return "session: string expected";
                    if (message.drawId != null && message.hasOwnProperty("drawId"))
                        if (!$util.isString(message.drawId))
                            return "drawId: string expected";
                    if (message.state != null && message.hasOwnProperty("state"))
                        if (!$util.isString(message.state))
                            return "state: string expected";
                    if (message.currentValue != null && message.hasOwnProperty("currentValue"))
                        if (!$util.isInteger(message.currentValue))
                            return "currentValue: integer expected";
                    if (message.previousValue != null && message.hasOwnProperty("previousValue"))
                        if (!$util.isInteger(message.previousValue))
                            return "previousValue: integer expected";
                    if (message.resultAtMs != null && message.hasOwnProperty("resultAtMs"))
                        if (!$util.isInteger(message.resultAtMs) && !(message.resultAtMs && $util.isInteger(message.resultAtMs.low) && $util.isInteger(message.resultAtMs.high)))
                            return "resultAtMs: integer|Long expected";
                    if (message.nextTransitionMs != null && message.hasOwnProperty("nextTransitionMs"))
                        if (!$util.isInteger(message.nextTransitionMs) && !(message.nextTransitionMs && $util.isInteger(message.nextTransitionMs.low) && $util.isInteger(message.nextTransitionMs.high)))
                            return "nextTransitionMs: integer|Long expected";
                    return null;
                };

                /**
                 * Creates a LiveDrawStateUpdated message from a plain object. Also converts values to their respective internal types.
                 * @function fromObject
                 * @memberof gmaing.events.v1.LiveDrawStateUpdated
                 * @static
                 * @param {Object.<string,*>} object Plain object
                 * @returns {gmaing.events.v1.LiveDrawStateUpdated} LiveDrawStateUpdated
                 */
                LiveDrawStateUpdated.fromObject = function fromObject(object) {
                    if (object instanceof $root.gmaing.events.v1.LiveDrawStateUpdated)
                        return object;
                    var message = new $root.gmaing.events.v1.LiveDrawStateUpdated();
                    if (object.market != null)
                        message.market = String(object.market);
                    if (object.session != null)
                        message.session = String(object.session);
                    if (object.drawId != null)
                        message.drawId = String(object.drawId);
                    if (object.state != null)
                        message.state = String(object.state);
                    if (object.currentValue != null)
                        message.currentValue = object.currentValue | 0;
                    if (object.previousValue != null)
                        message.previousValue = object.previousValue | 0;
                    if (object.resultAtMs != null)
                        if ($util.Long)
                            (message.resultAtMs = $util.Long.fromValue(object.resultAtMs)).unsigned = false;
                        else if (typeof object.resultAtMs === "string")
                            message.resultAtMs = parseInt(object.resultAtMs, 10);
                        else if (typeof object.resultAtMs === "number")
                            message.resultAtMs = object.resultAtMs;
                        else if (typeof object.resultAtMs === "object")
                            message.resultAtMs = new $util.LongBits(object.resultAtMs.low >>> 0, object.resultAtMs.high >>> 0).toNumber();
                    if (object.nextTransitionMs != null)
                        if ($util.Long)
                            (message.nextTransitionMs = $util.Long.fromValue(object.nextTransitionMs)).unsigned = false;
                        else if (typeof object.nextTransitionMs === "string")
                            message.nextTransitionMs = parseInt(object.nextTransitionMs, 10);
                        else if (typeof object.nextTransitionMs === "number")
                            message.nextTransitionMs = object.nextTransitionMs;
                        else if (typeof object.nextTransitionMs === "object")
                            message.nextTransitionMs = new $util.LongBits(object.nextTransitionMs.low >>> 0, object.nextTransitionMs.high >>> 0).toNumber();
                    return message;
                };

                /**
                 * Creates a plain object from a LiveDrawStateUpdated message. Also converts values to other types if specified.
                 * @function toObject
                 * @memberof gmaing.events.v1.LiveDrawStateUpdated
                 * @static
                 * @param {gmaing.events.v1.LiveDrawStateUpdated} message LiveDrawStateUpdated
                 * @param {$protobuf.IConversionOptions} [options] Conversion options
                 * @returns {Object.<string,*>} Plain object
                 */
                LiveDrawStateUpdated.toObject = function toObject(message, options) {
                    if (!options)
                        options = {};
                    var object = {};
                    if (options.defaults) {
                        object.market = "";
                        object.session = "";
                        object.drawId = "";
                        object.state = "";
                        object.currentValue = 0;
                        object.previousValue = 0;
                        if ($util.Long) {
                            var long = new $util.Long(0, 0, false);
                            object.resultAtMs = options.longs === String ? long.toString() : options.longs === Number ? long.toNumber() : long;
                        } else
                            object.resultAtMs = options.longs === String ? "0" : 0;
                        if ($util.Long) {
                            var long = new $util.Long(0, 0, false);
                            object.nextTransitionMs = options.longs === String ? long.toString() : options.longs === Number ? long.toNumber() : long;
                        } else
                            object.nextTransitionMs = options.longs === String ? "0" : 0;
                    }
                    if (message.market != null && message.hasOwnProperty("market"))
                        object.market = message.market;
                    if (message.session != null && message.hasOwnProperty("session"))
                        object.session = message.session;
                    if (message.drawId != null && message.hasOwnProperty("drawId"))
                        object.drawId = message.drawId;
                    if (message.state != null && message.hasOwnProperty("state"))
                        object.state = message.state;
                    if (message.currentValue != null && message.hasOwnProperty("currentValue"))
                        object.currentValue = message.currentValue;
                    if (message.previousValue != null && message.hasOwnProperty("previousValue"))
                        object.previousValue = message.previousValue;
                    if (message.resultAtMs != null && message.hasOwnProperty("resultAtMs"))
                        if (typeof message.resultAtMs === "number")
                            object.resultAtMs = options.longs === String ? String(message.resultAtMs) : message.resultAtMs;
                        else
                            object.resultAtMs = options.longs === String ? $util.Long.prototype.toString.call(message.resultAtMs) : options.longs === Number ? new $util.LongBits(message.resultAtMs.low >>> 0, message.resultAtMs.high >>> 0).toNumber() : message.resultAtMs;
                    if (message.nextTransitionMs != null && message.hasOwnProperty("nextTransitionMs"))
                        if (typeof message.nextTransitionMs === "number")
                            object.nextTransitionMs = options.longs === String ? String(message.nextTransitionMs) : message.nextTransitionMs;
                        else
                            object.nextTransitionMs = options.longs === String ? $util.Long.prototype.toString.call(message.nextTransitionMs) : options.longs === Number ? new $util.LongBits(message.nextTransitionMs.low >>> 0, message.nextTransitionMs.high >>> 0).toNumber() : message.nextTransitionMs;
                    return object;
                };

                /**
                 * Converts this LiveDrawStateUpdated to JSON.
                 * @function toJSON
                 * @memberof gmaing.events.v1.LiveDrawStateUpdated
                 * @instance
                 * @returns {Object.<string,*>} JSON object
                 */
                LiveDrawStateUpdated.prototype.toJSON = function toJSON() {
                    return this.constructor.toObject(this, $protobuf.util.toJSONOptions);
                };

                /**
                 * Gets the default type url for LiveDrawStateUpdated
                 * @function getTypeUrl
                 * @memberof gmaing.events.v1.LiveDrawStateUpdated
                 * @static
                 * @param {string} [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
                 * @returns {string} The default type url
                 */
                LiveDrawStateUpdated.getTypeUrl = function getTypeUrl(typeUrlPrefix) {
                    if (typeUrlPrefix === undefined) {
                        typeUrlPrefix = "type.googleapis.com";
                    }
                    return typeUrlPrefix + "/gmaing.events.v1.LiveDrawStateUpdated";
                };

                return LiveDrawStateUpdated;
            })();

            v1.LiveOddsUpdated = (function() {

                /**
                 * Properties of a LiveOddsUpdated.
                 * @memberof gmaing.events.v1
                 * @interface ILiveOddsUpdated
                 * @property {string|null} [market] LiveOddsUpdated market
                 * @property {string|null} [session] LiveOddsUpdated session
                 * @property {string|null} [drawId] LiveOddsUpdated drawId
                 * @property {Array.<gmaing.events.v1.IOddsItem>|null} [odds] LiveOddsUpdated odds
                 */

                /**
                 * Constructs a new LiveOddsUpdated.
                 * @memberof gmaing.events.v1
                 * @classdesc Represents a LiveOddsUpdated.
                 * @implements ILiveOddsUpdated
                 * @constructor
                 * @param {gmaing.events.v1.ILiveOddsUpdated=} [properties] Properties to set
                 */
                function LiveOddsUpdated(properties) {
                    this.odds = [];
                    if (properties)
                        for (var keys = Object.keys(properties), i = 0; i < keys.length; ++i)
                            if (properties[keys[i]] != null)
                                this[keys[i]] = properties[keys[i]];
                }

                /**
                 * LiveOddsUpdated market.
                 * @member {string} market
                 * @memberof gmaing.events.v1.LiveOddsUpdated
                 * @instance
                 */
                LiveOddsUpdated.prototype.market = "";

                /**
                 * LiveOddsUpdated session.
                 * @member {string} session
                 * @memberof gmaing.events.v1.LiveOddsUpdated
                 * @instance
                 */
                LiveOddsUpdated.prototype.session = "";

                /**
                 * LiveOddsUpdated drawId.
                 * @member {string} drawId
                 * @memberof gmaing.events.v1.LiveOddsUpdated
                 * @instance
                 */
                LiveOddsUpdated.prototype.drawId = "";

                /**
                 * LiveOddsUpdated odds.
                 * @member {Array.<gmaing.events.v1.IOddsItem>} odds
                 * @memberof gmaing.events.v1.LiveOddsUpdated
                 * @instance
                 */
                LiveOddsUpdated.prototype.odds = $util.emptyArray;

                /**
                 * Creates a new LiveOddsUpdated instance using the specified properties.
                 * @function create
                 * @memberof gmaing.events.v1.LiveOddsUpdated
                 * @static
                 * @param {gmaing.events.v1.ILiveOddsUpdated=} [properties] Properties to set
                 * @returns {gmaing.events.v1.LiveOddsUpdated} LiveOddsUpdated instance
                 */
                LiveOddsUpdated.create = function create(properties) {
                    return new LiveOddsUpdated(properties);
                };

                /**
                 * Encodes the specified LiveOddsUpdated message. Does not implicitly {@link gmaing.events.v1.LiveOddsUpdated.verify|verify} messages.
                 * @function encode
                 * @memberof gmaing.events.v1.LiveOddsUpdated
                 * @static
                 * @param {gmaing.events.v1.ILiveOddsUpdated} message LiveOddsUpdated message or plain object to encode
                 * @param {$protobuf.Writer} [writer] Writer to encode to
                 * @returns {$protobuf.Writer} Writer
                 */
                LiveOddsUpdated.encode = function encode(message, writer) {
                    if (!writer)
                        writer = $Writer.create();
                    if (message.market != null && Object.hasOwnProperty.call(message, "market"))
                        writer.uint32(/* id 1, wireType 2 =*/10).string(message.market);
                    if (message.session != null && Object.hasOwnProperty.call(message, "session"))
                        writer.uint32(/* id 2, wireType 2 =*/18).string(message.session);
                    if (message.drawId != null && Object.hasOwnProperty.call(message, "drawId"))
                        writer.uint32(/* id 3, wireType 2 =*/26).string(message.drawId);
                    if (message.odds != null && message.odds.length)
                        for (var i = 0; i < message.odds.length; ++i)
                            $root.gmaing.events.v1.OddsItem.encode(message.odds[i], writer.uint32(/* id 4, wireType 2 =*/34).fork()).ldelim();
                    return writer;
                };

                /**
                 * Encodes the specified LiveOddsUpdated message, length delimited. Does not implicitly {@link gmaing.events.v1.LiveOddsUpdated.verify|verify} messages.
                 * @function encodeDelimited
                 * @memberof gmaing.events.v1.LiveOddsUpdated
                 * @static
                 * @param {gmaing.events.v1.ILiveOddsUpdated} message LiveOddsUpdated message or plain object to encode
                 * @param {$protobuf.Writer} [writer] Writer to encode to
                 * @returns {$protobuf.Writer} Writer
                 */
                LiveOddsUpdated.encodeDelimited = function encodeDelimited(message, writer) {
                    return this.encode(message, writer).ldelim();
                };

                /**
                 * Decodes a LiveOddsUpdated message from the specified reader or buffer.
                 * @function decode
                 * @memberof gmaing.events.v1.LiveOddsUpdated
                 * @static
                 * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
                 * @param {number} [length] Message length if known beforehand
                 * @returns {gmaing.events.v1.LiveOddsUpdated} LiveOddsUpdated
                 * @throws {Error} If the payload is not a reader or valid buffer
                 * @throws {$protobuf.util.ProtocolError} If required fields are missing
                 */
                LiveOddsUpdated.decode = function decode(reader, length, error) {
                    if (!(reader instanceof $Reader))
                        reader = $Reader.create(reader);
                    var end = length === undefined ? reader.len : reader.pos + length, message = new $root.gmaing.events.v1.LiveOddsUpdated();
                    while (reader.pos < end) {
                        var tag = reader.uint32();
                        if (tag === error)
                            break;
                        switch (tag >>> 3) {
                        case 1: {
                                message.market = reader.string();
                                break;
                            }
                        case 2: {
                                message.session = reader.string();
                                break;
                            }
                        case 3: {
                                message.drawId = reader.string();
                                break;
                            }
                        case 4: {
                                if (!(message.odds && message.odds.length))
                                    message.odds = [];
                                message.odds.push($root.gmaing.events.v1.OddsItem.decode(reader, reader.uint32()));
                                break;
                            }
                        default:
                            reader.skipType(tag & 7);
                            break;
                        }
                    }
                    return message;
                };

                /**
                 * Decodes a LiveOddsUpdated message from the specified reader or buffer, length delimited.
                 * @function decodeDelimited
                 * @memberof gmaing.events.v1.LiveOddsUpdated
                 * @static
                 * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
                 * @returns {gmaing.events.v1.LiveOddsUpdated} LiveOddsUpdated
                 * @throws {Error} If the payload is not a reader or valid buffer
                 * @throws {$protobuf.util.ProtocolError} If required fields are missing
                 */
                LiveOddsUpdated.decodeDelimited = function decodeDelimited(reader) {
                    if (!(reader instanceof $Reader))
                        reader = new $Reader(reader);
                    return this.decode(reader, reader.uint32());
                };

                /**
                 * Verifies a LiveOddsUpdated message.
                 * @function verify
                 * @memberof gmaing.events.v1.LiveOddsUpdated
                 * @static
                 * @param {Object.<string,*>} message Plain object to verify
                 * @returns {string|null} `null` if valid, otherwise the reason why it is not
                 */
                LiveOddsUpdated.verify = function verify(message) {
                    if (typeof message !== "object" || message === null)
                        return "object expected";
                    if (message.market != null && message.hasOwnProperty("market"))
                        if (!$util.isString(message.market))
                            return "market: string expected";
                    if (message.session != null && message.hasOwnProperty("session"))
                        if (!$util.isString(message.session))
                            return "session: string expected";
                    if (message.drawId != null && message.hasOwnProperty("drawId"))
                        if (!$util.isString(message.drawId))
                            return "drawId: string expected";
                    if (message.odds != null && message.hasOwnProperty("odds")) {
                        if (!Array.isArray(message.odds))
                            return "odds: array expected";
                        for (var i = 0; i < message.odds.length; ++i) {
                            var error = $root.gmaing.events.v1.OddsItem.verify(message.odds[i]);
                            if (error)
                                return "odds." + error;
                        }
                    }
                    return null;
                };

                /**
                 * Creates a LiveOddsUpdated message from a plain object. Also converts values to their respective internal types.
                 * @function fromObject
                 * @memberof gmaing.events.v1.LiveOddsUpdated
                 * @static
                 * @param {Object.<string,*>} object Plain object
                 * @returns {gmaing.events.v1.LiveOddsUpdated} LiveOddsUpdated
                 */
                LiveOddsUpdated.fromObject = function fromObject(object) {
                    if (object instanceof $root.gmaing.events.v1.LiveOddsUpdated)
                        return object;
                    var message = new $root.gmaing.events.v1.LiveOddsUpdated();
                    if (object.market != null)
                        message.market = String(object.market);
                    if (object.session != null)
                        message.session = String(object.session);
                    if (object.drawId != null)
                        message.drawId = String(object.drawId);
                    if (object.odds) {
                        if (!Array.isArray(object.odds))
                            throw TypeError(".gmaing.events.v1.LiveOddsUpdated.odds: array expected");
                        message.odds = [];
                        for (var i = 0; i < object.odds.length; ++i) {
                            if (typeof object.odds[i] !== "object")
                                throw TypeError(".gmaing.events.v1.LiveOddsUpdated.odds: object expected");
                            message.odds[i] = $root.gmaing.events.v1.OddsItem.fromObject(object.odds[i]);
                        }
                    }
                    return message;
                };

                /**
                 * Creates a plain object from a LiveOddsUpdated message. Also converts values to other types if specified.
                 * @function toObject
                 * @memberof gmaing.events.v1.LiveOddsUpdated
                 * @static
                 * @param {gmaing.events.v1.LiveOddsUpdated} message LiveOddsUpdated
                 * @param {$protobuf.IConversionOptions} [options] Conversion options
                 * @returns {Object.<string,*>} Plain object
                 */
                LiveOddsUpdated.toObject = function toObject(message, options) {
                    if (!options)
                        options = {};
                    var object = {};
                    if (options.arrays || options.defaults)
                        object.odds = [];
                    if (options.defaults) {
                        object.market = "";
                        object.session = "";
                        object.drawId = "";
                    }
                    if (message.market != null && message.hasOwnProperty("market"))
                        object.market = message.market;
                    if (message.session != null && message.hasOwnProperty("session"))
                        object.session = message.session;
                    if (message.drawId != null && message.hasOwnProperty("drawId"))
                        object.drawId = message.drawId;
                    if (message.odds && message.odds.length) {
                        object.odds = [];
                        for (var j = 0; j < message.odds.length; ++j)
                            object.odds[j] = $root.gmaing.events.v1.OddsItem.toObject(message.odds[j], options);
                    }
                    return object;
                };

                /**
                 * Converts this LiveOddsUpdated to JSON.
                 * @function toJSON
                 * @memberof gmaing.events.v1.LiveOddsUpdated
                 * @instance
                 * @returns {Object.<string,*>} JSON object
                 */
                LiveOddsUpdated.prototype.toJSON = function toJSON() {
                    return this.constructor.toObject(this, $protobuf.util.toJSONOptions);
                };

                /**
                 * Gets the default type url for LiveOddsUpdated
                 * @function getTypeUrl
                 * @memberof gmaing.events.v1.LiveOddsUpdated
                 * @static
                 * @param {string} [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
                 * @returns {string} The default type url
                 */
                LiveOddsUpdated.getTypeUrl = function getTypeUrl(typeUrlPrefix) {
                    if (typeUrlPrefix === undefined) {
                        typeUrlPrefix = "type.googleapis.com";
                    }
                    return typeUrlPrefix + "/gmaing.events.v1.LiveOddsUpdated";
                };

                return LiveOddsUpdated;
            })();

            v1.OddsItem = (function() {

                /**
                 * Properties of an OddsItem.
                 * @memberof gmaing.events.v1
                 * @interface IOddsItem
                 * @property {number|null} [digit] OddsItem digit
                 * @property {number|null} [payoutMultiplier] OddsItem payoutMultiplier
                 * @property {boolean|null} [suspended] OddsItem suspended
                 */

                /**
                 * Constructs a new OddsItem.
                 * @memberof gmaing.events.v1
                 * @classdesc Represents an OddsItem.
                 * @implements IOddsItem
                 * @constructor
                 * @param {gmaing.events.v1.IOddsItem=} [properties] Properties to set
                 */
                function OddsItem(properties) {
                    if (properties)
                        for (var keys = Object.keys(properties), i = 0; i < keys.length; ++i)
                            if (properties[keys[i]] != null)
                                this[keys[i]] = properties[keys[i]];
                }

                /**
                 * OddsItem digit.
                 * @member {number} digit
                 * @memberof gmaing.events.v1.OddsItem
                 * @instance
                 */
                OddsItem.prototype.digit = 0;

                /**
                 * OddsItem payoutMultiplier.
                 * @member {number} payoutMultiplier
                 * @memberof gmaing.events.v1.OddsItem
                 * @instance
                 */
                OddsItem.prototype.payoutMultiplier = 0;

                /**
                 * OddsItem suspended.
                 * @member {boolean} suspended
                 * @memberof gmaing.events.v1.OddsItem
                 * @instance
                 */
                OddsItem.prototype.suspended = false;

                /**
                 * Creates a new OddsItem instance using the specified properties.
                 * @function create
                 * @memberof gmaing.events.v1.OddsItem
                 * @static
                 * @param {gmaing.events.v1.IOddsItem=} [properties] Properties to set
                 * @returns {gmaing.events.v1.OddsItem} OddsItem instance
                 */
                OddsItem.create = function create(properties) {
                    return new OddsItem(properties);
                };

                /**
                 * Encodes the specified OddsItem message. Does not implicitly {@link gmaing.events.v1.OddsItem.verify|verify} messages.
                 * @function encode
                 * @memberof gmaing.events.v1.OddsItem
                 * @static
                 * @param {gmaing.events.v1.IOddsItem} message OddsItem message or plain object to encode
                 * @param {$protobuf.Writer} [writer] Writer to encode to
                 * @returns {$protobuf.Writer} Writer
                 */
                OddsItem.encode = function encode(message, writer) {
                    if (!writer)
                        writer = $Writer.create();
                    if (message.digit != null && Object.hasOwnProperty.call(message, "digit"))
                        writer.uint32(/* id 1, wireType 0 =*/8).int32(message.digit);
                    if (message.payoutMultiplier != null && Object.hasOwnProperty.call(message, "payoutMultiplier"))
                        writer.uint32(/* id 2, wireType 1 =*/17).double(message.payoutMultiplier);
                    if (message.suspended != null && Object.hasOwnProperty.call(message, "suspended"))
                        writer.uint32(/* id 3, wireType 0 =*/24).bool(message.suspended);
                    return writer;
                };

                /**
                 * Encodes the specified OddsItem message, length delimited. Does not implicitly {@link gmaing.events.v1.OddsItem.verify|verify} messages.
                 * @function encodeDelimited
                 * @memberof gmaing.events.v1.OddsItem
                 * @static
                 * @param {gmaing.events.v1.IOddsItem} message OddsItem message or plain object to encode
                 * @param {$protobuf.Writer} [writer] Writer to encode to
                 * @returns {$protobuf.Writer} Writer
                 */
                OddsItem.encodeDelimited = function encodeDelimited(message, writer) {
                    return this.encode(message, writer).ldelim();
                };

                /**
                 * Decodes an OddsItem message from the specified reader or buffer.
                 * @function decode
                 * @memberof gmaing.events.v1.OddsItem
                 * @static
                 * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
                 * @param {number} [length] Message length if known beforehand
                 * @returns {gmaing.events.v1.OddsItem} OddsItem
                 * @throws {Error} If the payload is not a reader or valid buffer
                 * @throws {$protobuf.util.ProtocolError} If required fields are missing
                 */
                OddsItem.decode = function decode(reader, length, error) {
                    if (!(reader instanceof $Reader))
                        reader = $Reader.create(reader);
                    var end = length === undefined ? reader.len : reader.pos + length, message = new $root.gmaing.events.v1.OddsItem();
                    while (reader.pos < end) {
                        var tag = reader.uint32();
                        if (tag === error)
                            break;
                        switch (tag >>> 3) {
                        case 1: {
                                message.digit = reader.int32();
                                break;
                            }
                        case 2: {
                                message.payoutMultiplier = reader.double();
                                break;
                            }
                        case 3: {
                                message.suspended = reader.bool();
                                break;
                            }
                        default:
                            reader.skipType(tag & 7);
                            break;
                        }
                    }
                    return message;
                };

                /**
                 * Decodes an OddsItem message from the specified reader or buffer, length delimited.
                 * @function decodeDelimited
                 * @memberof gmaing.events.v1.OddsItem
                 * @static
                 * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
                 * @returns {gmaing.events.v1.OddsItem} OddsItem
                 * @throws {Error} If the payload is not a reader or valid buffer
                 * @throws {$protobuf.util.ProtocolError} If required fields are missing
                 */
                OddsItem.decodeDelimited = function decodeDelimited(reader) {
                    if (!(reader instanceof $Reader))
                        reader = new $Reader(reader);
                    return this.decode(reader, reader.uint32());
                };

                /**
                 * Verifies an OddsItem message.
                 * @function verify
                 * @memberof gmaing.events.v1.OddsItem
                 * @static
                 * @param {Object.<string,*>} message Plain object to verify
                 * @returns {string|null} `null` if valid, otherwise the reason why it is not
                 */
                OddsItem.verify = function verify(message) {
                    if (typeof message !== "object" || message === null)
                        return "object expected";
                    if (message.digit != null && message.hasOwnProperty("digit"))
                        if (!$util.isInteger(message.digit))
                            return "digit: integer expected";
                    if (message.payoutMultiplier != null && message.hasOwnProperty("payoutMultiplier"))
                        if (typeof message.payoutMultiplier !== "number")
                            return "payoutMultiplier: number expected";
                    if (message.suspended != null && message.hasOwnProperty("suspended"))
                        if (typeof message.suspended !== "boolean")
                            return "suspended: boolean expected";
                    return null;
                };

                /**
                 * Creates an OddsItem message from a plain object. Also converts values to their respective internal types.
                 * @function fromObject
                 * @memberof gmaing.events.v1.OddsItem
                 * @static
                 * @param {Object.<string,*>} object Plain object
                 * @returns {gmaing.events.v1.OddsItem} OddsItem
                 */
                OddsItem.fromObject = function fromObject(object) {
                    if (object instanceof $root.gmaing.events.v1.OddsItem)
                        return object;
                    var message = new $root.gmaing.events.v1.OddsItem();
                    if (object.digit != null)
                        message.digit = object.digit | 0;
                    if (object.payoutMultiplier != null)
                        message.payoutMultiplier = Number(object.payoutMultiplier);
                    if (object.suspended != null)
                        message.suspended = Boolean(object.suspended);
                    return message;
                };

                /**
                 * Creates a plain object from an OddsItem message. Also converts values to other types if specified.
                 * @function toObject
                 * @memberof gmaing.events.v1.OddsItem
                 * @static
                 * @param {gmaing.events.v1.OddsItem} message OddsItem
                 * @param {$protobuf.IConversionOptions} [options] Conversion options
                 * @returns {Object.<string,*>} Plain object
                 */
                OddsItem.toObject = function toObject(message, options) {
                    if (!options)
                        options = {};
                    var object = {};
                    if (options.defaults) {
                        object.digit = 0;
                        object.payoutMultiplier = 0;
                        object.suspended = false;
                    }
                    if (message.digit != null && message.hasOwnProperty("digit"))
                        object.digit = message.digit;
                    if (message.payoutMultiplier != null && message.hasOwnProperty("payoutMultiplier"))
                        object.payoutMultiplier = options.json && !isFinite(message.payoutMultiplier) ? String(message.payoutMultiplier) : message.payoutMultiplier;
                    if (message.suspended != null && message.hasOwnProperty("suspended"))
                        object.suspended = message.suspended;
                    return object;
                };

                /**
                 * Converts this OddsItem to JSON.
                 * @function toJSON
                 * @memberof gmaing.events.v1.OddsItem
                 * @instance
                 * @returns {Object.<string,*>} JSON object
                 */
                OddsItem.prototype.toJSON = function toJSON() {
                    return this.constructor.toObject(this, $protobuf.util.toJSONOptions);
                };

                /**
                 * Gets the default type url for OddsItem
                 * @function getTypeUrl
                 * @memberof gmaing.events.v1.OddsItem
                 * @static
                 * @param {string} [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
                 * @returns {string} The default type url
                 */
                OddsItem.getTypeUrl = function getTypeUrl(typeUrlPrefix) {
                    if (typeUrlPrefix === undefined) {
                        typeUrlPrefix = "type.googleapis.com";
                    }
                    return typeUrlPrefix + "/gmaing.events.v1.OddsItem";
                };

                return OddsItem;
            })();

            v1.BettingBetPlaced = (function() {

                /**
                 * Properties of a BettingBetPlaced.
                 * @memberof gmaing.events.v1
                 * @interface IBettingBetPlaced
                 * @property {string|null} [betId] BettingBetPlaced betId
                 * @property {string|null} [userId] BettingBetPlaced userId
                 * @property {number|null} [digit] BettingBetPlaced digit
                 * @property {number|Long|null} [amount] BettingBetPlaced amount
                 * @property {string|null} [drawId] BettingBetPlaced drawId
                 * @property {string|null} [session] BettingBetPlaced session
                 * @property {number|Long|null} [placedAtMs] BettingBetPlaced placedAtMs
                 */

                /**
                 * Constructs a new BettingBetPlaced.
                 * @memberof gmaing.events.v1
                 * @classdesc Represents a BettingBetPlaced.
                 * @implements IBettingBetPlaced
                 * @constructor
                 * @param {gmaing.events.v1.IBettingBetPlaced=} [properties] Properties to set
                 */
                function BettingBetPlaced(properties) {
                    if (properties)
                        for (var keys = Object.keys(properties), i = 0; i < keys.length; ++i)
                            if (properties[keys[i]] != null)
                                this[keys[i]] = properties[keys[i]];
                }

                /**
                 * BettingBetPlaced betId.
                 * @member {string} betId
                 * @memberof gmaing.events.v1.BettingBetPlaced
                 * @instance
                 */
                BettingBetPlaced.prototype.betId = "";

                /**
                 * BettingBetPlaced userId.
                 * @member {string} userId
                 * @memberof gmaing.events.v1.BettingBetPlaced
                 * @instance
                 */
                BettingBetPlaced.prototype.userId = "";

                /**
                 * BettingBetPlaced digit.
                 * @member {number} digit
                 * @memberof gmaing.events.v1.BettingBetPlaced
                 * @instance
                 */
                BettingBetPlaced.prototype.digit = 0;

                /**
                 * BettingBetPlaced amount.
                 * @member {number|Long} amount
                 * @memberof gmaing.events.v1.BettingBetPlaced
                 * @instance
                 */
                BettingBetPlaced.prototype.amount = $util.Long ? $util.Long.fromBits(0,0,false) : 0;

                /**
                 * BettingBetPlaced drawId.
                 * @member {string} drawId
                 * @memberof gmaing.events.v1.BettingBetPlaced
                 * @instance
                 */
                BettingBetPlaced.prototype.drawId = "";

                /**
                 * BettingBetPlaced session.
                 * @member {string} session
                 * @memberof gmaing.events.v1.BettingBetPlaced
                 * @instance
                 */
                BettingBetPlaced.prototype.session = "";

                /**
                 * BettingBetPlaced placedAtMs.
                 * @member {number|Long} placedAtMs
                 * @memberof gmaing.events.v1.BettingBetPlaced
                 * @instance
                 */
                BettingBetPlaced.prototype.placedAtMs = $util.Long ? $util.Long.fromBits(0,0,false) : 0;

                /**
                 * Creates a new BettingBetPlaced instance using the specified properties.
                 * @function create
                 * @memberof gmaing.events.v1.BettingBetPlaced
                 * @static
                 * @param {gmaing.events.v1.IBettingBetPlaced=} [properties] Properties to set
                 * @returns {gmaing.events.v1.BettingBetPlaced} BettingBetPlaced instance
                 */
                BettingBetPlaced.create = function create(properties) {
                    return new BettingBetPlaced(properties);
                };

                /**
                 * Encodes the specified BettingBetPlaced message. Does not implicitly {@link gmaing.events.v1.BettingBetPlaced.verify|verify} messages.
                 * @function encode
                 * @memberof gmaing.events.v1.BettingBetPlaced
                 * @static
                 * @param {gmaing.events.v1.IBettingBetPlaced} message BettingBetPlaced message or plain object to encode
                 * @param {$protobuf.Writer} [writer] Writer to encode to
                 * @returns {$protobuf.Writer} Writer
                 */
                BettingBetPlaced.encode = function encode(message, writer) {
                    if (!writer)
                        writer = $Writer.create();
                    if (message.betId != null && Object.hasOwnProperty.call(message, "betId"))
                        writer.uint32(/* id 1, wireType 2 =*/10).string(message.betId);
                    if (message.userId != null && Object.hasOwnProperty.call(message, "userId"))
                        writer.uint32(/* id 2, wireType 2 =*/18).string(message.userId);
                    if (message.digit != null && Object.hasOwnProperty.call(message, "digit"))
                        writer.uint32(/* id 3, wireType 0 =*/24).int32(message.digit);
                    if (message.amount != null && Object.hasOwnProperty.call(message, "amount"))
                        writer.uint32(/* id 4, wireType 0 =*/32).int64(message.amount);
                    if (message.drawId != null && Object.hasOwnProperty.call(message, "drawId"))
                        writer.uint32(/* id 5, wireType 2 =*/42).string(message.drawId);
                    if (message.session != null && Object.hasOwnProperty.call(message, "session"))
                        writer.uint32(/* id 6, wireType 2 =*/50).string(message.session);
                    if (message.placedAtMs != null && Object.hasOwnProperty.call(message, "placedAtMs"))
                        writer.uint32(/* id 7, wireType 0 =*/56).int64(message.placedAtMs);
                    return writer;
                };

                /**
                 * Encodes the specified BettingBetPlaced message, length delimited. Does not implicitly {@link gmaing.events.v1.BettingBetPlaced.verify|verify} messages.
                 * @function encodeDelimited
                 * @memberof gmaing.events.v1.BettingBetPlaced
                 * @static
                 * @param {gmaing.events.v1.IBettingBetPlaced} message BettingBetPlaced message or plain object to encode
                 * @param {$protobuf.Writer} [writer] Writer to encode to
                 * @returns {$protobuf.Writer} Writer
                 */
                BettingBetPlaced.encodeDelimited = function encodeDelimited(message, writer) {
                    return this.encode(message, writer).ldelim();
                };

                /**
                 * Decodes a BettingBetPlaced message from the specified reader or buffer.
                 * @function decode
                 * @memberof gmaing.events.v1.BettingBetPlaced
                 * @static
                 * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
                 * @param {number} [length] Message length if known beforehand
                 * @returns {gmaing.events.v1.BettingBetPlaced} BettingBetPlaced
                 * @throws {Error} If the payload is not a reader or valid buffer
                 * @throws {$protobuf.util.ProtocolError} If required fields are missing
                 */
                BettingBetPlaced.decode = function decode(reader, length, error) {
                    if (!(reader instanceof $Reader))
                        reader = $Reader.create(reader);
                    var end = length === undefined ? reader.len : reader.pos + length, message = new $root.gmaing.events.v1.BettingBetPlaced();
                    while (reader.pos < end) {
                        var tag = reader.uint32();
                        if (tag === error)
                            break;
                        switch (tag >>> 3) {
                        case 1: {
                                message.betId = reader.string();
                                break;
                            }
                        case 2: {
                                message.userId = reader.string();
                                break;
                            }
                        case 3: {
                                message.digit = reader.int32();
                                break;
                            }
                        case 4: {
                                message.amount = reader.int64();
                                break;
                            }
                        case 5: {
                                message.drawId = reader.string();
                                break;
                            }
                        case 6: {
                                message.session = reader.string();
                                break;
                            }
                        case 7: {
                                message.placedAtMs = reader.int64();
                                break;
                            }
                        default:
                            reader.skipType(tag & 7);
                            break;
                        }
                    }
                    return message;
                };

                /**
                 * Decodes a BettingBetPlaced message from the specified reader or buffer, length delimited.
                 * @function decodeDelimited
                 * @memberof gmaing.events.v1.BettingBetPlaced
                 * @static
                 * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
                 * @returns {gmaing.events.v1.BettingBetPlaced} BettingBetPlaced
                 * @throws {Error} If the payload is not a reader or valid buffer
                 * @throws {$protobuf.util.ProtocolError} If required fields are missing
                 */
                BettingBetPlaced.decodeDelimited = function decodeDelimited(reader) {
                    if (!(reader instanceof $Reader))
                        reader = new $Reader(reader);
                    return this.decode(reader, reader.uint32());
                };

                /**
                 * Verifies a BettingBetPlaced message.
                 * @function verify
                 * @memberof gmaing.events.v1.BettingBetPlaced
                 * @static
                 * @param {Object.<string,*>} message Plain object to verify
                 * @returns {string|null} `null` if valid, otherwise the reason why it is not
                 */
                BettingBetPlaced.verify = function verify(message) {
                    if (typeof message !== "object" || message === null)
                        return "object expected";
                    if (message.betId != null && message.hasOwnProperty("betId"))
                        if (!$util.isString(message.betId))
                            return "betId: string expected";
                    if (message.userId != null && message.hasOwnProperty("userId"))
                        if (!$util.isString(message.userId))
                            return "userId: string expected";
                    if (message.digit != null && message.hasOwnProperty("digit"))
                        if (!$util.isInteger(message.digit))
                            return "digit: integer expected";
                    if (message.amount != null && message.hasOwnProperty("amount"))
                        if (!$util.isInteger(message.amount) && !(message.amount && $util.isInteger(message.amount.low) && $util.isInteger(message.amount.high)))
                            return "amount: integer|Long expected";
                    if (message.drawId != null && message.hasOwnProperty("drawId"))
                        if (!$util.isString(message.drawId))
                            return "drawId: string expected";
                    if (message.session != null && message.hasOwnProperty("session"))
                        if (!$util.isString(message.session))
                            return "session: string expected";
                    if (message.placedAtMs != null && message.hasOwnProperty("placedAtMs"))
                        if (!$util.isInteger(message.placedAtMs) && !(message.placedAtMs && $util.isInteger(message.placedAtMs.low) && $util.isInteger(message.placedAtMs.high)))
                            return "placedAtMs: integer|Long expected";
                    return null;
                };

                /**
                 * Creates a BettingBetPlaced message from a plain object. Also converts values to their respective internal types.
                 * @function fromObject
                 * @memberof gmaing.events.v1.BettingBetPlaced
                 * @static
                 * @param {Object.<string,*>} object Plain object
                 * @returns {gmaing.events.v1.BettingBetPlaced} BettingBetPlaced
                 */
                BettingBetPlaced.fromObject = function fromObject(object) {
                    if (object instanceof $root.gmaing.events.v1.BettingBetPlaced)
                        return object;
                    var message = new $root.gmaing.events.v1.BettingBetPlaced();
                    if (object.betId != null)
                        message.betId = String(object.betId);
                    if (object.userId != null)
                        message.userId = String(object.userId);
                    if (object.digit != null)
                        message.digit = object.digit | 0;
                    if (object.amount != null)
                        if ($util.Long)
                            (message.amount = $util.Long.fromValue(object.amount)).unsigned = false;
                        else if (typeof object.amount === "string")
                            message.amount = parseInt(object.amount, 10);
                        else if (typeof object.amount === "number")
                            message.amount = object.amount;
                        else if (typeof object.amount === "object")
                            message.amount = new $util.LongBits(object.amount.low >>> 0, object.amount.high >>> 0).toNumber();
                    if (object.drawId != null)
                        message.drawId = String(object.drawId);
                    if (object.session != null)
                        message.session = String(object.session);
                    if (object.placedAtMs != null)
                        if ($util.Long)
                            (message.placedAtMs = $util.Long.fromValue(object.placedAtMs)).unsigned = false;
                        else if (typeof object.placedAtMs === "string")
                            message.placedAtMs = parseInt(object.placedAtMs, 10);
                        else if (typeof object.placedAtMs === "number")
                            message.placedAtMs = object.placedAtMs;
                        else if (typeof object.placedAtMs === "object")
                            message.placedAtMs = new $util.LongBits(object.placedAtMs.low >>> 0, object.placedAtMs.high >>> 0).toNumber();
                    return message;
                };

                /**
                 * Creates a plain object from a BettingBetPlaced message. Also converts values to other types if specified.
                 * @function toObject
                 * @memberof gmaing.events.v1.BettingBetPlaced
                 * @static
                 * @param {gmaing.events.v1.BettingBetPlaced} message BettingBetPlaced
                 * @param {$protobuf.IConversionOptions} [options] Conversion options
                 * @returns {Object.<string,*>} Plain object
                 */
                BettingBetPlaced.toObject = function toObject(message, options) {
                    if (!options)
                        options = {};
                    var object = {};
                    if (options.defaults) {
                        object.betId = "";
                        object.userId = "";
                        object.digit = 0;
                        if ($util.Long) {
                            var long = new $util.Long(0, 0, false);
                            object.amount = options.longs === String ? long.toString() : options.longs === Number ? long.toNumber() : long;
                        } else
                            object.amount = options.longs === String ? "0" : 0;
                        object.drawId = "";
                        object.session = "";
                        if ($util.Long) {
                            var long = new $util.Long(0, 0, false);
                            object.placedAtMs = options.longs === String ? long.toString() : options.longs === Number ? long.toNumber() : long;
                        } else
                            object.placedAtMs = options.longs === String ? "0" : 0;
                    }
                    if (message.betId != null && message.hasOwnProperty("betId"))
                        object.betId = message.betId;
                    if (message.userId != null && message.hasOwnProperty("userId"))
                        object.userId = message.userId;
                    if (message.digit != null && message.hasOwnProperty("digit"))
                        object.digit = message.digit;
                    if (message.amount != null && message.hasOwnProperty("amount"))
                        if (typeof message.amount === "number")
                            object.amount = options.longs === String ? String(message.amount) : message.amount;
                        else
                            object.amount = options.longs === String ? $util.Long.prototype.toString.call(message.amount) : options.longs === Number ? new $util.LongBits(message.amount.low >>> 0, message.amount.high >>> 0).toNumber() : message.amount;
                    if (message.drawId != null && message.hasOwnProperty("drawId"))
                        object.drawId = message.drawId;
                    if (message.session != null && message.hasOwnProperty("session"))
                        object.session = message.session;
                    if (message.placedAtMs != null && message.hasOwnProperty("placedAtMs"))
                        if (typeof message.placedAtMs === "number")
                            object.placedAtMs = options.longs === String ? String(message.placedAtMs) : message.placedAtMs;
                        else
                            object.placedAtMs = options.longs === String ? $util.Long.prototype.toString.call(message.placedAtMs) : options.longs === Number ? new $util.LongBits(message.placedAtMs.low >>> 0, message.placedAtMs.high >>> 0).toNumber() : message.placedAtMs;
                    return object;
                };

                /**
                 * Converts this BettingBetPlaced to JSON.
                 * @function toJSON
                 * @memberof gmaing.events.v1.BettingBetPlaced
                 * @instance
                 * @returns {Object.<string,*>} JSON object
                 */
                BettingBetPlaced.prototype.toJSON = function toJSON() {
                    return this.constructor.toObject(this, $protobuf.util.toJSONOptions);
                };

                /**
                 * Gets the default type url for BettingBetPlaced
                 * @function getTypeUrl
                 * @memberof gmaing.events.v1.BettingBetPlaced
                 * @static
                 * @param {string} [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
                 * @returns {string} The default type url
                 */
                BettingBetPlaced.getTypeUrl = function getTypeUrl(typeUrlPrefix) {
                    if (typeUrlPrefix === undefined) {
                        typeUrlPrefix = "type.googleapis.com";
                    }
                    return typeUrlPrefix + "/gmaing.events.v1.BettingBetPlaced";
                };

                return BettingBetPlaced;
            })();

            v1.BettingSettlementApplied = (function() {

                /**
                 * Properties of a BettingSettlementApplied.
                 * @memberof gmaing.events.v1
                 * @interface IBettingSettlementApplied
                 * @property {string|null} [runId] BettingSettlementApplied runId
                 * @property {string|null} [settlementId] BettingSettlementApplied settlementId
                 * @property {string|null} [drawId] BettingSettlementApplied drawId
                 * @property {number|null} [winningDigit] BettingSettlementApplied winningDigit
                 * @property {number|null} [claimedRows] BettingSettlementApplied claimedRows
                 * @property {number|null} [appliedRows] BettingSettlementApplied appliedRows
                 * @property {number|Long|null} [adminDelta] BettingSettlementApplied adminDelta
                 * @property {number|Long|null} [appliedAtMs] BettingSettlementApplied appliedAtMs
                 */

                /**
                 * Constructs a new BettingSettlementApplied.
                 * @memberof gmaing.events.v1
                 * @classdesc Represents a BettingSettlementApplied.
                 * @implements IBettingSettlementApplied
                 * @constructor
                 * @param {gmaing.events.v1.IBettingSettlementApplied=} [properties] Properties to set
                 */
                function BettingSettlementApplied(properties) {
                    if (properties)
                        for (var keys = Object.keys(properties), i = 0; i < keys.length; ++i)
                            if (properties[keys[i]] != null)
                                this[keys[i]] = properties[keys[i]];
                }

                /**
                 * BettingSettlementApplied runId.
                 * @member {string} runId
                 * @memberof gmaing.events.v1.BettingSettlementApplied
                 * @instance
                 */
                BettingSettlementApplied.prototype.runId = "";

                /**
                 * BettingSettlementApplied settlementId.
                 * @member {string} settlementId
                 * @memberof gmaing.events.v1.BettingSettlementApplied
                 * @instance
                 */
                BettingSettlementApplied.prototype.settlementId = "";

                /**
                 * BettingSettlementApplied drawId.
                 * @member {string} drawId
                 * @memberof gmaing.events.v1.BettingSettlementApplied
                 * @instance
                 */
                BettingSettlementApplied.prototype.drawId = "";

                /**
                 * BettingSettlementApplied winningDigit.
                 * @member {number} winningDigit
                 * @memberof gmaing.events.v1.BettingSettlementApplied
                 * @instance
                 */
                BettingSettlementApplied.prototype.winningDigit = 0;

                /**
                 * BettingSettlementApplied claimedRows.
                 * @member {number} claimedRows
                 * @memberof gmaing.events.v1.BettingSettlementApplied
                 * @instance
                 */
                BettingSettlementApplied.prototype.claimedRows = 0;

                /**
                 * BettingSettlementApplied appliedRows.
                 * @member {number} appliedRows
                 * @memberof gmaing.events.v1.BettingSettlementApplied
                 * @instance
                 */
                BettingSettlementApplied.prototype.appliedRows = 0;

                /**
                 * BettingSettlementApplied adminDelta.
                 * @member {number|Long} adminDelta
                 * @memberof gmaing.events.v1.BettingSettlementApplied
                 * @instance
                 */
                BettingSettlementApplied.prototype.adminDelta = $util.Long ? $util.Long.fromBits(0,0,false) : 0;

                /**
                 * BettingSettlementApplied appliedAtMs.
                 * @member {number|Long} appliedAtMs
                 * @memberof gmaing.events.v1.BettingSettlementApplied
                 * @instance
                 */
                BettingSettlementApplied.prototype.appliedAtMs = $util.Long ? $util.Long.fromBits(0,0,false) : 0;

                /**
                 * Creates a new BettingSettlementApplied instance using the specified properties.
                 * @function create
                 * @memberof gmaing.events.v1.BettingSettlementApplied
                 * @static
                 * @param {gmaing.events.v1.IBettingSettlementApplied=} [properties] Properties to set
                 * @returns {gmaing.events.v1.BettingSettlementApplied} BettingSettlementApplied instance
                 */
                BettingSettlementApplied.create = function create(properties) {
                    return new BettingSettlementApplied(properties);
                };

                /**
                 * Encodes the specified BettingSettlementApplied message. Does not implicitly {@link gmaing.events.v1.BettingSettlementApplied.verify|verify} messages.
                 * @function encode
                 * @memberof gmaing.events.v1.BettingSettlementApplied
                 * @static
                 * @param {gmaing.events.v1.IBettingSettlementApplied} message BettingSettlementApplied message or plain object to encode
                 * @param {$protobuf.Writer} [writer] Writer to encode to
                 * @returns {$protobuf.Writer} Writer
                 */
                BettingSettlementApplied.encode = function encode(message, writer) {
                    if (!writer)
                        writer = $Writer.create();
                    if (message.runId != null && Object.hasOwnProperty.call(message, "runId"))
                        writer.uint32(/* id 1, wireType 2 =*/10).string(message.runId);
                    if (message.settlementId != null && Object.hasOwnProperty.call(message, "settlementId"))
                        writer.uint32(/* id 2, wireType 2 =*/18).string(message.settlementId);
                    if (message.drawId != null && Object.hasOwnProperty.call(message, "drawId"))
                        writer.uint32(/* id 3, wireType 2 =*/26).string(message.drawId);
                    if (message.winningDigit != null && Object.hasOwnProperty.call(message, "winningDigit"))
                        writer.uint32(/* id 4, wireType 0 =*/32).int32(message.winningDigit);
                    if (message.claimedRows != null && Object.hasOwnProperty.call(message, "claimedRows"))
                        writer.uint32(/* id 5, wireType 0 =*/40).int32(message.claimedRows);
                    if (message.appliedRows != null && Object.hasOwnProperty.call(message, "appliedRows"))
                        writer.uint32(/* id 6, wireType 0 =*/48).int32(message.appliedRows);
                    if (message.adminDelta != null && Object.hasOwnProperty.call(message, "adminDelta"))
                        writer.uint32(/* id 7, wireType 0 =*/56).int64(message.adminDelta);
                    if (message.appliedAtMs != null && Object.hasOwnProperty.call(message, "appliedAtMs"))
                        writer.uint32(/* id 8, wireType 0 =*/64).int64(message.appliedAtMs);
                    return writer;
                };

                /**
                 * Encodes the specified BettingSettlementApplied message, length delimited. Does not implicitly {@link gmaing.events.v1.BettingSettlementApplied.verify|verify} messages.
                 * @function encodeDelimited
                 * @memberof gmaing.events.v1.BettingSettlementApplied
                 * @static
                 * @param {gmaing.events.v1.IBettingSettlementApplied} message BettingSettlementApplied message or plain object to encode
                 * @param {$protobuf.Writer} [writer] Writer to encode to
                 * @returns {$protobuf.Writer} Writer
                 */
                BettingSettlementApplied.encodeDelimited = function encodeDelimited(message, writer) {
                    return this.encode(message, writer).ldelim();
                };

                /**
                 * Decodes a BettingSettlementApplied message from the specified reader or buffer.
                 * @function decode
                 * @memberof gmaing.events.v1.BettingSettlementApplied
                 * @static
                 * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
                 * @param {number} [length] Message length if known beforehand
                 * @returns {gmaing.events.v1.BettingSettlementApplied} BettingSettlementApplied
                 * @throws {Error} If the payload is not a reader or valid buffer
                 * @throws {$protobuf.util.ProtocolError} If required fields are missing
                 */
                BettingSettlementApplied.decode = function decode(reader, length, error) {
                    if (!(reader instanceof $Reader))
                        reader = $Reader.create(reader);
                    var end = length === undefined ? reader.len : reader.pos + length, message = new $root.gmaing.events.v1.BettingSettlementApplied();
                    while (reader.pos < end) {
                        var tag = reader.uint32();
                        if (tag === error)
                            break;
                        switch (tag >>> 3) {
                        case 1: {
                                message.runId = reader.string();
                                break;
                            }
                        case 2: {
                                message.settlementId = reader.string();
                                break;
                            }
                        case 3: {
                                message.drawId = reader.string();
                                break;
                            }
                        case 4: {
                                message.winningDigit = reader.int32();
                                break;
                            }
                        case 5: {
                                message.claimedRows = reader.int32();
                                break;
                            }
                        case 6: {
                                message.appliedRows = reader.int32();
                                break;
                            }
                        case 7: {
                                message.adminDelta = reader.int64();
                                break;
                            }
                        case 8: {
                                message.appliedAtMs = reader.int64();
                                break;
                            }
                        default:
                            reader.skipType(tag & 7);
                            break;
                        }
                    }
                    return message;
                };

                /**
                 * Decodes a BettingSettlementApplied message from the specified reader or buffer, length delimited.
                 * @function decodeDelimited
                 * @memberof gmaing.events.v1.BettingSettlementApplied
                 * @static
                 * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
                 * @returns {gmaing.events.v1.BettingSettlementApplied} BettingSettlementApplied
                 * @throws {Error} If the payload is not a reader or valid buffer
                 * @throws {$protobuf.util.ProtocolError} If required fields are missing
                 */
                BettingSettlementApplied.decodeDelimited = function decodeDelimited(reader) {
                    if (!(reader instanceof $Reader))
                        reader = new $Reader(reader);
                    return this.decode(reader, reader.uint32());
                };

                /**
                 * Verifies a BettingSettlementApplied message.
                 * @function verify
                 * @memberof gmaing.events.v1.BettingSettlementApplied
                 * @static
                 * @param {Object.<string,*>} message Plain object to verify
                 * @returns {string|null} `null` if valid, otherwise the reason why it is not
                 */
                BettingSettlementApplied.verify = function verify(message) {
                    if (typeof message !== "object" || message === null)
                        return "object expected";
                    if (message.runId != null && message.hasOwnProperty("runId"))
                        if (!$util.isString(message.runId))
                            return "runId: string expected";
                    if (message.settlementId != null && message.hasOwnProperty("settlementId"))
                        if (!$util.isString(message.settlementId))
                            return "settlementId: string expected";
                    if (message.drawId != null && message.hasOwnProperty("drawId"))
                        if (!$util.isString(message.drawId))
                            return "drawId: string expected";
                    if (message.winningDigit != null && message.hasOwnProperty("winningDigit"))
                        if (!$util.isInteger(message.winningDigit))
                            return "winningDigit: integer expected";
                    if (message.claimedRows != null && message.hasOwnProperty("claimedRows"))
                        if (!$util.isInteger(message.claimedRows))
                            return "claimedRows: integer expected";
                    if (message.appliedRows != null && message.hasOwnProperty("appliedRows"))
                        if (!$util.isInteger(message.appliedRows))
                            return "appliedRows: integer expected";
                    if (message.adminDelta != null && message.hasOwnProperty("adminDelta"))
                        if (!$util.isInteger(message.adminDelta) && !(message.adminDelta && $util.isInteger(message.adminDelta.low) && $util.isInteger(message.adminDelta.high)))
                            return "adminDelta: integer|Long expected";
                    if (message.appliedAtMs != null && message.hasOwnProperty("appliedAtMs"))
                        if (!$util.isInteger(message.appliedAtMs) && !(message.appliedAtMs && $util.isInteger(message.appliedAtMs.low) && $util.isInteger(message.appliedAtMs.high)))
                            return "appliedAtMs: integer|Long expected";
                    return null;
                };

                /**
                 * Creates a BettingSettlementApplied message from a plain object. Also converts values to their respective internal types.
                 * @function fromObject
                 * @memberof gmaing.events.v1.BettingSettlementApplied
                 * @static
                 * @param {Object.<string,*>} object Plain object
                 * @returns {gmaing.events.v1.BettingSettlementApplied} BettingSettlementApplied
                 */
                BettingSettlementApplied.fromObject = function fromObject(object) {
                    if (object instanceof $root.gmaing.events.v1.BettingSettlementApplied)
                        return object;
                    var message = new $root.gmaing.events.v1.BettingSettlementApplied();
                    if (object.runId != null)
                        message.runId = String(object.runId);
                    if (object.settlementId != null)
                        message.settlementId = String(object.settlementId);
                    if (object.drawId != null)
                        message.drawId = String(object.drawId);
                    if (object.winningDigit != null)
                        message.winningDigit = object.winningDigit | 0;
                    if (object.claimedRows != null)
                        message.claimedRows = object.claimedRows | 0;
                    if (object.appliedRows != null)
                        message.appliedRows = object.appliedRows | 0;
                    if (object.adminDelta != null)
                        if ($util.Long)
                            (message.adminDelta = $util.Long.fromValue(object.adminDelta)).unsigned = false;
                        else if (typeof object.adminDelta === "string")
                            message.adminDelta = parseInt(object.adminDelta, 10);
                        else if (typeof object.adminDelta === "number")
                            message.adminDelta = object.adminDelta;
                        else if (typeof object.adminDelta === "object")
                            message.adminDelta = new $util.LongBits(object.adminDelta.low >>> 0, object.adminDelta.high >>> 0).toNumber();
                    if (object.appliedAtMs != null)
                        if ($util.Long)
                            (message.appliedAtMs = $util.Long.fromValue(object.appliedAtMs)).unsigned = false;
                        else if (typeof object.appliedAtMs === "string")
                            message.appliedAtMs = parseInt(object.appliedAtMs, 10);
                        else if (typeof object.appliedAtMs === "number")
                            message.appliedAtMs = object.appliedAtMs;
                        else if (typeof object.appliedAtMs === "object")
                            message.appliedAtMs = new $util.LongBits(object.appliedAtMs.low >>> 0, object.appliedAtMs.high >>> 0).toNumber();
                    return message;
                };

                /**
                 * Creates a plain object from a BettingSettlementApplied message. Also converts values to other types if specified.
                 * @function toObject
                 * @memberof gmaing.events.v1.BettingSettlementApplied
                 * @static
                 * @param {gmaing.events.v1.BettingSettlementApplied} message BettingSettlementApplied
                 * @param {$protobuf.IConversionOptions} [options] Conversion options
                 * @returns {Object.<string,*>} Plain object
                 */
                BettingSettlementApplied.toObject = function toObject(message, options) {
                    if (!options)
                        options = {};
                    var object = {};
                    if (options.defaults) {
                        object.runId = "";
                        object.settlementId = "";
                        object.drawId = "";
                        object.winningDigit = 0;
                        object.claimedRows = 0;
                        object.appliedRows = 0;
                        if ($util.Long) {
                            var long = new $util.Long(0, 0, false);
                            object.adminDelta = options.longs === String ? long.toString() : options.longs === Number ? long.toNumber() : long;
                        } else
                            object.adminDelta = options.longs === String ? "0" : 0;
                        if ($util.Long) {
                            var long = new $util.Long(0, 0, false);
                            object.appliedAtMs = options.longs === String ? long.toString() : options.longs === Number ? long.toNumber() : long;
                        } else
                            object.appliedAtMs = options.longs === String ? "0" : 0;
                    }
                    if (message.runId != null && message.hasOwnProperty("runId"))
                        object.runId = message.runId;
                    if (message.settlementId != null && message.hasOwnProperty("settlementId"))
                        object.settlementId = message.settlementId;
                    if (message.drawId != null && message.hasOwnProperty("drawId"))
                        object.drawId = message.drawId;
                    if (message.winningDigit != null && message.hasOwnProperty("winningDigit"))
                        object.winningDigit = message.winningDigit;
                    if (message.claimedRows != null && message.hasOwnProperty("claimedRows"))
                        object.claimedRows = message.claimedRows;
                    if (message.appliedRows != null && message.hasOwnProperty("appliedRows"))
                        object.appliedRows = message.appliedRows;
                    if (message.adminDelta != null && message.hasOwnProperty("adminDelta"))
                        if (typeof message.adminDelta === "number")
                            object.adminDelta = options.longs === String ? String(message.adminDelta) : message.adminDelta;
                        else
                            object.adminDelta = options.longs === String ? $util.Long.prototype.toString.call(message.adminDelta) : options.longs === Number ? new $util.LongBits(message.adminDelta.low >>> 0, message.adminDelta.high >>> 0).toNumber() : message.adminDelta;
                    if (message.appliedAtMs != null && message.hasOwnProperty("appliedAtMs"))
                        if (typeof message.appliedAtMs === "number")
                            object.appliedAtMs = options.longs === String ? String(message.appliedAtMs) : message.appliedAtMs;
                        else
                            object.appliedAtMs = options.longs === String ? $util.Long.prototype.toString.call(message.appliedAtMs) : options.longs === Number ? new $util.LongBits(message.appliedAtMs.low >>> 0, message.appliedAtMs.high >>> 0).toNumber() : message.appliedAtMs;
                    return object;
                };

                /**
                 * Converts this BettingSettlementApplied to JSON.
                 * @function toJSON
                 * @memberof gmaing.events.v1.BettingSettlementApplied
                 * @instance
                 * @returns {Object.<string,*>} JSON object
                 */
                BettingSettlementApplied.prototype.toJSON = function toJSON() {
                    return this.constructor.toObject(this, $protobuf.util.toJSONOptions);
                };

                /**
                 * Gets the default type url for BettingSettlementApplied
                 * @function getTypeUrl
                 * @memberof gmaing.events.v1.BettingSettlementApplied
                 * @static
                 * @param {string} [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
                 * @returns {string} The default type url
                 */
                BettingSettlementApplied.getTypeUrl = function getTypeUrl(typeUrlPrefix) {
                    if (typeUrlPrefix === undefined) {
                        typeUrlPrefix = "type.googleapis.com";
                    }
                    return typeUrlPrefix + "/gmaing.events.v1.BettingSettlementApplied";
                };

                return BettingSettlementApplied;
            })();

            v1.SystemNotice = (function() {

                /**
                 * Properties of a SystemNotice.
                 * @memberof gmaing.events.v1
                 * @interface ISystemNotice
                 * @property {string|null} [level] SystemNotice level
                 * @property {string|null} [code] SystemNotice code
                 * @property {string|null} [message] SystemNotice message
                 */

                /**
                 * Constructs a new SystemNotice.
                 * @memberof gmaing.events.v1
                 * @classdesc Represents a SystemNotice.
                 * @implements ISystemNotice
                 * @constructor
                 * @param {gmaing.events.v1.ISystemNotice=} [properties] Properties to set
                 */
                function SystemNotice(properties) {
                    if (properties)
                        for (var keys = Object.keys(properties), i = 0; i < keys.length; ++i)
                            if (properties[keys[i]] != null)
                                this[keys[i]] = properties[keys[i]];
                }

                /**
                 * SystemNotice level.
                 * @member {string} level
                 * @memberof gmaing.events.v1.SystemNotice
                 * @instance
                 */
                SystemNotice.prototype.level = "";

                /**
                 * SystemNotice code.
                 * @member {string} code
                 * @memberof gmaing.events.v1.SystemNotice
                 * @instance
                 */
                SystemNotice.prototype.code = "";

                /**
                 * SystemNotice message.
                 * @member {string} message
                 * @memberof gmaing.events.v1.SystemNotice
                 * @instance
                 */
                SystemNotice.prototype.message = "";

                /**
                 * Creates a new SystemNotice instance using the specified properties.
                 * @function create
                 * @memberof gmaing.events.v1.SystemNotice
                 * @static
                 * @param {gmaing.events.v1.ISystemNotice=} [properties] Properties to set
                 * @returns {gmaing.events.v1.SystemNotice} SystemNotice instance
                 */
                SystemNotice.create = function create(properties) {
                    return new SystemNotice(properties);
                };

                /**
                 * Encodes the specified SystemNotice message. Does not implicitly {@link gmaing.events.v1.SystemNotice.verify|verify} messages.
                 * @function encode
                 * @memberof gmaing.events.v1.SystemNotice
                 * @static
                 * @param {gmaing.events.v1.ISystemNotice} message SystemNotice message or plain object to encode
                 * @param {$protobuf.Writer} [writer] Writer to encode to
                 * @returns {$protobuf.Writer} Writer
                 */
                SystemNotice.encode = function encode(message, writer) {
                    if (!writer)
                        writer = $Writer.create();
                    if (message.level != null && Object.hasOwnProperty.call(message, "level"))
                        writer.uint32(/* id 1, wireType 2 =*/10).string(message.level);
                    if (message.code != null && Object.hasOwnProperty.call(message, "code"))
                        writer.uint32(/* id 2, wireType 2 =*/18).string(message.code);
                    if (message.message != null && Object.hasOwnProperty.call(message, "message"))
                        writer.uint32(/* id 3, wireType 2 =*/26).string(message.message);
                    return writer;
                };

                /**
                 * Encodes the specified SystemNotice message, length delimited. Does not implicitly {@link gmaing.events.v1.SystemNotice.verify|verify} messages.
                 * @function encodeDelimited
                 * @memberof gmaing.events.v1.SystemNotice
                 * @static
                 * @param {gmaing.events.v1.ISystemNotice} message SystemNotice message or plain object to encode
                 * @param {$protobuf.Writer} [writer] Writer to encode to
                 * @returns {$protobuf.Writer} Writer
                 */
                SystemNotice.encodeDelimited = function encodeDelimited(message, writer) {
                    return this.encode(message, writer).ldelim();
                };

                /**
                 * Decodes a SystemNotice message from the specified reader or buffer.
                 * @function decode
                 * @memberof gmaing.events.v1.SystemNotice
                 * @static
                 * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
                 * @param {number} [length] Message length if known beforehand
                 * @returns {gmaing.events.v1.SystemNotice} SystemNotice
                 * @throws {Error} If the payload is not a reader or valid buffer
                 * @throws {$protobuf.util.ProtocolError} If required fields are missing
                 */
                SystemNotice.decode = function decode(reader, length, error) {
                    if (!(reader instanceof $Reader))
                        reader = $Reader.create(reader);
                    var end = length === undefined ? reader.len : reader.pos + length, message = new $root.gmaing.events.v1.SystemNotice();
                    while (reader.pos < end) {
                        var tag = reader.uint32();
                        if (tag === error)
                            break;
                        switch (tag >>> 3) {
                        case 1: {
                                message.level = reader.string();
                                break;
                            }
                        case 2: {
                                message.code = reader.string();
                                break;
                            }
                        case 3: {
                                message.message = reader.string();
                                break;
                            }
                        default:
                            reader.skipType(tag & 7);
                            break;
                        }
                    }
                    return message;
                };

                /**
                 * Decodes a SystemNotice message from the specified reader or buffer, length delimited.
                 * @function decodeDelimited
                 * @memberof gmaing.events.v1.SystemNotice
                 * @static
                 * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
                 * @returns {gmaing.events.v1.SystemNotice} SystemNotice
                 * @throws {Error} If the payload is not a reader or valid buffer
                 * @throws {$protobuf.util.ProtocolError} If required fields are missing
                 */
                SystemNotice.decodeDelimited = function decodeDelimited(reader) {
                    if (!(reader instanceof $Reader))
                        reader = new $Reader(reader);
                    return this.decode(reader, reader.uint32());
                };

                /**
                 * Verifies a SystemNotice message.
                 * @function verify
                 * @memberof gmaing.events.v1.SystemNotice
                 * @static
                 * @param {Object.<string,*>} message Plain object to verify
                 * @returns {string|null} `null` if valid, otherwise the reason why it is not
                 */
                SystemNotice.verify = function verify(message) {
                    if (typeof message !== "object" || message === null)
                        return "object expected";
                    if (message.level != null && message.hasOwnProperty("level"))
                        if (!$util.isString(message.level))
                            return "level: string expected";
                    if (message.code != null && message.hasOwnProperty("code"))
                        if (!$util.isString(message.code))
                            return "code: string expected";
                    if (message.message != null && message.hasOwnProperty("message"))
                        if (!$util.isString(message.message))
                            return "message: string expected";
                    return null;
                };

                /**
                 * Creates a SystemNotice message from a plain object. Also converts values to their respective internal types.
                 * @function fromObject
                 * @memberof gmaing.events.v1.SystemNotice
                 * @static
                 * @param {Object.<string,*>} object Plain object
                 * @returns {gmaing.events.v1.SystemNotice} SystemNotice
                 */
                SystemNotice.fromObject = function fromObject(object) {
                    if (object instanceof $root.gmaing.events.v1.SystemNotice)
                        return object;
                    var message = new $root.gmaing.events.v1.SystemNotice();
                    if (object.level != null)
                        message.level = String(object.level);
                    if (object.code != null)
                        message.code = String(object.code);
                    if (object.message != null)
                        message.message = String(object.message);
                    return message;
                };

                /**
                 * Creates a plain object from a SystemNotice message. Also converts values to other types if specified.
                 * @function toObject
                 * @memberof gmaing.events.v1.SystemNotice
                 * @static
                 * @param {gmaing.events.v1.SystemNotice} message SystemNotice
                 * @param {$protobuf.IConversionOptions} [options] Conversion options
                 * @returns {Object.<string,*>} Plain object
                 */
                SystemNotice.toObject = function toObject(message, options) {
                    if (!options)
                        options = {};
                    var object = {};
                    if (options.defaults) {
                        object.level = "";
                        object.code = "";
                        object.message = "";
                    }
                    if (message.level != null && message.hasOwnProperty("level"))
                        object.level = message.level;
                    if (message.code != null && message.hasOwnProperty("code"))
                        object.code = message.code;
                    if (message.message != null && message.hasOwnProperty("message"))
                        object.message = message.message;
                    return object;
                };

                /**
                 * Converts this SystemNotice to JSON.
                 * @function toJSON
                 * @memberof gmaing.events.v1.SystemNotice
                 * @instance
                 * @returns {Object.<string,*>} JSON object
                 */
                SystemNotice.prototype.toJSON = function toJSON() {
                    return this.constructor.toObject(this, $protobuf.util.toJSONOptions);
                };

                /**
                 * Gets the default type url for SystemNotice
                 * @function getTypeUrl
                 * @memberof gmaing.events.v1.SystemNotice
                 * @static
                 * @param {string} [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
                 * @returns {string} The default type url
                 */
                SystemNotice.getTypeUrl = function getTypeUrl(typeUrlPrefix) {
                    if (typeUrlPrefix === undefined) {
                        typeUrlPrefix = "type.googleapis.com";
                    }
                    return typeUrlPrefix + "/gmaing.events.v1.SystemNotice";
                };

                return SystemNotice;
            })();

            v1.Heartbeat = (function() {

                /**
                 * Properties of a Heartbeat.
                 * @memberof gmaing.events.v1
                 * @interface IHeartbeat
                 * @property {number|Long|null} [heartbeatSeq] Heartbeat heartbeatSeq
                 */

                /**
                 * Constructs a new Heartbeat.
                 * @memberof gmaing.events.v1
                 * @classdesc Represents a Heartbeat.
                 * @implements IHeartbeat
                 * @constructor
                 * @param {gmaing.events.v1.IHeartbeat=} [properties] Properties to set
                 */
                function Heartbeat(properties) {
                    if (properties)
                        for (var keys = Object.keys(properties), i = 0; i < keys.length; ++i)
                            if (properties[keys[i]] != null)
                                this[keys[i]] = properties[keys[i]];
                }

                /**
                 * Heartbeat heartbeatSeq.
                 * @member {number|Long} heartbeatSeq
                 * @memberof gmaing.events.v1.Heartbeat
                 * @instance
                 */
                Heartbeat.prototype.heartbeatSeq = $util.Long ? $util.Long.fromBits(0,0,false) : 0;

                /**
                 * Creates a new Heartbeat instance using the specified properties.
                 * @function create
                 * @memberof gmaing.events.v1.Heartbeat
                 * @static
                 * @param {gmaing.events.v1.IHeartbeat=} [properties] Properties to set
                 * @returns {gmaing.events.v1.Heartbeat} Heartbeat instance
                 */
                Heartbeat.create = function create(properties) {
                    return new Heartbeat(properties);
                };

                /**
                 * Encodes the specified Heartbeat message. Does not implicitly {@link gmaing.events.v1.Heartbeat.verify|verify} messages.
                 * @function encode
                 * @memberof gmaing.events.v1.Heartbeat
                 * @static
                 * @param {gmaing.events.v1.IHeartbeat} message Heartbeat message or plain object to encode
                 * @param {$protobuf.Writer} [writer] Writer to encode to
                 * @returns {$protobuf.Writer} Writer
                 */
                Heartbeat.encode = function encode(message, writer) {
                    if (!writer)
                        writer = $Writer.create();
                    if (message.heartbeatSeq != null && Object.hasOwnProperty.call(message, "heartbeatSeq"))
                        writer.uint32(/* id 1, wireType 0 =*/8).int64(message.heartbeatSeq);
                    return writer;
                };

                /**
                 * Encodes the specified Heartbeat message, length delimited. Does not implicitly {@link gmaing.events.v1.Heartbeat.verify|verify} messages.
                 * @function encodeDelimited
                 * @memberof gmaing.events.v1.Heartbeat
                 * @static
                 * @param {gmaing.events.v1.IHeartbeat} message Heartbeat message or plain object to encode
                 * @param {$protobuf.Writer} [writer] Writer to encode to
                 * @returns {$protobuf.Writer} Writer
                 */
                Heartbeat.encodeDelimited = function encodeDelimited(message, writer) {
                    return this.encode(message, writer).ldelim();
                };

                /**
                 * Decodes a Heartbeat message from the specified reader or buffer.
                 * @function decode
                 * @memberof gmaing.events.v1.Heartbeat
                 * @static
                 * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
                 * @param {number} [length] Message length if known beforehand
                 * @returns {gmaing.events.v1.Heartbeat} Heartbeat
                 * @throws {Error} If the payload is not a reader or valid buffer
                 * @throws {$protobuf.util.ProtocolError} If required fields are missing
                 */
                Heartbeat.decode = function decode(reader, length, error) {
                    if (!(reader instanceof $Reader))
                        reader = $Reader.create(reader);
                    var end = length === undefined ? reader.len : reader.pos + length, message = new $root.gmaing.events.v1.Heartbeat();
                    while (reader.pos < end) {
                        var tag = reader.uint32();
                        if (tag === error)
                            break;
                        switch (tag >>> 3) {
                        case 1: {
                                message.heartbeatSeq = reader.int64();
                                break;
                            }
                        default:
                            reader.skipType(tag & 7);
                            break;
                        }
                    }
                    return message;
                };

                /**
                 * Decodes a Heartbeat message from the specified reader or buffer, length delimited.
                 * @function decodeDelimited
                 * @memberof gmaing.events.v1.Heartbeat
                 * @static
                 * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
                 * @returns {gmaing.events.v1.Heartbeat} Heartbeat
                 * @throws {Error} If the payload is not a reader or valid buffer
                 * @throws {$protobuf.util.ProtocolError} If required fields are missing
                 */
                Heartbeat.decodeDelimited = function decodeDelimited(reader) {
                    if (!(reader instanceof $Reader))
                        reader = new $Reader(reader);
                    return this.decode(reader, reader.uint32());
                };

                /**
                 * Verifies a Heartbeat message.
                 * @function verify
                 * @memberof gmaing.events.v1.Heartbeat
                 * @static
                 * @param {Object.<string,*>} message Plain object to verify
                 * @returns {string|null} `null` if valid, otherwise the reason why it is not
                 */
                Heartbeat.verify = function verify(message) {
                    if (typeof message !== "object" || message === null)
                        return "object expected";
                    if (message.heartbeatSeq != null && message.hasOwnProperty("heartbeatSeq"))
                        if (!$util.isInteger(message.heartbeatSeq) && !(message.heartbeatSeq && $util.isInteger(message.heartbeatSeq.low) && $util.isInteger(message.heartbeatSeq.high)))
                            return "heartbeatSeq: integer|Long expected";
                    return null;
                };

                /**
                 * Creates a Heartbeat message from a plain object. Also converts values to their respective internal types.
                 * @function fromObject
                 * @memberof gmaing.events.v1.Heartbeat
                 * @static
                 * @param {Object.<string,*>} object Plain object
                 * @returns {gmaing.events.v1.Heartbeat} Heartbeat
                 */
                Heartbeat.fromObject = function fromObject(object) {
                    if (object instanceof $root.gmaing.events.v1.Heartbeat)
                        return object;
                    var message = new $root.gmaing.events.v1.Heartbeat();
                    if (object.heartbeatSeq != null)
                        if ($util.Long)
                            (message.heartbeatSeq = $util.Long.fromValue(object.heartbeatSeq)).unsigned = false;
                        else if (typeof object.heartbeatSeq === "string")
                            message.heartbeatSeq = parseInt(object.heartbeatSeq, 10);
                        else if (typeof object.heartbeatSeq === "number")
                            message.heartbeatSeq = object.heartbeatSeq;
                        else if (typeof object.heartbeatSeq === "object")
                            message.heartbeatSeq = new $util.LongBits(object.heartbeatSeq.low >>> 0, object.heartbeatSeq.high >>> 0).toNumber();
                    return message;
                };

                /**
                 * Creates a plain object from a Heartbeat message. Also converts values to other types if specified.
                 * @function toObject
                 * @memberof gmaing.events.v1.Heartbeat
                 * @static
                 * @param {gmaing.events.v1.Heartbeat} message Heartbeat
                 * @param {$protobuf.IConversionOptions} [options] Conversion options
                 * @returns {Object.<string,*>} Plain object
                 */
                Heartbeat.toObject = function toObject(message, options) {
                    if (!options)
                        options = {};
                    var object = {};
                    if (options.defaults)
                        if ($util.Long) {
                            var long = new $util.Long(0, 0, false);
                            object.heartbeatSeq = options.longs === String ? long.toString() : options.longs === Number ? long.toNumber() : long;
                        } else
                            object.heartbeatSeq = options.longs === String ? "0" : 0;
                    if (message.heartbeatSeq != null && message.hasOwnProperty("heartbeatSeq"))
                        if (typeof message.heartbeatSeq === "number")
                            object.heartbeatSeq = options.longs === String ? String(message.heartbeatSeq) : message.heartbeatSeq;
                        else
                            object.heartbeatSeq = options.longs === String ? $util.Long.prototype.toString.call(message.heartbeatSeq) : options.longs === Number ? new $util.LongBits(message.heartbeatSeq.low >>> 0, message.heartbeatSeq.high >>> 0).toNumber() : message.heartbeatSeq;
                    return object;
                };

                /**
                 * Converts this Heartbeat to JSON.
                 * @function toJSON
                 * @memberof gmaing.events.v1.Heartbeat
                 * @instance
                 * @returns {Object.<string,*>} JSON object
                 */
                Heartbeat.prototype.toJSON = function toJSON() {
                    return this.constructor.toObject(this, $protobuf.util.toJSONOptions);
                };

                /**
                 * Gets the default type url for Heartbeat
                 * @function getTypeUrl
                 * @memberof gmaing.events.v1.Heartbeat
                 * @static
                 * @param {string} [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
                 * @returns {string} The default type url
                 */
                Heartbeat.getTypeUrl = function getTypeUrl(typeUrlPrefix) {
                    if (typeUrlPrefix === undefined) {
                        typeUrlPrefix = "type.googleapis.com";
                    }
                    return typeUrlPrefix + "/gmaing.events.v1.Heartbeat";
                };

                return Heartbeat;
            })();

            return v1;
        })();

        return events;
    })();

    return gmaing;
})();

module.exports = $root;
