// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'provider.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Provider _$ProviderFromJson(Map<String, dynamic> json) => Provider(
      name: json['name'] as String,
      type: $enumDecode(_$ProviderTypeEnumMap, json['type']),
      vehicleType:
          $enumDecode(_$ProviderVehicleTypeEnumMap, json['vehicleType']),
      updatedAt: json['updatedAt'] as int,
    );

Map<String, dynamic> _$ProviderToJson(Provider instance) => <String, dynamic>{
      'name': instance.name,
      'type': _$ProviderTypeEnumMap[instance.type]!,
      'vehicleType': _$ProviderVehicleTypeEnumMap[instance.vehicleType]!,
      'updatedAt': instance.updatedAt,
    };

const _$ProviderTypeEnumMap = {
  ProviderType.proxy: 'proxy',
  ProviderType.rule: 'rule',
};

const _$ProviderVehicleTypeEnumMap = {
  ProviderVehicleType.http: 'http',
  ProviderVehicleType.file: 'file',
  ProviderVehicleType.compatible: 'compatible',
};
