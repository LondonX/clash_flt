import 'package:json_annotation/json_annotation.dart';

import 'proxy.dart';
import 'proxy_group.dart';

part 'profile.g.dart';

@JsonSerializable(fieldRename: FieldRename.kebab)
class Profile {
  final String filePath;
  final int port;
  final int socksPort;
  final bool? allowLan;
  final String mode;
  final String logLevel;
  final String? externalController;
  final List<Proxy> proxies;
  final List<ProxyGroup> proxyGroups;
  final List<String> rules;
  Profile({
    required this.filePath,
    required this.port,
    required this.socksPort,
    this.allowLan,
    required this.mode,
    required this.logLevel,
    this.externalController,
    required this.proxies,
    required this.proxyGroups,
    required this.rules,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return _$ProfileFromJson(json);
  }

  Map<String, dynamic> toJson() {
    return _$ProfileToJson(this);
  }
}
