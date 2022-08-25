// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'proxy_group.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProxyGroup _$ProxyGroupFromJson(Map<String, dynamic> json) => ProxyGroup(
      type: $enumDecode(_$ProxyTypeEnumMap, json['type']),
      proxies: (json['proxies'] as List<dynamic>)
          .map((e) => Proxy.fromJson(e as Map<String, dynamic>))
          .toList(),
      now: json['now'] as String,
    );

Map<String, dynamic> _$ProxyGroupToJson(ProxyGroup instance) =>
    <String, dynamic>{
      'type': _$ProxyTypeEnumMap[instance.type]!,
      'proxies': instance.proxies,
      'now': instance.now,
    };

const _$ProxyTypeEnumMap = {
  ProxyType.direct: 'direct',
  ProxyType.reject: 'reject',
  ProxyType.shadowsocks: 'shadowsocks',
  ProxyType.shadowsocksR: 'shadowsocksR',
  ProxyType.snell: 'snell',
  ProxyType.socks5: 'socks5',
  ProxyType.http: 'http',
  ProxyType.vmess: 'vmess',
  ProxyType.trojan: 'trojan',
  ProxyType.relay: 'relay',
  ProxyType.selector: 'selector',
  ProxyType.fallback: 'fallback',
  ProxyType.uRLTest: 'uRLTest',
  ProxyType.loadBalance: 'loadBalance',
  ProxyType.unknown: 'unknown',
};
