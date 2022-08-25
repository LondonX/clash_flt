import 'package:json_annotation/json_annotation.dart';

part 'provider.g.dart';

@JsonSerializable()
class Provider {
  final String name;
  final ProviderType type;
  final ProviderVehicleType vehicleType;
  final int updatedAt;
  Provider({
    required this.name,
    required this.type,
    required this.vehicleType,
    required this.updatedAt,
  });

  factory Provider.fromJson(Map<String, dynamic> json) {
    return _$ProviderFromJson(json);
  }

  Map<String, dynamic> toJson() {
    return _$ProviderToJson(this);
  }

  @override
  String toString() {
    return 'Provider(name: $name, type: $type, vehicleType: $vehicleType, updatedAt: $updatedAt)';
  }
}

enum ProviderType {
  proxy,
  rule,
}

enum ProviderVehicleType {
  http,
  file,
  compatible,
}
