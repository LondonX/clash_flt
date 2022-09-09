import 'package:json_annotation/json_annotation.dart';

part 'proxy_group.g.dart';

@JsonSerializable()
class ProxyGroup {
  final String name;
  final String type;
  final List<String> proxies;
  final String? url; //only url-test
  final int? interval;
  ProxyGroup({
    required this.name,
    required this.type,
    required this.proxies,
    required this.url,
    this.interval,
  });

  factory ProxyGroup.fromJson(Map<String, dynamic> json) {
    return _$ProxyGroupFromJson(json);
  }

  Map<String, dynamic> toJson() {
    return _$ProxyGroupToJson(this);
  }

  @override
  String toString() {
    return 'ProxyGroup(name: $name, type: $type, proxies: $proxies, url: $url, interval: $interval)';
  }
}
