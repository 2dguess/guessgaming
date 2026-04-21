import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/realtime/live_events_realtime.dart';

class LiveProtoMetricsCard extends ConsumerWidget {
  const LiveProtoMetricsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metrics = ref.watch(liveProtoMetricsProvider);
    final circuit = ref.watch(liveProtoCircuitProvider);
    final opsLogs = ref.watch(liveProtoOpsLogProvider);
    final int decodeErr = metrics.decodeErrorCount;
    final int fallback = metrics.fallbackJsonCount;
    final bool isCritical = circuit.isOpen;
    final bool isWarn = !isCritical && (decodeErr >= 5 || fallback >= 10);
    final String status = isCritical
        ? 'CRIT'
        : (isWarn ? 'WARN' : 'OK');
    final Color statusColor = isCritical
        ? Colors.red
        : (isWarn ? Colors.orange : Colors.green);
    final String actionText = isCritical
        ? 'Action: protobuf decode is paused. Keep fallback active, inspect payload/schema, and rollback recent realtime changes if needed.'
        : (isWarn
            ? 'Action: investigate rising decode/fallback counts (publisher payload, channel, schema version).'
            : 'Action: no urgent fix needed. Continue monitoring.');

    Widget metricTile(String label, int value, Color color) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Text(
                '$value',
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Live Proto Metrics (Debug)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Status: $status',
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              circuit.isOpen
                  ? 'Circuit: OPEN until ${circuit.openUntil}'
                  : 'Circuit: CLOSED',
              style: TextStyle(
                color: circuit.isOpen ? Colors.red : Colors.green,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              actionText,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black87,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                metricTile(
                  'Decode OK',
                  metrics.decodeSuccessCount,
                  Colors.green,
                ),
                const SizedBox(width: 8),
                metricTile(
                  'Decode ERR',
                  metrics.decodeErrorCount,
                  Colors.red,
                ),
                const SizedBox(width: 8),
                metricTile(
                  'JSON Fallback',
                  metrics.fallbackJsonCount,
                  Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'Ops log (latest 30):',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            ),
            const SizedBox(height: 6),
            Container(
              constraints: const BoxConstraints(maxHeight: 130),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(8),
              ),
              child: opsLogs.isEmpty
                  ? const Text(
                      'No circuit events yet',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    )
                  : ListView.builder(
                      itemCount: opsLogs.length,
                      itemBuilder: (context, index) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          opsLogs[index],
                          style:
                              const TextStyle(fontSize: 11, color: Colors.black87),
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
