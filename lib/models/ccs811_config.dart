import 'package:equatable/equatable.dart';

class CCS811Config extends Equatable {
  final int updatePeriod;
  final bool includeLocationData;

  const CCS811Config({
    this.updatePeriod = 1000,
    this.includeLocationData = false,
  });

  CCS811Config copyWith({
    int? updatePeriod,
    bool? includeLocationData,
  }) {
    return CCS811Config(
      updatePeriod: updatePeriod ?? this.updatePeriod,
      includeLocationData: includeLocationData ?? this.includeLocationData,
    );
  }

  factory CCS811Config.fromJson(Map<String, dynamic> json) {
    return CCS811Config(
      updatePeriod: json['updatePeriod'] ?? 1000,
      includeLocationData: json['includeLocationData'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'updatePeriod': updatePeriod,
      'includeLocationData': includeLocationData,
    };
  }

  @override
  List<Object?> get props => [
        updatePeriod,
        includeLocationData,
      ];
}
