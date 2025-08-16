class ChartDataPoint {
  final double x;
  final double y;

  ChartDataPoint(this.x, this.y);

  @override
  String toString() => 'ChartDataPoint(x: $x, y: $y)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChartDataPoint && other.x == x && other.y == y;
  }

  @override
  int get hashCode => Object.hash(x, y);

  factory ChartDataPoint.fromMap(Map<String, dynamic> map) {
    return ChartDataPoint(
      map['x']?.toDouble() ?? 0.0,
      map['y']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'x': x,
      'y': y,
    };
  }

  ChartDataPoint copyWith({
    double? x,
    double? y,
  }) {
    return ChartDataPoint(
      x ?? this.x,
      y ?? this.y,
    );
  }
}
