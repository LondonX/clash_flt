import 'package:json_annotation/json_annotation.dart';
part 'tunnel_state.g.dart';

@JsonSerializable()
class TunnelState {
  final TunnelStateMode mode;
  TunnelState({
    required this.mode,
  });

  factory TunnelState.fromJson(Map<String, dynamic> json) {
    return _$TunnelStateFromJson(json);
  }

  Map<String, dynamic> toJson() {
    return _$TunnelStateToJson(this);
  }
}

enum TunnelStateMode {
  direct,
  global,
  rule,
  script,
}
