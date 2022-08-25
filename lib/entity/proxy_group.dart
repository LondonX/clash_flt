import 'package:json_annotation/json_annotation.dart';

import 'proxy.dart';

part 'proxy_group.g.dart';

@JsonSerializable()
class ProxyGroup {
  final ProxyType type;
  final List<Proxy> proxies;
  final String now;
  ProxyGroup({
    required this.type,
    required this.proxies,
    required this.now,
  });

  factory ProxyGroup.fromJson(Map<String, dynamic> json) {
    //fix cast issue
    final proxies = (json['proxies'] as List)
        .map(
          (e) => Map<String, dynamic>.from(e),
        )
        .toList();
    json['proxies'] = proxies;
    return _$ProxyGroupFromJson(json);
  }

  Map<String, dynamic> toJson() {
    return _$ProxyGroupToJson(this);
  }

  @override
  String toString() => 'ProxyGroup(type: $type, proxies: $proxies, now: $now)';
}

enum ProxySort {
  title,
  delay,
}
