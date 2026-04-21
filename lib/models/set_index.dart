class SetIndexResult {
  final String id;
  final DateTime drawDate;
  final String drawTime;
  final double setValue;
  final double setIndex;
  final int resultDigit;
  final String source;
  final DateTime createdAt;

  SetIndexResult({
    required this.id,
    required this.drawDate,
    required this.drawTime,
    required this.setValue,
    required this.setIndex,
    required this.resultDigit,
    required this.source,
    required this.createdAt,
  });

  factory SetIndexResult.fromJson(Map<String, dynamic> json) {
    return SetIndexResult(
      id: json['id'] as String,
      drawDate: DateTime.parse(json['draw_date'] as String),
      drawTime: json['draw_time'] as String,
      setValue: (json['set_value'] as num).toDouble(),
      setIndex: (json['set_index'] as num).toDouble(),
      resultDigit: json['result_digit'] as int,
      source: json['source'] as String? ?? 'api',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'draw_date': drawDate.toIso8601String().split('T')[0],
      'draw_time': drawTime,
      'set_value': setValue,
      'set_index': setIndex,
      'result_digit': resultDigit,
      'source': source,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get formattedSetValue => setValue.toStringAsFixed(2);
  String get formattedSetIndex => setIndex.toStringAsFixed(2);
  String get formattedResultDigit => resultDigit.toString().padLeft(2, '0');
}
