// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tunnel_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TunnelState _$TunnelStateFromJson(Map<String, dynamic> json) => TunnelState(
      mode: $enumDecode(_$TunnelStateModeEnumMap, json['mode']),
    );

Map<String, dynamic> _$TunnelStateToJson(TunnelState instance) =>
    <String, dynamic>{
      'mode': _$TunnelStateModeEnumMap[instance.mode]!,
    };

const _$TunnelStateModeEnumMap = {
  TunnelStateMode.direct: 'direct',
  TunnelStateMode.global: 'global',
  TunnelStateMode.rule: 'rule',
  TunnelStateMode.script: 'script',
};
