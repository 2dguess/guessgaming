import * as $protobuf from "protobufjs";
import Long = require("long");
/** Namespace gmaing. */
export namespace gmaing {

    /** Namespace events. */
    namespace events {

        /** Namespace v1. */
        namespace v1 {

            /** Properties of an EventEnvelope. */
            interface IEventEnvelope {

                /** EventEnvelope eventId */
                eventId?: (string|null);

                /** EventEnvelope serverTsMs */
                serverTsMs?: (number|Long|null);

                /** EventEnvelope source */
                source?: (string|null);

                /** EventEnvelope channel */
                channel?: (string|null);

                /** EventEnvelope seq */
                seq?: (number|Long|null);

                /** EventEnvelope socialPostCreated */
                socialPostCreated?: (gmaing.events.v1.ISocialPostCreated|null);

                /** EventEnvelope socialGiftSent */
                socialGiftSent?: (gmaing.events.v1.ISocialGiftSent|null);

                /** EventEnvelope liveDrawStateUpdated */
                liveDrawStateUpdated?: (gmaing.events.v1.ILiveDrawStateUpdated|null);

                /** EventEnvelope liveOddsUpdated */
                liveOddsUpdated?: (gmaing.events.v1.ILiveOddsUpdated|null);

                /** EventEnvelope bettingBetPlaced */
                bettingBetPlaced?: (gmaing.events.v1.IBettingBetPlaced|null);

                /** EventEnvelope bettingSettlementApplied */
                bettingSettlementApplied?: (gmaing.events.v1.IBettingSettlementApplied|null);

                /** EventEnvelope systemNotice */
                systemNotice?: (gmaing.events.v1.ISystemNotice|null);

                /** EventEnvelope heartbeat */
                heartbeat?: (gmaing.events.v1.IHeartbeat|null);
            }

            /** Represents an EventEnvelope. */
            class EventEnvelope implements IEventEnvelope {

                /**
                 * Constructs a new EventEnvelope.
                 * @param [properties] Properties to set
                 */
                constructor(properties?: gmaing.events.v1.IEventEnvelope);

                /** EventEnvelope eventId. */
                public eventId: string;

                /** EventEnvelope serverTsMs. */
                public serverTsMs: (number|Long);

                /** EventEnvelope source. */
                public source: string;

                /** EventEnvelope channel. */
                public channel: string;

                /** EventEnvelope seq. */
                public seq: (number|Long);

                /** EventEnvelope socialPostCreated. */
                public socialPostCreated?: (gmaing.events.v1.ISocialPostCreated|null);

                /** EventEnvelope socialGiftSent. */
                public socialGiftSent?: (gmaing.events.v1.ISocialGiftSent|null);

                /** EventEnvelope liveDrawStateUpdated. */
                public liveDrawStateUpdated?: (gmaing.events.v1.ILiveDrawStateUpdated|null);

                /** EventEnvelope liveOddsUpdated. */
                public liveOddsUpdated?: (gmaing.events.v1.ILiveOddsUpdated|null);

                /** EventEnvelope bettingBetPlaced. */
                public bettingBetPlaced?: (gmaing.events.v1.IBettingBetPlaced|null);

                /** EventEnvelope bettingSettlementApplied. */
                public bettingSettlementApplied?: (gmaing.events.v1.IBettingSettlementApplied|null);

                /** EventEnvelope systemNotice. */
                public systemNotice?: (gmaing.events.v1.ISystemNotice|null);

                /** EventEnvelope heartbeat. */
                public heartbeat?: (gmaing.events.v1.IHeartbeat|null);

                /** EventEnvelope payload. */
                public payload?: ("socialPostCreated"|"socialGiftSent"|"liveDrawStateUpdated"|"liveOddsUpdated"|"bettingBetPlaced"|"bettingSettlementApplied"|"systemNotice"|"heartbeat");

                /**
                 * Creates a new EventEnvelope instance using the specified properties.
                 * @param [properties] Properties to set
                 * @returns EventEnvelope instance
                 */
                public static create(properties?: gmaing.events.v1.IEventEnvelope): gmaing.events.v1.EventEnvelope;

                /**
                 * Encodes the specified EventEnvelope message. Does not implicitly {@link gmaing.events.v1.EventEnvelope.verify|verify} messages.
                 * @param message EventEnvelope message or plain object to encode
                 * @param [writer] Writer to encode to
                 * @returns Writer
                 */
                public static encode(message: gmaing.events.v1.IEventEnvelope, writer?: $protobuf.Writer): $protobuf.Writer;

                /**
                 * Encodes the specified EventEnvelope message, length delimited. Does not implicitly {@link gmaing.events.v1.EventEnvelope.verify|verify} messages.
                 * @param message EventEnvelope message or plain object to encode
                 * @param [writer] Writer to encode to
                 * @returns Writer
                 */
                public static encodeDelimited(message: gmaing.events.v1.IEventEnvelope, writer?: $protobuf.Writer): $protobuf.Writer;

                /**
                 * Decodes an EventEnvelope message from the specified reader or buffer.
                 * @param reader Reader or buffer to decode from
                 * @param [length] Message length if known beforehand
                 * @returns EventEnvelope
                 * @throws {Error} If the payload is not a reader or valid buffer
                 * @throws {$protobuf.util.ProtocolError} If required fields are missing
                 */
                public static decode(reader: ($protobuf.Reader|Uint8Array), length?: number): gmaing.events.v1.EventEnvelope;

                /**
                 * Decodes an EventEnvelope message from the specified reader or buffer, length delimited.
                 * @param reader Reader or buffer to decode from
                 * @returns EventEnvelope
                 * @throws {Error} If the payload is not a reader or valid buffer
                 * @throws {$protobuf.util.ProtocolError} If required fields are missing
                 */
                public static decodeDelimited(reader: ($protobuf.Reader|Uint8Array)): gmaing.events.v1.EventEnvelope;

                /**
                 * Verifies an EventEnvelope message.
                 * @param message Plain object to verify
                 * @returns `null` if valid, otherwise the reason why it is not
                 */
                public static verify(message: { [k: string]: any }): (string|null);

                /**
                 * Creates an EventEnvelope message from a plain object. Also converts values to their respective internal types.
                 * @param object Plain object
                 * @returns EventEnvelope
                 */
                public static fromObject(object: { [k: string]: any }): gmaing.events.v1.EventEnvelope;

                /**
                 * Creates a plain object from an EventEnvelope message. Also converts values to other types if specified.
                 * @param message EventEnvelope
                 * @param [options] Conversion options
                 * @returns Plain object
                 */
                public static toObject(message: gmaing.events.v1.EventEnvelope, options?: $protobuf.IConversionOptions): { [k: string]: any };

                /**
                 * Converts this EventEnvelope to JSON.
                 * @returns JSON object
                 */
                public toJSON(): { [k: string]: any };

                /**
                 * Gets the default type url for EventEnvelope
                 * @param [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
                 * @returns The default type url
                 */
                public static getTypeUrl(typeUrlPrefix?: string): string;
            }

            /** Properties of a SocialPostCreated. */
            interface ISocialPostCreated {

                /** SocialPostCreated postId */
                postId?: (string|null);

                /** SocialPostCreated authorUserId */
                authorUserId?: (string|null);

                /** SocialPostCreated previewText */
                previewText?: (string|null);

                /** SocialPostCreated createdAtMs */
                createdAtMs?: (number|Long|null);
            }

            /** Represents a SocialPostCreated. */
            class SocialPostCreated implements ISocialPostCreated {

                /**
                 * Constructs a new SocialPostCreated.
                 * @param [properties] Properties to set
                 */
                constructor(properties?: gmaing.events.v1.ISocialPostCreated);

                /** SocialPostCreated postId. */
                public postId: string;

                /** SocialPostCreated authorUserId. */
                public authorUserId: string;

                /** SocialPostCreated previewText. */
                public previewText: string;

                /** SocialPostCreated createdAtMs. */
                public createdAtMs: (number|Long);

                /**
                 * Creates a new SocialPostCreated instance using the specified properties.
                 * @param [properties] Properties to set
                 * @returns SocialPostCreated instance
                 */
                public static create(properties?: gmaing.events.v1.ISocialPostCreated): gmaing.events.v1.SocialPostCreated;

                /**
                 * Encodes the specified SocialPostCreated message. Does not implicitly {@link gmaing.events.v1.SocialPostCreated.verify|verify} messages.
                 * @param message SocialPostCreated message or plain object to encode
                 * @param [writer] Writer to encode to
                 * @returns Writer
                 */
                public static encode(message: gmaing.events.v1.ISocialPostCreated, writer?: $protobuf.Writer): $protobuf.Writer;

                /**
                 * Encodes the specified SocialPostCreated message, length delimited. Does not implicitly {@link gmaing.events.v1.SocialPostCreated.verify|verify} messages.
                 * @param message SocialPostCreated message or plain object to encode
                 * @param [writer] Writer to encode to
                 * @returns Writer
                 */
                public static encodeDelimited(message: gmaing.events.v1.ISocialPostCreated, writer?: $protobuf.Writer): $protobuf.Writer;

                /**
                 * Decodes a SocialPostCreated message from the specified reader or buffer.
                 * @param reader Reader or buffer to decode from
                 * @param [length] Message length if known beforehand
                 * @returns SocialPostCreated
                 * @throws {Error} If the payload is not a reader or valid buffer
                 * @throws {$protobuf.util.ProtocolError} If required fields are missing
                 */
                public static decode(reader: ($protobuf.Reader|Uint8Array), length?: number): gmaing.events.v1.SocialPostCreated;

                /**
                 * Decodes a SocialPostCreated message from the specified reader or buffer, length delimited.
                 * @param reader Reader or buffer to decode from
                 * @returns SocialPostCreated
                 * @throws {Error} If the payload is not a reader or valid buffer
                 * @throws {$protobuf.util.ProtocolError} If required fields are missing
                 */
                public static decodeDelimited(reader: ($protobuf.Reader|Uint8Array)): gmaing.events.v1.SocialPostCreated;

                /**
                 * Verifies a SocialPostCreated message.
                 * @param message Plain object to verify
                 * @returns `null` if valid, otherwise the reason why it is not
                 */
                public static verify(message: { [k: string]: any }): (string|null);

                /**
                 * Creates a SocialPostCreated message from a plain object. Also converts values to their respective internal types.
                 * @param object Plain object
                 * @returns SocialPostCreated
                 */
                public static fromObject(object: { [k: string]: any }): gmaing.events.v1.SocialPostCreated;

                /**
                 * Creates a plain object from a SocialPostCreated message. Also converts values to other types if specified.
                 * @param message SocialPostCreated
                 * @param [options] Conversion options
                 * @returns Plain object
                 */
                public static toObject(message: gmaing.events.v1.SocialPostCreated, options?: $protobuf.IConversionOptions): { [k: string]: any };

                /**
                 * Converts this SocialPostCreated to JSON.
                 * @returns JSON object
                 */
                public toJSON(): { [k: string]: any };

                /**
                 * Gets the default type url for SocialPostCreated
                 * @param [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
                 * @returns The default type url
                 */
                public static getTypeUrl(typeUrlPrefix?: string): string;
            }

            /** Properties of a SocialGiftSent. */
            interface ISocialGiftSent {

                /** SocialGiftSent postId */
                postId?: (string|null);

                /** SocialGiftSent fromUserId */
                fromUserId?: (string|null);

                /** SocialGiftSent toUserId */
                toUserId?: (string|null);

                /** SocialGiftSent giftItemId */
                giftItemId?: (string|null);

                /** SocialGiftSent quantity */
                quantity?: (number|null);

                /** SocialGiftSent totalValue */
                totalValue?: (number|Long|null);

                /** SocialGiftSent createdAtMs */
                createdAtMs?: (number|Long|null);
            }

            /** Represents a SocialGiftSent. */
            class SocialGiftSent implements ISocialGiftSent {

                /**
                 * Constructs a new SocialGiftSent.
                 * @param [properties] Properties to set
                 */
                constructor(properties?: gmaing.events.v1.ISocialGiftSent);

                /** SocialGiftSent postId. */
                public postId: string;

                /** SocialGiftSent fromUserId. */
                public fromUserId: string;

                /** SocialGiftSent toUserId. */
                public toUserId: string;

                /** SocialGiftSent giftItemId. */
                public giftItemId: string;

                /** SocialGiftSent quantity. */
                public quantity: number;

                /** SocialGiftSent totalValue. */
                public totalValue: (number|Long);

                /** SocialGiftSent createdAtMs. */
                public createdAtMs: (number|Long);

                /**
                 * Creates a new SocialGiftSent instance using the specified properties.
                 * @param [properties] Properties to set
                 * @returns SocialGiftSent instance
                 */
                public static create(properties?: gmaing.events.v1.ISocialGiftSent): gmaing.events.v1.SocialGiftSent;

                /**
                 * Encodes the specified SocialGiftSent message. Does not implicitly {@link gmaing.events.v1.SocialGiftSent.verify|verify} messages.
                 * @param message SocialGiftSent message or plain object to encode
                 * @param [writer] Writer to encode to
                 * @returns Writer
                 */
                public static encode(message: gmaing.events.v1.ISocialGiftSent, writer?: $protobuf.Writer): $protobuf.Writer;

                /**
                 * Encodes the specified SocialGiftSent message, length delimited. Does not implicitly {@link gmaing.events.v1.SocialGiftSent.verify|verify} messages.
                 * @param message SocialGiftSent message or plain object to encode
                 * @param [writer] Writer to encode to
                 * @returns Writer
                 */
                public static encodeDelimited(message: gmaing.events.v1.ISocialGiftSent, writer?: $protobuf.Writer): $protobuf.Writer;

                /**
                 * Decodes a SocialGiftSent message from the specified reader or buffer.
                 * @param reader Reader or buffer to decode from
                 * @param [length] Message length if known beforehand
                 * @returns SocialGiftSent
                 * @throws {Error} If the payload is not a reader or valid buffer
                 * @throws {$protobuf.util.ProtocolError} If required fields are missing
                 */
                public static decode(reader: ($protobuf.Reader|Uint8Array), length?: number): gmaing.events.v1.SocialGiftSent;

                /**
                 * Decodes a SocialGiftSent message from the specified reader or buffer, length delimited.
                 * @param reader Reader or buffer to decode from
                 * @returns SocialGiftSent
                 * @throws {Error} If the payload is not a reader or valid buffer
                 * @throws {$protobuf.util.ProtocolError} If required fields are missing
                 */
                public static decodeDelimited(reader: ($protobuf.Reader|Uint8Array)): gmaing.events.v1.SocialGiftSent;

                /**
                 * Verifies a SocialGiftSent message.
                 * @param message Plain object to verify
                 * @returns `null` if valid, otherwise the reason why it is not
                 */
                public static verify(message: { [k: string]: any }): (string|null);

                /**
                 * Creates a SocialGiftSent message from a plain object. Also converts values to their respective internal types.
                 * @param object Plain object
                 * @returns SocialGiftSent
                 */
                public static fromObject(object: { [k: string]: any }): gmaing.events.v1.SocialGiftSent;

                /**
                 * Creates a plain object from a SocialGiftSent message. Also converts values to other types if specified.
                 * @param message SocialGiftSent
                 * @param [options] Conversion options
                 * @returns Plain object
                 */
                public static toObject(message: gmaing.events.v1.SocialGiftSent, options?: $protobuf.IConversionOptions): { [k: string]: any };

                /**
                 * Converts this SocialGiftSent to JSON.
                 * @returns JSON object
                 */
                public toJSON(): { [k: string]: any };

                /**
                 * Gets the default type url for SocialGiftSent
                 * @param [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
                 * @returns The default type url
                 */
                public static getTypeUrl(typeUrlPrefix?: string): string;
            }

            /** Properties of a LiveDrawStateUpdated. */
            interface ILiveDrawStateUpdated {

                /** LiveDrawStateUpdated market */
                market?: (string|null);

                /** LiveDrawStateUpdated session */
                session?: (string|null);

                /** LiveDrawStateUpdated drawId */
                drawId?: (string|null);

                /** LiveDrawStateUpdated state */
                state?: (string|null);

                /** LiveDrawStateUpdated currentValue */
                currentValue?: (number|null);

                /** LiveDrawStateUpdated previousValue */
                previousValue?: (number|null);

                /** LiveDrawStateUpdated resultAtMs */
                resultAtMs?: (number|Long|null);

                /** LiveDrawStateUpdated nextTransitionMs */
                nextTransitionMs?: (number|Long|null);
            }

            /** Represents a LiveDrawStateUpdated. */
            class LiveDrawStateUpdated implements ILiveDrawStateUpdated {

                /**
                 * Constructs a new LiveDrawStateUpdated.
                 * @param [properties] Properties to set
                 */
                constructor(properties?: gmaing.events.v1.ILiveDrawStateUpdated);

                /** LiveDrawStateUpdated market. */
                public market: string;

                /** LiveDrawStateUpdated session. */
                public session: string;

                /** LiveDrawStateUpdated drawId. */
                public drawId: string;

                /** LiveDrawStateUpdated state. */
                public state: string;

                /** LiveDrawStateUpdated currentValue. */
                public currentValue: number;

                /** LiveDrawStateUpdated previousValue. */
                public previousValue: number;

                /** LiveDrawStateUpdated resultAtMs. */
                public resultAtMs: (number|Long);

                /** LiveDrawStateUpdated nextTransitionMs. */
                public nextTransitionMs: (number|Long);

                /**
                 * Creates a new LiveDrawStateUpdated instance using the specified properties.
                 * @param [properties] Properties to set
                 * @returns LiveDrawStateUpdated instance
                 */
                public static create(properties?: gmaing.events.v1.ILiveDrawStateUpdated): gmaing.events.v1.LiveDrawStateUpdated;

                /**
                 * Encodes the specified LiveDrawStateUpdated message. Does not implicitly {@link gmaing.events.v1.LiveDrawStateUpdated.verify|verify} messages.
                 * @param message LiveDrawStateUpdated message or plain object to encode
                 * @param [writer] Writer to encode to
                 * @returns Writer
                 */
                public static encode(message: gmaing.events.v1.ILiveDrawStateUpdated, writer?: $protobuf.Writer): $protobuf.Writer;

                /**
                 * Encodes the specified LiveDrawStateUpdated message, length delimited. Does not implicitly {@link gmaing.events.v1.LiveDrawStateUpdated.verify|verify} messages.
                 * @param message LiveDrawStateUpdated message or plain object to encode
                 * @param [writer] Writer to encode to
                 * @returns Writer
                 */
                public static encodeDelimited(message: gmaing.events.v1.ILiveDrawStateUpdated, writer?: $protobuf.Writer): $protobuf.Writer;

                /**
                 * Decodes a LiveDrawStateUpdated message from the specified reader or buffer.
                 * @param reader Reader or buffer to decode from
                 * @param [length] Message length if known beforehand
                 * @returns LiveDrawStateUpdated
                 * @throws {Error} If the payload is not a reader or valid buffer
                 * @throws {$protobuf.util.ProtocolError} If required fields are missing
                 */
                public static decode(reader: ($protobuf.Reader|Uint8Array), length?: number): gmaing.events.v1.LiveDrawStateUpdated;

                /**
                 * Decodes a LiveDrawStateUpdated message from the specified reader or buffer, length delimited.
                 * @param reader Reader or buffer to decode from
                 * @returns LiveDrawStateUpdated
                 * @throws {Error} If the payload is not a reader or valid buffer
                 * @throws {$protobuf.util.ProtocolError} If required fields are missing
                 */
                public static decodeDelimited(reader: ($protobuf.Reader|Uint8Array)): gmaing.events.v1.LiveDrawStateUpdated;

                /**
                 * Verifies a LiveDrawStateUpdated message.
                 * @param message Plain object to verify
                 * @returns `null` if valid, otherwise the reason why it is not
                 */
                public static verify(message: { [k: string]: any }): (string|null);

                /**
                 * Creates a LiveDrawStateUpdated message from a plain object. Also converts values to their respective internal types.
                 * @param object Plain object
                 * @returns LiveDrawStateUpdated
                 */
                public static fromObject(object: { [k: string]: any }): gmaing.events.v1.LiveDrawStateUpdated;

                /**
                 * Creates a plain object from a LiveDrawStateUpdated message. Also converts values to other types if specified.
                 * @param message LiveDrawStateUpdated
                 * @param [options] Conversion options
                 * @returns Plain object
                 */
                public static toObject(message: gmaing.events.v1.LiveDrawStateUpdated, options?: $protobuf.IConversionOptions): { [k: string]: any };

                /**
                 * Converts this LiveDrawStateUpdated to JSON.
                 * @returns JSON object
                 */
                public toJSON(): { [k: string]: any };

                /**
                 * Gets the default type url for LiveDrawStateUpdated
                 * @param [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
                 * @returns The default type url
                 */
                public static getTypeUrl(typeUrlPrefix?: string): string;
            }

            /** Properties of a LiveOddsUpdated. */
            interface ILiveOddsUpdated {

                /** LiveOddsUpdated market */
                market?: (string|null);

                /** LiveOddsUpdated session */
                session?: (string|null);

                /** LiveOddsUpdated drawId */
                drawId?: (string|null);

                /** LiveOddsUpdated odds */
                odds?: (gmaing.events.v1.IOddsItem[]|null);
            }

            /** Represents a LiveOddsUpdated. */
            class LiveOddsUpdated implements ILiveOddsUpdated {

                /**
                 * Constructs a new LiveOddsUpdated.
                 * @param [properties] Properties to set
                 */
                constructor(properties?: gmaing.events.v1.ILiveOddsUpdated);

                /** LiveOddsUpdated market. */
                public market: string;

                /** LiveOddsUpdated session. */
                public session: string;

                /** LiveOddsUpdated drawId. */
                public drawId: string;

                /** LiveOddsUpdated odds. */
                public odds: gmaing.events.v1.IOddsItem[];

                /**
                 * Creates a new LiveOddsUpdated instance using the specified properties.
                 * @param [properties] Properties to set
                 * @returns LiveOddsUpdated instance
                 */
                public static create(properties?: gmaing.events.v1.ILiveOddsUpdated): gmaing.events.v1.LiveOddsUpdated;

                /**
                 * Encodes the specified LiveOddsUpdated message. Does not implicitly {@link gmaing.events.v1.LiveOddsUpdated.verify|verify} messages.
                 * @param message LiveOddsUpdated message or plain object to encode
                 * @param [writer] Writer to encode to
                 * @returns Writer
                 */
                public static encode(message: gmaing.events.v1.ILiveOddsUpdated, writer?: $protobuf.Writer): $protobuf.Writer;

                /**
                 * Encodes the specified LiveOddsUpdated message, length delimited. Does not implicitly {@link gmaing.events.v1.LiveOddsUpdated.verify|verify} messages.
                 * @param message LiveOddsUpdated message or plain object to encode
                 * @param [writer] Writer to encode to
                 * @returns Writer
                 */
                public static encodeDelimited(message: gmaing.events.v1.ILiveOddsUpdated, writer?: $protobuf.Writer): $protobuf.Writer;

                /**
                 * Decodes a LiveOddsUpdated message from the specified reader or buffer.
                 * @param reader Reader or buffer to decode from
                 * @param [length] Message length if known beforehand
                 * @returns LiveOddsUpdated
                 * @throws {Error} If the payload is not a reader or valid buffer
                 * @throws {$protobuf.util.ProtocolError} If required fields are missing
                 */
                public static decode(reader: ($protobuf.Reader|Uint8Array), length?: number): gmaing.events.v1.LiveOddsUpdated;

                /**
                 * Decodes a LiveOddsUpdated message from the specified reader or buffer, length delimited.
                 * @param reader Reader or buffer to decode from
                 * @returns LiveOddsUpdated
                 * @throws {Error} If the payload is not a reader or valid buffer
                 * @throws {$protobuf.util.ProtocolError} If required fields are missing
                 */
                public static decodeDelimited(reader: ($protobuf.Reader|Uint8Array)): gmaing.events.v1.LiveOddsUpdated;

                /**
                 * Verifies a LiveOddsUpdated message.
                 * @param message Plain object to verify
                 * @returns `null` if valid, otherwise the reason why it is not
                 */
                public static verify(message: { [k: string]: any }): (string|null);

                /**
                 * Creates a LiveOddsUpdated message from a plain object. Also converts values to their respective internal types.
                 * @param object Plain object
                 * @returns LiveOddsUpdated
                 */
                public static fromObject(object: { [k: string]: any }): gmaing.events.v1.LiveOddsUpdated;

                /**
                 * Creates a plain object from a LiveOddsUpdated message. Also converts values to other types if specified.
                 * @param message LiveOddsUpdated
                 * @param [options] Conversion options
                 * @returns Plain object
                 */
                public static toObject(message: gmaing.events.v1.LiveOddsUpdated, options?: $protobuf.IConversionOptions): { [k: string]: any };

                /**
                 * Converts this LiveOddsUpdated to JSON.
                 * @returns JSON object
                 */
                public toJSON(): { [k: string]: any };

                /**
                 * Gets the default type url for LiveOddsUpdated
                 * @param [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
                 * @returns The default type url
                 */
                public static getTypeUrl(typeUrlPrefix?: string): string;
            }

            /** Properties of an OddsItem. */
            interface IOddsItem {

                /** OddsItem digit */
                digit?: (number|null);

                /** OddsItem payoutMultiplier */
                payoutMultiplier?: (number|null);

                /** OddsItem suspended */
                suspended?: (boolean|null);
            }

            /** Represents an OddsItem. */
            class OddsItem implements IOddsItem {

                /**
                 * Constructs a new OddsItem.
                 * @param [properties] Properties to set
                 */
                constructor(properties?: gmaing.events.v1.IOddsItem);

                /** OddsItem digit. */
                public digit: number;

                /** OddsItem payoutMultiplier. */
                public payoutMultiplier: number;

                /** OddsItem suspended. */
                public suspended: boolean;

                /**
                 * Creates a new OddsItem instance using the specified properties.
                 * @param [properties] Properties to set
                 * @returns OddsItem instance
                 */
                public static create(properties?: gmaing.events.v1.IOddsItem): gmaing.events.v1.OddsItem;

                /**
                 * Encodes the specified OddsItem message. Does not implicitly {@link gmaing.events.v1.OddsItem.verify|verify} messages.
                 * @param message OddsItem message or plain object to encode
                 * @param [writer] Writer to encode to
                 * @returns Writer
                 */
                public static encode(message: gmaing.events.v1.IOddsItem, writer?: $protobuf.Writer): $protobuf.Writer;

                /**
                 * Encodes the specified OddsItem message, length delimited. Does not implicitly {@link gmaing.events.v1.OddsItem.verify|verify} messages.
                 * @param message OddsItem message or plain object to encode
                 * @param [writer] Writer to encode to
                 * @returns Writer
                 */
                public static encodeDelimited(message: gmaing.events.v1.IOddsItem, writer?: $protobuf.Writer): $protobuf.Writer;

                /**
                 * Decodes an OddsItem message from the specified reader or buffer.
                 * @param reader Reader or buffer to decode from
                 * @param [length] Message length if known beforehand
                 * @returns OddsItem
                 * @throws {Error} If the payload is not a reader or valid buffer
                 * @throws {$protobuf.util.ProtocolError} If required fields are missing
                 */
                public static decode(reader: ($protobuf.Reader|Uint8Array), length?: number): gmaing.events.v1.OddsItem;

                /**
                 * Decodes an OddsItem message from the specified reader or buffer, length delimited.
                 * @param reader Reader or buffer to decode from
                 * @returns OddsItem
                 * @throws {Error} If the payload is not a reader or valid buffer
                 * @throws {$protobuf.util.ProtocolError} If required fields are missing
                 */
                public static decodeDelimited(reader: ($protobuf.Reader|Uint8Array)): gmaing.events.v1.OddsItem;

                /**
                 * Verifies an OddsItem message.
                 * @param message Plain object to verify
                 * @returns `null` if valid, otherwise the reason why it is not
                 */
                public static verify(message: { [k: string]: any }): (string|null);

                /**
                 * Creates an OddsItem message from a plain object. Also converts values to their respective internal types.
                 * @param object Plain object
                 * @returns OddsItem
                 */
                public static fromObject(object: { [k: string]: any }): gmaing.events.v1.OddsItem;

                /**
                 * Creates a plain object from an OddsItem message. Also converts values to other types if specified.
                 * @param message OddsItem
                 * @param [options] Conversion options
                 * @returns Plain object
                 */
                public static toObject(message: gmaing.events.v1.OddsItem, options?: $protobuf.IConversionOptions): { [k: string]: any };

                /**
                 * Converts this OddsItem to JSON.
                 * @returns JSON object
                 */
                public toJSON(): { [k: string]: any };

                /**
                 * Gets the default type url for OddsItem
                 * @param [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
                 * @returns The default type url
                 */
                public static getTypeUrl(typeUrlPrefix?: string): string;
            }

            /** Properties of a BettingBetPlaced. */
            interface IBettingBetPlaced {

                /** BettingBetPlaced betId */
                betId?: (string|null);

                /** BettingBetPlaced userId */
                userId?: (string|null);

                /** BettingBetPlaced digit */
                digit?: (number|null);

                /** BettingBetPlaced amount */
                amount?: (number|Long|null);

                /** BettingBetPlaced drawId */
                drawId?: (string|null);

                /** BettingBetPlaced session */
                session?: (string|null);

                /** BettingBetPlaced placedAtMs */
                placedAtMs?: (number|Long|null);
            }

            /** Represents a BettingBetPlaced. */
            class BettingBetPlaced implements IBettingBetPlaced {

                /**
                 * Constructs a new BettingBetPlaced.
                 * @param [properties] Properties to set
                 */
                constructor(properties?: gmaing.events.v1.IBettingBetPlaced);

                /** BettingBetPlaced betId. */
                public betId: string;

                /** BettingBetPlaced userId. */
                public userId: string;

                /** BettingBetPlaced digit. */
                public digit: number;

                /** BettingBetPlaced amount. */
                public amount: (number|Long);

                /** BettingBetPlaced drawId. */
                public drawId: string;

                /** BettingBetPlaced session. */
                public session: string;

                /** BettingBetPlaced placedAtMs. */
                public placedAtMs: (number|Long);

                /**
                 * Creates a new BettingBetPlaced instance using the specified properties.
                 * @param [properties] Properties to set
                 * @returns BettingBetPlaced instance
                 */
                public static create(properties?: gmaing.events.v1.IBettingBetPlaced): gmaing.events.v1.BettingBetPlaced;

                /**
                 * Encodes the specified BettingBetPlaced message. Does not implicitly {@link gmaing.events.v1.BettingBetPlaced.verify|verify} messages.
                 * @param message BettingBetPlaced message or plain object to encode
                 * @param [writer] Writer to encode to
                 * @returns Writer
                 */
                public static encode(message: gmaing.events.v1.IBettingBetPlaced, writer?: $protobuf.Writer): $protobuf.Writer;

                /**
                 * Encodes the specified BettingBetPlaced message, length delimited. Does not implicitly {@link gmaing.events.v1.BettingBetPlaced.verify|verify} messages.
                 * @param message BettingBetPlaced message or plain object to encode
                 * @param [writer] Writer to encode to
                 * @returns Writer
                 */
                public static encodeDelimited(message: gmaing.events.v1.IBettingBetPlaced, writer?: $protobuf.Writer): $protobuf.Writer;

                /**
                 * Decodes a BettingBetPlaced message from the specified reader or buffer.
                 * @param reader Reader or buffer to decode from
                 * @param [length] Message length if known beforehand
                 * @returns BettingBetPlaced
                 * @throws {Error} If the payload is not a reader or valid buffer
                 * @throws {$protobuf.util.ProtocolError} If required fields are missing
                 */
                public static decode(reader: ($protobuf.Reader|Uint8Array), length?: number): gmaing.events.v1.BettingBetPlaced;

                /**
                 * Decodes a BettingBetPlaced message from the specified reader or buffer, length delimited.
                 * @param reader Reader or buffer to decode from
                 * @returns BettingBetPlaced
                 * @throws {Error} If the payload is not a reader or valid buffer
                 * @throws {$protobuf.util.ProtocolError} If required fields are missing
                 */
                public static decodeDelimited(reader: ($protobuf.Reader|Uint8Array)): gmaing.events.v1.BettingBetPlaced;

                /**
                 * Verifies a BettingBetPlaced message.
                 * @param message Plain object to verify
                 * @returns `null` if valid, otherwise the reason why it is not
                 */
                public static verify(message: { [k: string]: any }): (string|null);

                /**
                 * Creates a BettingBetPlaced message from a plain object. Also converts values to their respective internal types.
                 * @param object Plain object
                 * @returns BettingBetPlaced
                 */
                public static fromObject(object: { [k: string]: any }): gmaing.events.v1.BettingBetPlaced;

                /**
                 * Creates a plain object from a BettingBetPlaced message. Also converts values to other types if specified.
                 * @param message BettingBetPlaced
                 * @param [options] Conversion options
                 * @returns Plain object
                 */
                public static toObject(message: gmaing.events.v1.BettingBetPlaced, options?: $protobuf.IConversionOptions): { [k: string]: any };

                /**
                 * Converts this BettingBetPlaced to JSON.
                 * @returns JSON object
                 */
                public toJSON(): { [k: string]: any };

                /**
                 * Gets the default type url for BettingBetPlaced
                 * @param [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
                 * @returns The default type url
                 */
                public static getTypeUrl(typeUrlPrefix?: string): string;
            }

            /** Properties of a BettingSettlementApplied. */
            interface IBettingSettlementApplied {

                /** BettingSettlementApplied runId */
                runId?: (string|null);

                /** BettingSettlementApplied settlementId */
                settlementId?: (string|null);

                /** BettingSettlementApplied drawId */
                drawId?: (string|null);

                /** BettingSettlementApplied winningDigit */
                winningDigit?: (number|null);

                /** BettingSettlementApplied claimedRows */
                claimedRows?: (number|null);

                /** BettingSettlementApplied appliedRows */
                appliedRows?: (number|null);

                /** BettingSettlementApplied adminDelta */
                adminDelta?: (number|Long|null);

                /** BettingSettlementApplied appliedAtMs */
                appliedAtMs?: (number|Long|null);
            }

            /** Represents a BettingSettlementApplied. */
            class BettingSettlementApplied implements IBettingSettlementApplied {

                /**
                 * Constructs a new BettingSettlementApplied.
                 * @param [properties] Properties to set
                 */
                constructor(properties?: gmaing.events.v1.IBettingSettlementApplied);

                /** BettingSettlementApplied runId. */
                public runId: string;

                /** BettingSettlementApplied settlementId. */
                public settlementId: string;

                /** BettingSettlementApplied drawId. */
                public drawId: string;

                /** BettingSettlementApplied winningDigit. */
                public winningDigit: number;

                /** BettingSettlementApplied claimedRows. */
                public claimedRows: number;

                /** BettingSettlementApplied appliedRows. */
                public appliedRows: number;

                /** BettingSettlementApplied adminDelta. */
                public adminDelta: (number|Long);

                /** BettingSettlementApplied appliedAtMs. */
                public appliedAtMs: (number|Long);

                /**
                 * Creates a new BettingSettlementApplied instance using the specified properties.
                 * @param [properties] Properties to set
                 * @returns BettingSettlementApplied instance
                 */
                public static create(properties?: gmaing.events.v1.IBettingSettlementApplied): gmaing.events.v1.BettingSettlementApplied;

                /**
                 * Encodes the specified BettingSettlementApplied message. Does not implicitly {@link gmaing.events.v1.BettingSettlementApplied.verify|verify} messages.
                 * @param message BettingSettlementApplied message or plain object to encode
                 * @param [writer] Writer to encode to
                 * @returns Writer
                 */
                public static encode(message: gmaing.events.v1.IBettingSettlementApplied, writer?: $protobuf.Writer): $protobuf.Writer;

                /**
                 * Encodes the specified BettingSettlementApplied message, length delimited. Does not implicitly {@link gmaing.events.v1.BettingSettlementApplied.verify|verify} messages.
                 * @param message BettingSettlementApplied message or plain object to encode
                 * @param [writer] Writer to encode to
                 * @returns Writer
                 */
                public static encodeDelimited(message: gmaing.events.v1.IBettingSettlementApplied, writer?: $protobuf.Writer): $protobuf.Writer;

                /**
                 * Decodes a BettingSettlementApplied message from the specified reader or buffer.
                 * @param reader Reader or buffer to decode from
                 * @param [length] Message length if known beforehand
                 * @returns BettingSettlementApplied
                 * @throws {Error} If the payload is not a reader or valid buffer
                 * @throws {$protobuf.util.ProtocolError} If required fields are missing
                 */
                public static decode(reader: ($protobuf.Reader|Uint8Array), length?: number): gmaing.events.v1.BettingSettlementApplied;

                /**
                 * Decodes a BettingSettlementApplied message from the specified reader or buffer, length delimited.
                 * @param reader Reader or buffer to decode from
                 * @returns BettingSettlementApplied
                 * @throws {Error} If the payload is not a reader or valid buffer
                 * @throws {$protobuf.util.ProtocolError} If required fields are missing
                 */
                public static decodeDelimited(reader: ($protobuf.Reader|Uint8Array)): gmaing.events.v1.BettingSettlementApplied;

                /**
                 * Verifies a BettingSettlementApplied message.
                 * @param message Plain object to verify
                 * @returns `null` if valid, otherwise the reason why it is not
                 */
                public static verify(message: { [k: string]: any }): (string|null);

                /**
                 * Creates a BettingSettlementApplied message from a plain object. Also converts values to their respective internal types.
                 * @param object Plain object
                 * @returns BettingSettlementApplied
                 */
                public static fromObject(object: { [k: string]: any }): gmaing.events.v1.BettingSettlementApplied;

                /**
                 * Creates a plain object from a BettingSettlementApplied message. Also converts values to other types if specified.
                 * @param message BettingSettlementApplied
                 * @param [options] Conversion options
                 * @returns Plain object
                 */
                public static toObject(message: gmaing.events.v1.BettingSettlementApplied, options?: $protobuf.IConversionOptions): { [k: string]: any };

                /**
                 * Converts this BettingSettlementApplied to JSON.
                 * @returns JSON object
                 */
                public toJSON(): { [k: string]: any };

                /**
                 * Gets the default type url for BettingSettlementApplied
                 * @param [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
                 * @returns The default type url
                 */
                public static getTypeUrl(typeUrlPrefix?: string): string;
            }

            /** Properties of a SystemNotice. */
            interface ISystemNotice {

                /** SystemNotice level */
                level?: (string|null);

                /** SystemNotice code */
                code?: (string|null);

                /** SystemNotice message */
                message?: (string|null);
            }

            /** Represents a SystemNotice. */
            class SystemNotice implements ISystemNotice {

                /**
                 * Constructs a new SystemNotice.
                 * @param [properties] Properties to set
                 */
                constructor(properties?: gmaing.events.v1.ISystemNotice);

                /** SystemNotice level. */
                public level: string;

                /** SystemNotice code. */
                public code: string;

                /** SystemNotice message. */
                public message: string;

                /**
                 * Creates a new SystemNotice instance using the specified properties.
                 * @param [properties] Properties to set
                 * @returns SystemNotice instance
                 */
                public static create(properties?: gmaing.events.v1.ISystemNotice): gmaing.events.v1.SystemNotice;

                /**
                 * Encodes the specified SystemNotice message. Does not implicitly {@link gmaing.events.v1.SystemNotice.verify|verify} messages.
                 * @param message SystemNotice message or plain object to encode
                 * @param [writer] Writer to encode to
                 * @returns Writer
                 */
                public static encode(message: gmaing.events.v1.ISystemNotice, writer?: $protobuf.Writer): $protobuf.Writer;

                /**
                 * Encodes the specified SystemNotice message, length delimited. Does not implicitly {@link gmaing.events.v1.SystemNotice.verify|verify} messages.
                 * @param message SystemNotice message or plain object to encode
                 * @param [writer] Writer to encode to
                 * @returns Writer
                 */
                public static encodeDelimited(message: gmaing.events.v1.ISystemNotice, writer?: $protobuf.Writer): $protobuf.Writer;

                /**
                 * Decodes a SystemNotice message from the specified reader or buffer.
                 * @param reader Reader or buffer to decode from
                 * @param [length] Message length if known beforehand
                 * @returns SystemNotice
                 * @throws {Error} If the payload is not a reader or valid buffer
                 * @throws {$protobuf.util.ProtocolError} If required fields are missing
                 */
                public static decode(reader: ($protobuf.Reader|Uint8Array), length?: number): gmaing.events.v1.SystemNotice;

                /**
                 * Decodes a SystemNotice message from the specified reader or buffer, length delimited.
                 * @param reader Reader or buffer to decode from
                 * @returns SystemNotice
                 * @throws {Error} If the payload is not a reader or valid buffer
                 * @throws {$protobuf.util.ProtocolError} If required fields are missing
                 */
                public static decodeDelimited(reader: ($protobuf.Reader|Uint8Array)): gmaing.events.v1.SystemNotice;

                /**
                 * Verifies a SystemNotice message.
                 * @param message Plain object to verify
                 * @returns `null` if valid, otherwise the reason why it is not
                 */
                public static verify(message: { [k: string]: any }): (string|null);

                /**
                 * Creates a SystemNotice message from a plain object. Also converts values to their respective internal types.
                 * @param object Plain object
                 * @returns SystemNotice
                 */
                public static fromObject(object: { [k: string]: any }): gmaing.events.v1.SystemNotice;

                /**
                 * Creates a plain object from a SystemNotice message. Also converts values to other types if specified.
                 * @param message SystemNotice
                 * @param [options] Conversion options
                 * @returns Plain object
                 */
                public static toObject(message: gmaing.events.v1.SystemNotice, options?: $protobuf.IConversionOptions): { [k: string]: any };

                /**
                 * Converts this SystemNotice to JSON.
                 * @returns JSON object
                 */
                public toJSON(): { [k: string]: any };

                /**
                 * Gets the default type url for SystemNotice
                 * @param [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
                 * @returns The default type url
                 */
                public static getTypeUrl(typeUrlPrefix?: string): string;
            }

            /** Properties of a Heartbeat. */
            interface IHeartbeat {

                /** Heartbeat heartbeatSeq */
                heartbeatSeq?: (number|Long|null);
            }

            /** Represents a Heartbeat. */
            class Heartbeat implements IHeartbeat {

                /**
                 * Constructs a new Heartbeat.
                 * @param [properties] Properties to set
                 */
                constructor(properties?: gmaing.events.v1.IHeartbeat);

                /** Heartbeat heartbeatSeq. */
                public heartbeatSeq: (number|Long);

                /**
                 * Creates a new Heartbeat instance using the specified properties.
                 * @param [properties] Properties to set
                 * @returns Heartbeat instance
                 */
                public static create(properties?: gmaing.events.v1.IHeartbeat): gmaing.events.v1.Heartbeat;

                /**
                 * Encodes the specified Heartbeat message. Does not implicitly {@link gmaing.events.v1.Heartbeat.verify|verify} messages.
                 * @param message Heartbeat message or plain object to encode
                 * @param [writer] Writer to encode to
                 * @returns Writer
                 */
                public static encode(message: gmaing.events.v1.IHeartbeat, writer?: $protobuf.Writer): $protobuf.Writer;

                /**
                 * Encodes the specified Heartbeat message, length delimited. Does not implicitly {@link gmaing.events.v1.Heartbeat.verify|verify} messages.
                 * @param message Heartbeat message or plain object to encode
                 * @param [writer] Writer to encode to
                 * @returns Writer
                 */
                public static encodeDelimited(message: gmaing.events.v1.IHeartbeat, writer?: $protobuf.Writer): $protobuf.Writer;

                /**
                 * Decodes a Heartbeat message from the specified reader or buffer.
                 * @param reader Reader or buffer to decode from
                 * @param [length] Message length if known beforehand
                 * @returns Heartbeat
                 * @throws {Error} If the payload is not a reader or valid buffer
                 * @throws {$protobuf.util.ProtocolError} If required fields are missing
                 */
                public static decode(reader: ($protobuf.Reader|Uint8Array), length?: number): gmaing.events.v1.Heartbeat;

                /**
                 * Decodes a Heartbeat message from the specified reader or buffer, length delimited.
                 * @param reader Reader or buffer to decode from
                 * @returns Heartbeat
                 * @throws {Error} If the payload is not a reader or valid buffer
                 * @throws {$protobuf.util.ProtocolError} If required fields are missing
                 */
                public static decodeDelimited(reader: ($protobuf.Reader|Uint8Array)): gmaing.events.v1.Heartbeat;

                /**
                 * Verifies a Heartbeat message.
                 * @param message Plain object to verify
                 * @returns `null` if valid, otherwise the reason why it is not
                 */
                public static verify(message: { [k: string]: any }): (string|null);

                /**
                 * Creates a Heartbeat message from a plain object. Also converts values to their respective internal types.
                 * @param object Plain object
                 * @returns Heartbeat
                 */
                public static fromObject(object: { [k: string]: any }): gmaing.events.v1.Heartbeat;

                /**
                 * Creates a plain object from a Heartbeat message. Also converts values to other types if specified.
                 * @param message Heartbeat
                 * @param [options] Conversion options
                 * @returns Plain object
                 */
                public static toObject(message: gmaing.events.v1.Heartbeat, options?: $protobuf.IConversionOptions): { [k: string]: any };

                /**
                 * Converts this Heartbeat to JSON.
                 * @returns JSON object
                 */
                public toJSON(): { [k: string]: any };

                /**
                 * Gets the default type url for Heartbeat
                 * @param [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
                 * @returns The default type url
                 */
                public static getTypeUrl(typeUrlPrefix?: string): string;
            }
        }
    }
}
