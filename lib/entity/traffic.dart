import 'package:json_annotation/json_annotation.dart';

part 'traffic.g.dart';

@JsonSerializable()
class Traffic {
  final int up;
  final int down;
  const Traffic({
    required this.up,
    required this.down,
  });
  static const zero = Traffic(up: 0, down: 0);

  factory Traffic.fromJson(Map<String, dynamic> json) {
    return _$TrafficFromJson(json);
  }

  Map<String, dynamic> toJson() {
    return _$TrafficToJson(this);
  }

  @override
  bool operator ==(covariant Traffic other) {
    if (identical(this, other)) return true;

    return other.up == up && other.down == down;
  }

  @override
  int get hashCode => up.hashCode ^ down.hashCode;
}
